class_name DogMenu
extends Control
## The dog menu: Chad's orders for Brownie. The game pauses while it is open. Pick an order
## with up/down and Attack or Interact (or tap it); Dog, Pause or Escape closes it. "Sic 'em"
## then asks for a target: left/right (or up/down) cycles through enemies nearby, marked by a
## red ring in the world, and Attack sends her.
## Emits `closed` with {"order": "sic" | "stay" | "come" | "fetch" | "dig" | "", "target": Node}.

signal closed(choice: Dictionary)

const WIDTH := 360.0
const ROW := 64.0
const NAMES := {
	"Pothound": "Stray dog",
	"Corbeau": "Corbeau",
	"Bandit": "Bandit",
	"Soucouyant": "Soucouyant",
	"Crab": "Crab",
	"BigCrab": "Big Blue Crab",
	"Cauldron": "Callaloo Cauldron",
}

var options: Array[String] = []

var _companion: Companion
var _index := 0
var _picking := false
var _targets: Array = []
var _target_index := 0
var _open_frame := -1
var _panel: Panel
var _rows: Array[Label] = []
var _title: Label
var _marker: Node2D


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
	options = ["sic", "come" if companion.mode == Companion.Mode.STAY else "stay", "fetch", "dig"]
	options.append("close")
	_index = 0
	_picking = false
	_open_frame = Engine.get_process_frames()
	_build_rows()
	visible = true


## Picks the highlighted order (or target).
func confirm() -> void:
	if _picking:
		if _targets.is_empty():
			_picking = false
			_build_rows()
			return
		_finish({"order": "sic", "target": _targets[_target_index]})
		return
	var order := options[_index]
	if order == "close":
		_finish({"order": "", "target": null})
	elif order == "sic":
		_targets = _companion.targets()
		_target_index = 0
		_picking = true
		_build_rows()
	else:
		_finish({"order": order, "target": null})


func cancel() -> void:
	if _picking:
		_picking = false
		_build_rows()
	else:
		_finish({"order": "", "target": null})


func move(step: int) -> void:
	if _picking:
		if not _targets.is_empty():
			_target_index = posmod(_target_index + step, _targets.size())
	else:
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
	_picking = false
	_show_marker(null)
	closed.emit(choice)


func _build_rows() -> void:
	for row in _rows:
		row.queue_free()
	_rows.clear()
	var lines: Array[String] = []
	if _picking:
		_title.text = "Sic 'em: who?"
		if _targets.is_empty():
			lines.append("Nobody to bite. (Back)")
		else:
			var target: Node = _targets[_target_index]
			var kind: String = target.get_script().get_global_name()
			lines.append("<  %s  >" % NAMES.get(kind, kind))
			lines.append("%d of %d" % [_target_index + 1, _targets.size()])
		_show_marker(null if _targets.is_empty() else _targets[_target_index])
	else:
		_title.text = "Brownie"
		for order in options:
			lines.append(_order_text(order))
		_show_marker(null)
	for i in lines.size():
		var row := _label(32, Color.WHITE)
		row.text = lines[i]
		row.position = Vector2(48, 62 + i * ROW)
		var selected := (not _picking and i == _index) or (_picking and i == 0)
		row.add_theme_color_override(
			"font_color", Color(1, 0.86, 0.4) if selected else Color(0.85, 0.85, 0.92)
		)
		if selected and not _picking:
			row.text = "> " + row.text
			row.position.x -= 26
		_panel.add_child(row)
		_rows.append(row)
	_panel.size = Vector2(WIDTH, 80 + lines.size() * ROW)
	_panel.position = (get_viewport_rect().size - _panel.size) / 2.0 + Vector2(0, -40)


static func _order_text(order: String) -> String:
	return {
		"sic": "Sic 'em",
		"stay": "Stay",
		"come": "Come",
		"fetch": "Fetch",
		"dig": "Dig",
		"close": "Never mind",
	}[order]


## Taps: a row picks it; while choosing a target, the left or right half cycles and a tap
## on the name sends her.
func _on_panel_input(event: InputEvent) -> void:
	var tapped: bool = (
		(event is InputEventScreenTouch and event.pressed)
		or (event is InputEventMouseButton and event.pressed)
	)
	if not tapped:
		return
	var row := int((event.position.y - 62.0) / ROW)
	if _picking:
		if row != 0 or _targets.is_empty():
			cancel()
		elif event.position.x < WIDTH * 0.25:
			move(-1)
		elif event.position.x > WIDTH * 0.75:
			move(1)
		else:
			confirm()
	elif row >= 0 and row < options.size():
		_index = row
		confirm()


func _exit_tree() -> void:
	if _marker != null and is_instance_valid(_marker) and _marker.get_parent() == null:
		_marker.free()


func _show_marker(target: Node) -> void:
	if _marker != null and not is_instance_valid(_marker):
		_marker = null
	if _marker == null:
		_marker = Node2D.new()
		_marker.z_index = 30
		_marker.draw.connect(
			func():
				_marker.draw_arc(Vector2.ZERO, 46.0, 0.0, TAU, 48, Color(1, 0.25, 0.2), 5.0, true)
				_marker.draw_arc(Vector2.ZERO, 54.0, 0.0, TAU, 48, Color(1, 1, 1, 0.6), 2.0, true)
		)
	if _marker.get_parent() != null:
		_marker.get_parent().remove_child(_marker)
	if target != null and is_instance_valid(target):
		target.add_child(_marker)
		_marker.position = Vector2(0, -30)
		_marker.queue_redraw()


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
