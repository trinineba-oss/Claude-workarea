class_name Boomerang
extends Area2D
## The coconut boomerang: flies out the way Chad faces, then comes back to him. It hits
## enemies (and flips big crabs over) and crystal switches, sails over water, and turns back
## when it hits a wall or anything solid.

const TEXTURE := preload("res://assets/items/coconut_boomerang.png")
const SPEED := 760.0
const RETURN_SPEED := 900.0
const RANGE := 6.0 * WorldMap.TILE
const DAMAGE := 1
const HEIGHT := 36.0

var returning := false

var _player: Node2D
var _world: WorldMap
var _direction := Vector2.RIGHT
var _travelled := 0.0
var _hit: Array[Node] = []
var _sprite: Sprite2D


## Sends it off from `player` toward `direction`; `world` tells walls from water.
func launch(player: Node2D, direction: Vector2, world: WorldMap) -> void:
	_player = player
	_world = world
	_direction = direction
	position = player.position + direction * 24.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 4
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36, 36)
	shape.shape = rect
	shape.position = Vector2(0, -HEIGHT / 2.0)
	add_child(shape)
	var shadow := Sprite2D.new()
	shadow.texture = preload("res://assets/sprites/shadow.png")
	shadow.scale = Vector2(0.5, 0.5)
	shadow.z_index = -4
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.position = Vector2(0, -HEIGHT)
	_sprite.scale = Vector2(0.8, 0.8)
	add_child(_sprite)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_sprite.rotation += delta * 22.0
	if not is_instance_valid(_player):
		queue_free()
		return
	if returning:
		var home := _player.position
		position = position.move_toward(home, RETURN_SPEED * delta)
		if position.distance_to(home) < 24.0:
			queue_free()
		return
	position += _direction * SPEED * delta
	_travelled += SPEED * delta
	if _travelled >= RANGE or _over_wall():
		returning = true


func _over_wall() -> bool:
	if _world == null:
		return false
	var cell := Vector2i((position / WorldMap.TILE).floor())
	var ch := _world.tile_at(cell)
	return Tiles.is_solid(ch) and ch != "~"


func _on_body_entered(body: Node) -> void:
	if body is TileMapLayer or body in _hit:
		return  # walls are checked by tile, so it can fly over water
	if body.has_method("boomerang_hit"):
		_hit.append(body)
		body.boomerang_hit()
		Effects.burst(get_parent(), position + Vector2(0, -HEIGHT), "hit")
	elif body.has_method("take_hit"):
		_hit.append(body)
		body.take_hit(DAMAGE, position)
		Effects.burst(get_parent(), position + Vector2(0, -HEIGHT), "hit")
	returning = true
