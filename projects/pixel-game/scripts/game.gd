class_name Game
extends Node2D
## The adventure: one room at a time, with a scrolling transition between rooms,
## autosave on every room change, and pause.

signal transition_finished

const TRANSITION_SECONDS := 0.5
## How far the hero is carried into the next room during a transition.
const PUSH_IN := 24.0
const ROOMS_DIR := "res://data/rooms"
## Pause between fainting and getting back up at the room entrance.
const FAINT_SECONDS := 1.2

var save := SaveGame.new()
var world: WorldMap
var coords := Vector2i.ZERO

var _room: Room
var _transitioning := false
var _entry_position := Vector2.ZERO

@onready var _rooms: Node2D = $Rooms
@onready var _player: Player = $Player
@onready var _camera: Camera2D = $Camera2D
@onready var _pause: PauseOverlay = $HUD/PauseOverlay
@onready var _status: StatusBar = $HUD/StatusBar
@onready var _faint_label: Label = $HUD/FaintLabel


func _ready() -> void:
	world = WorldMap.load_dir(ROOMS_DIR)
	for problem in world.validate():
		push_error("world map: " + problem)
	_pause.paused_changed.connect(_on_paused_changed)
	_player.health_changed.connect(_status.set_health)
	_player.money_changed.connect(_status.set_money)
	_player.died.connect(_on_player_died)
	if not _restore(save.read()):
		coords = world.start_room()
		_player.position = world.start_position()
	_status.set_health(_player.health, _player.max_health)
	_status.set_money(_player.money)
	_entry_position = _player.position
	_room = _make_room(coords)
	_camera.position = _room_center(coords)


func _physics_process(_delta: float) -> void:
	if _transitioning:
		return
	var local := _player.position - WorldMap.room_origin(coords)
	var size := WorldMap.room_size()
	var dir := Vector2i.ZERO
	if local.x < 0.0:
		dir = Vector2i.LEFT
	elif local.x >= size.x:
		dir = Vector2i.RIGHT
	elif local.y < 0.0:
		dir = Vector2i.UP
	elif local.y >= size.y:
		dir = Vector2i.DOWN
	if dir == Vector2i.ZERO:
		return
	if world.has_room(coords + dir):
		_transition(dir)
	else:
		_player.position = _clamp_to_room(_player.position, coords, 1.0)


func _notification(what: int) -> void:
	if world == null:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


## Jumps straight to a room, e.g. for fast travel (maxi taxis) or tests.
func go_to(room_coords: Vector2i, pos: Vector2) -> void:
	_room.free()
	coords = room_coords
	_room = _make_room(coords)
	_player.position = pos
	_entry_position = pos
	_camera.position = _room_center(coords)
	save_game()


func is_transitioning() -> bool:
	return _transitioning


func save_game() -> void:
	var data := {
		"room": [coords.x, coords.y],
		"position": [_player.position.x, _player.position.y],
		"health": _player.health,
		"money": _player.money,
	}
	save.write(data)


func _restore(data: Dictionary) -> bool:
	var room: Variant = data.get("room")
	var position: Variant = data.get("position")
	if not (room is Array and room.size() == 2 and position is Array and position.size() == 2):
		return false
	var saved_coords := Vector2i(int(room[0]), int(room[1]))
	if not world.has_room(saved_coords):
		return false
	coords = saved_coords
	_player.position = _clamp_to_room(Vector2(position[0], position[1]), coords, 8.0)
	var health := int(data.get("health", _player.max_health))
	_player.health = health if health > 0 else _player.max_health
	_player.money = maxi(int(data.get("money", 0)), 0)
	return true


func _transition(dir: Vector2i) -> void:
	var target := coords + dir
	_transitioning = true
	_player.frozen = true
	var old_room := _room
	_room = _make_room(target)
	old_room.process_mode = Node.PROCESS_MODE_DISABLED
	_room.process_mode = Node.PROCESS_MODE_DISABLED
	var player_end := _clamp_to_room(_player.position + Vector2(dir) * PUSH_IN, target, 8.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_camera, "position", _room_center(target), TRANSITION_SECONDS)
	tween.tween_property(_player, "position", player_end, TRANSITION_SECONDS)
	await tween.finished
	old_room.queue_free()
	_room.process_mode = Node.PROCESS_MODE_INHERIT
	coords = target
	_entry_position = _player.position
	_player.frozen = false
	_transitioning = false
	save_game()
	transition_finished.emit()


func _make_room(room_coords: Vector2i) -> Room:
	var room := Room.new()
	room.build(room_coords, world.rows(room_coords), world.objects_in(room_coords))
	_rooms.add_child(room)
	return room


func _room_center(room_coords: Vector2i) -> Vector2:
	return WorldMap.room_origin(room_coords) + WorldMap.room_size() / 2.0


func _clamp_to_room(pos: Vector2, room_coords: Vector2i, margin: float) -> Vector2:
	var origin := WorldMap.room_origin(room_coords)
	return pos.clamp(
		origin + Vector2.ONE * margin, origin + WorldMap.room_size() - Vector2.ONE * margin
	)


func _on_player_died() -> void:
	_faint_label.visible = true
	await get_tree().create_timer(FAINT_SECONDS).timeout
	_faint_label.visible = false
	_room.queue_free()
	_room = _make_room(coords)
	_player.position = _entry_position
	_player.revive()
	save_game()


func _on_paused_changed(is_paused: bool) -> void:
	if is_paused:
		save_game()
