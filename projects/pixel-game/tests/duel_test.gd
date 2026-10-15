extends "res://tests/test_base.gd"
## Dog duels: the rules (DogBattle) with fixed luck, Evey's levels, and a whole duel on the
## screen against Scraps through TopDog, including the rewards and the after-talk.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_duel.json"


func _new_game() -> Game:
	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	return game


func _at(room: Vector2i, x: float, y: float) -> Vector2:
	return WorldMap.room_origin(room) + (Vector2(x, y) + Vector2(0.5, 0.5)) * WorldMap.TILE


func _close_dialogue(game: Game) -> void:
	var box: DialogueBox = game.get_node("HUD/DialogueBox")
	await _frames(1)
	var guard := 0
	while box.is_open() and guard < 40:
		box.advance()
		await process_frame
		box.advance()
		await process_frame
		guard += 1
	await _settle()


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)

	# --- the data -----------------------------------------------------------------------------
	for id in ["brownie", "scraps", "duchess", "tiger"]:
		var data := GameData.dog(id)
		_check(not data.is_empty(), "%s is in dogs.json" % id)
		for talk in ["intro", "win", "lose", "after"]:
			_check(GameData.has_conversation(data.get(talk, "")), "%s has its %s talk" % [id, talk])
	_check(GameData.has_conversation("topdog_no_dog"), "a line for when Evey is not around")

	# --- the rules ----------------------------------------------------------------------------
	var stats := DogBattle.stats_for(1)
	_check(stats["hp"] == 16 and stats["attack"] == 4, "Evey at level 1")
	_check(DogBattle.stats_for(3)["hp"] > stats["hp"], "levels make her tougher")
	var flags := {}
	var grew := DogBattle.add_xp(flags, 25)
	_check(flags["evey_level"] == 2 and flags["evey_xp"] == 15, "xp carries over levels")
	_check(grew.size() == 1, "a line for the level gained")

	var punchbag := {"name": "Bag", "hp": 30, "attack": 3, "defense": 1, "moves": ["growl"]}
	var duel := DogBattle.new(1, punchbag, 7)
	duel.play_round("bite")
	_check(duel.foe["hp"] < 30, "bite hurts")
	_check(duel.evey["mod"] == -1, "growl lowers Evey's attack")
	duel.evey["hp"] = 5
	duel.play_round("treat", 7)
	_check(duel.evey["hp"] == 12, "a treat heals")
	duel.play_round("treat", 50)
	_check(duel.evey["hp"] == duel.evey["max_hp"], "but not past full")

	var pouncer := {"name": "Pouncer", "hp": 50, "attack": 6, "defense": 0, "moves": ["pounce"]}
	duel = DogBattle.new(1, pouncer, 3)
	var log := duel.play_round("guard")
	_check(duel.foe["charging"] and "Guard" in log[-1], "a pounce is telegraphed")
	var before: int = duel.evey["hp"]
	duel.play_round("guard")
	var guarded := before - int(duel.evey["hp"])
	duel = DogBattle.new(1, pouncer, 3)
	duel.play_round("guard")
	before = duel.evey["hp"]
	duel.play_round("bite")
	var open_hit := before - int(duel.evey["hp"])
	_check(guarded > 0 and guarded * 2 <= open_hit + 1, "guarding halves the pounce")

	var flinches := 0
	for seed_value in 40:
		var b := DogBattle.new(1, punchbag, seed_value)
		var lines := b.play_round("bark")
		if lines.any(func(l): return "flinches" in l):
			flinches += 1
			_check(b.evey["mod"] == 0, "a flinching foe does nothing that round")
	_check(flinches > 0 and flinches < 40, "barking sometimes makes the foe flinch")

	var wins := 0
	for seed_value in 20:
		var b := DogBattle.new(1, GameData.dog("scraps"), seed_value)
		var guard := 0
		while not b.over and guard < 60:
			b.play_round("bite")
			guard += 1
		_check(b.over, "a duel always ends")
		if b.evey_won:
			wins += 1
	_check(wins >= 15, "level-1 Evey usually beats Scraps by biting (%d/20)" % wins)
	var tiger_wins := 0
	for seed_value in 20:
		var b := DogBattle.new(1, GameData.dog("tiger"), seed_value)
		while not b.over:
			b.play_round("bite")
		tiger_wins += 1 if b.evey_won else 0
	_check(tiger_wins <= 5, "Tiger is too much for a level-1 Evey (%d/20)" % tiger_wins)

	# --- a whole duel on screen ---------------------------------------------------------------
	var game := _new_game()
	await _physics_frames(2)
	var player: Player = game.get_node("Player")
	var screen: DuelScreen = game.get_node("HUD/DuelScreen")
	screen.line_seconds = 0.02
	game.day_night.seconds_per_day = 1.0e9
	var junction := Vector2i(1, 0)
	game.go_to(junction, _at(junction, 16, 8))
	await _physics_frames(2)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	var is_scraps := func(n): return n is TopDog and n.dog_id == "scraps"
	get_first_node_in_group("companion").joined = false
	var scraps: TopDog = get_nodes_in_group("interactables").filter(is_scraps)[0]
	scraps.use(game)
	await _frames(2)
	_check(game.is_talking(), "without Evey, Scraps just yawns")
	await _close_dialogue(game)
	_check(not screen.is_open(), "and there is no duel")

	var evey: Companion = get_first_node_in_group("companion")
	evey.join()
	game.inventory.add("mango", 2)
	var money := player.money
	scraps.use(game)
	await _frames(2)
	await _close_dialogue(game)
	var opened := false
	for i in 60:
		if screen.is_open():
			opened = true
			break
		await process_frame
	_check(opened and paused, "the duel screen opens and the world pauses")
	var rounds := 0
	var used_treat := false
	while screen.is_open() and rounds < 80:
		if screen.get("_menu_open"):
			if not used_treat and screen.battle.evey["hp"] < screen.battle.evey["max_hp"]:
				screen.choose("treat")
				used_treat = true
			else:
				screen.choose("bite")
			rounds += 1
		await process_frame
	_check(not screen.is_open(), "the duel ends")
	_check(screen.battle.evey_won, "Evey beats Scraps")
	_check(not used_treat or game.inventory.count("mango") == 1, "a treat uses up a mango")
	await _settle()
	await _frames(2)
	_check(game.is_talking(), "Scraps has something to say afterwards")
	await _close_dialogue(game)
	_check(not paused, "the world goes on")
	_check(game.flags.get("beat_scraps", false), "Scraps is marked as beaten")
	_check(player.money == money + 10, "TT$10 for the win")
	_check(int(game.flags.get("evey_xp", 0)) == 8, "Evey learns from it")
	scraps.use(game)
	await _frames(2)
	_check(game.is_talking() and not screen.is_open(), "once beaten, Scraps is friendly")
	await _close_dialogue(game)

	game.save_game()
	game.free()
	game = _new_game()
	await _physics_frames(2)
	_check(game.flags.get("beat_scraps", false), "the win is saved")
	_check(int(game.flags.get("evey_xp", 0)) == 8, "and so is her experience")
	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
