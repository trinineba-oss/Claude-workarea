extends "res://tests/test_base.gd"
## Night dangers: spawns after dark, the bandit's snatch-and-run, lamplight keeping him away,
## the soucouyant, and everything slipping away at dawn.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_night.json"


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


func _gone(node: Variant) -> bool:
	return not is_instance_valid(node) or node.is_queued_for_deletion()


func _night_enemies(game: Game) -> Array:
	var found := []
	for room: Room in game.loaded_rooms():
		for child in room.get_children():
			if child is NightSpawn and is_instance_valid(child.enemy):
				found.append(child.enemy)
	return found


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)

	# --- the room files -----------------------------------------------------------------------
	_check(Entities.argument_problem("night", "bandit") == "", "a night bandit is valid")
	_check(Entities.argument_problem("night", "dragon") != "", "unknown night kinds are caught")
	_check(Entities.argument_problem("night", "") != "", "night needs a kind")
	var world := WorldMap.load_dir(Game.ROOMS_DIR)
	var spots := 0
	for coords: Vector2i in world.objects:
		for obj in world.objects_in(coords):
			if obj["kind"] == "night":
				spots += 1
	_check(spots >= 6, "the town has night spawns (%d)" % spots)
	_check(
		world.objects_in(world.start_room()).all(func(o): return o["kind"] != "night"),
		"the wharf stays safe at night"
	)

	# --- night spawns -------------------------------------------------------------------------
	var game := _new_game()
	await _physics_frames(2)
	var player: Player = game.get_node("Player")
	game.day_night.seconds_per_day = 1.0e9  # hold the clock still
	var road := Vector2i(0, 0)
	var t := float(WorldMap.TILE)
	game.go_to(road, WorldMap.room_origin(road) + Vector2(16.5 * t, 7.5 * t))
	await _physics_frames(4)
	_check(_night_enemies(game).is_empty(), "nothing comes out by day")
	game.day_night.set_hour(22.0)
	await _physics_frames(4)
	var out := _night_enemies(game)
	_check(out.size() >= 2, "night brings out the road's bandit and dog (%d)" % out.size())
	_check(out.any(func(e): return e is Bandit), "a bandit is out")
	for enemy: Enemy in out:
		enemy.queue_free()
	await _physics_frames(4)
	_check(_night_enemies(game).is_empty(), "beaten night enemies stay gone")
	await _physics_frames(10)
	_check(_night_enemies(game).is_empty(), "they do not come back the same night")

	# Dawn sends them home, and the next night they are back.
	game.day_night.set_hour(7.0)
	await _physics_frames(2)
	game.day_night.set_hour(23.0)
	await _physics_frames(4)
	out = _night_enemies(game)
	_check(not out.is_empty(), "the next night they come out again")
	game.day_night.set_hour(6.6)
	await _physics_frames(70)
	_check(out.all(func(e): return _gone(e)), "at dawn they slip away")
	_check(_night_enemies(game).is_empty(), "no one is left out in daylight")

	# Spots under a lamp never spawn anything.
	game.day_night.set_hour(22.0)
	var lamp: NightLight = null
	for node in get_nodes_in_group("safe_lights"):
		var far: float = node.global_position.distance_to(player.global_position)
		if lamp == null or far > lamp.global_position.distance_to(player.global_position):
			lamp = node
	var lit_spot := NightSpawn.new()
	lit_spot.setup("bandit")
	lit_spot.position = lamp.global_position - game.current_room().position
	game.current_room().add_child(lit_spot)
	await _physics_frames(4)
	_check(lit_spot.enemy == null, "nothing spawns under a street lamp")
	_check(NightLight.is_lit(self, lamp.global_position), "the lamp lights its spot at night")
	game.day_night.set_hour(12.0)
	_check(not NightLight.is_lit(self, lamp.global_position), "by day nothing counts as lit")
	game.day_night.set_hour(22.0)

	# --- the bandit snatches money and runs ---------------------------------------------------
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	var beach := Vector2i(1, 1)
	var centre := WorldMap.room_origin(beach) + Vector2(6.5 * t, 5.5 * t)
	game.go_to(beach, centre)
	await _physics_frames(2)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	for room: Room in game.loaded_rooms():
		for child in room.get_children():
			if child is NightSpawn:
				child.free()
	player.money = 10
	var bandit: Bandit = _spawn(game, "bandit", centre + Vector2(300, 0))
	var stolen := []
	bandit.stole.connect(func(what, amount): stolen.append([what, amount]))
	var health := player.health
	for i in 200:
		await physics_frame
		if bandit.state == Bandit.State.GLOAT:
			break
	_check(bandit.state == Bandit.State.GLOAT, "the bandit sneaks up and grabs")
	_check(player.money == 5 and bandit.loot_money == 5, "he takes half (%d)" % player.money)
	_check(stolen == [["money", 5]], "stole fires with what he took")
	_check(player.health == health, "a snatch does not hurt")
	_check(bandit.get_node("Bag").visible, "he carries a loot bag")
	await _physics_frames(80)
	_check(bandit.state == Bandit.State.FLEE, "then he runs")
	_check(bandit.global_position.distance_to(player.global_position) > 120.0, "away from Chad")

	# Hitting him gets it back.
	bandit.take_hit(1, player.global_position)
	_check(player.money == 10 and not bandit.has_loot(), "a hit makes him drop the money")
	_check(not bandit.get_node("Bag").visible, "the bag is gone")
	bandit.free()

	# With empty pockets he grabs the best thing in the bag, never a tool, and gets away with it.
	player.money = 0
	game.inventory.clear()
	game.inventory.add("fishing_rod")
	game.inventory.add("mango", 3)
	game.inventory.add("red_snapper")
	player.position = centre
	bandit = _spawn(game, "bandit", centre + Vector2(250, 0))
	var escaped := [false]
	bandit.escaped.connect(func(): escaped[0] = true)
	for i in 400:
		await physics_frame
		if escaped[0]:
			break
	_check(game.inventory.count("red_snapper") == 0, "he took the snapper")
	_check(game.inventory.count("fishing_rod") == 1, "tools are never taken")
	_check(game.inventory.count("mango") == 3, "only one thing is taken")
	_check(escaped[0], "left alone, he gets away")
	await _physics_frames(60)
	_check(_gone(bandit), "and disappears")
	_check(game.inventory.count("red_snapper") == 0, "the snapper is gone for good")

	# --- lamplight keeps him off --------------------------------------------------------------
	var junction := Vector2i(1, 0)
	game.go_to(junction, WorldMap.room_origin(junction) + Vector2(3.5 * t, 7.5 * t))
	await _physics_frames(2)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	player.money = 8
	# The lamp on the pole at (6, 9); just east of its light, Cipero Street is dark.
	var pole_base := WorldMap.room_origin(junction) + Vector2(6.5 * t, 9.5 * t)
	var safe: NightLight = null
	for node in get_nodes_in_group("safe_lights"):
		if node.get_parent().global_position.distance_to(pole_base) < 1.0:
			safe = node
	_check(safe != null, "the junction has street lamps")
	player.position = safe.global_position
	_check(NightLight.is_lit(self, player.global_position), "Chad stands in the light")
	var dark := safe.global_position + Vector2(safe.safe_radius() + 80.0, 0)
	_check(not NightLight.is_lit(self, dark), "the street beside it is dark")
	var lurker: Bandit = _spawn(game, "bandit", dark)
	var closest := INF
	for i in 180:
		await physics_frame
		closest = minf(closest, lurker.global_position.distance_to(safe.global_position))
	_check(player.money == 8, "nothing is stolen under a lamp")
	_check(closest > safe.safe_radius() - 8.0, "the bandit never steps into the light")
	lurker.free()

	# --- the soucouyant -----------------------------------------------------------------------
	player.end_invincibility()
	player.health = player.max_health
	player.position = WorldMap.room_origin(beach) + Vector2(6.5 * t, 5.5 * t)
	game.go_to(beach, player.position)
	await _physics_frames(2)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	var fire: Soucouyant = _spawn(game, "soucouyant", player.position + Vector2(200, -40))
	_check(fire.get_children().any(func(n): return n is NightLight), "the soucouyant glows")
	var swooped := false
	for i in 180:
		await physics_frame
		if fire.state == Corbeau.State.SWOOP:
			swooped = true
	_check(swooped and player.health < player.max_health, "the soucouyant swoops and burns")
	fire.free()

	# --- nightfall warning --------------------------------------------------------------------
	game.day_night.set_hour(17.0)
	await _frames(2)
	game.day_night.set_hour(21.0)
	await _frames(2)
	var warned := game.get_children().any(
		func(n): return n is Label and n.text.begins_with("Night.")
	)
	_check(warned, "nightfall warns Chad to stick to the lights")

	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
