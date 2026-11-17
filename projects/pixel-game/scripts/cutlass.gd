class_name Cutlass
extends Node2D
## The hero's sword swing: a sweeping blade with a soft trail. Damages each body in reach once.
## Each swing has its own damage, sweep (negative sweeps the other way), reach and force; a
## hit freezes the action for an instant and shakes the screen (Juice), and shows its damage.

signal landed(body: Node, damage: int)

## The blade can hit between these fractions of the swing.
const ACTIVE_FROM := 0.18
const ACTIVE_TO := 0.8
const REACH := 52.0
const DAMAGE := 1
const SWEEP := deg_to_rad(120.0)
const BLADE := Color("eef2fb")
const BLADE_EDGE := Color("9aa6bf")
const HANDLE := Color("6b3f22")
const TRAIL := Color(1.0, 1.0, 1.0, 0.55)

var _elapsed := -1.0
var _duration := 0.28
var _dir := Vector2.DOWN
var _already_hit: Array[Node] = []
var _damage := DAMAGE
var _sweep := SWEEP
var _reach := REACH
var _force := 1.0

@onready var _area: Area2D = $Hit


func _ready() -> void:
	_area.monitoring = false
	visible = false


func _physics_process(delta: float) -> void:
	if _elapsed < 0.0:
		return
	_elapsed += delta
	var played := _elapsed / _duration
	var active := played >= ACTIVE_FROM and played <= ACTIVE_TO
	_area.monitoring = active
	if active:
		for body in _area.get_overlapping_bodies():
			if body not in _already_hit and body.has_method("take_hit"):
				_already_hit.append(body)
				if "hit_force" in body:
					body.hit_force = _force
				if not body.take_hit(_damage, global_position):
					continue
				var room := body.get_parent()
				Effects.burst(room, body.position + Vector2(0, -30), "hit")
				Effects.float_text(
					room,
					body.position + Vector2(randf_range(-14, 14), -70),
					str(_damage),
					Color(1, 0.95, 0.5) if _force > 1.5 else Color.WHITE
				)
				if _force > 1.5:
					Effects.flourish(room, body.position, "ring_shockwave_white", 1.8, 0.4)
				Juice.hit_stop(get_tree(), 0.09 if _force > 1.5 else 0.05)
				Juice.shake(0.2 if _force > 1.5 else 0.09)
				landed.emit(body, _damage)
	if _elapsed >= _duration:
		cancel()
	else:
		queue_redraw()


func _draw() -> void:
	var t := clampf(_elapsed / _duration, 0.0, 1.0)
	var start := _dir.angle() - _sweep / 2.0
	var angle := start + _sweep * ease(t, 0.5)
	# Trail: a fading ribbon from where the swing started to the blade.
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var steps := 10
	for i in steps + 1:
		var a := lerpf(start, angle, float(i) / steps)
		points.append(Vector2.from_angle(a) * (_reach + 18.0))
		colors.append(Color(TRAIL, TRAIL.a * float(i) / steps))
	for i in range(steps, -1, -1):
		var a := lerpf(start, angle, float(i) / steps)
		points.append(Vector2.from_angle(a) * 22.0)
		colors.append(Color(TRAIL, 0.0))
	draw_polygon(points, colors)
	var direction := Vector2.from_angle(angle)
	var side := direction.orthogonal() * 3.0
	draw_line(direction * 10.0, direction * 22.0, HANDLE, 6.0)
	draw_colored_polygon(
		PackedVector2Array(
			[
				direction * 22.0 + side,
				direction * (_reach + 14.0) + side * 0.6,
				direction * (_reach + 20.0),
				direction * 22.0 - side,
			]
		),
		BLADE
	)
	draw_line(direction * 22.0 - side, direction * (_reach + 20.0), BLADE_EDGE, 1.5)


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
	_area.position = direction * reach
	_area.rotation = direction.angle()
	visible = true
	queue_redraw()


func cancel() -> void:
	_elapsed = -1.0
	_area.monitoring = false
	visible = false
