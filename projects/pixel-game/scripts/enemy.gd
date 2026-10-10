class_name Enemy
extends CharacterBody2D
## Base class for enemies: health, knockback, contact damage, drops and a little animation.
## Subclasses implement _think() to set `velocity` each physics frame, and may override
## _animate(). The node's origin is at the enemy's feet (or its shadow, for fliers).

signal died

const KNOCKBACK_TIME := 0.18
const MARGIN := 32.0

@export var max_health := 2
@export var contact_damage := 1
@export var knockback_speed := 520.0
@export_range(0.0, 1.0) var coin_chance := 0.5
@export_range(0.0, 1.0) var snack_chance := 0.2

var health := 0

var _knockback := Vector2.ZERO
var _stun := 0.0
var _age := 0.0
var _leaving := false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _contact: Area2D = $Contact


func _ready() -> void:
	health = max_health
	add_to_group("enemies")


func _process(delta: float) -> void:
	_age += delta
	_animate(delta)


func _physics_process(delta: float) -> void:
	if _leaving:
		return
	if _stun > 0.0:
		_stun -= delta
		velocity = _knockback * maxf(_stun, 0.0) / KNOCKBACK_TIME
	else:
		_think(delta)
	move_and_slide()
	_stay_in_room()
	for body in _contact.get_overlapping_bodies():
		if body is Player:
			_touch_player(body)


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


## Fades in where it stands (night spawns use this so nothing pops into view).
func appear() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)


## Slips away without a fight or a drop (night creatures at dawn).
func leave() -> void:
	if _leaving or is_queued_for_deletion():
		return
	_leaving = true
	health = 0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)


func _think(_delta: float) -> void:
	velocity = Vector2.ZERO


## Called every physics frame while touching Chad. Most enemies just hurt him.
func _touch_player(player: Player) -> void:
	player.take_hit(contact_damage, global_position)


## Default animation: a little hop while moving, facing the way it goes.
func _animate(_delta: float) -> void:
	var moving := velocity.length() > 1.0
	_sprite.position.y = -absf(sin(_age * 12.0)) * 5.0 if moving else 0.0
	if velocity.x != 0.0:
		_sprite.flip_h = velocity.x < 0.0


func _player() -> Player:
	var player := get_tree().get_first_node_in_group("player") as Player
	return player if player != null and not player.frozen else null


func _die() -> void:
	died.emit()
	var room := get_parent()
	Effects.burst(room, position + Vector2(0, -24), "poof")
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
