extends "res://tests/test_base.gd"
## Milestone 5: the Pepper Key, the sealed door, the Callaloo Cauldron, the extra double, the
## Sacred Chadon Beni, the ride out, and Doner Dread on the beach.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_boss.json"
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


func _clear_small_enemies() -> void:
	for enemy in get_nodes_in_group("enemies"):
		if not enemy.is_in_group("bosses"):
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

	# --- the data -----------------------------------------------------------------------------
	_check(GameData.item("sacred_chadon_beni").get("seasoning", false), "the first seasoning")
	_check(GameData.item("sacred_chadon_beni").get("tool", false), "seasonings cannot be stolen")
	var rival := GameData.character("rival")
	_check(rival.get("present_if") == "has_sacred_chadon_beni", "the rival waits for the herb")
	var ibis_talk: Array = GameData.character("ibis")["talk"]
	var after := {"intro_done": true, "has_sacred_chadon_beni": true}
	_check(GameData.pick_dialogue(ibis_talk, after) == "ibis_seasoning1", "the ibis congratulates")

	var game := _new_game()
	await _physics_frames(2)
	var player: Player = game.get_node("Player")
	var status: StatusBar = game.get_node("HUD/StatusBar")
	game.day_night.seconds_per_day = 1.0e9
	game.inventory.add("coconut_boomerang")
	var hall := Vector2i(0, 0)

	# --- the sealed door, before the key ------------------------------------------------------
	game.enter_map(TEMPLE, hall, _at(hall, 9.5, 1))
	await _physics_frames(2)
	var is_seal := func(d): return d.mode == DungeonDoor.Mode.BOSS
	var seal: DungeonDoor = _in_room(game, DungeonDoor).filter(is_seal)[0]
	await _hold(&"move_up", 20)
	_check(not seal.is_open, "the pepper door stays sealed without its key")
	seal.use(game)
	await _frames(2)
	_check(game.is_talking(), "reading the seal says what it needs")
	await _close_dialogue(game)

	# --- the Pepper Key, behind a crystal only the boomerang reaches --------------------------
	var west := Vector2i(0, 1)
	game.go_to(west, _at(west, 4, 1))
	await _physics_frames(2)
	_clear_small_enemies()
	var key_chest: Chest = _in_room(game, Chest).filter(func(c): return c.content == "bosskey")[0]
	_check(not key_chest.visible, "the Pepper Key's chest is hidden")
	player.facing = Vector2.LEFT
	game.throw_boomerang()
	var lit := await _wait_until(func(): return game.progress.is_triggered("west_crystal"), 60)
	_check(lit, "the boomerang hits the crystal on the island")
	await _wait_until(func(): return game.boomerang() == null, 120)
	_check(key_chest.visible, "the chest appears")
	key_chest.use(game)
	await _close_dialogue(game)
	_check(game.progress.has_boss_key(), "Chad has the Pepper Key")
	_check(status.get("_boss_key"), "the HUD shows it")

	game.go_to(hall, _at(hall, 9.5, 1))
	await _physics_frames(2)
	seal = _in_room(game, DungeonDoor).filter(is_seal)[0]
	await _hold(&"move_up", 20)
	_check(seal.is_open, "the Pepper Key opens the sealed door")
	_check(game.progress.has_boss_key(), "and is kept (it is not used up)")

	# --- the Callaloo Cauldron ----------------------------------------------------------------
	var lair := Vector2i(0, -1)
	game.go_to(lair, _at(lair, 9.5, 8))
	await _physics_frames(4)
	_clear_small_enemies()
	var pot: Cauldron = get_nodes_in_group("bosses").filter(func(b): return b is Cauldron)[0]
	var shutter: DungeonDoor = _in_room(game, DungeonDoor)[0]
	_check(not shutter.is_open, "the shutter closes behind Chad")
	_check(not pot.take_hit(1, player.global_position), "the lid shrugs off the cutlass")
	var blobs := [0]
	game.current_room().child_entered_tree.connect(
		func(n): blobs[0] += 1 if n is CallalooBlob else 0
	)
	var spat := await _wait_until(func(): return pot.state == Cauldron.State.OPEN, 300)
	_check(spat, "it lifts its lid")
	_check(blobs[0] == Cauldron.BLOBS, "and spits callaloo (%d)" % blobs[0])
	_check(not pot.take_hit(1, player.global_position), "the open pot is too hot to hit")
	player.health = player.max_health
	player.position = Vector2(pot.global_position.x, player.position.y)
	player.facing = Vector2.UP
	game.throw_boomerang()
	var dizzy := await _wait_until(func(): return pot.state == Cauldron.State.DIZZY, 60)
	_check(dizzy, "a boomerang into the open pot knocks the lid off")
	_check(pot.take_hit(1, player.global_position), "a dizzy pot can be hurt")
	_check(pot.health == pot.max_health - 1, "one hit, one less health")
	await _physics_frames(200)
	_check(pot.state != Cauldron.State.DIZZY, "it recovers")
	while is_instance_valid(pot) and pot.health > 0:
		if pot.health == pot.max_health / 2:
			_check(pot.is_angry(), "at half health it gets angry")
		pot.state = Cauldron.State.DIZZY
		pot.take_hit(1, player.global_position)
	await _physics_frames(4)
	_check(game.progress.is_triggered("pot"), "beating it fires its trigger")
	_check(shutter.is_open, "the shutter opens")

	# --- the prizes ---------------------------------------------------------------------------
	var heart: Chest = _in_room(game, Chest)[0]
	_check(heart.visible and heart.content == "heart", "a chest appears with a heart")
	heart.use(game)
	await _close_dialogue(game)
	_check(player.max_health == 8 and player.is_full_health(), "one more double, all filled")
	var herb: Seasoning = _in_room(game, Seasoning)[0]
	_check(herb.visible and herb.can_interact({}), "the Sacred Chadon Beni appears")
	herb.use(game)
	await _frames(2)
	_check(game.is_talking(), "taking it plays its scene")
	await _close_dialogue(game)
	var out := await _wait_until(func(): return game.map_id == Game.OVERWORLD, 120)
	_check(out, "then carries Chad out of the temple")
	await _wait_until(func(): return not player.frozen, 60)
	_check(game.coords == Vector2i(1, 1), "back on the beach")
	_check(game.flags.get("has_sacred_chadon_beni", false), "the seasoning flag is set")
	_check(game.inventory.count("sacred_chadon_beni") == 1, "the seasoning is in the bag")

	# --- Doner Dread --------------------------------------------------------------------------
	var talked := await _wait_until(func(): return game.is_talking(), 120)
	_check(talked, "the rival walks up and talks")
	await _close_dialogue(game)
	_check(game.flags.get("met_rival", false), "and leaves a flag behind")
	var gone := get_nodes_in_group("interactables").filter(
		func(n): return n is Npc and n.character_id == "rival"
	)
	_check(gone.size() == 1 and not gone[0].visible, "then he is gone")
	await _physics_frames(30)
	_check(not game.is_talking(), "he does not come back for more")

	# --- saved --------------------------------------------------------------------------------
	game.save_game()
	game.free()
	game = _new_game()
	await _physics_frames(2)
	player = game.get_node("Player")
	_check(player.max_health == 8, "the extra double is saved")
	game.enter_map(TEMPLE, lair, _at(lair, 9.5, 8))
	await _physics_frames(4)
	_check(
		not get_nodes_in_group("bosses").any(func(b): return b is Cauldron), "the pot stays beaten"
	)
	_check(not _in_room(game, Seasoning)[0].visible, "the seasoning is not there twice")
	_check(_in_room(game, Chest)[0].opened, "the heart chest stays open")

	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
