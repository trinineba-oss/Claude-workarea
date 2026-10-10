class_name Soucouyant
extends Corbeau
## A soucouyant from Trinidad folklore: an old woman by day, a ball of fire by night. It hovers
## and swoops like a corbeau, but glows, so you can see it coming across a dark street.

const GLOW := Color(1.0, 0.45, 0.2)


func _ready() -> void:
	super()
	var glow := NightLight.make(GLOW, 300, 1.1)
	glow.position = Vector2(0, -FLY_HEIGHT - 20.0)
	add_child(glow)


func _animate(delta: float) -> void:
	super(delta)
	# Flicker like a flame instead of flapping.
	var flicker := 1.0 + sin(_age * 23.0) * 0.06 + sin(_age * 37.0) * 0.04
	_sprite.scale = Vector2(flicker, 2.0 - flicker)
	_sprite.flip_h = false
