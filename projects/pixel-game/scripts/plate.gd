class_name Plate
extends Node2D
## A pressure plate set into the floor. Slide a push block onto it and its trigger fires for
## good (opening gates with the same trigger name).

const UP := preload("res://assets/sprites/plate.png")
const DOWN := preload("res://assets/sprites/plate_down.png")
## How close a block's centre must be to count as on the plate.
const SNAP := 6.0

var trigger_name := ""

var _sprite: Sprite2D


func setup(arg: String) -> void:
	trigger_name = arg


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = DOWN if is_pressed() else UP
	_sprite.z_index = -5
	add_child(_sprite)


func is_pressed() -> bool:
	var game := get_tree().get_first_node_in_group("game") as Game
	return game != null and game.progress.is_triggered(trigger_name)


func _physics_process(_delta: float) -> void:
	if _sprite.texture == DOWN:
		return
	for block: PushBlock in get_tree().get_nodes_in_group("blocks"):
		if not block.is_moving() and block.global_position.distance_to(global_position) < SNAP:
			_sprite.texture = DOWN
			var game := get_tree().get_first_node_in_group("game") as Game
			if game != null:
				game.progress.fire(trigger_name)
			Effects.float_text(get_parent(), position + Vector2(0, -80), "Click!", Color(1, 1, 0.7))
			return
