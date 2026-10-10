extends SceneTree
## Shared helpers for the headless tests. Subclasses override _run().
## Run one with: godot --headless --path . --script res://tests/<name>_test.gd

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	pass


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _physics_frames(count: int) -> void:
	for i in count:
		await physics_frame


func _finish() -> void:
	print("PASS" if _failures == 0 else "%d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)
