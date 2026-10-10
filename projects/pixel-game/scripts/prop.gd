class_name Prop
extends Interactable
## A large static thing (wrecked boat, food stall) from data/props.json. Its footprint of
## tiles is solid; it can optionally be read like a sign.

## Where wires attach on a utility pole, relative to its base.
const POLE_TOP := -220.0

var prop_id := ""
var footprint := Vector2i.ONE

var _conversation := ""


func setup(id: String) -> void:
	prop_id = id
	var data := GameData.prop(id)
	var size: Array = data.get("footprint", [1, 1])
	footprint = Vector2i(int(size[0]), int(size[1]))
	_conversation = data.get("dialogue", "")
	var tile := float(WorldMap.TILE)
	var area := Vector2(footprint) * tile
	add_child(_shadow(Vector2(area.x / 64.0 * 1.1, 1.0)))
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/sprites/%s.png" % data.get("sprite", "crate"))
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0 + 4.0)
	add_child(sprite)
	var solid: Variant = data.get("solid", [])
	if solid is Array and solid.size() == 2:
		add_child(_feet_shape(Vector2(solid[0], solid[1]), Vector2(0, -solid[1] / 2.0)))
	elif not (solid is String and solid == "none"):
		add_child(_feet_shape(area - Vector2(8, 8), Vector2(0, -area.y / 2.0)))
	var lamp: Array = data.get("light", [])
	if lamp.size() == 4:
		var light := NightLight.make(Color(lamp[3]), lamp[2])
		light.safe = true
		light.position = Vector2(lamp[0], lamp[1])
		add_child(light)
	var text: String = data.get("label", "")
	if text != "":
		var label := Label.new()
		label.text = text
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(0.25, 0.12, 0.08))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size = Vector2(96, 26)
		label.position = Vector2(-48, -sprite.texture.get_height() + 6.0)
		add_child(label)
	bubble_height = sprite.texture.get_height() + 10.0


func dialogue_id(_flags: Dictionary) -> String:
	return _conversation


func touch_point(from: Vector2) -> Vector2:
	var area := Vector2(footprint) * WorldMap.TILE
	var rect := Rect2(global_position - Vector2(area.x / 2.0, area.y), area)
	return from.clamp(rect.position, rect.end)
