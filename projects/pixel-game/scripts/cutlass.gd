class_name Cutlass
extends Node2D
## The hero's sword swing: a sweeping blade with a soft trail. Damages each body in reach once.

const ACTIVE_START := 0.06
const ACTIVE_END := 0.2
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

@onready var _area: Area2D = $Hit


func _ready() -> void:
	_area.monitoring = false
	visible = false


func _physics_process(delta: float) -> void:
	if _elapsed < 0.0:
		return
	_elapsed += delta
	var active := _elapsed >= ACTIVE_START and _elapsed <= ACTIVE_END
	_area.monitoring = active
	if active:
		for body in _area.get_overlapping_bodies():
			if body not in _already_hit and body.has_method("take_hit"):
				_already_hit.append(body)
				body.take_hit(DAMAGE, global_position)
				Effects.burst(body.get_parent(), body.position + Vector2(0, -30), "hit")
	if _elapsed >= _duration:
		cancel()
	else:
		queue_redraw()


func _draw() -> void:
	var t := clampf(_elapsed / _duration, 0.0, 1.0)
	var start := _dir.angle() - SWEEP / 2.0
	var angle := start + SWEEP * ease(t, 0.5)
	# Trail: a fading ribbon from where the swing started to the blade.
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var steps := 10
	for i in steps + 1:
		var a := lerpf(start, angle, float(i) / steps)
		points.append(Vector2.from_angle(a) * (REACH + 18.0))
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
				direction * (REACH + 14.0) + side * 0.6,
				direction * (REACH + 20.0),
				direction * 22.0 - side,
			]
		),
		BLADE
	)
	draw_line(direction * 22.0 - side, direction * (REACH + 20.0), BLADE_EDGE, 1.5)


func swing(direction: Vector2, duration: float) -> void:
	_dir = direction
	_duration = duration
	_elapsed = 0.0
	_already_hit.clear()
	_area.position = direction * REACH
	_area.rotation = direction.angle()
	visible = true
	queue_redraw()


func cancel() -> void:
	_elapsed = -1.0
	_area.monitoring = false
	visible = false
