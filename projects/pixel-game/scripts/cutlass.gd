class_name Cutlass
extends Node2D
## The hero's sword swing. Draws a sweeping blade and damages each body in reach once.

const ACTIVE_START := 0.06
const ACTIVE_END := 0.2
const REACH := 13.0
const DAMAGE := 1
const SWEEP := deg_to_rad(110.0)
const BLADE := Color("dfe6f5")
const HANDLE := Color("78492c")

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
	if _elapsed >= _duration:
		cancel()
	else:
		queue_redraw()


func _draw() -> void:
	var t := clampf(_elapsed / _duration, 0.0, 1.0)
	var angle := _dir.angle() - SWEEP / 2.0 + SWEEP * t
	var direction := Vector2.from_angle(angle)
	draw_line(direction * 3.0, direction * 6.0, HANDLE, 2.0)
	draw_line(direction * 6.0, direction * (REACH + 4.0), BLADE, 2.0)


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
