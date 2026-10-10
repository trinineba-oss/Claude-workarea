class_name Signpost
extends Interactable
## A wooden sign; reading it plays its conversation.

const TEXTURE := preload("res://assets/sprites/sign.png")

var conversation := ""


func setup(id: String) -> void:
	conversation = id
	add_child(_shadow(Vector2(0.6, 0.6)))
	var sprite := Sprite2D.new()
	sprite.texture = TEXTURE
	sprite.offset = Vector2(0, -34)
	add_child(sprite)
	add_child(_feet_shape(Vector2(40, 20), Vector2(0, -8)))
	bubble_height = 90.0


func dialogue_id(_flags: Dictionary) -> String:
	return conversation
