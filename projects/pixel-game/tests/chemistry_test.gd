extends "res://tests/test_base.gd"
## The chemistry grid (open-world systems, phase 1): tiles have materials, fire spreads
## through flammable ones and burns out to ash, burns away bushes (opening the way), stops at
## sand, never catches next to water, hurts whoever stands in it; and Chad's flambeau lights
## it.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_chemistry.json"


func _test_room() -> Room:
	var lines := PackedStringArray()
	for y in WorldMap.ROWS:
		var row := ""
		for x in WorldMap.COLS:
			var ch := "."
			if x == 10:
				ch = "s"  # a sand path: a firebreak
			elif y == 0 and x < 4:
				ch = "~"
			elif y == 3 and x in [3, 4]:
				ch = "b"
			row += ch
		lines.append(row)
	var room := Room.new()
	room.build(Vector2i(40, 40), lines)
	root.add_child(room)
	return room


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	var room := _test_room()
	await _frames(1)
	var chem := room.chemistry
	_check(chem != null, "every room has a chemistry grid")
	_check(chem.material_at(Vector2i(5, 5)) == "grass", "grass is grass")
	_check(chem.material_at(Vector2i(3, 3)) == "foliage", "bushes are foliage")
	_check(chem.material_at(Vector2i(10, 5)) == "", "sand is inert")
	_check(not chem.ignite(Vector2i(10, 5)), "sand won't burn")
	_check(not chem.ignite(Vector2i(1, 1)), "grass next to water is too wet to burn")

	_check(chem.ignite(Vector2i(5, 5)), "dry grass catches")
	_check(chem.is_burning(Vector2i(5, 5)), "and burns")
	for i in 40:
		chem._step(0.25)
	var burnt := 0
	for y in WorldMap.ROWS:
		for x in range(0, 10):
			if chem.state_at(Vector2i(x, y)) != RoomChemistry.State.NORMAL:
				burnt += 1
	_check(burnt > 30, "the fire spreads through the grass by itself (%d tiles)" % burnt)
	var crossed := false
	for y in WorldMap.ROWS:
		for x in range(11, WorldMap.COLS):
			if chem.state_at(Vector2i(x, y)) != RoomChemistry.State.NORMAL:
				crossed = true
	_check(not crossed, "and stops at the sand path")
	_check(chem.state_at(Vector2i(1, 1)) == RoomChemistry.State.NORMAL, "the wet shore survives")
	_check(chem.state_at(Vector2i(5, 5)) == RoomChemistry.State.ASH, "burnt grass is left as ash")
	for i in 40:
		chem._step(0.25)
	_check(
		chem.state_at(Vector2i(3, 3)) == RoomChemistry.State.ASH, "the bushes burned too (spread)"
	)
	var collision := room.get_node("Collision") as TileMapLayer
	_check(collision.get_cell_source_id(Vector2i(3, 3)) == -1, "a burnt bush no longer blocks")
	_check(room.map_lines[3][3] == "p", "and the map shows bare ground there")
	_check(chem.burning_count() == 0, "the fire burns itself out")
	_check(not chem.ignite(Vector2i(6, 6)), "ash won't burn again")

	# Fire hurts: a crab standing in it.
	var fresh := _test_room()
	await _frames(1)
	var crab: Enemy = Entities.create("crab")
	crab.position = (Vector2(15, 6) + Vector2(0.5, 0.5)) * WorldMap.TILE
	fresh.add_child(crab)
	crab.set_physics_process(false)
	await _frames(1)
	fresh.chemistry.ignite(Vector2i(15, 6))
	fresh.chemistry._burn_bystanders()
	_check(crab.health < crab.max_health, "standing in fire hurts")
	fresh.chemistry.douse(Vector2i(15, 6))
	_check(not fresh.chemistry.is_burning(Vector2i(15, 6)), "water puts a fire out")
	room.free()
	fresh.free()

	# Chad's flambeau.
	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.wharf_demo = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	_bench_evey()
	await _physics_frames(3)
	_check(GameData.has_item("flambeau"), "the flambeau is an item")
	var current := game.current_room()
	var player: Player = game.get_node("Player")
	player.facing = Vector2.RIGHT
	var ahead := player.position + Vector2(70, -8) - current.position
	var cell := RoomChemistry.cell_of(ahead)
	# Whatever is there, make it dry grass for the test.
	var index := cell.y * current.chemistry.cols + cell.x
	current.chemistry.get("_material")[index] = "grass"
	current.chemistry.get("_wet")[index] = 0.0
	_check(game.light_fire(), "the flambeau lights the grass in front of Chad")
	_check(current.chemistry.is_burning(cell), "that tile is burning")
	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
