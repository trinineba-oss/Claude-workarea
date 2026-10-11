class_name Seasoning
extends Interactable
## A sacred seasoning, floating where a temple's boss fell (`seasoning <x> <y> <item>@<trigger>`
## appears once the trigger fires). Taking it plays "got_<item>", sets the flag
## "has_<item>" and carries Chad out of the temple (Game.MAPS "exit").

const GLOW := Color(0.6, 1.0, 0.55)

var item_id := ""
var trigger_name := ""

var _sprite: Sprite2D
var _shape: CollisionShape2D
var _age := 0.0


func setup(arg: String) -> void:
	var parts := arg.split("@")
	item_id = parts[0]
	trigger_name = parts[1] if parts.size() > 1 else ""


## Why `arg` is not a valid seasoning, or "".
static func argument_problem(arg: String) -> String:
	var parts := arg.split("@")
	if parts.size() != 2 or parts[1] == "":
		return "seasoning needs <item>@<trigger>"
	return "" if GameData.has_item(parts[0]) else "unknown seasoning '%s'" % parts[0]


func _ready() -> void:
	super()
	add_child(_shadow(Vector2(0.8, 0.6)))
	_sprite = Sprite2D.new()
	_sprite.texture = load(
		"res://assets/items/%s.png" % GameData.item(item_id).get("icon", item_id)
	)
	_sprite.scale = Vector2(1.6, 1.6)
	add_child(_sprite)
	var glow := NightLight.make(GLOW, 300, 1.2)
	glow.position = Vector2(0, -60)
	add_child(glow)
	_shape = _feet_shape(Vector2(40, 24), Vector2(0, -6))
	add_child(_shape)
	bubble_height = 130.0
	var game := _game()
	var taken: bool = game != null and game.flags.get("has_" + item_id, false)
	var waiting: bool = game != null and not game.progress.is_triggered(trigger_name)
	if taken or waiting:
		_set_shown(false)
	if waiting and not taken:
		game.progress.triggered.connect(_on_triggered)


func _process(delta: float) -> void:
	super(delta)
	_age += delta
	_sprite.position = Vector2(0, -64.0 - sin(_age * 2.5) * 8.0)
	_sprite.rotation = sin(_age * 1.7) * 0.12


func can_interact(_flags: Dictionary) -> bool:
	return visible


func use(game: Game) -> void:
	if not visible:
		return
	_set_shown(false)
	game.flags["has_" + item_id] = true
	game.inventory.add(item_id)
	Effects.burst(get_parent(), position + Vector2(0, -60), "sparkle")
	await game.talk("got_" + item_id)
	var exit: String = Game.MAPS[game.map_id].get("exit", "")
	if exit != "":
		game.warp(exit)


func _on_triggered(trigger: String) -> void:
	if trigger == trigger_name:
		_set_shown(true)
		Effects.burst(get_parent(), position + Vector2(0, -60), "sparkle")


func _set_shown(shown: bool) -> void:
	visible = shown
	_shape.set_deferred("disabled", not shown)
	if not shown and _highlighted:
		set_highlighted(false)


func _game() -> Game:
	return get_tree().get_first_node_in_group("game") as Game
