extends "res://tests/test_base.gd"
## Boots the game: start position, collisions, room transitions, saving, loading and pause.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_game.json"


func _new_game() -> Game:
	var game: Game = GAME.instantiate()
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

	_check(game.coords == Vector2i(1, 1), "starts in the start room")
	_check(player.position == game.world.start_position(), "starts on the start tile")
	_check(camera.position == WorldMap.room_origin(Vector2i(1, 1)) + size / 2.0, "camera centred")
	_check(rooms.get_child_count() == 1, "one room loaded")

	# Walking: right moves the hero, and the water at the bottom stops them.
	var x0 := player.position.x
	Input.action_press(&"move_right")
	await _physics_frames(10)
	Input.action_release(&"move_right")
	_check(player.position.x > x0 + 5.0, "moves right")
	var origin := WorldMap.room_origin(Vector2i(1, 1))
	player.position = origin + Vector2(160, 8 * 16 + 8)  # last sand row above the water
	Input.action_press(&"move_down")
	await _physics_frames(60)
	Input.action_release(&"move_down")
	_check(
		player.position.y < origin.y + 9 * 16, "water blocks the hero (y=%f)" % player.position.y
	)

	# Walking off the right edge scrolls to the next room.
	player.position = origin + Vector2(size.x + 1.0, 5 * 16 + 8)
	await _physics_frames(2)
	_check(game.is_transitioning(), "transition starts at the edge")
	await _wait_for_transition(game)
	var next_origin := WorldMap.room_origin(Vector2i(2, 1))
	_check(game.coords == Vector2i(2, 1), "now in room (2, 1)")
	_check(camera.position == next_origin + size / 2.0, "camera moved to the new room")
	_check(Rect2(next_origin, size).has_point(player.position), "hero is inside the new room")
	_check(not player.frozen, "hero can move again")
	_check(rooms.get_child_count() == 1, "old room freed")
	var resume_position := player.position

	# An edge that leads nowhere never starts a transition (the walls stop the hero first).
	player.position = next_origin + Vector2(size.x + 5.0, 5 * 16 + 8)
	await _physics_frames(2)
	_check(not game.is_transitioning(), "no transition toward a missing room")
	_check(game.coords == Vector2i(2, 1), "still in room (2, 1)")

	# The autosave was written on the room change, and a new game resumes from it.
	var saved := game.save.read()
	_check(saved.get("room") == [2.0, 1.0], "autosave holds the room")
	game.free()
	game = _new_game()
	await _physics_frames(2)
	_check(game.coords == Vector2i(2, 1), "resumes in the saved room")
	_check(
		game.get_node("Player").position.distance_to(resume_position) < 1.0,
		"resumes at the saved spot"
	)
	_check(
		game.get_node("Camera2D").position == next_origin + size / 2.0,
		"camera resumes in the saved room"
	)
	game.free()

	# A corrupt save falls back to a fresh start.
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string("garbage")
	file.close()
	game = _new_game()
	await _physics_frames(2)
	_check(game.coords == Vector2i(1, 1), "corrupt save starts a new game")

	# Pause toggles the tree and saves.
	var overlay: PauseOverlay = game.get_node("HUD/PauseOverlay")
	overlay.toggle()
	_check(paused and overlay.visible, "pause shows the overlay and stops the game")
	overlay.toggle()
	_check(not paused and not overlay.visible, "unpause resumes")

	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
