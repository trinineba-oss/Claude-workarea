class_name WharfDemo
extends Node
## The demo: waves of enemies on San Fernando Wharf, ending with the pack leader. A banner
## announces each wave; the next comes when the last enemy falls. If Chad faints, the wave
## starts again. Clearing the wharf sets the "demo_done" flag.

signal wave_started(number: int)
signal completed

const ROOM := Vector2i(0, 1)
## What each wave brings ("alpha" is the boss: a big pothound).
const WAVES := [
	["crab", "crab", "crab"],
	["dog", "dog", "crab", "crab"],
	["corbeau", "corbeau", "dog", "dog"],
	["dog", "dog", "dog", "corbeau", "crab", "crab"],
	["alpha", "dog", "dog"],
]
const BREAK_SECONDS := 2.2
## Enemies appear at least this far from Chad.
const SPAWN_DISTANCE := 280.0

var wave := 0
var running := false
var alive: Array[Enemy] = []

var _game: Game
var _banner: Label
var _pause := 0.0
var _waiting_for_revive := false


func setup(game: Game) -> void:
	_game = game
	name = "WharfDemo"
	_banner = Label.new()
	_banner.name = "WaveBanner"
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 64)
	_banner.add_theme_color_override("font_color", Color(1, 0.92, 0.5))
	_banner.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.1))
	_banner.add_theme_constant_override("outline_size", 14)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_left = -500
	_banner.offset_right = 500
	_banner.offset_top = 110
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	game.get_node("HUD").add_child(_banner)
	game.get_node("Player").died.connect(_on_player_died)


func is_done() -> bool:
	return bool(_game.flags.get("demo_done", false))


## Begins (or begins again) from the first wave.
func start() -> void:
	if is_done():
		return
	running = true
	wave = 0
	_pause = 1.0


func _physics_process(delta: float) -> void:
	if not running or _game.get_tree().paused:
		return
	var player: Player = _game.get_node("Player")
	if _waiting_for_revive:
		if player.health > 0 and not player.frozen:
			_waiting_for_revive = false
			_clear()
			wave = maxi(wave - 1, 0)
			_pause = 1.5
		return
	alive = alive.filter(func(e): return is_instance_valid(e) and e.health > 0)
	if not alive.is_empty() or _game.coords != ROOM or _game.map_id != Game.OVERWORLD:
		return
	_pause -= delta
	if _pause > 0.0:
		return
	if wave >= WAVES.size():
		_finish()
	else:
		_spawn_wave()


func _spawn_wave() -> void:
	var room := _game.current_room()
	if room == null:
		return
	var kinds: Array = WAVES[wave]
	wave += 1
	var boss := "alpha" in kinds
	_show("THE PACK LEADER!" if boss else "WAVE %d" % wave)
	for kind: String in kinds:
		var enemy: Enemy = Entities.create("dog" if kind == "alpha" else kind)
		if kind == "alpha":
			(enemy as Pothound).alpha = true
		enemy.position = _spawn_spot(room)
		room.add_child(enemy)
		enemy.appear()
		Effects.burst(room, enemy.position + Vector2(0, -20), "poof")
		alive.append(enemy)
	_pause = BREAK_SECONDS
	wave_started.emit(wave)


## A free tile of the wharf, away from Chad.
func _spawn_spot(room: Room) -> Vector2:
	var player: Player = _game.get_node("Player")
	var tile := float(WorldMap.TILE)
	var best := Vector2(WorldMap.COLS, WorldMap.ROWS) * tile / 2.0
	for attempt in 40:
		var cell := Vector2i(randi_range(3, WorldMap.COLS - 3), randi_range(1, WorldMap.ROWS - 3))
		var ch := room.map_lines[cell.y][cell.x]
		if Tiles.is_solid(ch) or ch == "~":
			continue
		var spot := (Vector2(cell) + Vector2(0.5, 0.5)) * tile
		best = spot
		if (room.position + spot).distance_to(player.global_position) >= SPAWN_DISTANCE:
			return spot
	return best


func _finish() -> void:
	running = false
	_game.flags["demo_done"] = true
	_show("WHARF CLEARED!")
	_game.get_node("Player").add_money(25)
	completed.emit()
	_game.save_game()
	_game.talk.call_deferred("demo_complete")


func _on_player_died() -> void:
	if running:
		_waiting_for_revive = true


## Sends what is left of the wave away (the room is rebuilt when Chad faints).
func _clear() -> void:
	for enemy in alive:
		if is_instance_valid(enemy):
			enemy.queue_free()
	alive.clear()


func _show(text: String) -> void:
	_banner.text = text
	_banner.modulate.a = 1.0
	_banner.scale = Vector2.ONE
	var tween := _banner.create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.6)
