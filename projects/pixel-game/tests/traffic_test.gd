extends "res://tests/test_base.gd"
## Cars on Cipero Street: lanes spawn cars that drive across, hit and knock back Chad, and
## leave; power lines are strung between the poles.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_traffic.json"


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	_check(Entities.argument_problem("traffic", "down") == "", "down is a valid lane")
	_check(Entities.argument_problem("traffic", "sideways") != "", "sideways is not")

	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	await _physics_frames(2)
	var t := float(WorldMap.TILE)
	var crossing := Vector2i(1, 0)
	var origin := WorldMap.room_origin(crossing)
	game.go_to(crossing, origin + Vector2(3.5 * t, 7.5 * t))
	await _physics_frames(2)
	var room: Room = game.current_room()
	var lanes := room.get_children().filter(func(n): return n is Traffic)
	_check(lanes.size() == 2, "Cross Crossing has two lanes")
	var wires := room.get_children().filter(func(n): return n is Wires)
	_check(wires.size() == 1 and not wires[0].get("_spans").is_empty(), "power lines are strung")

	# Stand in the down lane and send a car at Chad.
	var lane: Traffic = lanes.filter(func(l): return l.direction == Vector2.DOWN)[0]
	var player: Player = game.get_node("Player")
	for car in get_nodes_in_group("cars"):
		car.queue_free()
	player.position = origin + Vector2(lane.position.x, 4.5 * t)
	var before := player.position
	var car: Car = lane.spawn_car()
	var hit := false
	for i in 120:
		await physics_frame
		player.position.y = before.y if not hit else player.position.y
		if player.health < player.max_health:
			hit = true
			break
	_check(hit, "the car hits Chad")
	await _physics_frames(8)
	_check(player.position.distance_to(before) > 10.0, "and knocks him back")

	Engine.time_scale = 4.0
	for i in 240:
		await physics_frame
		if not is_instance_valid(car):
			break
	Engine.time_scale = 1.0
	_check(not is_instance_valid(car), "the car drives off and is removed")
	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
