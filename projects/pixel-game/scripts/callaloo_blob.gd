class_name CallalooBlob
extends Area2D
## A glob of hot callaloo spat by the Callaloo Cauldron. Flies straight, burns Chad on contact
## and splats against walls.

const TEXTURE := preload("res://assets/sprites/callaloo_blob.png")
const SPEED := 300.0
const LIFETIME := 3.0
const HEIGHT := 30.0

var velocity := Vector2.ZERO

var _age := 0.0
var _world: WorldMap
var _sprite: Sprite2D


func launch(from: Vector2, direction: Vector2, world: WorldMap) -> void:
	position = from
	velocity = direction.normalized() * SPEED
	_world = world


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	shape.position = Vector2(0, -HEIGHT / 2.0)
	add_child(shape)
	var shadow := Sprite2D.new()
	shadow.texture = preload("res://assets/sprites/shadow.png")
	shadow.scale = Vector2(0.4, 0.4)
	shadow.z_index = -4
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.position = Vector2(0, -HEIGHT)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	_age += delta
	position += velocity * delta
	_sprite.scale = Vector2.ONE * (1.0 + sin(_age * 20.0) * 0.08)
	for body in get_overlapping_bodies():
		if body is Player:
			body.take_hit(1, position)
			_splat()
			return
	var hit_wall := false
	if _world != null:
		var ch := _world.tile_at(Vector2i((position / WorldMap.TILE).floor()))
		hit_wall = Tiles.is_solid(ch) and ch != "~"
	if hit_wall or _age > LIFETIME:
		_splat()


func _splat() -> void:
	Effects.burst(get_parent(), position + Vector2(0, -HEIGHT), "poof")
	queue_free()
