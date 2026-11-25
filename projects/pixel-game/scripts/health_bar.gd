class_name HealthBar
extends Node2D
## An enemy's health bar over its head, shown once it has been hurt: the remaining health, a
## pale chunk for the damage just done (it drains away after a hit), a dark border. Drawn on
## the 2x pixel grid; wider for bosses.

## Size in art pixels (drawn at 2x).
const SIZE := Vector2i(16, 3)
## Fraction of the bar the pale chunk drains each second.
const DRAIN := 0.9
const BORDER := Color(0.1, 0.05, 0.08)
const EMPTY := Color(0.24, 0.13, 0.16)
const FULL := Color(0.92, 0.25, 0.2)
const CHUNK := Color(1.0, 0.95, 0.82)

var enemy: Enemy
## Height above the feet (px).
var height := 90.0

var _trail := 1.0


func setup(target: Enemy, top: float) -> void:
	enemy = target
	height = top
	name = "HealthBar"
	z_index = 30
	visible = false


func _process(delta: float) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var top := float(enemy.max_health)
	var hp := float(enemy.health)
	visible = top > 1.0 and hp > 0.0 and hp < top
	if not visible:
		_trail = 1.0
		return
	_trail = maxf(move_toward(_trail, hp / top, delta * DRAIN), hp / top)
	position = Vector2(0, -height).round()
	queue_redraw()


func fill() -> float:
	return float(enemy.health) / float(enemy.max_health) if enemy != null else 0.0


func _draw() -> void:
	var wide := int(SIZE.x * clampf(enemy.max_health / 12.0, 1.0, 1.8))
	var px := 2.0
	var size := Vector2(wide, SIZE.y) * px
	var at := Vector2(-size.x / 2.0, 0).round()
	draw_rect(Rect2(at - Vector2(px, px), size + Vector2(px, px) * 2.0), BORDER)
	draw_rect(Rect2(at, size), EMPTY)
	var inner := float(wide)
	draw_rect(Rect2(at, Vector2(roundf(inner * _trail) * px, size.y)), CHUNK)
	draw_rect(Rect2(at, Vector2(roundf(inner * fill()) * px, size.y)), FULL)
