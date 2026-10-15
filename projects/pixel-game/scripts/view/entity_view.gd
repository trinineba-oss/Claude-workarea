class_name EntityView
extends Node3D
## The 3D twin of one 2D thing (Chad, Evey, a vendor, a crab, a food truck, a coin...). Every
## frame it copies the 2D node's position and the look of its sprites: each Sprite2D becomes an
## upright Sprite3D facing the camera (shadows and floor decals, z_index -4 and below, lie flat
## on the ground instead), each Label a Label3D and each NightLight an OmniLight3D. Heights come
## from the 2D offsets: in 2D "up the screen" is "up in the air". When the node is
## highlighted (something to talk to) a speech bubble floats over it.

const PX := View3D.PX
## Sprites of things that stand (characters, props) stand on this layer; floor decals lie on
## the ground at this height.
const DECAL_HEIGHT := 0.012

var source: Node2D

var _pairs: Array = []  # [2D node, 3D node]
var _child_count := -1
var _bubble: Label3D


func setup(node: Node2D) -> void:
	source = node
	name = "View_" + str(node.name)


func sync() -> void:
	if source.get_child_count() != _child_count:
		_rebuild()
	position = View3D.to_3d(source.global_position)
	visible = source.is_visible_in_tree()
	if not visible:
		return
	var origin := source.global_position
	for pair: Array in _pairs:
		if not is_instance_valid(pair[0]):
			continue
		var from: CanvasItem = pair[0]
		var to: Node3D = pair[1]
		to.visible = from.is_visible_in_tree()
		if not to.visible:
			continue
		if from is Sprite2D:
			_sync_sprite(from, to, origin)
		elif from is Label:
			_sync_label(from, to, origin)
		elif from is NightLight:
			_sync_light(from, to, origin)
	if _bubble != null:
		var talking: bool = source is Interactable and source.get("_highlighted") == true
		_bubble.visible = talking
		if talking:
			var bob := absf(sin(Time.get_ticks_msec() / 250.0)) * 0.08
			_bubble.position = Vector3(0, source.bubble_height * PX + 0.2 + bob, 0.05)


func _rebuild() -> void:
	for pair: Array in _pairs:
		if is_instance_valid(pair[1]):
			pair[1].queue_free()
	_pairs.clear()
	_child_count = source.get_child_count()
	var found: Array[Node] = [source]
	found.append_array(source.find_children("*", "", true, false))
	var index := 0
	for node in found:
		var made: Node3D = null
		if node is Sprite2D:
			made = _make_sprite(node, index)
		elif node is Label:
			made = Label3D.new()
		elif node is NightLight:
			made = OmniLight3D.new()
		if made != null:
			add_child(made)
			_pairs.append([node, made])
			index += 1
	if source is Interactable and _bubble == null:
		_bubble = Label3D.new()
		_bubble.text = "..."
		_bubble.font_size = 64
		_bubble.outline_size = 24
		_bubble.modulate = Color(0.15, 0.1, 0.2)
		_bubble.outline_modulate = Color(1, 1, 1)
		_bubble.pixel_size = 0.006
		_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bubble.no_depth_test = true
		_bubble.visible = false
		add_child(_bubble)


func _make_sprite(from: Sprite2D, index: int) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.pixel_size = PX
	sprite.shaded = true
	sprite.double_sided = true
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	if _is_decal(from):
		sprite.rotation_degrees.x = -90.0
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		sprite.render_priority = index
	else:
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	sprite.set_meta("order", index)
	return sprite


static func _is_decal(from: Sprite2D) -> bool:
	var tex := from.texture
	var is_shadow := tex != null and tex.resource_path.ends_with("shadow.png")
	return is_shadow or from.z_index <= -4


func _sync_sprite(from: Sprite2D, to: Sprite3D, origin: Vector2) -> void:
	if to.texture != from.texture:
		to.texture = from.texture
	to.hframes = from.hframes
	to.vframes = from.vframes
	to.frame = from.frame
	to.region_enabled = from.region_enabled
	to.region_rect = from.region_rect
	to.flip_h = from.flip_h
	to.flip_v = from.flip_v
	to.centered = from.centered
	to.modulate = from.modulate * from.self_modulate * _inherited_modulate(from)
	var scale2d := from.global_scale
	var rel := from.global_position - origin
	var order: int = to.get_meta("order", 0)
	if to.billboard == BaseMaterial3D.BILLBOARD_DISABLED:
		# Lying flat: 2D x/y map straight onto the ground.
		to.position = Vector3(rel.x * PX, DECAL_HEIGHT + order * 0.002, rel.y * PX)
		to.offset = Vector2(from.offset.x, -from.offset.y)
		to.scale = Vector3(scale2d.x, scale2d.y, 1.0)
		to.rotation.z = -from.global_rotation
	else:
		# Standing: 2D "up" is height. Later sprites sit a hair nearer the camera.
		to.position = Vector3(rel.x * PX, -rel.y * PX, order * 0.004)
		to.offset = Vector2(from.offset.x, -from.offset.y)
		to.scale = Vector3(absf(scale2d.x), absf(scale2d.y), 1.0)


static func _inherited_modulate(from: CanvasItem) -> Color:
	var colour := Color.WHITE
	var parent := from.get_parent()
	while parent is CanvasItem and not parent is Room:
		colour *= (parent as CanvasItem).modulate
		parent = parent.get_parent()
	return colour


func _sync_label(from: Label, to: Label3D, origin: Vector2) -> void:
	to.text = from.text
	to.pixel_size = PX
	to.font_size = from.get_theme_font_size("font_size")
	to.modulate = from.get_theme_color("font_color") * from.modulate
	to.outline_size = from.get_theme_constant("outline_size")
	to.outline_modulate = from.get_theme_color("font_outline_color")
	to.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	var centre := from.global_position + from.size / 2.0 - origin
	to.position = Vector3(centre.x * PX, -centre.y * PX, 0.06)


func _sync_light(from: NightLight, to: OmniLight3D, origin: Vector2) -> void:
	var rel := from.global_position - origin
	to.position = Vector3(rel.x * PX, maxf(-rel.y * PX, 0.3), 0.2)
	to.light_color = from.color
	to.light_energy = from.energy * 2.2
	to.omni_range = from.texture_scale * 256.0 * PX * 0.75
	to.visible = from.visible
