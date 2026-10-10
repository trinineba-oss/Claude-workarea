extends "res://tests/test_base.gd"
## The room maps are valid, line up with their neighbours, and the tile set builds.


func _run() -> void:
	var world := WorldMap.load_dir("res://data/rooms")
	_check(world.rooms.size() == 7, "loads 7 rooms (got %d)" % world.rooms.size())
	var problems := world.validate()
	_check(problems.is_empty(), "world is valid: %s" % ", ".join(problems))
	_check(world.start_room() == Vector2i(0, 1), "the start room is the wharf (0, 1)")
	var kinds := world.objects_in(Vector2i(0, 1)).map(func(o): return o["kind"])
	_check("dog" not in kinds and "corbeau" not in kinds, "the start room has no enemies")
	_check(
		kinds.count("npc") == 2 and kinds.count("prop") == 1, "the wharf has 2 people and the boat"
	)
	var crossing := world.objects_in(Vector2i(1, 0)).map(func(o): return o["arg"])
	_check(
		"gas_station" in crossing and "down" in crossing,
		"Cross Crossing has the gas station and traffic"
	)
	var avenue := world.objects_in(Vector2i(2, 0)).map(func(o): return o["arg"])
	_check("gyro_vendor" in avenue, "the gyro man is on Lady Hailes Avenue")
	world.objects[Vector2i(0, 0)].append({"kind": "unicorn", "cell": Vector2i(1, 1)})
	world.objects[Vector2i(0, 0)].append({"kind": "dog", "cell": Vector2i(0, 0)})
	world.objects[Vector2i(0, 0)].append({"kind": "dog", "cell": Vector2i(40, 0)})
	world.objects[Vector2i(0, 0)].append({"kind": "npc", "cell": Vector2i(2, 2), "arg": "nobody"})
	world.objects[Vector2i(0, 0)].append({"kind": "sign", "cell": Vector2i(2, 2), "arg": ""})
	world.objects[Vector2i(0, 0)].append({"kind": "dog", "cell": Vector2i(2, 2), "arg": "rex"})
	var object_problems := world.validate()
	_check(object_problems.size() == 6, "6 bad objects reported (got %s)" % [object_problems])
	var parsed := WorldMap.new()
	parsed._parse_objects(
		Vector2i(0, 0),
		PackedStringArray(["; comment", "dog 1 2", "npc 3 4 ibis", "dog x", "a 1 2 3 4"])
	)
	_check(parsed.objects_in(Vector2i(0, 0)).size() == 2, "good object lines parse")
	_check(parsed.objects_in(Vector2i(0, 0))[1]["arg"] == "ibis", "ids are read")
	_check(parsed.validate().size() >= 1, "bad object lines are reported")

	var broken := WorldMap.new()
	broken.rooms[Vector2i(0, 0)] = PackedStringArray(["short"])
	_check(not broken.validate().is_empty(), "bad room is reported")

	var tileset := Tiles.collision_tileset()
	var source: TileSetAtlasSource = tileset.get_source(0)
	_check(source.get_tiles_count() == 1, "one collision tile")
	var solid := source.get_tile_data(Vector2i.ZERO, 0)
	_check(solid.get_collision_polygons_count(0) == 1, "the collision tile is solid")
	for ch in ["T", "#", "~", "b"]:
		_check(Tiles.is_solid(ch), "'%s' is solid" % ch)
	for ch in [".", ",", "s", "p", "=", "@"]:
		_check(not Tiles.is_solid(ch), "'%s' is walkable" % ch)

	var beach := PackedStringArray(["sss", "sbs", "sss"])
	_check(Tiles.ground_at(beach, 1, 1) == "sand", "a bush on the beach stands on sand")
	var meadow := PackedStringArray(["...", ".T.", "~~~"])
	_check(Tiles.ground_at(meadow, 1, 1) == "grass", "scenery ignores water when picking ground")
	_check(Tiles.ground_at(meadow, 0, 2) == "water", "water is water")
	_check(Tiles.scenery("T") == "tree" and Tiles.scenery(".") == "", "scenery lookup")
	_finish()
