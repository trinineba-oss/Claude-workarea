class_name Pickup
extends Area2D
## A collectable: "snack" (a double) heals one heart, "coin" adds money.

const DROP_LIFETIME := 8.0
const TEXTURES := {
	"snack": preload("res://assets/sprites/snack.png"),
	"coin": preload("res://assets/sprites/coin.png"),
}
const HEAL_AMOUNT := 2
const COIN_VALUE := 1

@export var kind := "coin"
## Seconds until it disappears (blinking at the end); 0 keeps it forever.
var lifetime := 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_sprite.texture = TEXTURES[kind]


func _physics_process(delta: float) -> void:
	if lifetime > 0.0:
		lifetime -= delta
		_sprite.visible = lifetime > 2.0 or int(lifetime * 8.0) % 2 == 0
		if lifetime <= 0.0:
			queue_free()
			return
	for body in get_overlapping_bodies():
		if body is Player and _collect(body):
			queue_free()
			return


func _collect(player: Player) -> bool:
	if kind == "snack":
		if player.is_full_health():
			return false
		player.heal(HEAL_AMOUNT)
	else:
		player.add_money(COIN_VALUE)
	return true
