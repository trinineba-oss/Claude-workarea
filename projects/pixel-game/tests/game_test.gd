extends "res://tests/test_base.gd"
## Boots the game: start position, collisions, the seamless world, saving, loading and pause.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_game.json"


func _new_game() -> Game:
	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	return game


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)

	var game := _new_game()
	await _physics_frames(2)
	var player: Player = game.get_node("Player")
	var camera: Camera2D = game.get_node("Camera2D")
	var size := WorldMap.room_size()
	var t := float(WorldMap.TILE)

	var start := game.world.start_room()
	var origin := WorldMap.room_origin(start)
	_check(start == Vector2i(0, 1), "the start room is the wharf (0, 1)")
	_check(game.coords == start, "starts in the start room")
	_check(player.position == game.world.start_position(), "starts on the start tile")
	_check(
		camera.get_screen_center_position().distance_to(player.position) < size.x, "camera on Chad"
	)
	_check(game.current_room().coords == start, "the current room is loaded")
	_check(game.loaded_rooms().size() == 9, "the room and its 8 neighbours are loaded")
	var fillers := game.loaded_rooms().filter(func(r): return r.filler)
	_check(not fillers.is_empty(), "cells with no room are filled in at the edge of the world")

	# Walking: right moves the hero, and the water at the bottom stops them.
	var x0 := player.position.x
	Input.action_press(&"move_right")
	await _physics_frames(10)
	Input.action_release(&"move_right")
	_check(player.position.x > x0 + 20.0, "moves right")
	_check(camera.position == player.position, "the camera follows Chad")
	player.position = origin + Vector2(10.5 * t, 8.5 * t)  # last plank row above the water
	Input.action_press(&"move_down")
	await _physics_frames(60)
	Input.action_release(&"move_down")
	_check(player.position.y < origin.y + 9 * t, "water blocks the hero (y=%f)" % player.position.y)

	# Walking over the east edge carries straight on into the next room: no flip, no freeze.
	var next := start + Vector2i.RIGHT
	var next_origin := WorldMap.room_origin(next)
	player.position = origin + Vector2(size.x - 20.0, 5.5 * t)
	Input.action_press(&"move_right")
	for i in 30:
		await physics_frame
		if game.coords == next:
			break
	Input.action_release(&"move_right")
	_check(game.coords == next, "now in room %s" % next)
	_check(not player.frozen, "Chad never stops")
	_check(Rect2(next_origin, size).has_point(player.position), "Chad is inside the new room")
	await _physics_frames(2)
	var east_of_next := game.loaded_rooms().filter(
		func(r): return r.coords == next + Vector2i.RIGHT
	)
	_check(east_of_next.size() == 1, "the rooms around the new one are loaded")
	var far := game.loaded_rooms().filter(func(r): return r.coords == start + Vector2i.LEFT)
	_check(far.is_empty(), "rooms out of range are unloaded")
	# The autosave was written on the room change, and a new game resumes from it.
	var saved := game.save.read()
	_check(saved.get("room") == [float(next.x), float(next.y)], "autosave holds the room")
	var resume_position := Vector2(saved["position"][0], saved["position"][1])
	game.free()
	game = _new_game()
	await _physics_frames(2)
	player = game.get_node("Player")
	_check(game.coords == next, "resumes in the saved room")
	# Loading nudges Chad up to 32 px in from the room edge, so allow for that.
	_check(player.position.distance_to(resume_position) <= 33.0, "resumes at the saved spot")
	_check(
		(
			game.get_node("Camera2D").get_screen_center_position().distance_to(player.position)
			< size.x
		),
		"camera resumes on Chad"
	)

	# Walking into the edge of the world: the wall holds.
	var east := Vector2i(2, 1)
	game.go_to(east, WorldMap.room_origin(east) + Vector2(17.5 * t, 5.5 * t))
	Input.action_press(&"move_right")
	await _physics_frames(60)
	Input.action_release(&"move_right")
	_check(game.coords == east, "still in room (2, 1)")
	_check(player.position.x < WorldMap.room_origin(east).x + size.x, "kept inside the world")
	game.free()

	# A corrupt save falls back to a fresh start.
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string("garbage")
	file.close()
	game = _new_game()
	await _physics_frames(2)
	_check(game.coords == game.world.start_room(), "corrupt save starts a new game")

	# Pause toggles the tree and saves.
	var overlay: PauseOverlay = game.get_node("HUD/PauseOverlay")
	overlay.toggle()
	_check(paused and overlay.visible, "pause shows the overlay and stops the game")
	overlay.toggle()
	_check(not paused and not overlay.visible, "unpause resumes")

	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
