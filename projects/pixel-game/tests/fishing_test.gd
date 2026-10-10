extends "res://tests/test_base.gd"
## Fishing: the catch minigame, which fish bite when, getting the rod, and casting at the wharf.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_fishing.json"


## Plays the minigame with a simple strategy; returns the result.
func _play(logic: FishingLogic, smart: bool) -> String:
	for i in 60 * 60:
		var centre := logic.zone_pos + FishingLogic.ZONE_SIZE / 2.0
		var result := logic.step(1.0 / 60.0, smart and centre < logic.fish_pos)
		if result != "":
			return result
	return ""


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)

	# --- the minigame logic -----------------------------------------------------------------
	_check(_play(FishingLogic.new(1.0, 11), true) == "caught", "tracking the fish catches it")
	_check(_play(FishingLogic.new(1.0, 11), false) == "escaped", "doing nothing loses it")
	var caught := 0
	for i in 10:
		if _play(FishingLogic.new(2.2, 100 + i), true) == "caught":
			caught += 1
	_check(caught >= 5, "the hardest fish can still be caught by tracking it (%d/10)" % caught)

	# --- which fish bite when ------------------------------------------------------------------
	for id: String in GameData.fish_ids():
		_check(GameData.item_icon(id) != null, "%s has an icon" % id)
	_check(not GameData.fish_bites_at("kingfish", 12.0), "no kingfish at noon")
	_check(GameData.fish_bites_at("kingfish", 21.0), "kingfish at 9 pm")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 50:
		var noon := GameData.pick_fish(12.0, rng)
		_check(GameData.fish_bites_at(noon, 12.0), "only fish that bite at noon (%s)" % noon)

	# --- the rod comes from the fisherman -----------------------------------------------------
	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	await _physics_frames(2)
	var box: DialogueBox = game.get_node("HUD/DialogueBox")
	var fisherman_talk: Array = GameData.character("fisherman")["talk"]
	_check(
		GameData.pick_dialogue(fisherman_talk, {}) == "fisherman_rod", "first talk gives the rod"
	)
	game.talk("fisherman_rod")
	await _frames(2)
	while box.is_open():
		box.advance()
		await process_frame
		box.advance()
		await process_frame
	await _frames(3)
	_check(game.inventory.count("fishing_rod") == 1, "Chad has the rod")
	_check(game.flags.get("has_rod", false), "and the has_rod flag")

	# --- casting on the pier ----------------------------------------------------------------------
	var player: Player = game.get_node("Player")
	var t := float(WorldMap.TILE)
	var wharf := game.world.start_room()
	game.go_to(wharf, WorldMap.room_origin(wharf) + Vector2(10.5 * t, 8.5 * t))
	player.facing = Vector2.UP
	await _physics_frames(2)
	_check(game.water_in_front() == null, "no water in front facing the dock")
	player.facing = Vector2.DOWN
	_check(game.water_in_front() != null, "water in front facing the sea")
	var slot := game.inventory.slots.find(
		game.inventory.slots.filter(func(s): return s.get("id") == "fishing_rod")[0]
	)
	game.hotbar().select(slot)
	var fishing: Array = [""]
	var done := [false]
	var run := func():
		fishing[0] = await game.fish(0.2)
		done[0] = true
	run.call()
	_check(game.is_fishing() and player.frozen, "casting freezes Chad while he waits")
	for i in 120:
		await process_frame
		if game.fishing_minigame().is_open():
			break
	_check(game.fishing_minigame().is_open() and paused, "a bite starts the minigame")
	var fish_id := game.fishing_minigame().fish_id
	game.fishing_minigame().finish("caught")
	for i in 30:
		await process_frame
		if done[0]:
			break
	_check(done[0] and fishing[0] == fish_id, "the fish is caught (%s)" % fish_id)
	_check(game.inventory.count(fish_id) == 1, "and in the bag")
	_check(not paused and not player.frozen and not game.is_fishing(), "back to normal")

	done[0] = false
	run.call()
	for i in 120:
		await process_frame
		if game.fishing_minigame().is_open():
			break
	game.fishing_minigame().finish("escaped")
	for i in 30:
		await process_frame
		if done[0]:
			break
	_check(fishing[0] == "", "an escaped fish gives nothing")

	player.facing = Vector2.UP
	_check(await game.fish(0.0) == "", "casting at the dock does nothing")
	_check(not game.is_fishing() and not player.frozen, "and does not freeze Chad")
	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
