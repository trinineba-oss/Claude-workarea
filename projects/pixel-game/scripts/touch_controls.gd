class_name TouchControls
extends Control
## The on-screen joystick and buttons. Shown on touch devices (and in the browser, for
## testing); hidden on desktop unless force_visible is set.

@export var force_visible := false


func _ready() -> void:
	visible = force_visible or _wants_touch_controls()


static func _wants_touch_controls() -> bool:
	return (
		DisplayServer.is_touchscreen_available()
		or OS.has_feature("mobile")
		or OS.has_feature("web")
	)
