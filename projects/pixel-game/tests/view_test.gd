extends "res://tests/test_base.gd"
## The 2.5D view: the 2D world is hidden and drawn in 3D instead (rooms, scenery, characters,
## lights), the camera follows Chad inside the world's edges, the sky follows the clock and
## the inside of a temple, and the view keeps up as rooms come and go.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_view.json"


func _new_game(use_3d := true) -> Game:
	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.use_3d = use_3d
	game.save.path = SAVE_PATH
	root.add_child(game)
	_bench_evey()
	return game


func _at(room: Vector2i, x: float, y: float) -> Vector2:
	return WorldMap.room_origin(room) + (Vector2(x, y) + Vector2(0.5, 0.5)) * WorldMap.TILE


func _count(room: Room, ch: String) -> int:
	var total := 0
	for row in room.map_lines:
		total += row.count(ch)
	return total


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	_check(View3D.to_3d(Vector2(64, 128)) == Vector3(1, 0, 2), "a tile is one unit; 2D y is 3D z")
	_check(View3D.to_2d(Vector3(1, 5, 2)) == Vector2(64, 128), "and back")

	var game := _new_game()
	await _physics_frames(3)
	await _frames(2)
	var view: View3D = game.get_node("View3D")
	var player: Player = game.get_node("Player")
	_check(View3D.current == view, "the view is the current one")
	_check(game.visibility_layer == View3D.HIDDEN_LAYER, "the 2D world is on the hidden layer")
	_check(
		root.get_viewport().canvas_cull_mask & View3D.HIDDEN_LAYER == 0, "and the screen skips it"
	)
	_check(view.camera.current, "the 3D camera is the one in use")

	# --- rooms and scenery --------------------------------------------------------------------
	_check(view.room_views().size() == game.loaded_rooms().size(), "every loaded room is drawn")
	var wharf: Room = game.current_room()
	var wharf_view: RoomView = view.room_views().filter(func(v): return v.room == wharf)[0]
	_check(wharf_view.get_node_or_null("Floor") is MeshInstance3D, "the room has a floor")
	var crates: MultiMeshInstance3D = wharf_view.get_node_or_null("crate")
	_check(
		crates != null and crates.multimesh.instance_count == _count(wharf, "c"),
		"one crate per crate tile"
	)
	_check(
		wharf_view.position == View3D.to_3d(wharf.position), "the room sits where the 2D room is"
	)

	# --- characters ---------------------------------------------------------------------------
	var chad_view := view.entity_view(player)
	_check(chad_view != null, "Chad has a 3D twin")
	_check(
		chad_view.position.distance_to(View3D.to_3d(player.global_position)) < 0.01,
		"standing where he stands"
	)
	_check(
		chad_view.find_children("*", "Sprite3D", true, false).size() >= 1,
		"drawn as an upright sprite"
	)
	var npcs := get_nodes_in_group("interactables").filter(func(n): return n is Npc)
	_check(npcs.all(func(n): return view.entity_view(n) != null), "people have twins too")
	var x0 := player.position.x
	Input.action_press(&"move_right")
	await _physics_frames(12)
	Input.action_release(&"move_right")
	await _frames(2)
	_check(player.position.x > x0, "Chad walked")
	_check(
		chad_view.position.distance_to(View3D.to_3d(player.global_position)) < 0.01,
		"and his twin kept up"
	)

	# --- the camera ---------------------------------------------------------------------------
	var road := Vector2i(0, 0)
	game.go_to(road, _at(road, 10, 5))
	await _frames(3)
	var aim := (
		view.camera.position
		- Vector3(0, sin(View3D.CAMERA_PITCH), cos(View3D.CAMERA_PITCH)) * View3D.CAMERA_DISTANCE
	)
	_check(absf(aim.x - View3D.to_3d(player.position).x) < 0.5, "the camera looks at Chad")
	game.go_to(road, _at(road, 1, 2))
	await _frames(3)
	aim = (
		view.camera.position
		- Vector3(0, sin(View3D.CAMERA_PITCH), cos(View3D.CAMERA_PITCH)) * View3D.CAMERA_DISTANCE
	)
	_check(aim.x >= View3D.VIEW_MARGIN.x - 0.01, "but not past the edge of the world")
	_check(view.room_views().size() == game.loaded_rooms().size(), "rooms are redrawn after a jump")

	# --- day, night and indoors ---------------------------------------------------------------
	game.day_night.set_hour(12.0)
	await _frames(2)
	_check(view.sun.visible and view.sun.light_energy > 0.5, "the sun is up at noon")
	game.day_night.set_hour(23.0)
	await _frames(2)
	_check(view.moon.visible and view.sun.light_energy < 0.05, "the moon at night")
	var hall := Vector2i(1, 2)
	game.enter_map("temple1", hall, _at(hall, 9, 7))
	await _frames(3)
	_check(not view.sun.visible, "no sun in the cave")
	_check(view.environment.background_mode == Environment.BG_COLOR, "and no sky")
	var lights := view.find_children("*", "OmniLight3D", true, false)
	_check(lights.any(func(l): return l.is_visible_in_tree()), "the torches are lit")

	# --- effects ------------------------------------------------------------------------------
	var before := view.find_children("*", "Label3D", true, false).size()
	Effects.float_text(game, player.position, "Hello", Color.WHITE)
	_check(
		view.find_children("*", "Label3D", true, false).size() == before + 1,
		"floating text appears in 3D"
	)
	game.free()

	# --- the 2D drawing is still there without the view ---------------------------------------
	game = _new_game(false)
	await _physics_frames(2)
	_check(game.get_node_or_null("View3D") == null, "the view can be switched off")
	_check(game.visibility_layer & View3D.HIDDEN_LAYER == 0, "and then the 2D world shows")
	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
