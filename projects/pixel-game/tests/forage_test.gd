extends "res://tests/test_base.gd"
## Picking plants, regrowing the next days, eating from the hotbar, and saving it all.

const GAME := preload("res://scenes/game.tscn")
const SAVE_PATH := "user://test_save_forage.json"


func _new_game() -> Game:
	var game: Game = GAME.instantiate()
	game.play_intro = false
	game.save.path = SAVE_PATH
	root.add_child(game)
	return game


func _mango_tree(game: Game) -> Forage:
	for child in game.current_room().get_children():
		if child is Forage and child.forage_id == "mango_tree":
			return child
	return null


func _run() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	for id: String in GameData.forage_ids():
		var data := GameData.forage(id)
		_check(GameData.has_item(data.get("item", "")), "%s gives a real item" % id)

	var game := _new_game()
	await _physics_frames(2)
	var t := float(WorldMap.TILE)
	var road := Vector2i(0, 0)
	game.go_to(road, WorldMap.room_origin(road) + Vector2(4.5 * t, 4.5 * t))
	await _physics_frames(2)
	var player: Player = game.get_node("Player")
	var tree := _mango_tree(game)

	# Face the tree and press interact: mangoes go in the bag.
	player.facing = Vector2.UP
	await _physics_frames(2)
	_check(player.target == tree, "the ripe mango tree can be picked")
	Input.action_press(&"interact")
	await _physics_frames(2)
	Input.action_release(&"interact")
	await _physics_frames(1)
	var mangoes := game.inventory.count("mango")
	_check(mangoes >= 2 and mangoes <= 3, "picking gives 2-3 mangoes (%d)" % mangoes)
	_check(not tree.is_ready(game.day_night.day), "the tree is bare now")
	await _physics_frames(2)
	_check(player.target != tree, "a bare tree cannot be picked")
	_check(game.harvest(tree) == 0, "picking again gives nothing")

	# The next day it is still bare (regrows in 2 days), the day after it is ripe again.
	game.day_night.set_hour(game.day_night.hour + 24.0)
	_check(game.day_night.day == 2, "a day passes")
	_check(not tree.is_ready(game.day_night.day), "still bare on day 2")
	game.day_night.set_hour(game.day_night.hour + 24.0)
	_check(tree.is_ready(game.day_night.day), "ripe again on day 3")

	# Eat a mango from the hotbar to heal.
	var hotbar := game.hotbar()
	hotbar.select(0)
	_check(hotbar.selected_id() == "mango", "the mango is in the first slot")
	_check(not game.use_selected_item(), "not hungry at full health")
	player.end_invincibility()
	player.take_hit(2, player.position + Vector2(10, 0))
	_check(game.use_selected_item(), "eating a mango")
	_check(player.health == player.max_health - 1, "heals half a double")
	_check(game.inventory.count("mango") == mangoes - 1, "uses one mango")

	# A full bag leaves the fruit on the tree.
	game.inventory.clear()
	for i in Inventory.SLOTS:
		game.inventory.add("coconut", Inventory.MAX_STACK)
	_check(
		game.harvest(tree) == 0 and tree.is_ready(game.day_night.day), "a full bag picks nothing"
	)
	game.inventory.clear()
	game.inventory.add("pimento", 2)

	# Everything is saved: the bag, the day, and which plants were picked.
	game.harvest(tree)
	game.save_game()
	var day := game.day_night.day
	game.free()
	game = _new_game()
	await _physics_frames(2)
	_check(game.inventory.count("pimento") == 2, "the bag is restored")
	_check(game.inventory.count("mango") >= 2, "including the new mangoes")
	_check(game.day_night.day == day, "the day is restored")
	game.go_to(road, WorldMap.room_origin(road) + Vector2(4.5 * t, 4.5 * t))
	await _physics_frames(2)
	var again := _mango_tree(game)
	_check(not again.is_ready(game.day_night.day), "the picked tree is still bare after loading")
	game.free()
	DirAccess.remove_absolute(SAVE_PATH)
	_finish()
