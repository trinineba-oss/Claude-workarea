extends "res://tests/test_base.gd"
## Boots the game: start position, collisions, room transitions, saving, loading and pause.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_game.json"


func _new_game() -> Game:
	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	return game


func _wait_for_transition(game: Game) -> void:
	var frames := 0
	while game.is_transitioning() and frames < 240:
		await physics_frame
		frames += 1


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)

	var game := _new_game()
	await _physics_frames(2)
	var player: Player = game.get_node("Player")
	var camera: Camera2D = game.get_node("Camera2D")
	var rooms: Node2D = game.get_node("Rooms")
	var size := WorldMap.room_size()
	var t := float(WorldMap.TILE)

	var start := game.world.start_room()
	var origin := WorldMap.room_origin(start)
	_check(start == Vector2i(0, 1), "the start room is the wharf (0, 1)")
	_check(game.coords == start, "starts in the start room")
	_check(player.position == game.world.start_position(), "starts on the start tile")
	_check(camera.position == origin + size / 2.0, "camera centred")
	_check(rooms.get_child_count() == 1, "one room loaded")

	# Walking: right moves the hero, and the water at the bottom stops them.
	var x0 := player.position.x
	Input.action_press(&"move_right")
	await _physics_frames(10)
	Input.action_release(&"move_right")
	_check(player.position.x > x0 + 20.0, "moves right")
	player.position = origin + Vector2(10.5 * t, 8.5 * t)  # last plank row above the water
	Input.action_press(&"move_down")
	await _physics_frames(60)
	Input.action_release(&"move_down")
	_check(player.position.y < origin.y + 9 * t, "water blocks the hero (y=%f)" % player.position.y)

	# Walking off the right edge scrolls to the next room.
	var next := start + Vector2i.RIGHT
	var next_origin := WorldMap.room_origin(next)
	player.position = origin + Vector2(size.x + 1.0, 5.5 * t)
	await _physics_frames(2)
	_check(game.is_transitioning(), "transition starts at the edge")
	await _wait_for_transition(game)
	_check(game.coords == next, "now in room %s" % next)
	_check(camera.position == next_origin + size / 2.0, "camera moved to the new room")
	_check(Rect2(next_origin, size).has_point(player.position), "hero is inside the new room")
	_check(not player.frozen, "hero can move again")
	_check(rooms.get_child_count() == 1, "old room freed")
	var resume_position := player.position

	# The autosave was written on the room change, and a new game resumes from it.
	var saved := game.save.read()
	_check(saved.get("room") == [float(next.x), float(next.y)], "autosave holds the room")
	game.free()
	game = _new_game()
	await _physics_frames(2)
	player = game.get_node("Player")
	_check(game.coords == next, "resumes in the saved room")
	_check(player.position.distance_to(resume_position) < 1.0, "resumes at the saved spot")
	_check(
		game.get_node("Camera2D").position == next_origin + size / 2.0,
		"camera resumes in the saved room"
	)

	# An edge that leads nowhere never starts a transition (the walls stop the hero first).
	var east := Vector2i(2, 1)
	game.go_to(east, WorldMap.room_origin(east) + Vector2(10.5 * t, 5.5 * t))
	player.position = WorldMap.room_origin(east) + Vector2(size.x + 5.0, 5.5 * t)
	await _physics_frames(2)
	_check(not game.is_transitioning(), "no transition toward a missing room")
	_check(game.coords == east, "still in room (2, 1)")
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
