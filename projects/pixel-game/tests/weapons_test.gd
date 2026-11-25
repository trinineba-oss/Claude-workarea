extends "res://tests/test_base.gd"
## Open-world combat: weapons from data with their own combos, wear and breaking, swapping,
## picking up and throwing; bare-fisted boxing; the charged spin; the flurry rush after a
## perfect dodge.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_weapons.json"


func _spawn(game: Game, kind: String, pos: Vector2, arg := "") -> Node2D:
	var node := Entities.create(kind, arg)
	node.position = pos - game.current_room().position
	game.current_room().add_child(node)
	return node


## Presses an action for two physics frames (a press lands on the next physics tick).
func _tap(action: StringName) -> void:
	Input.action_press(action)
	await _physics_frames(2)
	Input.action_release(action)


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.wharf_demo = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	_bench_evey()
	await _physics_frames(2)
	var player: Player = game.get_node("Player")
	player.facing = Vector2.RIGHT
	player.aim = Vector2.RIGHT

	# --- the data ------------------------------------------------------------------------------
	for id in ["fists", "cutlass", "branch", "plank", "cricket_bat", "fishing_spear"]:
		_check(Weapons.has(id) and not Weapons.combo(id).is_empty(), "%s has a combo" % id)
		_check(id == "fists" or Weapons.icon(id) != null, "%s has an icon" % id)
	_check(Weapons.durability("fists") == 0, "fists never break")
	_check(Weapons.combo("fists").size() == 5, "a five-punch boxing combo")
	_check(
		Weapons.combo("cricket_bat")[0]["damage"] > Weapons.combo("cutlass")[0]["damage"],
		"a cricket bat hits harder than a cutlass"
	)

	# --- starting kit, swapping ------------------------------------------------------------------
	_check(player.weapon_id() == "cutlass", "Chad starts with the cutlass in hand")
	_check(player.weapon_wear() == Weapons.durability("cutlass"), "brand new")
	_check(player.add_weapon("cricket_bat"), "he can pick up another weapon")
	_check(player.weapon_id() == "cutlass", "which goes in the pouch")
	await _tap(&"swap_weapon")
	_check(player.weapon_id() == "cricket_bat", "swap takes the next one")
	await _tap(&"swap_weapon")
	_check(player.weapon_id() == "fists", "then bare fists")
	await _tap(&"swap_weapon")
	_check(player.weapon_id() == "cutlass", "then round again")
	for i in 3:
		player.add_weapon("branch")
	_check(not player.add_weapon("branch"), "five weapons is a full pouch")
	_check(game.flags.has("weapons"), "the pouch is kept with the save")

	# --- wear and breaking ---------------------------------------------------------------------
	player.cycle_weapon()  # cricket bat
	var before := player.weapon_wear()
	player.wear_weapon()
	_check(player.weapon_wear() == before - 1, "each hit wears a weapon down")
	player.wear_weapon(before)
	_check(player.weapon_id() != "cricket_bat", "and at zero it breaks")
	_check(player.weapons().size() == 4, "and is gone from the pouch")

	# --- boxing --------------------------------------------------------------------------------
	while player.weapon_id() != "fists":
		player.cycle_weapon()
	var dog: Pothound = _spawn(game, "dog", player.position + Vector2(44, 0))
	dog.set_physics_process(false)
	dog.coin_chance = 0.0
	dog.snack_chance = 0.0
	var health := dog.health
	await _tap(&"attack")
	await _physics_frames(2)
	_check(player.current_move.get("name", "") == "Jab", "bare-handed, attack is a jab")
	_check(player.current_move.get("anim", "") == "thrust", "played as a punch")
	await _physics_frames(10)
	_check(dog.health < health, "punches hurt")
	var names: Array = []
	for i in 5:
		await _tap(&"attack")
		await _physics_frames(2)
		names.append(player.current_move.get("name", ""))
		await _physics_frames(8)
	_check(names.has("Hook") and names.has("Uppercut"), "the combo runs to a hook and uppercut")
	_check(player.weapon_id() == "fists" and player.weapons().size() == 4, "fists never wear out")

	# --- charged spin --------------------------------------------------------------------------
	await _physics_frames(30)
	while player.weapon_id() != "cutlass":
		player.cycle_weapon()
	Input.action_press(&"attack")
	await _physics_frames(70)
	_check(player.state == Player.State.CHARGE, "holding attack after a swing charges")
	Input.action_release(&"attack")
	await _physics_frames(2)
	_check(
		player.state == Player.State.ATTACK and player.get_node("Cutlass").is_spin(),
		"letting go spins all the way round"
	)
	await _physics_frames(30)

	# --- throwing ------------------------------------------------------------------------------
	if is_instance_valid(dog):
		dog.free()
	var target: Pothound = _spawn(game, "dog", player.position + Vector2(220, -36))
	target.set_physics_process(false)
	var count := player.weapons().size()
	var thrown := player.throw_weapon()
	_check(thrown != null and player.weapons().size() == count - 1, "a weapon can be thrown")
	var hit := await _wait_until(func(): return target.health < target.max_health, 60)
	_check(hit, "a thrown weapon hits what it flies into")
	await _physics_frames(4)
	var lying := game.current_room().get_children().filter(
		func(n): return n is Pickup and n.kind == "weapon"
	)
	_check(not lying.is_empty(), "then lands on the ground to pick up again")
	if is_instance_valid(target):
		target.free()

	# --- flurry rush ---------------------------------------------------------------------------
	var lunger: Pothound = _spawn(game, "dog", player.position + Vector2(300, 0))
	await _tap(&"dodge")
	_check(player.is_dodge_safe(), "rolling")
	player.take_hit(1, lunger.global_position)
	_check(player.flurry > 0.0, "an attack dodged at the last moment starts a flurry rush")
	_check(not lunger.is_physics_processing(), "enemies freeze during it")
	_check(player.health == player.max_health, "and Chad takes no damage")
	lunger.free()
	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()


func _wait_until(condition: Callable, frames: int) -> bool:
	for i in frames:
		if condition.call():
			return true
		await physics_frame
	return condition.call()
