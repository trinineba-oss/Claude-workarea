class_name FishingMinigame
extends Control
## The on-screen catch minigame (see FishingLogic). Hold Attack or Interact, or keep a finger or
## the mouse button down anywhere, to lift the green zone. Runs while the game is paused.

signal finished(result: String)

const BAR := Rect2(Vector2(-60, -230), Vector2(80, 460))
const METER := Rect2(Vector2(36, -230), Vector2(18, 460))

var logic: FishingLogic
var fish_id := ""

var _touching := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func start(id: String, difficulty: float, rng_seed := 0) -> void:
	fish_id = id
	logic = FishingLogic.new(difficulty, rng_seed)
	_touching = false
	visible = true
	queue_redraw()


func is_open() -> bool:
	return visible


## Ends the minigame right away (used by tests, and if the game needs to interrupt it).
func finish(result: String) -> void:
	if not visible:
		return
	visible = false
	finished.emit(result)


func holding() -> bool:
	return _touching or Input.is_action_pressed(&"attack") or Input.is_action_pressed(&"interact")


func _process(delta: float) -> void:
	if not visible or logic == null:
		return
	var result := logic.step(delta, holding())
	queue_redraw()
	if result != "":
		finish(result)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_touching = event.pressed
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_touching = event.pressed
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if logic == null:
		return
	var centre := size / 2.0 + Vector2(220, 0)
	var bar := Rect2(centre + BAR.position, BAR.size)
	draw_rect(bar.grow(10), Color(0.08, 0.05, 0.12, 0.85), true)
	draw_rect(bar, Color(0.16, 0.42, 0.7), true)
	var zone_h := FishingLogic.ZONE_SIZE * bar.size.y
	var zone_y := bar.end.y - (logic.zone_pos * bar.size.y) - zone_h
	var zone_color := (
		Color(0.45, 0.95, 0.45, 0.75) if logic.on_fish() else Color(0.45, 0.95, 0.45, 0.45)
	)
	draw_rect(Rect2(Vector2(bar.position.x, zone_y), Vector2(bar.size.x, zone_h)), zone_color, true)
	var icon := GameData.item_icon(fish_id)
	var fish_y := bar.end.y - logic.fish_pos * bar.size.y
	if icon != null:
		draw_texture_rect(
			icon, Rect2(Vector2(bar.position.x + 8, fish_y - 32), Vector2(64, 64)), false
		)
	var meter := Rect2(centre + METER.position, METER.size)
	draw_rect(meter.grow(4), Color(0.08, 0.05, 0.12, 0.85), true)
	var fill := meter.size.y * clampf(logic.progress, 0.0, 1.0)
	draw_rect(
		Rect2(Vector2(meter.position.x, meter.end.y - fill), Vector2(meter.size.x, fill)),
		Color(1, 0.8, 0.3),
		true
	)
	var font := ThemeDB.fallback_font
	var tip := "Hold A, or hold the screen, to reel in"
	var at := Vector2(bar.position.x - 330, bar.end.y + 50)
	draw_string_outline(
		font, at, tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, Color(0.08, 0.05, 0.12)
	)
	draw_string(font, at, tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
