extends "res://tests/test_base.gd"
## Evey: found hungry on the road, won over with food, follows Chad everywhere (temples
## too), bites enemies near him, makes bandits drop their loot, and is remembered in the save.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_companion.json"


func _new_game() -> Game:
	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	return game


func _at(room: Vector2i, x: float, y: float) -> Vector2:
	return WorldMap.room_origin(room) + (Vector2(x, y) + Vector2(0.5, 0.5)) * WorldMap.TILE


func _wait_until(condition: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if condition.call():
			return true
		await physics_frame
	return condition.call()


func _close_dialogue(game: Game) -> void:
	var box: DialogueBox = game.get_node("HUD/DialogueBox")
	await _frames(1)
	var guard := 0
	while box.is_open() and guard < 40:
		box.advance()
		await process_frame
		box.advance()
		await process_frame
		guard += 1
	await _settle()


func _spawn(game: Game, kind: String, pos: Vector2) -> Node2D:
	var node := Entities.create(kind)
	node.position = pos - game.current_room().position
	game.current_room().add_child(node)
	return node


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	var game := _new_game()
	await _physics_frames(2)
	var player: Player = game.get_node("Player")
	game.day_night.seconds_per_day = 1.0e9
	var evey: Companion = get_first_node_in_group("companion")
	var road := Vector2i(0, 0)
	_check(evey != null and evey.joined, "Evey is with Chad from the start")
	_check(evey.position.distance_to(player.position) < 150.0, "at his heels")
	_check(not evey.can_interact({}), "Attack near her swings the cutlass, not a chat")
	var brownie_dog := GameData.dog("brownie")
	_check(not brownie_dog.is_empty(), "Brownie is one of the stray dogs now")
	var on_road: Array = game.world.objects_in(road).filter(
		func(o): return o["kind"] == "topdog" and o["arg"] == "brownie"
	)
	_check(on_road.size() == 1, "she waits on the road from the wharf")
	game.go_to(road, _at(road, 10, 4))
	await _physics_frames(2)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()

	# --- following ----------------------------------------------------------------------------
	player.position = _at(road, 14, 7)
	var near := await _wait_until(
		func(): return evey.position.distance_to(player.position) < 140.0, 180
	)
	_check(near, "she follows Chad")
	player.position = _at(road, 2, 2)
	await _physics_frames(3)
	_check(evey.position.distance_to(player.position) < 200.0, "she catches up from far away")

	# --- biting -------------------------------------------------------------------------------
	player.position = _at(road, 10, 7)
	await _physics_frames(30)
	var dog: Pothound = _spawn(game, "dog", player.position + Vector2(160, -40))
	dog.coin_chance = 0.0
	dog.snack_chance = 0.0
	var start := dog.health
	var dog_ref: WeakRef = weakref(dog)
	var bitten := await _wait_until(
		func(): return dog_ref.get_ref() == null or dog_ref.get_ref().health < start, 180
	)
	_check(bitten, "she bites an enemy near Chad")
	if dog_ref.get_ref() != null:
		dog.free()
	player.money = 0
	var bandit: Bandit = _spawn(game, "bandit", player.position + Vector2(-150, 0))
	bandit.loot_money = 6
	bandit.state = Bandit.State.FLEE
	bandit.set("_timer", 6.0)
	var dropped := await _wait_until(func(): return player.money == 6, 180)
	_check(dropped, "a bitten bandit drops what he stole")
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()

	# --- temples and saving -------------------------------------------------------------------
	var entrance := Vector2i(1, 2)
	game.enter_map("temple1", entrance, _at(entrance, 9, 7))
	await _physics_frames(2)
	_check(evey.position.distance_to(player.position) < 150.0, "she comes into the temple")
	game.save_game()
	game.free()
	game = _new_game()
	await _physics_frames(2)
	player = game.get_node("Player")
	evey = get_first_node_in_group("companion")
	_check(evey.joined, "the save remembers her")
	_check(evey.position.distance_to(player.position) < 150.0, "and she is at Chad's heels")
	game.free()

	# --- an old save with Brownie as the companion ------------------------------------------
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	(
		file
		. store_string(
			(
				JSON
				. stringify(
					{
						"version": 1,
						"room": [0, 1],
						"position": [600, 400],
						"flags": {"brownie_joined": true, "brownie_level": 3, "brownie_xp": 4},
					}
				)
			)
		)
	)
	file.close()
	game = _new_game()
	await _physics_frames(2)
	_check(int(game.flags.get("evey_level", 0)) == 3, "Brownie's old level carries over to Evey")
	_check(int(game.flags.get("evey_xp", 0)) == 4, "and so does her experience")
	_check(not game.flags.has("brownie_joined"), "the old flag is cleared")
	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
