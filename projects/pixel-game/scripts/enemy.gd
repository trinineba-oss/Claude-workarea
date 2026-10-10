class_name Enemy
extends CharacterBody2D
## Base class for enemies: health, knockback, contact damage and drops. Subclasses
## implement _think() to set `velocity` each physics frame.

signal died

const KNOCKBACK_TIME := 0.18
const MARGIN := 8.0

@export var max_health := 2
@export var contact_damage := 1
@export var knockback_speed := 130.0
@export_range(0.0, 1.0) var coin_chance := 0.5
@export_range(0.0, 1.0) var snack_chance := 0.2

var health := 0

var _knockback := Vector2.ZERO
var _stun := 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _contact: Area2D = $Contact


func _ready() -> void:
	health = max_health
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if _stun > 0.0:
		_stun -= delta
		velocity = _knockback * maxf(_stun, 0.0) / KNOCKBACK_TIME
	else:
		_think(delta)
	move_and_slide()
	_stay_in_room()
	for body in _contact.get_overlapping_bodies():
		if body is Player:
			body.take_hit(contact_damage, global_position)


func take_hit(damage: int, from_position: Vector2) -> bool:
	if health <= 0:
		return false
	health -= damage
	_knockback = (global_position - from_position).normalized() * knockback_speed
	_stun = KNOCKBACK_TIME
	_flash()
	if health <= 0:
		_die()
	return true


func _think(_delta: float) -> void:
	velocity = Vector2.ZERO


func _player() -> Player:
	var player := get_tree().get_first_node_in_group("player") as Player
	return player if player != null and not player.frozen else null


func _die() -> void:
	died.emit()
	var room := get_parent()
	var roll := randf()
	var drop := ""
	if roll < coin_chance:
		drop = "coin"
	elif roll < coin_chance + snack_chance:
		drop = "snack"
	if drop != "" and room != null:
		var pickup: Pickup = Entities.create(drop)
		pickup.position = position
		pickup.lifetime = Pickup.DROP_LIFETIME
		room.add_child.call_deferred(pickup)
	queue_free()


func _flash() -> void:
	_sprite.self_modulate = Color(3, 3, 3)
	create_tween().tween_property(_sprite, "self_modulate", Color.WHITE, 0.12)


func _stay_in_room() -> void:
	if get_parent() is Room:
		position = position.clamp(Vector2.ONE * MARGIN, WorldMap.room_size() - Vector2.ONE * MARGIN)
