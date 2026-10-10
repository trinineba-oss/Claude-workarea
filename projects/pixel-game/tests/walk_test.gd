extends "res://tests/test_base.gd"
## Every doorway between rooms can actually be walked through, from its first and last tile.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_walk.json"
const DIRECTIONS := {
	Vector2i.RIGHT: &"move_right",
	Vector2i.LEFT: &"move_left",
	Vector2i.DOWN: &"move_down",
	Vector2i.UP: &"move_up",
}
## Start in the middle of the doorway tile itself.
const INSET := WorldMap.TILE / 2.0


func _run() -> void:
	Engine.time_scale = 5.0
	DirAccess.remove_absolute(SAVE_PATH)
	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	await _physics_frames(2)
	var player: Player = game.get_node("Player")
	var world := game.world
	var size := WorldMap.room_size()
	var walks := 0

	for coords in world.rooms:
		for dir: Vector2i in DIRECTIONS:
			if not world.has_room(coords + dir):
				continue
			var tiles := _open_tiles(world, coords, dir)
			for tile in [tiles.front(), tiles.back()]:
				var local := (Vector2(tile) + Vector2(0.5, 0.5)) * WorldMap.TILE
				if dir.x != 0:
					local.x = size.x - INSET if dir.x > 0 else INSET
				else:
					local.y = size.y - INSET if dir.y > 0 else INSET
				game.go_to(coords, WorldMap.room_origin(coords) + local)
				player.revive()
				await physics_frame
				Input.action_press(DIRECTIONS[dir])
				var frames := 0
				while game.coords == coords and frames < 240:
					await physics_frame
					frames += 1
				Input.action_release(DIRECTIONS[dir])
				walks += 1
				_check(
					game.coords == coords + dir,
					"can walk from room %s through tile %s toward %s" % [coords, tile, dir]
				)
	_check(walks >= 20, "walked through %d doorways" % walks)
	Engine.time_scale = 1.0
	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()


## Tiles along the edge of `coords` facing `dir` that are not solid (as column or row indexes
## expressed as the tile's Vector2i position in the room).
func _open_tiles(world: WorldMap, coords: Vector2i, dir: Vector2i) -> Array[Vector2i]:
	var lines := world.rows(coords)
	var result: Array[Vector2i] = []
	if dir.x != 0:
		var x := WorldMap.COLS - 1 if dir.x > 0 else 0
		for y in WorldMap.ROWS:
			if not Tiles.is_solid(lines[y][x]):
				result.append(Vector2i(x, y))
	else:
		var y := WorldMap.ROWS - 1 if dir.y > 0 else 0
		for x in WorldMap.COLS:
			if not Tiles.is_solid(lines[y][x]):
				result.append(Vector2i(x, y))
	return result
