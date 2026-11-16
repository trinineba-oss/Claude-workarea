class_name Juice
extends RefCounted
## Game feel: hit-stop (the action freezes for an instant when a blow lands) and screen shake.
## Both are skipped when running headless, so tests keep their timing.

## Current shake strength, in tiles; View3D adds it to the camera and lets it die away.
static var shake_amount := 0.0

static var _stopping := false


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
