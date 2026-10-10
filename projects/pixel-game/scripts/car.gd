class_name Car
extends Area2D
## One car in a Traffic lane.

const DAMAGE := 1

var velocity := Vector2.ZERO

var _sprite: Sprite2D


func setup(texture: Texture2D, lane_velocity: Vector2) -> void:
	velocity = lane_velocity
	collision_layer = 0
	collision_mask = 2
	add_to_group("cars")
	var shadow := Sprite2D.new()
	shadow.texture = preload("res://assets/sprites/shadow.png")
	shadow.scale = Vector2(1.0, 1.6) if velocity.x == 0.0 else Vector2(1.6, 1.0)
	shadow.z_index = -4
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.rotation = Vector2.DOWN.angle_to(velocity)
	_sprite.position = Vector2(0, -16)
	add_child(_sprite)
	var headlights := NightLight.make(Color(1.0, 0.95, 0.8), 220, 0.9)
	headlights.position = Vector2(0, -16) + velocity.normalized() * 90.0
	add_child(headlights)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(52, 92) if velocity.x == 0.0 else Vector2(92, 52)
	shape.shape = rect
	shape.position = Vector2(0, -16)
	add_child(shape)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	for body in get_overlapping_bodies():
		if body is Player:
			body.take_hit(DAMAGE, global_position - velocity.normalized() * 40.0)
	var bounds := Rect2(Vector2(-200, -200), WorldMap.room_size() + Vector2(400, 400))
	if not bounds.has_point(position):
		queue_free()
