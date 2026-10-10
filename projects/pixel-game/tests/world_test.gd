extends "res://tests/test_base.gd"
## The room maps are valid, line up with their neighbours, and the tile set builds.


func _run() -> void:
	var world := WorldMap.load_dir("res://data/rooms")
	_check(world.rooms.size() == 6, "loads 6 rooms (got %d)" % world.rooms.size())
	var problems := world.validate()
	_check(problems.is_empty(), "world is valid: %s" % ", ".join(problems))
	_check(world.start_room() == Vector2i(1, 1), "start room is (1, 1)")

	_check(world.objects_in(Vector2i(0, 0)).size() == 3, "room (0, 0) has 3 objects")
	_check(world.objects_in(Vector2i(1, 1)).is_empty(), "the start room has no enemies")
	world.objects[Vector2i(0, 0)].append({"kind": "unicorn", "cell": Vector2i(1, 1)})
	world.objects[Vector2i(0, 0)].append({"kind": "dog", "cell": Vector2i(0, 0)})
	world.objects[Vector2i(0, 0)].append({"kind": "dog", "cell": Vector2i(40, 0)})
	var object_problems := world.validate()
	_check(object_problems.size() == 3, "3 bad objects reported (got %s)" % [object_problems])
	var parsed := WorldMap.new()
	parsed._parse_objects(Vector2i(0, 0), PackedStringArray(["; comment", "dog 1 2", "dog x"]))
	_check(parsed.objects_in(Vector2i(0, 0)).size() == 1, "good object lines parse")
	_check(parsed.validate().size() >= 1, "bad object lines are reported")

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
