class_name DigSpot
extends Node2D
## Something buried (`dig <x> <y> <reward>`): invisible until Brownie digs it up. She sniffs at
## it when she passes ("Sniff sniff?") and digs on command (Companion.dig). The reward works
## like a chest's: "tt<amount>" (money) or an item id. A dug spot stays dug.

const HOLE := preload("res://assets/sprites/dig_hole.png")

var reward := ""
## Progress key (set by Room).
var key := ""
var dug := false

var _hole: Sprite2D


func setup(arg: String) -> void:
	reward = arg


## Why `arg` is not a valid reward, or "".
static func reward_problem(arg: String) -> String:
	if arg.begins_with("tt") and arg.substr(2).is_valid_int():
		return ""
	return "" if GameData.has_item(arg) else "unknown dig reward '%s'" % arg


func _ready() -> void:
	add_to_group("dig_spots")
	_hole = Sprite2D.new()
	_hole.texture = HOLE
	_hole.z_index = -5
	add_child(_hole)
	var game := get_tree().get_first_node_in_group("game") as Game
	dug = game != null and game.progress.is_done(key)
	_hole.visible = dug


## Brownie found it: Chad gets the reward.
func dig_up(game: Game) -> void:
	if dug:
		return
	dug = true
	_hole.visible = true
	var above := position + Vector2(0, -100)
	Effects.burst(get_parent(), position, "sparkle")
	if game == null:
		return
	game.progress.mark_done(key)
	if reward.begins_with("tt"):
		var amount := int(reward.substr(2))
		game.get_node("Player").add_money(amount)
		Effects.float_text(get_parent(), above, "Dug up TT$%d!" % amount, Color(1, 0.95, 0.6))
	else:
		var name: String = GameData.item(reward).get("name", reward)
		if game.inventory.add(reward) == 0:
			Effects.float_text(get_parent(), above, "Dug up: %s!" % name, Color(1, 0.95, 0.6))
		else:
			Effects.float_text(get_parent(), above, "Bag full!", Color(1, 0.6, 0.5))
	game.save_game()
