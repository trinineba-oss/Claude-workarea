extends "res://tests/test_base.gd"
## The action combat (three-hit combo, buffered presses, the dodge roll, XP and levels, the
## pothound's telegraphed lunge) and the wharf demo's waves.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_action.json"


func _new_game() -> Game:
	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	_bench_evey()
	return game


func _spawn(game: Game, kind: String, pos: Vector2) -> Node2D:
	var node := Entities.create(kind)
	node.position = pos - game.current_room().position
	game.current_room().add_child(node)
	return node


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await _physics_frames(1)
	Input.action_release(action)


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	var game := _new_game()
	await _physics_frames(2)
	var player: Player = game.get_node("Player")
	var centre := player.position
	player.facing = Vector2.RIGHT
	player.aim = Vector2.RIGHT

	# --- the combo ------------------------------------------------------------------------
	await _tap(&"attack")
	await _physics_frames(3)
	_check(player.state == Player.State.ATTACK and player.combo_step == 0, "attack starts a swing")
	_check(player.position.x > centre.x, "the swing lunges forward")
	# A press early in the swing is remembered and chains when the swing allows it.
	await _physics_frames(3)
	await _tap(&"attack")
	await _physics_frames(6)
	_check(player.combo_step == 1, "a buffered press chains into the second hit")
	await _physics_frames(4)
	await _tap(&"attack")
	await _physics_frames(8)
	_check(player.combo_step == 2, "and the third, the finisher")
	_check(player.attack_time > Player.ATTACK_TIME, "which is a longer, heavier swing")
	_check(player.attack_damage(2) > player.attack_damage(0), "and hits harder")
	await _physics_frames(40)
	_check(player.state == Player.State.NORMAL, "the combo ends")
	await _tap(&"attack")
	await _physics_frames(2)
	_check(player.combo_step == 0, "a new press later starts from the first hit")
	await _physics_frames(30)

	# --- the dodge ------------------------------------------------------------------------
	player.position = centre
	Input.action_press(&"move_left")
	await _tap(&"dodge")
	await _physics_frames(2)
	_check(player.state == Player.State.DODGE, "dodge starts a roll")
	_check(player.is_dodge_safe(), "Chad can't be hurt early in the roll")
	_check(not player.take_hit(1, player.position + Vector2(20, 0)), "a hit passes through")
	Input.action_release(&"move_left")
	await _physics_frames(30)
	_check(player.position.x < centre.x - 100.0, "the roll covers ground, the way he held")
	_check(player.state == Player.State.NORMAL and not player.is_dodge_safe(), "and ends")
	_check(player.health == player.max_health, "unhurt")
	# A roll cancels a swing (once the last roll's short cooldown is over).
	await _physics_frames(20)
	await _tap(&"attack")
	await _physics_frames(3)
	_check(player.state == Player.State.ATTACK, "(swinging)")
	await _tap(&"dodge")
	await _physics_frames(3)
	_check(player.state == Player.State.DODGE, "a roll cancels a swing")
	await _physics_frames(40)

	# --- XP and levels --------------------------------------------------------------------
	_check(player.level == 1 and player.xp == 0, "Chad starts at level 1")
	var needed := player.xp_needed()
	player.take_hit(2, player.position + Vector2(30, 0))
	player.end_invincibility()
	await _physics_frames(20)
	player.gain_xp(needed - 1)
	_check(player.level == 1 and player.xp == needed - 1, "XP adds up")
	player.gain_xp(1)
	_check(player.level == 2 and player.xp == 0, "enough XP is a new level")
	_check(player.health == player.max_health, "a level heals Chad")
	player.gain_xp(player.xp_needed())
	_check(player.attack_damage(0) == 2, "levels make the cutlass hit harder")
	_check(game.flags.get("chad_level") == 3, "the level is kept with the story flags (saved)")
	var dog: Pothound = _spawn(game, "dog", player.position + Vector2(400, 0))
	dog.set_physics_process(false)
	var before := player.xp
	dog.take_hit(99, player.position)
	_check(player.xp == before + dog.xp, "beating an enemy gives its XP")

	# --- the pothound's lunge -------------------------------------------------------------
	player.position = centre
	var hound: Pothound = _spawn(game, "dog", centre + Vector2(110, 0))
	await _physics_frames(3)
	_check(hound.mode == Pothound.Mode.WINDUP, "close to Chad, the dog winds up first")
	_check(hound.velocity == Vector2.ZERO, "standing still while it does (the tell)")
	player.position = centre + Vector2(0, -400)  # step well out of the way
	var lunged := false
	for i in 60:
		await physics_frame
		if hound.mode == Pothound.Mode.LUNGE and hound.velocity != Vector2.ZERO:
			lunged = true
			break
	_check(lunged and hound.velocity.length() > Pothound.CHASE_SPEED * 2.0, "then lunges, fast")
	for i in 60:
		await physics_frame
		if hound.mode == Pothound.Mode.RECOVER:
			break
	_check(hound.mode == Pothound.Mode.RECOVER, "and has to recover: the opening to hit back")
	hound.queue_free()

	# --- the wharf demo -------------------------------------------------------------------
	var demo: WharfDemo = game.demo
	_check(demo != null and not demo.running, "the demo waits for the opening to finish")
	player.position = centre
	player.heal(99)
	demo.start()
	var waves := 0
	for round_number in WharfDemo.WAVES.size():
		for i in 240:
			await physics_frame
			if not demo.alive.is_empty():
				break
		_check(
			(
				demo.wave == round_number + 1
				and demo.alive.size() == WharfDemo.WAVES[round_number].size()
			),
			"wave %d arrives" % (round_number + 1)
		)
		waves += 1
		if round_number == WharfDemo.WAVES.size() - 1:
			var boss := demo.alive.filter(func(e): return e is Pothound and e.alpha)
			_check(
				boss.size() == 1 and boss[0].max_health > 10, "the last wave has the pack leader"
			)
		for enemy in demo.alive.duplicate():
			var spot: Vector2 = enemy.position
			var room: Room = game.current_room()
			var ch := room.map_lines[int(spot.y / WorldMap.TILE)][int(spot.x / WorldMap.TILE)]
			_check(not Tiles.is_solid(ch) and ch != "~", "enemies appear on the boards")
			enemy.set_physics_process(false)
			enemy.take_hit(999, player.position)
	_check(waves == WharfDemo.WAVES.size(), "every wave came")
	for i in 400:
		await physics_frame
		if demo.is_done():
			break
	_check(demo.is_done() and not demo.running, "clearing the last wave ends the demo")
	_check(game.flags.get("demo_done") == true, "and it is remembered")
	await _settle()
	var box := game.get_node("HUD/DialogueBox")
	_check(box.is_open(), "the ibis has something to say about it")
	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
