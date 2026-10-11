extends "res://tests/test_base.gd"
## Temple 1 (Callaloo Cave): warps in and out, small keys and locked doors, chests, the push
## block puzzle, the Big Blue Crab and its shutters, the coconut boomerang and the crystal
## switch, and saving inside the temple.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_temple.json"
const TEMPLE := "temple1"


func _new_game() -> Game:
	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	return game


func _at(room: Vector2i, x: float, y: float) -> Vector2:
	return WorldMap.room_origin(room) + (Vector2(x, y) + Vector2(0.5, 0.5)) * WorldMap.TILE


func _in_room(game: Game, type: Variant) -> Array:
	return game.current_room().get_children().filter(func(n): return is_instance_of(n, type))


func _clear_enemies() -> void:
	for enemy in get_nodes_in_group("enemies"):
		if not enemy is BigCrab:
			enemy.free()


func _hold(action: StringName, frames: int) -> void:
	Input.action_press(action)
	await _physics_frames(frames)
	Input.action_release(action)


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


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)

	# --- the map ------------------------------------------------------------------------------
	var maps := {}
	for id: String in Game.MAPS:
		var map := WorldMap.load_dir(Game.MAPS[id]["dir"])
		map.filler = Game.MAPS[id].get("filler", "")
		maps[id] = map
	var temple: WorldMap = maps[TEMPLE]
	_check(temple.rooms.size() == 8, "the temple has 8 rooms (%d)" % temple.rooms.size())
	var problems := temple.validate(false)
	_check(problems.is_empty(), "the temple is valid: %s" % ", ".join(problems))
	_check(temple.filler_tile(Vector2i(9, 9)) == "#", "outside the temple is rock")
	var warps := 0
	for id: String in maps:
		for coords: Vector2i in maps[id].rooms:
			for obj in maps[id].objects_in(coords):
				if obj["kind"] != "warp":
					continue
				warps += 1
				var to := Game.parse_warp(obj["arg"])
				var there: WorldMap = maps[to["map"]]
				var tile: Vector2i = (
					to["room"] * Vector2i(WorldMap.COLS, WorldMap.ROWS) + to["tile"]
				)
				_check(there.has_room(to["room"]), "warp %s lands in a real room" % obj["arg"])
				_check(
					not Tiles.is_solid(there.tile_at(tile)), "warp %s lands on floor" % obj["arg"]
				)
				var on_warp := there.objects_in(to["room"]).any(
					func(o): return o["kind"] == "warp" and o["cell"] == to["tile"]
				)
				_check(not on_warp, "warp %s does not land on another warp" % obj["arg"])
	_check(warps >= 3, "warps lead in and out (%d)" % warps)
	_check(Game.parse_warp("temple1:1_2:9_8")["tile"] == Vector2i(9, 8), "warp targets parse")
	_check(Game.parse_warp("nowhere:1_2:9_8").is_empty(), "unknown maps are refused")
	_check(Entities.argument_problem("chest", "key") == "", "a chest can hold a key")
	_check(Entities.argument_problem("chest", "coconut_boomerang@crab") == "", "or an item")
	_check(Entities.argument_problem("chest", "tt25") == "", "or money")
	_check(Entities.argument_problem("chest", "unicorn") != "", "but not nonsense")
	_check(Entities.argument_problem("warp", "beach") != "", "bad warps are caught")

	# --- walking in from the beach ------------------------------------------------------------
	var game := _new_game()
	await _physics_frames(2)
	var player: Player = game.get_node("Player")
	var status: StatusBar = game.get_node("HUD/StatusBar")
	game.day_night.seconds_per_day = 1.0e9
	var beach := Vector2i(1, 1)
	game.go_to(beach, _at(beach, 14, 3))
	await _physics_frames(2)
	_check(status.get("_keys") == -1, "no key counter outdoors")
	Input.action_press(&"move_up")
	var inside := await _wait_until(func(): return game.map_id == TEMPLE, 120)
	Input.action_release(&"move_up")
	_check(inside, "walking into the cave mouth enters the temple")
	await _wait_until(func(): return not player.frozen, 60)
	var entrance := Vector2i(1, 2)
	_check(game.coords == entrance, "Chad arrives in the entrance room")
	_check(game.day_night.indoors and game.is_indoors(), "it is dim inside")
	_check(status.get("_keys") == 0, "the key counter shows")
	var camera: Camera2D = game.get_node("Camera2D")
	_check(
		(
			camera.limit_left == int(WorldMap.room_origin(entrance).x)
			and camera.limit_bottom == 3 * 704
		),
		"the camera stays in the room"
	)
	var torches := get_nodes_in_group("safe_lights").filter(func(l): return l.visible)
	await _frames(2)
	torches = get_nodes_in_group("safe_lights").filter(func(l): return l.energy > 0.5)
	_check(not torches.is_empty(), "torches burn indoors, even by day")

	# --- a locked door ------------------------------------------------------------------------
	var hub := Vector2i(1, 1)
	game.go_to(hub, _at(hub, 9.5, 1))
	await _physics_frames(2)
	_clear_enemies()
	var doors := _in_room(game, DungeonDoor)
	_check(doors.size() == 1 and doors[0].mode == DungeonDoor.Mode.LOCKED, "the hub has a lock")
	var door: DungeonDoor = doors[0]
	_check(door.horizontal, "a door in the top wall runs sideways")
	await _hold(&"move_up", 20)
	_check(not door.is_open, "no key, no entry")
	_check(player.global_position.y > WorldMap.room_origin(hub).y + 40.0, "the door blocks")

	# --- the first key from a chest -----------------------------------------------------------
	var west := Vector2i(0, 1)
	game.go_to(west, _at(west, 3, 5))
	await _physics_frames(2)
	_clear_enemies()
	player.facing = Vector2.LEFT
	await _physics_frames(2)
	var chest: Chest = _in_room(game, Chest)[0]
	_check(player.target == chest, "the chest can be opened")
	await _hold(&"interact", 2)
	await _physics_frames(2)
	_check(chest.opened and game.progress.key_count() == 1, "the chest held a small key")
	_check(status.get("_keys") == 1, "the counter shows it")
	_check(not chest.can_interact({}), "an open chest is empty")

	# Now the lock opens, and stays open.
	game.go_to(hub, _at(hub, 9.5, 1))
	await _physics_frames(2)
	_clear_enemies()
	door = _in_room(game, DungeonDoor)[0]
	await _hold(&"move_up", 20)
	_check(door.is_open and game.progress.key_count() == 0, "walking into the lock uses the key")
	game.go_to(hub, _at(hub, 9.5, 3))
	await _physics_frames(2)
	_check(_in_room(game, DungeonDoor)[0].is_open, "an unlocked door stays open")
	game.go_to(west, _at(west, 3, 5))
	await _physics_frames(2)
	_check(_in_room(game, Chest)[0].opened, "an opened chest stays open")

	# --- the push block puzzle ----------------------------------------------------------------
	var east := Vector2i(2, 1)
	game.go_to(east, _at(east, 11, 7))
	await _physics_frames(2)
	_clear_enemies()
	var gate: DungeonDoor = _in_room(game, DungeonDoor)[0]
	var block: PushBlock = _in_room(game, PushBlock)[0]
	var start := block.position
	_check(not gate.is_open, "the gate starts shut")
	player.facing = Vector2.RIGHT
	await _hold(&"move_right", 45)
	await _physics_frames(15)
	_check(block.position.x >= start.x + WorldMap.TILE - 1.0, "pushing moves the block a tile")
	_check(fmod(block.position.x - start.x, WorldMap.TILE) < 1.0, "it moves whole tiles")
	game.current_room().on_enter()
	_check(block.position == start, "re-entering puts an unsolved puzzle back")
	player.position = _at(east, 6, 7)
	await _physics_frames(2)
	for step in [Vector2.RIGHT, Vector2.RIGHT, Vector2.RIGHT]:
		_check(block.try_move(step), "slides right")
		await _physics_frames(16)
	for i in 5:
		_check(block.try_move(Vector2.UP), "slides up")
		await _physics_frames(16)
	await _physics_frames(4)
	_check(game.progress.is_triggered("east_plate"), "the block on the plate fires its trigger")
	await _physics_frames(20)
	_check(gate.is_open, "and the gate opens")
	_check(block.try_move(Vector2.UP), "the block can still slide off the plate")
	await _physics_frames(16)
	_check(not block.try_move(Vector2.UP), "blocks stop at walls")
	_check(game.progress.is_triggered("east_plate") and gate.is_open, "the gate stays open")
	game.current_room().on_enter()
	_check(block.position != start, "a solved puzzle is left alone")

	# The second key is behind the gate.
	var north_east := Vector2i(2, 0)
	game.go_to(north_east, _at(north_east, 9, 3))
	await _physics_frames(2)
	_clear_enemies()
	_in_room(game, Chest)[0].use(game)
	_check(game.progress.key_count() == 1, "the second small key")

	# --- the Big Blue Crab --------------------------------------------------------------------
	var arena := Vector2i(1, 0)
	game.go_to(arena, _at(arena, 10, 8))
	await _physics_frames(4)
	var boss: BigCrab = get_nodes_in_group("bosses").filter(func(b): return b is BigCrab)[0]
	var shutters := _in_room(game, DungeonDoor)
	_check(shutters.size() == 2, "the arena has two shutters")
	_check(shutters.all(func(s): return not s.is_open), "the shutters slam shut")
	var prize: Chest = _in_room(game, Chest)[0]
	_check(not prize.visible and not prize.can_interact({}), "its chest is hidden")
	_check(not boss.take_hit(1, player.global_position), "the cutlass bounces off the shell")
	_check(boss.health == boss.max_health, "no damage while it is upright")
	var stunned := await _wait_until(func(): return boss.state == BigCrab.State.STUNNED, 400)
	_check(stunned, "charging into a wall stuns it")
	_check(boss.take_hit(1, player.global_position), "a stunned crab can be hurt")
	while is_instance_valid(boss) and boss.health > 0:
		boss.boomerang_hit()
		boss.take_hit(1, player.global_position)
	await _physics_frames(4)
	_check(game.progress.is_triggered("crab"), "beating it fires its trigger")
	_check(shutters.all(func(s): return s.is_open), "the shutters open")
	_check(prize.visible and prize.can_interact({}), "its chest appears")
	player.health = player.max_health
	prize.use(game)
	await _close_dialogue(game)
	_check(game.inventory.count("coconut_boomerang") == 1, "the chest holds the boomerang")
	game.go_to(arena, _at(arena, 10, 8))
	await _physics_frames(4)
	_check(
		not get_nodes_in_group("bosses").any(func(b): return b is BigCrab),
		"a beaten crab stays beaten"
	)
	_check(_in_room(game, DungeonDoor).all(func(s): return s.is_open), "the shutters stay open")

	# --- the boomerang ------------------------------------------------------------------------
	game.go_to(hub, _at(hub, 5, 2))
	await _physics_frames(2)
	_clear_enemies()
	player.facing = Vector2.UP
	_check(game.throw_boomerang(), "the boomerang flies")
	_check(not game.throw_boomerang(), "one at a time")
	var turned := await _wait_until(
		func(): return game.boomerang() == null or game.boomerang().returning, 30
	)
	_check(turned, "it turns back at a wall")
	var caught := await _wait_until(func(): return game.boomerang() == null, 90)
	_check(caught, "and comes back to Chad")
	var crab := Entities.create("crab")
	crab.position = _at(hub, 9.5, 5) - game.current_room().position
	game.current_room().add_child(crab)
	player.position = _at(hub, 9.5, 8)
	player.facing = Vector2.UP
	await _physics_frames(2)
	game.throw_boomerang()
	var crab_ref: WeakRef = weakref(crab)
	var hit := await _wait_until(func(): return crab_ref.get_ref() == null, 60)
	_check(hit, "it knocks out a crab")
	await _wait_until(func(): return game.boomerang() == null, 120)

	# Across the water, the crystal switch.
	var north_west := Vector2i(0, 0)
	game.go_to(north_west, _at(north_west, 7, 5))
	await _physics_frames(2)
	_clear_enemies()
	var orb: CrystalSwitch = _in_room(game, CrystalSwitch)[0]
	var is_gate := func(d): return d.mode == DungeonDoor.Mode.GATE
	var pepper_gate: DungeonDoor = _in_room(game, DungeonDoor).filter(is_gate)[0]
	_check(not orb.is_on() and not pepper_gate.is_open, "the switch is off, the gate shut")
	player.facing = Vector2.LEFT
	var slot := game.inventory.slots.find_custom(func(s): return s.get("id") == "coconut_boomerang")
	game.hotbar().select(slot)
	_check(game.use_selected_item(), "the boomerang is thrown from the hotbar")
	var switched := await _wait_until(func(): return orb.is_on(), 60)
	_check(switched, "it flies over the water and hits the switch")
	await _physics_frames(20)
	_check(pepper_gate.is_open, "the gate to the sealed door opens")
	await _wait_until(func(): return game.boomerang() == null, 120)

	# --- saving in the temple -----------------------------------------------------------------
	game.save_game()
	game.free()
	game = _new_game()
	await _physics_frames(2)
	_check(game.map_id == TEMPLE and game.coords == north_west, "the game resumes in the temple")
	_check(game.day_night.indoors, "still indoors")
	_check(
		game.progress.key_count() == 1 and game.progress.is_triggered("west_switch"),
		"progress is kept"
	)
	_check(game.get_node("HUD/StatusBar").get("_keys") == 1, "the key counter is restored")

	# --- and back out to the beach ------------------------------------------------------------
	player = game.get_node("Player")
	game.go_to(entrance, _at(entrance, 9, 8))
	await _physics_frames(2)
	_clear_enemies()
	Input.action_press(&"move_down")
	var outside := await _wait_until(func(): return game.map_id == Game.OVERWORLD, 120)
	Input.action_release(&"move_down")
	_check(outside, "the sand at the bottom leads out")
	await _wait_until(func(): return not player.frozen, 60)
	_check(game.coords == beach and not game.day_night.indoors, "back on the beach in daylight")
	_check(game.get_node("HUD/StatusBar").get("_keys") == -1, "the key counter hides outside")

	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
