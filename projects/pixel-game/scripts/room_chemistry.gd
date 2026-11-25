class_name RoomChemistry
extends Node2D
## The chemistry grid of one room (open-world systems, phase 1): every tile has a material
## (data/materials.json) and a state, and simple rules make things happen on their own,
## without special cases:
## - fire spreads from a burning tile to flammable neighbours, faster through grass than
##   wood, burns out to ash, and burns away bushes, crates and fences (opening the way);
## - water douses: tiles next to it are wet and won't catch, and wet tiles dry slowly;
## - anyone standing in fire gets hurt (Chad, enemies; Evey is too sensible to stand in it).
## Ash grows back after a while. The grid ticks a few times a second; it lives and dies with
## its room.

enum State { NORMAL, BURNING, ASH }

const TICK := 0.1
## Seconds a burning tile hurts whoever stands in it, between hits.
const BURN_HIT_EVERY := 0.8
## Ash grows back into grass after this many seconds.
const REGROW := 90.0
## Wet tiles dry out at this rate (wetness per second).
const DRY_RATE := 0.05
const MATERIALS_PATH := "res://data/materials.json"
const ASH := Color(0.16, 0.12, 0.11)
const EMBER := Color(1.0, 0.55, 0.15)
const FLAME := [Color(1.0, 0.86, 0.3), Color(1.0, 0.55, 0.15), Color(0.86, 0.22, 0.1)]

static var _data: Dictionary

var room: Room
var cols := WorldMap.COLS
var rows := WorldMap.ROWS

var _material: Array[String] = []
var _state: Array[int] = []
var _timer: Array[float] = []
var _wet: Array[float] = []
var _clock := 0.0
var _hit_clock := 0.0
var _fire_layer: Node2D
var _rng := RandomNumberGenerator.new()


func setup(owner_room: Room) -> void:
	room = owner_room
	name = "Chemistry"
	z_index = -6
	_rng.seed = hash(room.coords) + 7
	var lines := room.map_lines
	rows = lines.size()
	cols = lines[0].length() if rows > 0 else 0
	for y in rows:
		for x in cols:
			_material.append(material_for_tile(lines[y][x]))
			_state.append(State.NORMAL)
			_timer.append(0.0)
			_wet.append(0.0)
	# Water wets its neighbours from the start: shores don't burn.
	for y in rows:
		for x in cols:
			if bool(props(_material[_i(x, y)]).get("douses", false)):
				for n in _neighbours(Vector2i(x, y)):
					_wet[_i(n.x, n.y)] = 1.0
	_fire_layer = Node2D.new()
	_fire_layer.name = "Flames"
	_fire_layer.z_index = 12
	_fire_layer.draw.connect(_draw_flames)
	add_child(_fire_layer)


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MATERIALS_PATH))
		_data = parsed if parsed is Dictionary else {}
	return _data


static func material_for_tile(ch: String) -> String:
	return str(data().get("tiles", {}).get(ch, ""))


static func props(material: String) -> Dictionary:
	return data().get("materials", {}).get(material, {})


func material_at(cell: Vector2i) -> String:
	return _material[_i(cell.x, cell.y)] if _inside(cell) else ""


func state_at(cell: Vector2i) -> State:
	return _state[_i(cell.x, cell.y)] as State if _inside(cell) else State.NORMAL


func is_burning(cell: Vector2i) -> bool:
	return state_at(cell) == State.BURNING


func burning_count() -> int:
	return _state.count(State.BURNING)


## Sets a tile alight if it can burn (flammable, not wet, not already burnt). `cell` is in
## room tiles. Returns whether it caught.
func ignite(cell: Vector2i) -> bool:
	if not _inside(cell):
		return false
	var i := _i(cell.x, cell.y)
	if _state[i] != State.NORMAL or _wet[i] > 0.3:
		return false
	var p := props(_material[i])
	if not bool(p.get("flammable", false)):
		return false
	_state[i] = State.BURNING
	_timer[i] = float(p.get("burn_time", 3.0)) * _rng.randf_range(0.85, 1.15)
	set_process(true)
	queue_redraw()
	return true


## Puts out fire on a tile and soaks it.
func douse(cell: Vector2i) -> void:
	if not _inside(cell):
		return
	var i := _i(cell.x, cell.y)
	_wet[i] = 1.0
	if _state[i] == State.BURNING:
		_state[i] = State.ASH
		_timer[i] = REGROW
		queue_redraw()


## The room tile under a point given in room coordinates.
static func cell_of(local: Vector2) -> Vector2i:
	return Vector2i((local / WorldMap.TILE).floor())


func _process(delta: float) -> void:
	_clock += delta
	_hit_clock += delta
	if _clock >= TICK:
		_step(_clock)
		_clock = 0.0
	if _hit_clock >= BURN_HIT_EVERY:
		_hit_clock = 0.0
		_burn_bystanders()
	_fire_layer.queue_redraw()


## One tick of the rules.
func _step(dt: float) -> void:
	var lit: Array[Vector2i] = []
	for y in rows:
		for x in cols:
			var i := _i(x, y)
			if _wet[i] > 0.0 and not bool(props(_material[i]).get("douses", false)):
				var near_water := _next_to_water(Vector2i(x, y))
				if not near_water:
					_wet[i] = maxf(_wet[i] - DRY_RATE * dt, 0.0)
			match _state[i]:
				State.BURNING:
					_timer[i] -= dt
					for n in _neighbours(Vector2i(x, y)):
						var spread := float(props(_material[_i(n.x, n.y)]).get("spread", 0.0))
						if spread > 0.0 and _rng.randf() < spread * dt:
							lit.append(n)
					if _timer[i] <= 0.0:
						_burn_out(Vector2i(x, y))
				State.ASH:
					_timer[i] -= dt
					if _timer[i] <= 0.0 and _material[i] == "grass":
						_state[i] = State.NORMAL
						queue_redraw()
	for cell in lit:
		ignite(cell)


func _burn_out(cell: Vector2i) -> void:
	var i := _i(cell.x, cell.y)
	_state[i] = State.ASH
	_timer[i] = REGROW
	if bool(props(_material[i]).get("clears", false)):
		_clear(cell)
	queue_redraw()


## The thing on a tile (bush, crate, fence) burns away: its scenery goes, the tile is no
## longer solid, and the world map remembers it as bare ground.
func _clear(cell: Vector2i) -> void:
	for child in room.get_children():
		if child.name.ends_with("_%d_%d" % [cell.x, cell.y]) and not child is RoomChemistry:
			child.queue_free()
	var collision := room.get_node_or_null("Collision") as TileMapLayer
	if collision != null:
		collision.erase_cell(cell)
	var game := get_tree().get_first_node_in_group("game") as Game
	if game != null:
		game.world.set_tile(WorldMap.room_origin_cell(room.coords) + cell, "p")
	var line := room.map_lines[cell.y]
	room.map_lines[cell.y] = line.substr(0, cell.x) + "p" + line.substr(cell.x + 1)
	_material[_i(cell.x, cell.y)] = ""


## Chad and enemies standing in fire get hurt (and Evey has a word about it).
func _burn_bystanders() -> void:
	if burning_count() == 0:
		return
	for node in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("player"):
		var body := node as Node2D
		if body == null or not body.has_method("take_hit"):
			continue
		var local := body.global_position - room.global_position
		if is_burning(cell_of(local)):
			body.take_hit(1, body.global_position + Vector2(0, 30))
			Effects.burst(room, local + Vector2(0, -20), "hit")
			if body is Player:
				var evey := get_tree().get_first_node_in_group("companion") as Companion
				if evey != null:
					evey.remark("fire")


func _next_to_water(cell: Vector2i) -> bool:
	for n in _neighbours(cell):
		if bool(props(_material[_i(n.x, n.y)]).get("douses", false)):
			return true
	return false


func _neighbours(cell: Vector2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _inside(cell + d):
			found.append(cell + d)
	return found


func _inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < cols and cell.y < rows


func _i(x: int, y: int) -> int:
	return y * cols + x


# --- drawing (on the 2x pixel grid) ---------------------------------------------------------


## Ash: a soft scorch on burnt tiles, darker in the middle, with a few cinders.
func _draw() -> void:
	var tile := float(WorldMap.TILE)
	for y in rows:
		for x in cols:
			if _state[_i(x, y)] == State.NORMAL:
				continue
			var origin := Vector2(x, y) * tile
			draw_rect(Rect2(origin, Vector2(tile, tile)), Color(ASH, 0.45))
			draw_rect(
				Rect2(origin + Vector2(8, 8), Vector2(tile - 16, tile - 16)), Color(ASH, 0.25)
			)
			var seed := hash(Vector2i(x, y) + room.coords * 100)
			for k in 5:
				var px := 4 + (hash(seed + k * 31) % 14) * 4
				var py := 4 + (hash(seed + k * 57) % 14) * 4
				draw_rect(
					Rect2(origin + Vector2(px, py), Vector2(4, 4)), Color(0.08, 0.06, 0.06, 0.8)
				)


## Flames: little pixel tongues of fire flickering on burning tiles, and embers.
func _draw_flames() -> void:
	var tile := float(WorldMap.TILE)
	var t := Time.get_ticks_msec() / 1000.0
	for y in rows:
		for x in cols:
			if _state[_i(x, y)] != State.BURNING:
				continue
			var base := (Vector2(x, y) + Vector2(0.5, 0.9)) * tile
			for k in 3:
				var phase := t * 9.0 + float(k * 2 + x * 3 + y)
				var height := 18.0 + 10.0 * absf(sin(phase))
				var at := base + Vector2((k - 1) * 14.0, 0)
				for row in range(0, int(height), 4):
					var f := float(row) / height
					var width := roundf((1.0 - f) * 5.0) * 2.0 + 2.0
					var col: Color = FLAME[mini(int(f * 3.0), 2)]
					_fire_layer.draw_rect(
						Rect2((at + Vector2(-width / 2.0, -row - 4)).round(), Vector2(width, 4)),
						col
					)
			if int(t * 6.0 + x + y) % 3 == 0:
				var ember := base + Vector2(sin(t * 3.0 + x) * 16.0, -40.0 - fmod(t * 30.0, 20.0))
				_fire_layer.draw_rect(Rect2(ember.round(), Vector2(2, 2)), EMBER)
