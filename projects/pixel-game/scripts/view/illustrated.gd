class_name Illustrated
extends RefCounted
## The illustrated look, on trial in a few rooms (data/illustrated.json; the beach first).
## In those rooms the 2.5D view:
##   - paints the floor with the textures in assets/illustrated/ground/ (any that exist) and
##     draws dark ink lines where sand, water, grass and paths meet,
##   - shades scenery and props in flat toon bands with a dark ink outline,
##   - draws painted props from assets/illustrated/props/<kind>[_<n>].png (rock, bush, tree,
##     flowers, palm, ...) instead of the 3D shapes, when such pictures exist.
## Everything else stays as it is. Turn the trial off with "enabled": false.

const CONFIG_PATH := "res://data/illustrated.json"
const GROUND_DIR := "res://assets/illustrated/ground/%s.png"
const PROP_DIR := "res://assets/illustrated/props/%s.png"
const OUTLINE_SHADER := preload("res://shaders/ink_outline.gdshader")

static var _config: Dictionary
static var _outline: ShaderMaterial
static var _toon: Dictionary = {}  # original material -> toon copy
static var _props: Dictionary = {}  # kind -> Array[Texture2D]


static func config() -> Dictionary:
	if _config == null or _config.is_empty():
		var text := FileAccess.get_file_as_string(CONFIG_PATH)
		var parsed: Variant = JSON.parse_string(text) if text != "" else null
		_config = parsed if parsed is Dictionary else {"enabled": false}
	return _config


## Whether the illustrated look applies to this room (of the map Chad is on).
static func applies_to(room: Room) -> bool:
	if room == null or not bool(config().get("enabled", false)):
		return false
	var game := (
		room.get_tree().get_first_node_in_group("game") as Game if room.is_inside_tree() else null
	)
	var map_id := game.map_id if game != null else Game.OVERWORLD
	var key := "%s:%d_%d" % [map_id, room.coords.x, room.coords.y]
	return key in config().get("rooms", [])


## The room a 2D thing stands in, if any.
static func room_of(node: Node) -> Room:
	var parent := node.get_parent()
	while parent != null and not parent is Room:
		parent = parent.get_parent()
	return parent as Room


## A painted ground texture ("sand_tex" -> assets/illustrated/ground/sand.png), or null.
static func ground_texture(param: String) -> Texture2D:
	var path := GROUND_DIR % param.trim_suffix("_tex")
	return load(path) if ResourceLoader.exists(path) else null


## Painted pictures of a kind of prop: <kind>.png and/or <kind>_1.png, <kind>_2.png, ...
static func prop_textures(kind: String) -> Array:
	if _props.has(kind):
		return _props[kind]
	var found: Array = []
	if ResourceLoader.exists(PROP_DIR % kind):
		found.append(load(PROP_DIR % kind))
	for i in range(1, 10):
		var path := PROP_DIR % ("%s_%d" % [kind, i])
		if ResourceLoader.exists(path):
			found.append(load(path))
	_props[kind] = found
	return found


## An upright painted picture standing on the ground at its bottom centre. Painted props are
## drawn at 128 px per tile.
static func painted_sprite(texture: Texture2D) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.name = "Painted"
	sprite.texture = texture
	sprite.pixel_size = 1.0 / 128.0
	sprite.offset = Vector2(0, texture.get_height() / 2.0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sprite.shaded = true
	sprite.double_sided = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return sprite


## The painted-prop name for a 2D thing (a palm, a sign, the cave mouth...), or "".
static func prop_kind(node: Node) -> String:
	if node is Forage:
		return {"coconut_palm": "palm"}.get(node.forage_id, node.forage_id)
	if node is Signpost:
		return "sign"
	if node is Prop:
		return node.prop_id
	return ""


## Toon bands and an ink outline on every mesh under `root` (not the floor).
static func stylize(root: Node) -> void:
	var meshes: Array = [root] if root is GeometryInstance3D else []
	meshes.append_array(root.find_children("*", "GeometryInstance3D", true, false))
	for node: GeometryInstance3D in meshes:
		if node.name == "Floor" or node is SpriteBase3D or node is Label3D:
			continue
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			if mesh_node.mesh == null:
				continue
			for i in mesh_node.mesh.get_surface_count():
				var toon := toon_of(mesh_node.get_active_material(i))
				if toon != null:
					mesh_node.set_surface_override_material(i, toon)
		elif node.material_override != null:
			node.material_override = toon_of(node.material_override)
		if node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			node.material_overlay = outline()


## A copy of a standard material with flat toon lighting (glowing ones are left alone).
static func toon_of(material: Material) -> Material:
	if not material is StandardMaterial3D:
		return material
	var standard := material as StandardMaterial3D
	if standard.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		return material
	if _toon.has(material):
		return _toon[material]
	var copy := standard.duplicate() as StandardMaterial3D
	copy.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	copy.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	copy.metallic = 0.0
	_toon[material] = copy
	return copy


static func outline() -> ShaderMaterial:
	if _outline == null:
		_outline = ShaderMaterial.new()
		_outline.shader = OUTLINE_SHADER
		var ink: Array = config().get("ink", [0.12, 0.08, 0.07])
		_outline.set_shader_parameter("ink", Color(ink[0], ink[1], ink[2]))
		_outline.set_shader_parameter("width", float(config().get("outline_width", 0.03)))
	return _outline


## How strong the ink lines between ground materials are (0 = none).
static func ground_ink() -> float:
	return float(config().get("ground_ink", 0.7))
