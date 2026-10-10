extends "res://tests/test_base.gd"
## Health, the cutlass, both enemies, pickups, fainting and the saved stats.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_combat.json"

var _health_events := 0


func _new_game() -> Game:
	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	return game


func _spawn(game: Game, kind: String, pos: Vector2) -> Node2D:
	var node := Entities.create(kind)
	node.position = pos - game.current_room().position
	game.current_room().add_child(node)
	return node


func _swing() -> void:
	Input.action_press(&"attack")
	await _physics_frames(2)
	Input.action_release(&"attack")
	await _physics_frames(24)


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	var game := _new_game()
	await _physics_frames(2)
	var player: Player = game.get_node("Player")
	var centre := player.position

	# --- player health -------------------------------------------------------------------
	player.health_changed.connect(func(_h, _m): _health_events += 1)
	_check(player.take_hit(1, centre + Vector2(40, 0)), "a hit lands")
	_check(player.health == 5, "one hit costs one half")
	_check(not player.take_hit(1, centre), "no second hit while invincible")
	await _physics_frames(8)
	_check(player.position.x < centre.x - 8.0, "knockback pushes the hero away from the hit")
	player.end_invincibility()
	_check(player.take_hit(2, centre), "hits land again after invincibility")
	_check(player.health == 3, "damage can be more than one")
	_check(_health_events == 2, "health_changed fires per hit")
	player.heal(1)
	_check(player.health == 4, "heal adds health")
	player.heal(99)
	_check(player.is_full_health() and player.health == player.max_health, "heal is capped")
	player.add_money(3)
	_check(player.money == 3, "money adds up")
	player.end_invincibility()
	await _physics_frames(20)
	player.position = centre

	# --- the cutlass ---------------------------------------------------------------------
	player.facing = Vector2.RIGHT
	var dog: Pothound = _spawn(game, "dog", centre + Vector2(72, 0))
	dog.coin_chance = 1.0
	await _physics_frames(2)
	_check(dog.health == 2, "an idle cutlass does not hurt")
	await _swing()
	_check(dog.health == 1, "a swing hits once (health %d)" % dog.health)
	player.end_invincibility()
	player.position = centre
	dog.position = centre + Vector2(72, 0) - game.current_room().position
	await _swing()
	_check(not is_instance_valid(dog) or dog.is_queued_for_deletion(), "two swings kill the dog")
	await _physics_frames(4)
	var pickups := game.current_room().get_children().filter(func(n): return n is Pickup)
	_check(pickups.size() == 1, "the dog dropped a coin")
	player.end_invincibility()
	player.position = pickups[0].global_position
	await _physics_frames(4)
	_check(player.money == 4, "walking onto the coin collects it (money %d)" % player.money)

	# --- pickups --------------------------------------------------------------------------
	player.position = centre
	var snack: Pickup = _spawn(game, "snack", centre)
	await _physics_frames(4)
	_check(
		is_instance_valid(snack) and not snack.is_queued_for_deletion(),
		"a snack waits at full health"
	)
	player.end_invincibility()
	player.take_hit(2, centre + Vector2(20, 0))
	await _physics_frames(4)
	_check(player.health == player.max_health, "the snack heals one heart (%d)" % player.health)
	await _physics_frames(2)
	_check(not is_instance_valid(snack) or snack.is_queued_for_deletion(), "the snack is used up")

	# --- pothound AI ---------------------------------------------------------------------
	player.end_invincibility()
	player.position = centre
	player.facing = Vector2.DOWN
	var chaser: Pothound = _spawn(game, "dog", centre + Vector2(240, 0))
	var before := chaser.global_position.distance_to(player.global_position)
	await _physics_frames(40)
	_check(
		chaser.global_position.distance_to(player.global_position) < before - 32.0,
		"the dog chases the hero"
	)
	chaser.queue_free()
	await _physics_frames(2)

	# --- corbeau AI ----------------------------------------------------------------------
	player.end_invincibility()
	player.health = player.max_health
	player.position = centre
	var bird: Corbeau = _spawn(game, "corbeau", centre + Vector2(200, -40))
	var swooped := false
	for i in 180:
		await physics_frame
		if bird.state == Corbeau.State.SWOOP:
			swooped = true
	_check(swooped, "the corbeau swoops when the hero is near")
	_check(player.health < player.max_health, "a swoop can hurt the hero")
	bird.queue_free()
	await _physics_frames(2)

	# --- fainting ------------------------------------------------------------------------
	player.end_invincibility()
	player.health = 1
	player.take_hit(1, centre + Vector2(16, 0))
	_check(player.frozen and player.health == 0, "zero health freezes the hero")
	_check(game.get_node("HUD/FaintLabel").visible, "the faint message shows")
	player.end_invincibility()
	_check(not player.take_hit(1, centre), "a fainted hero cannot be hit again")
	for i in 150:
		await physics_frame
		if not player.frozen:
			break
	_check(
		not player.frozen and player.health == player.max_health,
		"the hero gets back up with full health"
	)
	_check(player.position == game.get("_entry_position"), "back at the room entrance")
	_check(not game.get_node("HUD/FaintLabel").visible, "the faint message hides")
	_check(game.loaded_rooms().size() == 9, "rooms are still streamed after fainting")

	# --- stats are saved ------------------------------------------------------------------
	player.health = 3
	player.money = 7
	game.save_game()
	game.free()
	game = _new_game()
	await _physics_frames(2)
	player = game.get_node("Player")
	_check(player.health == 3 and player.money == 7, "health and money are restored")
	game.free()

	# --- enemies come from the room files -------------------------------------------------
	var road := Vector2i(0, 0)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string('{"version": 1, "room": [0, 0], "position": [600, 400], "health": 0}')
	file.close()
	game = _new_game()
	await _physics_frames(2)
	var expected := game.world.objects_in(road).filter(
		func(o): return o["kind"] in ["dog", "corbeau"]
	)
	_check(
		get_nodes_in_group("enemies").size() == expected.size(),
		"room %s has its %d enemies" % [road, expected.size()]
	)
	_check(game.get_node("Player").health == 6, "a saved health of 0 restores to full")
	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
