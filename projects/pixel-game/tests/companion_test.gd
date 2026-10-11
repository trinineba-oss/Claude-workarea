extends "res://tests/test_base.gd"
## Brownie: found hungry on the road, won over with food, follows Chad everywhere (temples
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
	var brownie: Companion = get_first_node_in_group("companion")
	var road := Vector2i(0, 0)
	_check(brownie != null and not brownie.joined, "Brownie is waiting to be found")
	_check(brownie.position == _at(road, 6, 4), "at her spot on the road")

	# --- hungry, then fed ---------------------------------------------------------------------
	game.go_to(road, _at(road, 7, 4))
	await _physics_frames(2)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	player.facing = Vector2.LEFT
	await _physics_frames(2)
	_check(player.target == brownie, "Chad can talk to her")
	Input.action_press(&"interact")
	await _physics_frames(2)
	Input.action_release(&"interact")
	await _frames(1)
	_check(game.is_talking() and not brownie.joined, "with nothing to eat she just watches")
	await _close_dialogue(game)
	game.inventory.add("mango", 2)
	brownie.use(game)
	await _close_dialogue(game)
	_check(brownie.joined and game.flags.get(Companion.FLAG, false), "a mango wins her over")
	_check(game.inventory.count("mango") == 1, "she eats one")
	_check(not brownie.can_interact({}), "once she joins, attack is for enemies again")

	# --- following ----------------------------------------------------------------------------
	player.position = _at(road, 14, 7)
	var near := await _wait_until(
		func(): return brownie.position.distance_to(player.position) < 140.0, 180
	)
	_check(near, "she follows Chad")
	player.position = _at(road, 2, 2)
	await _physics_frames(3)
	_check(brownie.position.distance_to(player.position) < 200.0, "she catches up from far away")

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
	_check(brownie.position.distance_to(player.position) < 150.0, "she comes into the temple")
	game.save_game()
	game.free()
	game = _new_game()
	await _physics_frames(2)
	player = game.get_node("Player")
	brownie = get_first_node_in_group("companion")
	_check(brownie.joined, "the save remembers her")
	_check(brownie.position.distance_to(player.position) < 150.0, "and she is at Chad's heels")
	game.free()

	# --- not yet found: she stays on the road -------------------------------------------------
	DirAccess.remove_absolute(SAVE_PATH)
	game = _new_game()
	await _physics_frames(2)
	brownie = get_first_node_in_group("companion")
	game.enter_map("temple1", entrance, _at(entrance, 9, 7))
	await _physics_frames(3)
	_check(not brownie.visible, "an unfound Brownie is not in the temple")
	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
