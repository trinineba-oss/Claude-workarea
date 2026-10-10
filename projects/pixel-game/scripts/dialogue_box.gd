class_name DialogueBox
extends Control
## The conversation box at the bottom of the screen. Types each line out; tap the screen or
## press interact/attack to show the whole line, then again for the next one.
## Runs while the game is paused (the HUD layer always processes).

signal line_shown(line: Dictionary)
signal finished

const CHARS_PER_SECOND := 48.0
const MARGIN := 48.0
const HEIGHT := 190.0

var _lines: Array = []
var _index := 0
var _shown := 0.0
var _last_advance_frame := -1

var _panel: Panel
var _name_panel: Panel
var _name: Label
var _text: Label
var _more: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_panel = Panel.new()
	_panel.add_theme_stylebox_override("panel", _style(Color(0.08, 0.05, 0.12, 0.9), 26))
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = MARGIN * 3.0
	_panel.offset_right = -MARGIN * 3.0
	_panel.offset_top = -HEIGHT - MARGIN * 0.6
	_panel.offset_bottom = -MARGIN * 0.6
	add_child(_panel)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 32)
	_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text.offset_left = 36
	_text.offset_top = 34
	_text.offset_right = -36
	_text.offset_bottom = -24
	_panel.add_child(_text)
	_more = Control.new()
	_more.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_more.position = Vector2(-52, -40)
	_more.draw.connect(
		func():
			_more.draw_colored_polygon(
				PackedVector2Array([Vector2(0, 0), Vector2(22, 0), Vector2(11, 14)]),
				Color(1, 0.8, 0.3)
			)
	)
	_panel.add_child(_more)
	_name_panel = Panel.new()
	_name_panel.add_theme_stylebox_override("panel", _style(Color(0.95, 0.72, 0.2), 16))
	_name_panel.position = Vector2(28, -26)
	_name_panel.size = Vector2(220, 46)
	_panel.add_child(_name_panel)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 26)
	_name.add_theme_color_override("font_color", Color(0.15, 0.08, 0.05))
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name.set_anchors_preset(Control.PRESET_FULL_RECT)
	_name_panel.add_child(_name)


func _process(delta: float) -> void:
	if not visible:
		return
	if not _line_complete():
		_shown += delta * CHARS_PER_SECOND
		_text.visible_characters = int(_shown)
	_more.visible = _line_complete() and int(Time.get_ticks_msec() / 400.0) % 2 == 0
	if Input.is_action_just_pressed(&"interact") or Input.is_action_just_pressed(&"attack"):
		advance()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var tapped: bool = event is InputEventScreenTouch and event.pressed
	var clicked: bool = (
		event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	)
	if tapped or clicked:
		advance()
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return visible


func start(lines: Array) -> void:
	_lines = lines
	_index = 0
	visible = not lines.is_empty()
	if visible:
		_show_line()
	else:
		finished.emit()


## Shows the rest of the current line, or moves to the next one.
func advance() -> void:
	if not visible or Engine.get_process_frames() == _last_advance_frame:
		return
	_last_advance_frame = Engine.get_process_frames()
	if not _line_complete():
		_shown = _text.get_total_character_count()
		_text.visible_characters = -1
		return
	_index += 1
	if _index >= _lines.size():
		visible = false
		finished.emit()
	else:
		_show_line()


func _show_line() -> void:
	var line: Dictionary = _lines[_index]
	var speaker: String = line.get("speaker", "")
	_name_panel.visible = speaker != ""
	_name.text = speaker
	_text.text = line.get("text", "")
	_shown = 0.0
	_text.visible_characters = 0
	line_shown.emit(line)


func _line_complete() -> bool:
	return _text.visible_characters < 0 or _shown >= _text.get_total_character_count()


static func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = Color(1, 1, 1, 0.18)
	style.set_border_width_all(3)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 10
	return style
