class_name Game
extends Node2D
## The adventure: a free-scrolling world streamed room by room (the room Chad is in and its
## neighbours stay loaded), autosave whenever he enters another room, and pause. Dungeons are
## separate maps entered through warps; inside them the camera stays within one room at a time.

signal room_changed(coords: Vector2i)
signal conversation_finished(id: String)

const ROOMS_DIR := "res://data/rooms"
const OVERWORLD := "overworld"
## Map id -> where its rooms live and how it looks. Dungeons are indoors (cave light, one room
## on screen at a time) and filled with rock outside their rooms.
const MAPS := {
	"overworld": {"dir": ROOMS_DIR, "name": "San Fernando"},
	"temple1":
	{
		"dir": "res://data/dungeons/temple1",
		"name": "Callaloo Cave",
		"indoors": true,
		"filler": "#",
		# Where Chad comes out when he leaves with the temple's seasoning.
		"exit": "overworld:1_1:14_3",
	},
}
const FADE_SECONDS := 0.25
## Rooms within this many rooms of Chad stay loaded, so the camera never shows a gap.
const LOAD_RADIUS := 1
const CAMERA_SMOOTHING := 7.0
## Pause between fainting and getting back up at the room entrance.
const FAINT_SECONDS := 1.2
const NIGHT_COLOR := Color(0.75, 0.8, 1.0)

## Play the ibis's welcome the first time a game starts (tests turn this off).
@export var play_intro := true

var save := SaveGame.new()
## The map Chad is on (a key of MAPS).
var map_id := OVERWORLD
## Temple progress: opened doors and chests, fired triggers, small keys per map. Saved.
var progress := Progress.new()
## Story flags set by conversations ("intro_done", ...). Saved with the game.
var flags: Dictionary = {}
var world: WorldMap
var coords := Vector2i.ZERO
## Chad's bag. Saved with the game.
var inventory := Inventory.new()
## Forage plant key -> game day it is ready again. Saved with the game.
var forage_state: Dictionary = {}

var _loaded: Dictionary = {}  # Vector2i -> Room
var _entry_position := Vector2.ZERO
var _hotbar: Hotbar
var _minigame: FishingMinigame
var _fishing := false
var _was_night := false
var _boomerang: Boomerang
var _companion: Companion
var _dog_menu: DogMenu
var _worlds: Dictionary = {}  # map id -> WorldMap
var _fade: ColorRect
var _warping := false

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
	add_to_group("game")
	world = _world_for(OVERWORLD)
	for problem in world.validate():
		push_error("world map: " + problem)
	progress.keys_changed.connect(func(_count): _update_keys())
	progress.triggered.connect(func(_name): save_game())
	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.color = Color(0.02, 0.01, 0.04, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	$HUD.add_child(_fade)
	_pause.paused_changed.connect(_on_paused_changed)
	_player.health_changed.connect(_status.set_health)
	_player.money_changed.connect(_status.set_money)
	_player.died.connect(_on_player_died)
	_player.story_flags = flags
	day_night.minute_changed.connect(_status.set_time)
	day_night.day_changed.connect(_status.set_day)
	_hotbar = Hotbar.new()
	_hotbar.name = "Hotbar"
	$HUD.add_child(_hotbar)
	$HUD.move_child(_hotbar, _touch.get_index() + 1)
	_hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hotbar.offset_left = -_hotbar.size.x / 2.0
	_hotbar.offset_right = _hotbar.size.x / 2.0
	_hotbar.offset_top = -_hotbar.size.y - 20.0
	_hotbar.offset_bottom = -20.0
	_hotbar.bind(inventory)
	_dog_menu = DogMenu.new()
	_dog_menu.name = "DogMenu"
	$HUD.add_child(_dog_menu)
	var duel := DuelScreen.new()
	duel.name = "DuelScreen"
	$HUD.add_child(duel)
	_minigame = FishingMinigame.new()
	_minigame.name = "FishingMinigame"
	$HUD.add_child(_minigame)
	_player.interact_requested.connect(_on_interact_requested)
	_dialogue.line_shown.connect(_on_line_shown)
	if not _restore(save.read()):
		coords = world.start_room()
		_player.position = world.start_position()
	_apply_debug_start()
	_status.set_time(day_night.hour)
	_status.set_day(day_night.day)
	_status.set_health(_player.health, _player.max_health)
	_status.set_money(_player.money)
	_update_keys()
	_entry_position = _player.position
	_add_companion()
	_was_night = day_night.is_night()
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
		_on_room_entered()
		save_game()
		room_changed.emit(coords)
	else:
		# Edges toward empty cells are solid, so this only guards against teleports.
		_player.position = _clamp_to_room(_player.position, coords, 4.0)


func _process(_delta: float) -> void:
	_camera.position = _player.position
	var night := day_night.is_night()
	if night and not _was_night and not is_indoors():
		Effects.float_text(
			self, _player.position + Vector2(0, -120), "Night. Stick to the lights.", NIGHT_COLOR
		)
	_was_night = night
	if Input.is_action_just_pressed(&"item") and not _player.frozen and not is_talking():
		use_selected_item()
	var dog_ready := _companion != null and _companion.joined
	_touch.get_node("DogButton").visible = dog_ready
	if Input.is_action_just_pressed(&"dog") and dog_ready and _can_command_brownie():
		_command_brownie()


## Uses the item in the selected hotbar slot: cast the rod, or eat food to heal.
func use_selected_item() -> bool:
	var id := _hotbar.selected_id()
	if id == "":
		return false
	if id == "fishing_rod":
		fish()
		return true
	if id == "coconut_boomerang":
		return throw_boomerang()
	var heal := int(GameData.item(id).get("heal", 0))
	var above := _player.position + Vector2(0, -90)
	if heal <= 0:
		Effects.float_text(self, above, "Can't eat that", Color(1, 0.8, 0.6))
		return false
	if _player.is_full_health():
		Effects.float_text(self, above, "Not hungry", Color(1, 0.8, 0.6))
		return false
	inventory.remove(id)
	_player.heal(heal)
	Effects.float_text(self, above, "Yum!", Color(0.7, 1, 0.6))
	return true


## Throws the coconut boomerang the way Chad faces (one at a time).
func throw_boomerang() -> bool:
	if is_instance_valid(_boomerang):
		return false
	_boomerang = Boomerang.new()
	_boomerang.launch(_player, _player.facing, world)
	add_child(_boomerang)
	return true


## The boomerang in flight, if any.
func boomerang() -> Boomerang:
	return _boomerang if is_instance_valid(_boomerang) else null


## The hotbar at the bottom of the screen.
func hotbar() -> Hotbar:
	return _hotbar


## The catch minigame overlay.
func fishing_minigame() -> FishingMinigame:
	return _minigame


func is_fishing() -> bool:
	return _fishing


## Where Chad's line would land: the centre of the tile in front of him if it is water.
func water_in_front() -> Variant:
	var spot := _player.position + _player.facing * 70.0 + Vector2(0, -8)
	var cell := Vector2i((spot / WorldMap.TILE).floor())
	if world.tile_at(cell) != "~":
		return null
	return (Vector2(cell) + Vector2(0.5, 0.5)) * WorldMap.TILE


## Casts, waits for a bite, then plays the catch minigame. Returns the fish caught, or "".
func fish(bite_seconds := -1.0) -> String:
	if _fishing:
		return ""
	var spot: Variant = water_in_front()
	var above := _player.position + Vector2(0, -90)
	if spot == null:
		Effects.float_text(self, above, "Face the water to fish", Color(1, 0.8, 0.6))
		return ""
	_fishing = true
	_player.frozen = true
	var bobber := Sprite2D.new()
	bobber.texture = preload("res://assets/sprites/bobber.png")
	bobber.position = spot
	bobber.z_index = 2
	add_child(bobber)
	var bob := bobber.create_tween().set_loops()
	bob.tween_property(bobber, "position:y", spot.y + 5.0, 0.5)
	bob.tween_property(bobber, "position:y", spot.y, 0.5)
	var wait := bite_seconds if bite_seconds >= 0.0 else randf_range(1.0, 2.5)
	await get_tree().create_timer(wait, false).timeout
	Effects.float_text(self, spot + Vector2(0, -30), "!", Color(1, 0.9, 0.3))
	var id := GameData.pick_fish(day_night.hour)
	var difficulty := float(GameData.item(id).get("fish", {}).get("difficulty", 1.0))
	get_tree().paused = true
	var touch_was_visible := _touch.visible
	_touch.visible = false
	_hotbar.visible = false
	_minigame.start(id, difficulty)
	var result: String = await _minigame.finished
	_touch.visible = touch_was_visible
	_hotbar.visible = true
	await _let_input_go_stale()
	get_tree().paused = false
	bobber.queue_free()
	_player.frozen = false
	_fishing = false
	var name: String = GameData.item(id).get("name", id)
	if result != "caught":
		Effects.float_text(self, above, "It got away...", Color(0.8, 0.85, 1))
		return ""
	if inventory.add(id) > 0:
		Effects.float_text(self, above, "Bag full! You let the %s go" % name, Color(1, 0.6, 0.5))
		return ""
	Effects.float_text(self, above, "+1 %s" % name, Color(1, 0.95, 0.6))
	save_game()
	return id


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
	if _companion != null and _companion.joined:
		_companion.catch_up(_player)
	_refresh_rooms()
	_setup_camera()
	_snap_camera()
	_on_room_entered()
	save_game()


## Switches to another map (a key of MAPS) and puts Chad in a room there.
func enter_map(id: String, room_coords: Vector2i, pos: Vector2) -> void:
	map_id = id
	progress.map_id = id
	world = _world_for(id)
	day_night.indoors = MAPS[id].get("indoors", false)
	_update_keys()
	go_to(room_coords, pos)


## Walks through a warp: fade out, change map, fade in. `target` is "<map>:<x>_<y>:<tx>_<ty>"
## (a room and a tile in it), as written in room files.
func warp(target: String) -> void:
	var parsed := parse_warp(target)
	if _warping or parsed.is_empty():
		return
	_warping = true
	_player.frozen = true
	var out := create_tween()
	out.tween_property(_fade, "color:a", 1.0, FADE_SECONDS)
	await out.finished
	var room_coords: Vector2i = parsed["room"]
	var tile: Vector2i = parsed["tile"]
	enter_map(
		parsed["map"],
		room_coords,
		WorldMap.room_origin(room_coords) + (Vector2(tile) + Vector2(0.5, 0.5)) * WorldMap.TILE
	)
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, FADE_SECONDS)
	await back.finished
	_player.frozen = false
	_warping = false


## {"map", "room": Vector2i, "tile": Vector2i} for a warp target, or {} if it is malformed.
static func parse_warp(target: String) -> Dictionary:
	var parts := target.split(":")
	if parts.size() != 3 or not MAPS.has(parts[0]):
		return {}
	var room: Variant = _pair(parts[1])
	var tile: Variant = _pair(parts[2])
	if room == null or tile == null:
		return {}
	return {"map": parts[0], "room": room, "tile": tile}


static func _pair(text: String) -> Variant:
	var xy := text.split("_")
	if xy.size() != 2 or not xy[0].is_valid_int() or not xy[1].is_valid_int():
		return null
	return Vector2i(int(xy[0]), int(xy[1]))


## The map data for a map id (loaded once).
func _world_for(id: String) -> WorldMap:
	if not _worlds.has(id):
		var loaded := WorldMap.load_dir(MAPS[id]["dir"])
		loaded.filler = MAPS[id].get("filler", "")
		_worlds[id] = loaded
	return _worlds[id]


func is_indoors() -> bool:
	return MAPS[map_id].get("indoors", false)


func _update_keys() -> void:
	if _status != null:
		_status.set_keys(progress.key_count() if is_indoors() else -1, progress.has_boss_key())


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
	_hotbar.visible = false
	_dialogue.start(GameData.conversation(id))
	await _dialogue.finished
	_touch.visible = touch_was_visible
	_hotbar.visible = true
	await _let_input_go_stale()
	get_tree().paused = false
	save_game()
	conversation_finished.emit(id)


## Waits until the button press that closed a box or minigame can no longer count as "just
## pressed" for the hero. Physics ticks matter here: on a fast screen several frames can pass
## between two ticks.
func _let_input_go_stale() -> void:
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame


## Story flags plus "night" while it is dark, for choosing what characters say.
func dialogue_state() -> Dictionary:
	var state := flags.duplicate()
	state["night"] = day_night.is_night()
	state["day"] = day_night.day
	return state


func is_talking() -> bool:
	return _dialogue.is_open()


func save_game() -> void:
	var data := {
		"room": [coords.x, coords.y],
		"position": [_player.position.x, _player.position.y],
		"health": _player.health,
		"max_health": _player.max_health,
		"money": _player.money,
		"flags": flags,
		"hour": day_night.hour,
		"day": day_night.day,
		"inventory": inventory.to_data(),
		"forage": forage_state,
		"map": map_id,
		"progress": progress.data,
	}
	save.write(data)


func _restore(data: Dictionary) -> bool:
	var room: Variant = data.get("room")
	var position: Variant = data.get("position")
	if not (room is Array and room.size() == 2 and position is Array and position.size() == 2):
		return false
	var saved_coords := Vector2i(int(room[0]), int(room[1]))
	var saved_map := str(data.get("map", OVERWORLD))
	if not MAPS.has(saved_map) or not _world_for(saved_map).has_room(saved_coords):
		return false
	map_id = saved_map
	progress.map_id = saved_map
	world = _world_for(saved_map)
	day_night.indoors = is_indoors()
	var saved_progress: Variant = data.get("progress", {})
	if saved_progress is Dictionary:
		progress.data.merge(saved_progress, true)
	coords = saved_coords
	_player.position = _clamp_to_room(Vector2(position[0], position[1]), coords, 32.0)
	_player.max_health = clampi(int(data.get("max_health", _player.max_health)), 6, 40)
	var health := int(data.get("health", _player.max_health))
	_player.health = health if health > 0 else _player.max_health
	_player.money = maxi(int(data.get("money", 0)), 0)
	day_night.day = maxi(int(data.get("day", 1)), 1)
	day_night.set_hour(float(data.get("hour", day_night.hour)))
	inventory.from_data(data.get("inventory", []))
	var saved_forage: Variant = data.get("forage", {})
	if saved_forage is Dictionary:
		for key: String in saved_forage:
			forage_state[key] = int(saved_forage[key])
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


## Outdoors the camera roams the whole world; indoors it stays inside the current room and
## slides to the next one, like the rooms of a temple.
func _setup_camera() -> void:
	var rect := world.bounds()
	if is_indoors():
		rect = Rect2i(coords, Vector2i.ONE)
	_camera.limit_smoothed = is_indoors()
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
	room.key_prefix = "" if map_id == OVERWORLD else map_id + ":"
	var real := world.has_room(room_coords)
	room.build(
		room_coords,
		world.rows_or_filler(room_coords),
		world.objects_in(room_coords) if real else [],
		world.padded_rows(room_coords),
		not real
	)
	for child in room.get_children():
		if child is Forage:
			child.ready_day = int(forage_state.get(child.key, 0))
	_rooms.add_child(room)
	return room


## Runs when Chad arrives in a room: dungeon puzzles there reset if they are unsolved, and
## the indoor camera moves to the new room.
func _on_room_entered() -> void:
	if is_indoors():
		_setup_camera()
	var room := current_room()
	if room != null:
		room.on_enter()


func _can_command_brownie() -> bool:
	return (
		not get_tree().paused
		and not _player.frozen
		and not is_talking()
		and not _dog_menu.is_open()
	)


## The dog menu: pause, let Chad pick an order, then Brownie carries it out.
func _command_brownie() -> void:
	get_tree().paused = true
	var touch_was_visible := _touch.visible
	_touch.visible = false
	_hotbar.visible = false
	_dog_menu.open(_companion)
	var choice: Dictionary = await _dog_menu.closed
	_touch.visible = touch_was_visible
	_hotbar.visible = true
	await _let_input_go_stale()
	get_tree().paused = false
	match choice.get("order", ""):
		"sic":
			_companion.sic(choice["target"])
		"stay":
			_companion.stay()
		"come":
			_companion.come()
		"fetch":
			_companion.fetch()
		"dig":
			_companion.dig()


## Brownie: waiting at her spot on the road (`brownie` in a room file), or at Chad's heels if
## she has already joined.
func _add_companion() -> void:
	_companion = Companion.new()
	_companion.name = "Brownie"
	var overworld := _world_for(OVERWORLD)
	for room_coords: Vector2i in overworld.objects:
		for obj in overworld.objects_in(room_coords):
			if obj["kind"] == "brownie":
				_companion.home = (
					WorldMap.room_origin(room_coords)
					+ (Vector2(obj["cell"]) + Vector2(0.5, 0.5)) * WorldMap.TILE
				)
	_companion.position = _companion.home
	add_child(_companion)
	if flags.get(Companion.FLAG, false):
		_companion.join()
		_companion.catch_up(_player)


func _room_center(room_coords: Vector2i) -> Vector2:
	return WorldMap.room_origin(room_coords) + WorldMap.room_size() / 2.0


func _clamp_to_room(pos: Vector2, room_coords: Vector2i, margin: float) -> Vector2:
	var origin := WorldMap.room_origin(room_coords)
	return pos.clamp(
		origin + Vector2.ONE * margin, origin + WorldMap.room_size() - Vector2.ONE * margin
	)


## Developer aid for the Web build: `index.html?room=0_0` starts in that room, `&at=19_7` on
## that tile, `&time=21` at that hour, `&map=temple1` on another map, `&give=fishing_rod`
## puts an item in the bag, `&brownie=1` starts with Brownie and `&duel=scraps` opens a dog
## duel (used to take screenshots). Ignored everywhere else.
func _apply_debug_start() -> void:
	if not OS.has_feature("web"):
		return
	var query := str(JavaScriptBridge.eval("window.location.search", true))
	for gift in RegEx.create_from_string("give=([a-z_]+)").search_all(query):
		if GameData.has_item(gift.get_string(1)):
			inventory.add(gift.get_string(1))
	var time := RegEx.create_from_string("time=(\\d+(\\.\\d+)?)").search(query)
	if time != null:
		day_night.set_hour(float(time.get_string(1)))
	if query.contains("brownie=1"):
		flags[Companion.FLAG] = true
	var duel := RegEx.create_from_string("duel=([a-z_]+)").search(query)
	if duel != null and GameData.has_dog(duel.get_string(1)):
		flags[Companion.FLAG] = true
		var screen: DuelScreen = $HUD/DuelScreen
		screen.fight.call_deferred(self, duel.get_string(1))
	var on_map := RegEx.create_from_string("map=([a-z0-9_]+)").search(query)
	if on_map != null and MAPS.has(on_map.get_string(1)):
		map_id = on_map.get_string(1)
		progress.map_id = map_id
		world = _world_for(map_id)
		day_night.indoors = is_indoors()
		_update_keys()
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
	if target is Forage:
		harvest(target)
	elif target.has_method("use"):
		target.use(self)
	else:
		talk(target.dialogue_id(dialogue_state()), target)


## Picks a forage plant into the bag. Returns how many items were added.
func harvest(plant: Forage) -> int:
	if not plant.is_ready(day_night.day):
		return 0
	var before := plant.ready_day
	var got := plant.pick(day_night.day)
	var id: String = got[0]
	var amount: int = got[1]
	var added := amount - inventory.add(id, amount)
	var above := plant.position + Vector2(0, -120)
	if added == 0:
		plant.ready_day = before
		plant.refresh(day_night.day)
		Effects.float_text(plant.get_parent(), above, "Bag full!", Color(1, 0.6, 0.5))
		return 0
	forage_state[plant.key] = plant.ready_day
	var name: String = GameData.item(id).get("name", id)
	Effects.float_text(plant.get_parent(), above, "+%d %s" % [added, name], Color(1, 0.95, 0.6))
	Effects.burst(plant.get_parent(), plant.position + Vector2(0, -40), "sparkle")
	return added


func _on_line_shown(line: Dictionary) -> void:
	if line.has("set_flag"):
		flags[line["set_flag"]] = true
	if line.has("give") and GameData.has_item(line["give"]):
		inventory.add(line["give"])


func _on_player_died() -> void:
	_faint_label.visible = true
	await get_tree().create_timer(FAINT_SECONDS).timeout
	_faint_label.visible = false
	_loaded[coords].queue_free()
	_loaded[coords] = _make_room(coords)
	_player.position = _entry_position
	_player.revive()
	if _companion.joined:
		_companion.catch_up(_player)
	save_game()


func _on_paused_changed(is_paused: bool) -> void:
	if is_paused:
		save_game()
