class_name CrystalSwitch
extends StaticBody2D
## A crystal orb on a stand. Hit it (cutlass or boomerang) and its trigger fires for good; it
## turns from red to blue.

const OFF := preload("res://assets/sprites/switch_off.png")
const ON := preload("res://assets/sprites/switch_on.png")

var trigger_name := ""

var _sprite: Sprite2D


func setup(arg: String) -> void:
	trigger_name = arg


func _ready() -> void:
	# Solid like a wall, and on the enemy layer so swings and boomerangs can hit it.
	collision_layer = 1 | 4
	collision_mask = 0
	var game := get_tree().get_first_node_in_group("game") as Game
	_sprite = Sprite2D.new()
	_sprite.texture = ON if game != null and game.progress.is_triggered(trigger_name) else OFF
	_sprite.offset = Vector2(0, 24.0 - OFF.get_height() / 2.0)
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44, 40)
	shape.shape = rect
	shape.position = Vector2(0, -4)
	add_child(shape)
	var glow := NightLight.make(Color(0.6, 0.8, 1.0), 200, 0.7)
	glow.position = Vector2(0, -40)
	add_child(glow)


func is_on() -> bool:
	return _sprite.texture == ON


func take_hit(_damage: int, _from_position: Vector2) -> bool:
	if is_on():
		return false
	_sprite.texture = ON
	Effects.burst(get_parent(), position + Vector2(0, -40), "sparkle")
	var game := get_tree().get_first_node_in_group("game") as Game
	if game != null:
		game.progress.fire(trigger_name)
	return true
