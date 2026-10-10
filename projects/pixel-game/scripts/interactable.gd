class_name Interactable
extends StaticBody2D
## Something the hero can talk to or read: stands in the world, blocks movement, and shows a
## speech bubble when the hero is close and facing it. Subclasses say which conversation to
## play and where they are "touched" from.

const BUBBLE_COLOR := Color(1, 1, 1, 0.95)
const BUBBLE_INK := Color(0.15, 0.1, 0.2)

## Height of the speech bubble above the node's origin.
var bubble_height := 110.0

var _highlighted := false
var _bubble: Node2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("interactables")
	_bubble = Node2D.new()
	_bubble.z_index = 3
	_bubble.visible = false
	_bubble.draw.connect(_draw_bubble)
	add_child(_bubble)


func _process(_delta: float) -> void:
	if _highlighted:
		_bubble.position = Vector2(
			0, -bubble_height - absf(sin(Time.get_ticks_msec() / 250.0)) * 6.0
		)


## The conversation to play now, or "" if there is nothing to say.
func dialogue_id(_flags: Dictionary) -> String:
	return ""


func can_interact(flags: Dictionary) -> bool:
	return dialogue_id(flags) != ""


## Closest point of this thing to `from`, used for range and facing checks.
func touch_point(_from: Vector2) -> Vector2:
	return global_position


func set_highlighted(on: bool) -> void:
	_highlighted = on
	_bubble.visible = on
	_bubble.queue_redraw()


## Called when a conversation with it starts (e.g. to turn toward the hero).
func on_talk(_hero: Node2D) -> void:
	pass


func _draw_bubble() -> void:
	var rect := Rect2(-22, -18, 44, 32)
	_bubble.draw_rect(rect.grow(3), BUBBLE_INK, true)
	_bubble.draw_rect(rect, BUBBLE_COLOR, true)
	_bubble.draw_colored_polygon(
		PackedVector2Array([Vector2(-6, 14), Vector2(6, 14), Vector2(0, 24)]), BUBBLE_COLOR
	)
	for i in 3:
		_bubble.draw_circle(Vector2(-11 + i * 11, -2), 3.5, BUBBLE_INK)


static func _feet_shape(size: Vector2, offset: Vector2) -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = offset
	return shape


static func _shadow(scale: Vector2) -> Sprite2D:
	var shadow := Sprite2D.new()
	shadow.texture = preload("res://assets/sprites/shadow.png")
	shadow.scale = scale
	shadow.z_index = -4
	return shadow
