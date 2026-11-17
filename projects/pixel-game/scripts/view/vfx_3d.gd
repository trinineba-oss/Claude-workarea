class_name Vfx3D
extends RefCounted
## Impact effects for the 2.5D view, from two free CC BY 4.0 packs (credits in
## assets/vfx/CREDITS.md):
##   shader(...) a VFX 2D Free effect ("spark", "smoke") drawn on a camera-facing quad
##   sheet(...)  a Crisp Juice Free sprite sheet ("ring_shockwave_white", "star_burst_gold",
##               "coin_burst_gold") played once on a camera-facing sprite
## Both free themselves when done.

const SHADERS := {
	"spark": preload("res://shaders/vfx/spark.gdshader"),
	"smoke": preload("res://shaders/vfx/smoke.gdshader"),
}
const DURATION := {"spark": 0.3, "smoke": 0.9}
const SHEETS_PATH := "res://assets/vfx/crisp_juice/sheets.json"
const SHEET_TEXTURE := "res://assets/vfx/crisp_juice/%s.png"

static var _sheets: Dictionary


## A shader effect `size` units wide at `at` (3D), playing over `seconds` (0: its usual length).
static func shader(
	parent: Node3D, effect: String, at: Vector3, size: float, seconds := 0.0, tint := Color.WHITE
) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	var mat := ShaderMaterial.new()
	mat.shader = SHADERS[effect]
	mat.set_shader_parameter("seed", randf() * 10.0)
	mat.set_shader_parameter("rect_size", Vector2.ONE * 128.0)
	mat.set_shader_parameter("progress", 0.0)
	if tint != Color.WHITE:
		mat.set_shader_parameter("color_mid", tint)
	var node := MeshInstance3D.new()
	node.name = "Vfx_" + effect
	node.mesh = quad
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position = at
	parent.add_child(node)
	var length := seconds if seconds > 0.0 else float(DURATION[effect])
	var tween := node.create_tween()
	tween.tween_method(func(p: float): mat.set_shader_parameter("progress", p), 0.0, 1.0, length)
	tween.tween_callback(node.queue_free)
	return node


## A sprite-sheet effect `size` units wide at `at` (3D), played once at the sheet's speed.
static func sheet(parent: Node3D, sheet_name: String, at: Vector3, size: float) -> Sprite3D:
	var info: Dictionary = _load().get(sheet_name, {})
	if info.is_empty():
		return null
	var sprite := Sprite3D.new()
	sprite.name = "Vfx_" + sheet_name
	sprite.texture = load(SHEET_TEXTURE % sheet_name)
	sprite.hframes = int(info["cols"])
	sprite.vframes = int(info["rows"])
	sprite.pixel_size = size / float(info["cell"])
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.position = at
	parent.add_child(sprite)
	var frames := int(info["frames"])
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "frame", frames - 1, frames / float(info["fps"])).from(0)
	tween.tween_callback(sprite.queue_free)
	return sprite


static func _load() -> Dictionary:
	if _sheets == null or _sheets.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SHEETS_PATH))
		_sheets = parsed if parsed is Dictionary else {}
	return _sheets
