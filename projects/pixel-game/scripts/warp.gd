class_name Warp
extends Area2D
## An invisible doorway to somewhere else: stepping onto it takes Chad to `target`
## ("<map>:<x>_<y>:<tx>_<ty>", see Game.warp), e.g. into a cave and back out.

var target := ""


func setup(arg: String) -> void:
	target = arg


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 40)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	if body is Player and game != null and not body.frozen:
		game.warp(target)
