class_name DogMenu
extends Control
## The dog menu: Chad's orders for Evey. The game pauses while it is open. Pick an order
## with up/down and Attack or Interact (or tap it); Dog, Pause or Escape closes it. Evey is a
## peaceful dog: her orders are helping ones, never fighting.
## Emits `closed` with {"order": "stay" | "come" | "fetch" | "dig" | ""}.

signal closed(choice: Dictionary)

const WIDTH := 360.0
const ROW := 64.0

var options: Array[String] = []

var _companion: Companion
var _index := 0
var _open_frame := -1
var _panel: Panel
var _rows: Array[Label] = []
var _title: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_panel = Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.12, 0.92)
	style.set_corner_radius_all(22)
	style.border_color = Color(0.95, 0.72, 0.2)
	style.set_border_width_all(3)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(_on_panel_input)
	add_child(_panel)
	_title = _label(28, Color(0.95, 0.72, 0.2))
	_title.position = Vector2(28, 14)
	_panel.add_child(_title)


func is_open() -> bool:
	return visible


func open(companion: Companion) -> void:
	_companion = companion
	options = ["come" if companion.mode == Companion.Mode.STAY else "stay", "fetch", "dig"]
	options.append("close")
	_index = 0
	_open_frame = Engine.get_process_frames()
	_build_rows()
	visible = true


## Picks the highlighted order.
func confirm() -> void:
	Sfx.play("menu_accept", 0.0)
	var order := options[_index]
	_finish({"order": "" if order == "close" else order})


func cancel() -> void:
	_finish({"order": ""})


func move(step: int) -> void:
	Sfx.play("menu_move", 0.0)
	_index = posmod(_index + step, options.size())
	_build_rows()


func _process(_delta: float) -> void:
	if not visible or Engine.get_process_frames() == _open_frame:
		return
	if Input.is_action_just_pressed(&"move_up") or Input.is_action_just_pressed(&"move_left"):
		move(-1)
	elif Input.is_action_just_pressed(&"move_down") or Input.is_action_just_pressed(&"move_right"):
		move(1)
	elif Input.is_action_just_pressed(&"attack") or Input.is_action_just_pressed(&"interact"):
		confirm()
	elif (
		Input.is_action_just_pressed(&"dog")
		or Input.is_action_just_pressed(&"pause")
		or Input.is_action_just_pressed(&"ui_cancel")
	):
		cancel()


func _finish(choice: Dictionary) -> void:
	visible = false
	closed.emit(choice)


func _build_rows() -> void:
	for row in _rows:
		row.queue_free()
	_rows.clear()
	var lines: Array[String] = []
	_title.text = "Evey"
	for order in options:
		lines.append(_order_text(order))
	for i in lines.size():
		var row := _label(32, Color.WHITE)
		row.text = lines[i]
		row.position = Vector2(48, 62 + i * ROW)
		var selected := i == _index
		row.add_theme_color_override(
			"font_color", Color(1, 0.86, 0.4) if selected else Color(0.85, 0.85, 0.92)
		)
		if selected:
			row.text = "> " + row.text
			row.position.x -= 26
		_panel.add_child(row)
		_rows.append(row)
	_panel.size = Vector2(WIDTH, 80 + lines.size() * ROW)
	_panel.position = (get_viewport_rect().size - _panel.size) / 2.0 + Vector2(0, -40)


static func _order_text(order: String) -> String:
	return {
		"stay": "Stay",
		"come": "Come",
		"fetch": "Fetch",
		"dig": "Dig",
		"close": "Never mind",
	}[order]


## Taps: a row picks it.
func _on_panel_input(event: InputEvent) -> void:
	var tapped: bool = (
		(event is InputEventScreenTouch and event.pressed)
		or (event is InputEventMouseButton and event.pressed)
	)
	if not tapped:
		return
	var row := int((event.position.y - 62.0) / ROW)
	if row >= 0 and row < options.size():
		_index = row
		confirm()


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
