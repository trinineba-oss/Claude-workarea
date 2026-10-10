class_name WorldMap
extends RefCounted
## All rooms of the world, loaded from data/rooms/<x>_<y>.txt: 11 map rows of 20 characters
## (see Tiles for the legend), then optional object lines `<kind> <x> <y> [id]` (see
## Entities), e.g. `dog 12 5` or `npc 8 4 ibis`. Rooms form a grid; walking off an open
## edge moves to the neighbouring room.

const COLS := 20
const ROWS := 11
const TILE := Tiles.SIZE
const START := "@"

var rooms: Dictionary = {}  # Vector2i -> PackedStringArray (map rows)
var objects: Dictionary = {}  # Vector2i -> Array of {"kind", "cell": Vector2i, "arg"}

var _parse_problems := PackedStringArray()


static func load_dir(dir_path: String) -> WorldMap:
	var world := WorldMap.new()
	for file_name in DirAccess.get_files_at(dir_path):
		var parts := file_name.get_basename().split("_")
		if file_name.get_extension() != "txt" or parts.size() != 2:
			continue
		if not (parts[0].is_valid_int() and parts[1].is_valid_int()):
			continue
		var text := FileAccess.get_file_as_string(dir_path.path_join(file_name))
		var lines := PackedStringArray()
		for line in text.split("\n"):
			if not line.strip_edges().is_empty():
				lines.append(line.strip_edges(false, true))
		var coords := Vector2i(int(parts[0]), int(parts[1]))
		world.rooms[coords] = lines.slice(0, ROWS)
		world._parse_objects(coords, lines.slice(ROWS))
	return world


static func room_size() -> Vector2:
	return Vector2(COLS * TILE, ROWS * TILE)


static func room_origin(coords: Vector2i) -> Vector2:
	return Vector2(coords.x, coords.y) * room_size()


func has_room(coords: Vector2i) -> bool:
	return rooms.has(coords)


func rows(coords: Vector2i) -> PackedStringArray:
	return rooms[coords]


## The room that contains a world position.
static func room_at(pos: Vector2) -> Vector2i:
	var size := room_size()
	return Vector2i(floori(pos.x / size.x), floori(pos.y / size.y))


## Map character at a global tile position. Cells with no room are filled with sea in the
## south and grass elsewhere, so the edges of the world never look empty.
func tile_at(cell: Vector2i) -> String:
	var coords := Vector2i(floori(float(cell.x) / COLS), floori(float(cell.y) / ROWS))
	if not rooms.has(coords):
		return filler_tile(coords)
	var lines: PackedStringArray = rooms[coords]
	return lines[posmod(cell.y, ROWS)][posmod(cell.x, COLS)]


## Map rows for a room, or plain filler rows for a cell with no room.
func rows_or_filler(coords: Vector2i) -> PackedStringArray:
	if rooms.has(coords):
		return rooms[coords]
	var lines := PackedStringArray()
	for y in ROWS:
		lines.append(filler_tile(coords).repeat(COLS))
	return lines


## This room's map with a one-tile border taken from the neighbouring rooms, so ground
## materials can blend across room edges.
func padded_rows(coords: Vector2i) -> PackedStringArray:
	var lines := PackedStringArray()
	var top_left := Vector2i(coords.x * COLS, coords.y * ROWS) - Vector2i.ONE
	for y in ROWS + 2:
		var line := ""
		for x in COLS + 2:
			line += tile_at(top_left + Vector2i(x, y))
		lines.append(line)
	return lines


func filler_tile(coords: Vector2i) -> String:
	return "~" if coords.y >= 1 else "."


## Smallest rectangle of room coordinates that holds every room.
func bounds() -> Rect2i:
	var rect := Rect2i()
	var first := true
	for coords: Vector2i in rooms:
		if first:
			rect = Rect2i(coords, Vector2i.ONE)
			first = false
		else:
			rect = rect.merge(Rect2i(coords, Vector2i.ONE))
	return rect


func objects_in(coords: Vector2i) -> Array:
	return objects.get(coords, [])


## Room that contains the player start marker, or (0, 0) if there is none.
func start_room() -> Vector2i:
	for coords in rooms:
		if _find_start(coords) != Vector2i(-1, -1):
			return coords
	return Vector2i.ZERO


## Centre of the start tile in world coordinates.
func start_position() -> Vector2:
	var coords := start_room()
	var cell := _find_start(coords)
	if cell == Vector2i(-1, -1):
		cell = Vector2i(COLS / 2, ROWS / 2)
	return room_origin(coords) + Vector2(cell) * TILE + Vector2.ONE * (TILE / 2.0)


## Human-readable problems with the map data. Empty when the world is valid.
func validate() -> PackedStringArray:
	var problems := _parse_problems.duplicate()
	var starts := 0
	for coords in rooms:
		var lines: PackedStringArray = rooms[coords]
		if lines.size() != ROWS:
			problems.append("room %s has %d rows, expected %d" % [coords, lines.size(), ROWS])
			continue
		for y in ROWS:
			if lines[y].length() != COLS:
				problems.append(
					(
						"room %s row %d has %d columns, expected %d"
						% [coords, y, lines[y].length(), COLS]
					)
				)
				continue
			for x in COLS:
				var ch := lines[y][x]
				if not Tiles.is_known(ch):
					problems.append("room %s has unknown tile '%s' at %d,%d" % [coords, ch, x, y])
				elif ch == START:
					starts += 1
	if starts != 1:
		problems.append("expected exactly one start marker '@', found %d" % starts)
	if problems.is_empty():
		problems.append_array(_edge_problems())
		problems.append_array(_object_problems())
	return problems


func _parse_objects(coords: Vector2i, lines: PackedStringArray) -> void:
	var list := []
	for line in lines:
		var text := line.strip_edges()
		if text.is_empty() or text.begins_with(";"):
			continue
		var parts := text.split(" ", false)
		var size_ok := parts.size() == 3 or parts.size() == 4
		if not size_ok or not (parts[1].is_valid_int() and parts[2].is_valid_int()):
			_parse_problems.append("room %s: bad object line '%s'" % [coords, text])
			continue
		(
			list
			. append(
				{
					"kind": parts[0],
					"cell": Vector2i(int(parts[1]), int(parts[2])),
					"arg": parts[3] if parts.size() == 4 else "",
				}
			)
		)
	if not list.is_empty():
		objects[coords] = list


func _object_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	for coords in objects:
		for obj in objects[coords]:
			var cell: Vector2i = obj["cell"]
			if not Entities.is_known(obj["kind"]):
				problems.append("room %s: unknown object '%s'" % [coords, obj["kind"]])
			elif Entities.argument_problem(obj["kind"], obj.get("arg", "")) != "":
				problems.append(
					(
						"room %s: %s"
						% [coords, Entities.argument_problem(obj["kind"], obj.get("arg", ""))]
					)
				)
			elif cell.x < 0 or cell.x >= COLS or cell.y < 0 or cell.y >= ROWS:
				problems.append(
					"room %s: %s at %s is outside the room" % [coords, obj["kind"], cell]
				)
			elif Tiles.is_solid(rooms[coords][cell.y][cell.x]):
				problems.append(
					"room %s: %s at %s is on a solid tile" % [coords, obj["kind"], cell]
				)
	return problems


func _edge_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	for coords in rooms:
		for dir in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var neighbour: Vector2i = coords + dir
			var mine := _edge_solidity(coords, dir)
			if has_room(neighbour):
				if dir in [Vector2i.RIGHT, Vector2i.DOWN]:
					var theirs := _edge_solidity(neighbour, -dir)
					if mine != theirs:
						problems.append(
							"openings of %s and %s do not line up" % [coords, neighbour]
						)
			elif false in mine:
				problems.append(
					"room %s has an opening toward missing room %s" % [coords, neighbour]
				)
	return problems


## For each tile along the edge facing `dir`: is it solid?
func _edge_solidity(coords: Vector2i, dir: Vector2i) -> Array:
	var lines: PackedStringArray = rooms[coords]
	var result := []
	if dir.x != 0:
		var x := COLS - 1 if dir.x > 0 else 0
		for y in ROWS:
			result.append(Tiles.is_solid(lines[y][x]))
	else:
		var y := ROWS - 1 if dir.y > 0 else 0
		for x in COLS:
			result.append(Tiles.is_solid(lines[y][x]))
	return result


func _find_start(coords: Vector2i) -> Vector2i:
	var lines: PackedStringArray = rooms[coords]
	for y in lines.size():
		var x := lines[y].find(START)
		if x != -1:
			return Vector2i(x, y)
	return Vector2i(-1, -1)
