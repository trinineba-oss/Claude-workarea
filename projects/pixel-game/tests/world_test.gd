extends "res://tests/test_base.gd"
## The room maps are valid, line up with their neighbours, and the tile set builds.


func _run() -> void:
	var world := WorldMap.load_dir("res://data/rooms")
	_check(world.rooms.size() == 6, "loads 6 rooms (got %d)" % world.rooms.size())
	var problems := world.validate()
	_check(problems.is_empty(), "world is valid: %s" % ", ".join(problems))
	_check(world.start_room() == Vector2i(1, 1), "start room is (1, 1)")

	var broken := WorldMap.new()
	broken.rooms[Vector2i(0, 0)] = PackedStringArray(["short"])
	_check(not broken.validate().is_empty(), "bad room is reported")

	var tileset := Tiles.tileset()
	var source: TileSetAtlasSource = tileset.get_source(0)
	_check(source.get_tiles_count() == Tiles.COUNT, "tile set has %d tiles" % Tiles.COUNT)
	for ch in ["T", "#", "~", "b"]:
		var data := source.get_tile_data(Vector2i(Tiles.atlas_index(ch), 0), 0)
		_check(data.get_collision_polygons_count(0) == 1, "'%s' is solid" % ch)
	var grass := source.get_tile_data(Vector2i(Tiles.atlas_index("."), 0), 0)
	_check(grass.get_collision_polygons_count(0) == 0, "grass is walkable")
	_finish()
