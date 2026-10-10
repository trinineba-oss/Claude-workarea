class_name TouchButton
extends TouchWidget
## Round on-screen button that holds an input action while it is touched.

@export var action: StringName = &"attack"
@export var label := "A"


func _draw() -> void:
	var centre := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	var pressed := _finger != NO_FINGER
	draw_circle(centre, radius, Color(1, 1, 1, 0.4 if pressed else 0.14))
	draw_arc(centre, radius - 0.5, 0.0, TAU, 24, Color(1, 1, 1, 0.5), 1.0)
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(0, centre.y + 3.0),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		8,
		Color(1, 1, 1, 0.85)
	)


func _on_press(_position: Vector2) -> void:
	Input.action_press(action)
	queue_redraw()


func _on_release() -> void:
	Input.action_release(action)
	queue_redraw()
