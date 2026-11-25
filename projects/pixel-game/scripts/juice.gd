class_name Juice
extends RefCounted
## Game feel: hit-stop (the action freezes for an instant when a blow lands), screen shake, a
## camera punch (zoom in) and the finisher's beat: impact frame, longer freeze, slow motion.
## All are skipped when running headless, so tests keep their timing.

const IMPACT_FRAME := preload("res://shaders/impact_frame.gdshader")
## The finisher: freeze, then this much slow motion for this long (real seconds).
const FINISH_STOP := 0.12
const SLOW_SCALE := 0.35
const SLOW_SECONDS := 0.22
const IMPACT_SECONDS := 0.06

## Current shake strength, in tiles; Game adds it to the camera and lets it die away.
static var shake_amount := 0.0
## Current camera punch (extra zoom); Game eases it back to 0.
static var zoom_amount := 0.0

static var _stopping := false
static var _impact := false


static func enabled() -> bool:
	return DisplayServer.get_name() != "headless"


## Freezes the action for `seconds` (real time).
static func hit_stop(tree: SceneTree, seconds: float) -> void:
	if not enabled() or _stopping or tree == null:
		return
	_stopping = true
	Engine.time_scale = 0.05
	await tree.create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0
	_stopping = false


static func shake(amount: float) -> void:
	if enabled():
		shake_amount = maxf(shake_amount, amount)


static func punch(amount: float) -> void:
	if enabled():
		zoom_amount = maxf(zoom_amount, amount)


## The combo finisher landing: an impact frame, a longer freeze, a camera punch, then a beat of
## slow motion.
static func finisher(tree: SceneTree) -> void:
	if not enabled() or _stopping or tree == null:
		return
	punch(0.14)
	impact_frame(tree)
	await hit_stop(tree, FINISH_STOP)
	if _stopping:
		return
	_stopping = true
	Engine.time_scale = SLOW_SCALE
	await tree.create_timer(SLOW_SECONDS, true, false, true).timeout
	Engine.time_scale = 1.0
	_stopping = false


## For a split second the screen turns to stark ink on paper.
static func impact_frame(tree: SceneTree) -> void:
	if not enabled() or _impact or tree == null:
		return
	_impact = true
	var layer := CanvasLayer.new()
	layer.name = "ImpactFrame"
	layer.layer = 100
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = IMPACT_FRAME
	rect.material = mat
	layer.add_child(rect)
	tree.root.add_child(layer)
	await tree.create_timer(IMPACT_SECONDS, true, false, true).timeout
	layer.queue_free()
	_impact = false
