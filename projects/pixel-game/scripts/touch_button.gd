class_name TouchButton
extends TouchWidget
## Round on-screen button that holds an input action while it is touched.

@export var action: StringName = &"attack"
@export var label := "A"


func _draw() -> void:
	var centre := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	var pressed := _finger != NO_FINGER
	draw_circle(centre, radius, Color(1, 1, 1, 0.42 if pressed else 0.14))
	draw_arc(centre, radius - 1.5, 0.0, TAU, 64, Color(1, 1, 1, 0.55), 3.0, true)
	var font := ThemeDB.fallback_font
	var font_size := int(size.y * 0.36)
	draw_string(
		font,
		Vector2(0, centre.y + font_size * 0.36),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		font_size,
		Color(1, 1, 1, 0.9)
	)


func _on_press(_position: Vector2) -> void:
	Input.action_press(action)
	queue_redraw()


func _on_release() -> void:
	Input.action_release(action)
	queue_redraw()
