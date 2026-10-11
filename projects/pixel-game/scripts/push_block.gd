class_name PushBlock
extends StaticBody2D
## A heavy stone block. Walk into it for a moment and it slides one tile, if that tile is free.
## Blocks go back to where they started when Chad re-enters an unsolved room (Room.on_enter).

const TEXTURE := preload("res://assets/sprites/block.png")
## Seconds of pushing before it moves.
const PUSH_TIME := 0.3
const MOVE_TIME := 0.2

var _start := Vector2.ZERO
var _push := 0.0
var _push_dir := Vector2.ZERO
var _last_push_frame := -10
var _tween: Tween


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("blocks")
	_start = position
	var shadow := Sprite2D.new()
	shadow.texture = preload("res://assets/sprites/shadow.png")
	shadow.scale = Vector2(1.2, 0.9)
	shadow.position = Vector2(0, 28)
	shadow.z_index = -4
	add_child(shadow)
	var sprite := Sprite2D.new()
	sprite.texture = TEXTURE
	sprite.offset = Vector2(0, 32.0 - TEXTURE.get_height() / 2.0)
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WorldMap.TILE - 2.0, WorldMap.TILE - 2.0)
	shape.shape = rect
	add_child(shape)


func is_moving() -> bool:
	return _tween != null and _tween.is_running()


## Chad is walking into the block this physics frame.
func bump(player: Player, direction: Vector2) -> void:
	if is_moving():
		return
	var to_block := global_position - player.global_position
	if direction.dot(to_block.normalized()) < 0.7:
		return
	var frame := Engine.get_physics_frames()
	if direction != _push_dir or frame - _last_push_frame > 1:
		_push = 0.0
		_push_dir = direction
	_last_push_frame = frame
	_push += get_physics_process_delta_time()
	if _push >= PUSH_TIME:
		_push = 0.0
		try_move(direction)


## Slides one tile that way if nothing is in the way. Returns whether it moved.
func try_move(direction: Vector2) -> bool:
	var target := position + direction * WorldMap.TILE
	if not _is_free(global_position + direction * WorldMap.TILE):
		return false
	_tween = create_tween()
	_tween.tween_property(self, "position", target, MOVE_TIME)
	return true


## Back to the starting tile.
func reset() -> void:
	if _tween != null:
		_tween.kill()
	position = _start
	_push = 0.0


func _is_free(at: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2.ONE * (WorldMap.TILE - 16.0)
	query.shape = rect
	query.transform = Transform2D(0.0, at)
	query.collision_mask = 1 | 2 | 4
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()
