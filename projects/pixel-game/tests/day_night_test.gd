extends "res://tests/test_base.gd"
## The clock: tints, night lights, the HUD clock, saving, pausing, and night-only dialogue.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_daynight.json"


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	_check(DayNight.tint_at(12.0) == Color.WHITE, "noon is untinted")
	var midnight := DayNight.tint_at(0.0)
	_check(midnight.r < 0.5 and midnight.b > midnight.r, "midnight is dark blue")
	_check(DayNight.night_amount_at(12.0) == 0.0, "no night at noon")
	_check(DayNight.night_amount_at(23.0) == 1.0, "full night at 11 pm")
	var dusk := DayNight.night_amount_at(18.5)
	_check(dusk > 0.0 and dusk < 1.0, "dusk is in between")
	_check(DayNight.clock_text(0.0) == "12:00 AM", "midnight reads 12:00 AM")
	_check(DayNight.clock_text(13.5) == "1:30 PM", "13.5 reads 1:30 PM")

	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	await _physics_frames(2)
	var clock: DayNight = game.day_night
	_check(DayNight.current == clock, "the game's clock is current")
	_check(absf(clock.hour - 7.0) < 0.1, "a new game starts at 7 am")

	# Time runs (sped up here), and stops while paused.
	clock.seconds_per_day = 2.4
	var before := clock.hour
	await _frames(20)
	_check(clock.hour > before + 0.5, "time passes")
	paused = true
	before = clock.hour
	await _frames(10)
	_check(clock.hour == before, "time stops while paused")
	paused = false
	clock.seconds_per_day = DayNight.SECONDS_PER_DAY

	# Night lights on Lady Hailes Avenue.
	var t := float(WorldMap.TILE)
	game.go_to(Vector2i(2, 0), WorldMap.room_origin(Vector2i(2, 0)) + Vector2(10.5 * t, 5.5 * t))
	await _frames(2)
	clock.set_hour(12.0)
	await _frames(2)
	var lights := get_nodes_in_tree_of_type(game, "NightLight")
	_check(lights.size() >= 3, "food trucks and poles have lights (%d)" % lights.size())
	_check(lights.all(func(l): return not l.visible), "lights are off at noon")
	clock.set_hour(22.0)
	await _frames(2)
	_check(lights.all(func(l): return l.visible and l.energy > 0.5), "lights are on at 10 pm")
	var status: StatusBar = game.get_node("HUD/StatusBar")
	_check(absf(status.get("_hour") - clock.hour) < 1.0 / 60.0, "the HUD clock follows the time")

	# Night-only lines.
	_check(game.dialogue_state().get("night", false), "the dialogue state knows it is night")
	var ibis_talk: Array = GameData.character("ibis")["talk"]
	_check(
		GameData.pick_dialogue(ibis_talk, {"intro_done": true, "night": true}) == "ibis_night",
		"the ibis sleeps at night"
	)
	_check(
		GameData.pick_dialogue(ibis_talk, {"intro_done": true, "night": false}) == "ibis_hint",
		"and gives hints by day"
	)

	# The time is saved and restored.
	game.save_game()
	game.free()
	game = GAME.instantiate()
	game.play_intro = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	await _frames(2)
	_check(absf(game.day_night.hour - 22.0) < 0.1, "the saved hour comes back")
	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()


func get_nodes_in_tree_of_type(from: Node, type_name: String) -> Array:
	var found := []
	for child in from.find_children("*", type_name, true, false):
		found.append(child)
	return found
