extends SceneTree
## Headless smoke test: boots the main scene, checks the pixel-art settings,
## and collects a coin by moving the player onto it.
## Run: godot --headless --path . --script res://tests/smoke_test.gd

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)


func _run() -> void:
	_check(
		(
			ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")
			== 0
		),
		"nearest-neighbour texture filtering is on"
	)
	_check(
		ProjectSettings.get_setting("display/window/stretch/scale_mode") == "integer",
		"integer scaling is on"
	)

	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await physics_frame

	var coins := main.get_children().filter(func(n): return n is Coin)
	_check(coins.size() == main.COIN_COUNT, "spawns %d coins" % main.COIN_COUNT)

	main.get_node("Player").global_position = coins[0].global_position
	await physics_frame
	await physics_frame
	_check(main.score == 1, "touching a coin scores 1 (got %d)" % main.score)
	_check(main.get_node("HUD/ScoreLabel").text.begins_with("Coins: 1"), "HUD shows the score")

	print("PASS" if _failures == 0 else "%d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)
