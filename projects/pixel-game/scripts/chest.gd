class_name Chest
extends Interactable
## A treasure chest. Its content is "key" (a small key for this dungeon), an item id, or
## "tt<amount>" (money). With "<content>@<trigger>" it only appears once that trigger fires
## (e.g. after a mini-boss). Opened chests stay open.

const CLOSED := preload("res://assets/sprites/chest.png")
const OPEN := preload("res://assets/sprites/chest_open.png")

var content := ""
var trigger_name := ""
## Progress key (set by Room).
var key := ""
var opened := false

var _sprite: Sprite2D
var _shape: CollisionShape2D


func setup(arg: String) -> void:
	var parts := arg.split("@")
	content = parts[0]
	trigger_name = parts[1] if parts.size() > 1 else ""


## Why `arg` is not a valid chest content, or "".
static func content_problem(arg: String) -> String:
	var parts := arg.split("@")
	if parts.size() > 2 or parts[0] == "" or (parts.size() == 2 and parts[1] == ""):
		return "chest needs <content> or <content>@<trigger>"
	var what := parts[0]
	if what == "key" or GameData.has_item(what):
		return ""
	if what.begins_with("tt") and what.substr(2).is_valid_int():
		return ""
	return "unknown chest content '%s'" % what


func _ready() -> void:
	super()
	add_child(_shadow(Vector2(1.0, 0.8)))
	_sprite = Sprite2D.new()
	_sprite.texture = CLOSED
	_sprite.offset = Vector2(0, -CLOSED.get_height() / 2.0 + 24.0)
	add_child(_sprite)
	_shape = _feet_shape(Vector2(56, 36), Vector2(0, 4))
	add_child(_shape)
	bubble_height = CLOSED.get_height() + 6.0
	var game := _game()
	if game == null:
		return
	if game.progress.is_done(key):
		opened = true
		_sprite.texture = OPEN
	if trigger_name != "" and not game.progress.is_triggered(trigger_name):
		_set_shown(false)
		game.progress.triggered.connect(_on_triggered)


func can_interact(_flags: Dictionary) -> bool:
	return visible and not opened


## Opens the chest and hands over what is inside.
func use(game: Game) -> void:
	if opened or not visible:
		return
	opened = true
	_sprite.texture = OPEN
	game.progress.mark_done(key)
	set_highlighted(false)
	var above := position + Vector2(0, -110)
	Effects.burst(get_parent(), position + Vector2(0, -40), "sparkle")
	if content == "key":
		game.progress.add_key()
		Effects.float_text(get_parent(), above, "+1 Small key", Color(1, 0.95, 0.6))
	elif content.begins_with("tt") and content.substr(2).is_valid_int():
		var amount := int(content.substr(2))
		game.get_node("Player").add_money(amount)
		Effects.float_text(get_parent(), above, "+TT$%d" % amount, Color(1, 0.95, 0.6))
	else:
		game.inventory.add(content)
		var name: String = GameData.item(content).get("name", content)
		Effects.float_text(get_parent(), above, "You got the %s!" % name, Color(1, 0.95, 0.6))
		if GameData.has_conversation("got_" + content):
			game.talk("got_" + content)
	game.save_game()


func _on_triggered(trigger: String) -> void:
	if trigger == trigger_name:
		_set_shown(true)
		Effects.burst(get_parent(), position + Vector2(0, -30), "poof")


func _set_shown(shown: bool) -> void:
	visible = shown
	_shape.set_deferred("disabled", not shown)


func _game() -> Game:
	return get_tree().get_first_node_in_group("game") as Game
