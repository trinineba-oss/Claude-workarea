class_name Game
extends Node2D
## The adventure: a free-scrolling world streamed room by room (the room Chad is in and its
## neighbours stay loaded), autosave whenever he enters another room, and pause.

signal room_changed(coords: Vector2i)
signal conversation_finished(id: String)

const ROOMS_DIR := "res://data/rooms"
## Rooms within this many rooms of Chad stay loaded, so the camera never shows a gap.
const LOAD_RADIUS := 1
const CAMERA_SMOOTHING := 7.0
## Pause between fainting and getting back up at the room entrance.
const FAINT_SECONDS := 1.2

## Play the ibis's welcome the first time a game starts (tests turn this off).
@export var play_intro := true

var save := SaveGame.new()
## Story flags set by conversations ("intro_done", ...). Saved with the game.
var flags: Dictionary = {}
var world: WorldMap
var coords := Vector2i.ZERO

var _loaded: Dictionary = {}  # Vector2i -> Room
var _entry_position := Vector2.ZERO

@onready var day_night: DayNight = $DayNight
@onready var _rooms: Node2D = $Rooms
@onready var _player: Player = $Player
@onready var _camera: Camera2D = $Camera2D
@onready var _pause: PauseOverlay = $HUD/PauseOverlay
@onready var _status: StatusBar = $HUD/StatusBar
@onready var _faint_label: Label = $HUD/FaintLabel
@onready var _dialogue: DialogueBox = $HUD/DialogueBox
@onready var _touch: TouchControls = $HUD/TouchControls


func _ready() -> void:
	world = WorldMap.load_dir(ROOMS_DIR)
	for problem in world.validate():
		push_error("world map: " + problem)
	_pause.paused_changed.connect(_on_paused_changed)
	_player.health_changed.connect(_status.set_health)
	_player.money_changed.connect(_status.set_money)
	_player.died.connect(_on_player_died)
	_player.story_flags = flags
	day_night.minute_changed.connect(_status.set_time)
	_player.interact_requested.connect(_on_interact_requested)
	_dialogue.line_shown.connect(_on_line_shown)
	if not _restore(save.read()):
		coords = world.start_room()
		_player.position = world.start_position()
	_apply_debug_start()
	_status.set_time(day_night.hour)
	_status.set_health(_player.health, _player.max_health)
	_status.set_money(_player.money)
	_entry_position = _player.position
	_setup_camera()
	_refresh_rooms()
	_snap_camera()
	if play_intro and not flags.get("intro_done", false):
		_play_intro.call_deferred()


func _physics_process(_delta: float) -> void:
	var now := WorldMap.room_at(_player.position)
	if now == coords:
		return
	if world.has_room(now):
		coords = now
		_entry_position = _player.position
		_refresh_rooms()
		save_game()
		room_changed.emit(coords)
	else:
		# Edges toward empty cells are solid, so this only guards against teleports.
		_player.position = _clamp_to_room(_player.position, coords, 4.0)


func _process(_delta: float) -> void:
	_camera.position = _player.position


func _notification(what: int) -> void:
	if world == null:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


## Jumps straight to a room, e.g. for fast travel (maxi taxis) or tests.
func go_to(room_coords: Vector2i, pos: Vector2) -> void:
	for room: Room in _loaded.values():
		room.free()
	_loaded.clear()
	coords = room_coords
	_player.position = pos
	_entry_position = pos
	_refresh_rooms()
	_snap_camera()
	save_game()


## The room Chad is in.
func current_room() -> Room:
	return _loaded.get(coords)


## Every loaded room, including filler rooms at the edges of the world.
func loaded_rooms() -> Array:
	return _loaded.values()


## Plays a conversation from data/dialogue.json, pausing the game until it ends.
func talk(id: String, with: Interactable = null) -> void:
	if id == "" or _dialogue.is_open() or not GameData.has_conversation(id):
		return
	if with != null:
		with.on_talk(_player)
	get_tree().paused = true
	var touch_was_visible := _touch.visible
	_touch.visible = false
	_dialogue.start(GameData.conversation(id))
	await _dialogue.finished
	_touch.visible = touch_was_visible
	# Let the button press that closed the box go stale before the hero can act on it.
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().paused = false
	save_game()
	conversation_finished.emit(id)


## Story flags plus "night" while it is dark, for choosing what characters say.
func dialogue_state() -> Dictionary:
	var state := flags.duplicate()
	state["night"] = day_night.is_night()
	return state


func is_talking() -> bool:
	return _dialogue.is_open()


func save_game() -> void:
	var data := {
		"room": [coords.x, coords.y],
		"position": [_player.position.x, _player.position.y],
		"health": _player.health,
		"money": _player.money,
		"flags": flags,
		"hour": day_night.hour,
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
	_player.position = _clamp_to_room(Vector2(position[0], position[1]), coords, 32.0)
	var health := int(data.get("health", _player.max_health))
	_player.health = health if health > 0 else _player.max_health
	_player.money = maxi(int(data.get("money", 0)), 0)
	day_night.set_hour(float(data.get("hour", day_night.hour)))
	var saved_flags: Variant = data.get("flags", {})
	if saved_flags is Dictionary:
		flags.merge(saved_flags, true)
	return true


func _refresh_rooms() -> void:
	var wanted := {}
	for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			wanted[coords + Vector2i(dx, dy)] = true
	for room_coords: Vector2i in _loaded.keys():
		if not wanted.has(room_coords):
			_loaded[room_coords].queue_free()
			_loaded.erase(room_coords)
	for room_coords: Vector2i in wanted:
		if not _loaded.has(room_coords):
			_loaded[room_coords] = _make_room(room_coords)


func _setup_camera() -> void:
	var rect := world.bounds()
	var size := WorldMap.room_size()
	_camera.limit_left = int(rect.position.x * size.x)
	_camera.limit_top = int(rect.position.y * size.y)
	_camera.limit_right = int(rect.end.x * size.x)
	_camera.limit_bottom = int(rect.end.y * size.y)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = CAMERA_SMOOTHING


func _snap_camera() -> void:
	_camera.position = _player.position
	_camera.reset_smoothing()


func _make_room(room_coords: Vector2i) -> Room:
	var room := Room.new()
	var real := world.has_room(room_coords)
	room.build(
		room_coords,
		world.rows_or_filler(room_coords),
		world.objects_in(room_coords) if real else [],
		world.padded_rows(room_coords),
		not real
	)
	_rooms.add_child(room)
	return room


func _room_center(room_coords: Vector2i) -> Vector2:
	return WorldMap.room_origin(room_coords) + WorldMap.room_size() / 2.0


func _clamp_to_room(pos: Vector2, room_coords: Vector2i, margin: float) -> Vector2:
	var origin := WorldMap.room_origin(room_coords)
	return pos.clamp(
		origin + Vector2.ONE * margin, origin + WorldMap.room_size() - Vector2.ONE * margin
	)


## Developer aid for the Web build: `index.html?room=0_0` starts in that room, `&at=19_7` on
## that tile, and `&time=21` at that hour (used to take screenshots). Ignored everywhere else.
func _apply_debug_start() -> void:
	if not OS.has_feature("web"):
		return
	var query := str(JavaScriptBridge.eval("window.location.search", true))
	var time := RegEx.create_from_string("time=(\\d+(\\.\\d+)?)").search(query)
	if time != null:
		day_night.set_hour(float(time.get_string(1)))
	var found := RegEx.create_from_string("room=(-?\\d+)_(-?\\d+)").search(query)
	if found == null:
		return
	var target := Vector2i(int(found.get_string(1)), int(found.get_string(2)))
	if world.has_room(target):
		coords = target
		_player.position = _room_center(target)
		var at := RegEx.create_from_string("at=(\\d+)_(\\d+)").search(query)
		if at != null:
			var cell := Vector2(int(at.get_string(1)), int(at.get_string(2)))
			_player.position = (
				WorldMap.room_origin(target) + (cell + Vector2(0.5, 0.5)) * WorldMap.TILE
			)


func _play_intro() -> void:
	await get_tree().create_timer(0.8).timeout
	if not flags.get("intro_done", false):
		talk("ibis_intro")


func _on_interact_requested(target: Interactable) -> void:
	talk(target.dialogue_id(dialogue_state()), target)


func _on_line_shown(line: Dictionary) -> void:
	if line.has("set_flag"):
		flags[line["set_flag"]] = true


func _on_player_died() -> void:
	_faint_label.visible = true
	await get_tree().create_timer(FAINT_SECONDS).timeout
	_faint_label.visible = false
	_loaded[coords].queue_free()
	_loaded[coords] = _make_room(coords)
	_player.position = _entry_position
	_player.revive()
	save_game()


func _on_paused_changed(is_paused: bool) -> void:
	if is_paused:
		save_game()
