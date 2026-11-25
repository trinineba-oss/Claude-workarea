class_name Cutlass
extends Node2D
## The hero's swing with whatever is in hand (the node keeps its old name): a sweeping weapon
## drawn on the pixel grid with a soft trail; a cutlass, branch, plank, cricket bat, fishing
## spear, or a fist. Damages each body in reach once. Each swing has its own damage, sweep
## (negative sweeps the other way; 360 is a spin that hits all round), reach and force; a hit
## freezes the action for an instant and shakes the screen (Juice), and shows its damage.
## The swing also strikes the world: bushes, crates and fences in reach take a hit
## (RoomChemistry.strike), and so do trees (they shake down branches).

signal landed(body: Node, damage: int)
## The swing struck a breakable thing in the world (a room tile).
signal hit_world(cell: Vector2i)

## The weapon can hit between these fractions of the swing.
const ACTIVE_FROM := 0.18
const ACTIVE_TO := 0.8
const REACH := 52.0
const DAMAGE := 1
const SWEEP := deg_to_rad(120.0)
const TRAIL := Color(1.0, 1.0, 1.0, 0.55)
## How each weapon looks: [inner length from Chad, blade width, main colour, edge colour,
## handle colour, handle length].
const LOOKS := {
	"blade": [22.0, 3.0, Color("eef2fb"), Color("9aa6bf"), Color("6b3f22"), 12.0],
	"branch": [18.0, 3.0, Color("7a5230"), Color("4a2f1a"), Color("5a3a20"), 8.0],
	"plank": [18.0, 6.0, Color("a07850"), Color("5e4126"), Color("6b4a2c"), 10.0],
	"bat": [20.0, 7.0, Color("e8d6a8"), Color("a88d55"), Color("3a2a1c"), 14.0],
	"spear": [16.0, 2.0, Color("8a6a44"), Color("c9ced8"), Color("8a6a44"), 0.0],
	"fist": [10.0, 9.0, Color("7a4a30"), Color("4a2a1a"), Color("4a6a30"), 0.0],
}

var _elapsed := -1.0
var _duration := 0.28
var _dir := Vector2.DOWN
var _already_hit: Array[Node] = []
var _cells_hit: Array[Vector2i] = []
var _damage := DAMAGE
var _sweep := SWEEP
var _reach := REACH
var _force := 1.0
var _look := "blade"
var _kind := "slash"

@onready var _area: Area2D = $Hit


func _ready() -> void:
	_area.monitoring = false
	visible = false


## How the swing looks ("blade", "bat", "fist"...) and what it does to the world ("slash" or
## "blunt").
func set_style(look: String, kind: String) -> void:
	_look = look if LOOKS.has(look) else "blade"
	_kind = kind
	queue_redraw()


func is_spin() -> bool:
	return absf(_sweep) >= TAU - 0.01


func _physics_process(delta: float) -> void:
	if _elapsed < 0.0:
		return
	_elapsed += delta
	var played := _elapsed / _duration
	var active := played >= ACTIVE_FROM and played <= ACTIVE_TO
	_area.monitoring = active and not is_spin()
	if active:
		var bodies: Array = _area.get_overlapping_bodies() if not is_spin() else _all_round()
		for body in bodies:
			if body not in _already_hit and body.has_method("take_hit"):
				_already_hit.append(body)
				_hit_body(body)
		_strike_world()
	if _elapsed >= _duration:
		cancel()
	else:
		queue_redraw()


## A spin hits every enemy within reach, all the way round.
func _all_round() -> Array:
	return get_tree().get_nodes_in_group("enemies").filter(
		func(e): return e.global_position.distance_to(global_position) < _reach + 30.0
	)


func _hit_body(body: Node) -> void:
	if "hit_force" in body:
		body.hit_force = _force
	if not body.take_hit(_damage, global_position):
		return
	var room := body.get_parent()
	var heavy := _force > 1.5
	Effects.burst(room, body.position + Vector2(0, -30), "hit")
	Effects.slash_arc(room, body.position, room.to_local(global_position), heavy)
	Effects.float_text(
		room,
		body.position + Vector2(randf_range(-14, 14), -70),
		str(_damage),
		Color(1, 0.95, 0.5) if heavy else Color.WHITE
	)
	if heavy:
		Effects.flourish(room, body.position, "ring_shockwave_white", 1.8, 0.4)
		Juice.finisher(get_tree())
	else:
		Juice.hit_stop(get_tree(), 0.05)
	Juice.shake(0.2 if heavy else 0.09)
	landed.emit(body, _damage)


## Breakable things in the swing's path (bushes, crates, fences, trees) take a hit, once per
## swing each.
func _strike_world() -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	if game == null:
		return
	var room := game.current_room()
	if room == null or room.chemistry == null:
		return
	var t := clampf(_elapsed / _duration, 0.0, 1.0)
	var angle := _dir.angle() - _sweep / 2.0 + _sweep * ease(t, 0.5)
	var points := [Vector2.from_angle(angle) * _reach, _dir * _reach * 0.7]
	for offset: Vector2 in points:
		var local := global_position + offset - room.global_position
		var cell := RoomChemistry.cell_of(local)
		if cell in _cells_hit:
			continue
		if room.chemistry.strike(cell, _damage, _kind):
			_cells_hit.append(cell)
			hit_world.emit(cell)


func _draw() -> void:
	var t := clampf(_elapsed / _duration, 0.0, 1.0)
	var start := _dir.angle() - _sweep / 2.0
	var angle := start + _sweep * ease(t, 0.5)
	var spec: Array = LOOKS[_look]
	var inner: float = spec[0]
	var width: float = spec[1]
	# Trail: a fading ribbon from where the swing started to the weapon (not for fists).
	if _look != "fist":
		var points := PackedVector2Array()
		var colors := PackedColorArray()
		var steps := 10
		for i in steps + 1:
			var a := lerpf(start, angle, float(i) / steps)
			points.append(Vector2.from_angle(a) * (_reach + 18.0))
			colors.append(Color(TRAIL, TRAIL.a * float(i) / steps))
		for i in range(steps, -1, -1):
			var a := lerpf(start, angle, float(i) / steps)
			points.append(Vector2.from_angle(a) * inner)
			colors.append(Color(TRAIL, 0.0))
		if absf(_sweep) > 0.05:
			draw_polygon(points, colors)
	var direction := Vector2.from_angle(angle)
	var side := direction.orthogonal()
	if _look == "fist":
		# A punch: the fist shoots out and back, with a little impact star at full reach.
		var out := sin(t * PI)
		var at := direction * (inner + (_reach - inner) * out)
		draw_rect(Rect2((at - Vector2(width, width) / 2.0).round(), Vector2(width, width)), spec[2])
		draw_rect(Rect2((at - Vector2(width, width) / 2.0).round(), Vector2(width, 2)), spec[3])
		if out > 0.85:
			for k in 4:
				var ray := Vector2.from_angle(k * PI / 2.0 + PI / 4.0) * 8.0
				draw_rect(Rect2((at + ray).round(), Vector2(4, 4)), Color(1, 0.95, 0.7))
		return
	var handle: float = spec[5]
	if handle > 0.0:
		draw_line(direction * (inner - handle), direction * inner, spec[4], 6.0)
	var tip := direction * (_reach + 20.0)
	draw_colored_polygon(
		PackedVector2Array(
			[
				direction * inner + side * width,
				tip - direction * 6.0 + side * width * 0.6,
				tip,
				tip - direction * 6.0 - side * width * 0.6,
				direction * inner - side * width,
			]
		),
		spec[2]
	)
	draw_line(direction * inner - side * width, tip, spec[3], 2.0)


func swing(
	direction: Vector2,
	duration: float,
	damage := DAMAGE,
	sweep_degrees := 120.0,
	reach := REACH,
	force := 1.0
) -> void:
	_dir = direction
	_duration = duration
	_damage = damage
	_sweep = deg_to_rad(sweep_degrees)
	_reach = reach
	_force = force
	_elapsed = 0.0
	_already_hit.clear()
	_cells_hit.clear()
	_area.position = direction * reach
	_area.rotation = direction.angle()
	visible = true
	queue_redraw()


func cancel() -> void:
	_elapsed = -1.0
	_area.monitoring = false
	visible = false
