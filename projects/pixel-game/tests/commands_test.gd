extends "res://tests/test_base.gd"
## Evey's orders: the dog menu (pausing, picking; no fighting orders), stay and come
## (holding a pressure plate), fetch (swimming across water), and dig (sniffing, rewards, dug
## spots staying dug).

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_commands.json"


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


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)
	await _frames(1)


func _spawn(game: Game, kind: String, pos: Vector2) -> Node2D:
	var node := Entities.create(kind)
	node.position = pos - game.current_room().position
	game.current_room().add_child(node)
	return node


func _clear_enemies() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	var game := _new_game()
	await _physics_frames(2)
	var player: Player = game.get_node("Player")
	var menu: DogMenu = game.get_node("HUD/DogMenu")
	game.day_night.seconds_per_day = 1.0e9
	var evey: Companion = get_first_node_in_group("companion")
	var road := Vector2i(0, 0)
	game.go_to(road, _at(road, 10, 3))
	await _physics_frames(2)
	_clear_enemies()

	# --- the menu -----------------------------------------------------------------------------
	evey.joined = false
	await _tap(&"dog")
	_check(not menu.is_open(), "no dog menu without a dog")
	evey.join()
	evey.catch_up(player)
	await _tap(&"dog")
	_check(menu.is_open() and paused, "Dog opens the menu and pauses the game")
	_check(menu.options == ["stay", "fetch", "dig", "close"], "the orders (none of them fighting)")
	await _tap(&"attack")
	await _settle()
	_check(not menu.is_open() and not paused, "picking an order closes the menu")
	_check(evey.mode == Companion.Mode.STAY, "the first order is Stay")
	await _tap(&"dog")
	_check(menu.options[0] == "come", "while she stays, the menu offers Come")
	await _tap(&"pause")
	await _settle()
	_check(not menu.is_open() and not paused, "Pause closes the menu without an order")
	_check(evey.mode == Companion.Mode.STAY, "and changes nothing")

	# --- stay and come ------------------------------------------------------------------------
	var spot := evey.position
	player.position = _at(road, 16, 7)
	await _physics_frames(60)
	_check(evey.position == spot, "she stays put while Chad walks off")
	evey.come()
	var back := await _wait_until(
		func(): return evey.position.distance_to(player.position) < 150.0, 180
	)
	_check(back and evey.mode == Companion.Mode.FOLLOW, "Come brings her back")

	# --- fetch, across water ------------------------------------------------------------------
	var hall := Vector2i(0, 0)
	game.enter_map("temple1", hall, _at(hall, 8, 6))
	await _physics_frames(2)
	_clear_enemies()
	var coin: Pickup = _spawn(game, "coin", _at(hall, 1, 8))
	var money := player.money
	_check(evey.fetch(), "there is a coin to fetch (over the water)")
	var swam := await _wait_until(func(): return evey.get("_swimming"), 240)
	_check(swam, "she swims for it")
	var fetched := await _wait_until(func(): return player.money == money + 1, 600)
	_check(fetched, "and brings it back to Chad")
	_check(not is_instance_valid(coin), "the coin is used up")
	_check(evey.mode == Companion.Mode.FOLLOW, "then she follows again")
	_check(not evey.fetch(), "with nothing left to fetch she says so")

	# --- stay on a pressure plate -------------------------------------------------------------
	var east := Vector2i(2, 1)
	game.go_to(east, _at(east, 15, 4))
	await _physics_frames(2)
	_clear_enemies()
	evey.position = _at(east, 15, 2) + Vector2(20, 18)
	_check(not game.progress.is_triggered("east_plate"), "the plate is up")
	evey.stay()
	await _physics_frames(4)
	_check(game.progress.is_triggered("east_plate"), "Evey sitting on the plate holds it down")
	evey.come()

	# --- dig ----------------------------------------------------------------------------------
	var beach := Vector2i(1, 1)
	game.enter_map(Game.OVERWORLD, beach, _at(beach, 14, 4))
	await _physics_frames(2)
	_clear_enemies()
	var on_beach := func(d): return WorldMap.room_at(d.global_position) == beach
	var buried: DigSpot = get_nodes_in_group("dig_spots").filter(on_beach)[0]
	_check(not buried.dug, "something is buried on the beach")
	money = player.money
	_check(evey.dig(), "she finds it")
	var dug := await _wait_until(func(): return buried.dug, 400)
	_check(dug, "and digs it up")
	_check(player.money == money + 20, "TT$20 for Chad")
	_check(game.progress.is_done(buried.key), "the spot is remembered")
	game.go_to(beach, _at(beach, 14, 4))
	await _physics_frames(2)
	var again: DigSpot = get_nodes_in_group("dig_spots").filter(on_beach)[0]
	_check(again.dug, "a dug spot stays dug")
	_check(not evey.dig(), "nothing more to dig here")

	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
