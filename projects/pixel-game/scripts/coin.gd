class_name Coin
extends Area2D
## Collectable. Emits `collected` when the player touches it.

signal collected


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		collected.emit()
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-3, -3, 6, 6), Color("ffd23f"))
	draw_rect(Rect2(-1, -1, 2, 2), Color("fff3b0"))
