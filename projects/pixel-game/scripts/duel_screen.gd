class_name DuelScreen
extends Control
## The turn-based duel between Brownie and a top dog (rules in DogBattle). The world pauses
## behind it. Each round Chad picks Brownie's move from a 2x2 menu (arrows and Attack or
## Interact, or tap); then the round plays out line by line (press or tap to go on). Winning
## pays TT$, gives Brownie experience (she levels up) and marks the dog as beaten.

signal line_advanced
signal move_chosen(move: String)

## Half-doubles of HP a treat gives back in a duel.
const TREAT_HEAL := 7
## Lines go on by themselves after this long (a press goes on sooner).
const LINE_SECONDS := 2.2
const LABELS := {"bite": "Bite", "bark": "Bark", "guard": "Guard", "treat": "Treat"}

var battle: DogBattle
## Lines move on by themselves after this many seconds (tests shorten it).
var line_seconds := LINE_SECONDS

var _game: Game
var _dog_id := ""
var _menu_open := false
var _index := 0
var _line_time := 0.0
var _waiting_line := false
var _open_frame := -1
var _treats := 0
var _message: Label
var _buttons: Array[Label] = []
var _foe_sprite: TextureRect
var _brownie_sprite: TextureRect
var _foe_panel: Control
var _brownie_panel: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var back := ColorRect.new()
	back.color = Color(0.1, 0.16, 0.12, 0.97)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	var ground := ColorRect.new()
	ground.color = Color(0.24, 0.36, 0.2)
	ground.set_anchors_preset(Control.PRESET_FULL_RECT)
	ground.offset_top = 300
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	_foe_sprite = _sprite_rect(Vector2(820, 70))
	_foe_sprite.flip_h = true
	_brownie_sprite = _sprite_rect(Vector2(200, 250))
	_brownie_sprite.texture = preload("res://assets/sprites/brownie.png")
	_foe_panel = _stat_panel(Vector2(90, 60))
	_brownie_panel = _stat_panel(Vector2(760, 330))
	var box := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.12, 0.94)
	style.set_corner_radius_all(22)
	style.border_color = Color(0.95, 0.72, 0.2)
	style.set_border_width_all(3)
	box.add_theme_stylebox_override("panel", style)
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_left = 40
	box.offset_right = -40
	box.offset_top = -200
	box.offset_bottom = -24
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_font_size_override("font_size", 32)
	_message.position = Vector2(30, 26)
	_message.size = Vector2(600, 130)
	box.add_child(_message)
	for i in DogBattle.MOVES.size():
		var button := Label.new()
		button.add_theme_font_size_override("font_size", 34)
		button.position = Vector2(680 + (i % 2) * 260, 34 + (i / 2) * 64)
		button.size = Vector2(240, 56)
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(button)
		_buttons.append(button)


func is_open() -> bool:
	return visible


## Runs a whole duel against `dog_id`; returns true if Brownie won.
func fight(game: Game, dog_id: String) -> bool:
	_game = game
	_dog_id = dog_id
	var data := GameData.dog(dog_id)
	battle = DogBattle.new(int(game.flags.get("brownie_level", 1)), data)
	_foe_sprite.texture = load("res://assets/sprites/%s.png" % data.get("sprite", "dog"))
	_open_frame = Engine.get_process_frames()
	var tree := get_tree()
	var was_paused := tree.paused
	tree.paused = true
	var hud_bits: Array = [game.get_node("HUD/TouchControls"), game.hotbar()]
	var shown: Array = hud_bits.map(func(n): return n.visible)
	for bit: CanvasItem in hud_bits:
		bit.visible = false
	visible = true
	_refresh()
	await _say(["%s wants to duel!" % battle.foe["name"]])
	while not battle.over:
		var move: String = await _pick_move()
		var heal := 0
		if move == "treat":
			var food := Companion.food_in(game.inventory)
			game.inventory.remove(food)
			heal = TREAT_HEAL
		var lines := battle.play_round(move, heal)
		await _say(lines)
	var ending: Array[String] = []
	if battle.brownie_won:
		var reward := int(data.get("reward", 0))
		game.get_node("Player").add_money(reward)
		game.flags["beat_" + dog_id] = true
		ending.append("Brownie wins! Chad gets TT$%d." % reward)
		ending.append_array(DogBattle.add_xp(game.flags, int(data.get("xp", 0))))
	await _say(ending)
	visible = false
	for i in hud_bits.size():
		hud_bits[i].visible = shown[i]
	await tree.process_frame
	await tree.physics_frame
	await tree.physics_frame
	tree.paused = was_paused
	game.save_game()
	return battle.brownie_won


## Picks Brownie's move (what the menu does when Chad confirms).
func choose(move: String) -> void:
	if _menu_open and _move_allowed(move):
		_menu_open = false
		_refresh()
		move_chosen.emit(move)


## Goes on to the next line.
func advance() -> void:
	if _waiting_line:
		_waiting_line = false
		line_advanced.emit()


func _process(delta: float) -> void:
	if not visible or Engine.get_process_frames() == _open_frame:
		return
	var confirm := (
		Input.is_action_just_pressed(&"attack") or Input.is_action_just_pressed(&"interact")
	)
	if _waiting_line:
		_line_time += delta
		if confirm or _line_time >= line_seconds:
			advance()
		return
	if not _menu_open:
		return
	if Input.is_action_just_pressed(&"move_left") or Input.is_action_just_pressed(&"move_right"):
		_index = _index ^ 1
		_refresh()
	elif Input.is_action_just_pressed(&"move_up") or Input.is_action_just_pressed(&"move_down"):
		_index = _index ^ 2
		_refresh()
	elif confirm:
		choose(DogBattle.MOVES[_index])


func _gui_input(event: InputEvent) -> void:
	var tapped: bool = (
		(event is InputEventScreenTouch and event.pressed)
		or (event is InputEventMouseButton and event.pressed)
	)
	if not tapped:
		return
	if _waiting_line:
		advance()
		return
	if not _menu_open:
		return
	for i in _buttons.size():
		var rect := Rect2(_buttons[i].global_position, _buttons[i].size)
		if rect.has_point(event.position):
			_index = i
			choose(DogBattle.MOVES[i])


func _pick_move() -> String:
	_menu_open = true
	if not _move_allowed(DogBattle.MOVES[_index]):
		_index = 0
	_message.text = "What will Brownie do?"
	_refresh()
	return await move_chosen


func _say(lines: Array) -> void:
	for line: String in lines:
		_message.text = line
		_refresh()
		_line_time = 0.0
		_waiting_line = true
		await line_advanced


func _move_allowed(move: String) -> bool:
	return move != "treat" or Companion.food_in(_game.inventory) != ""


func _refresh() -> void:
	_treats = 0
	for slot: Dictionary in _game.inventory.slots:
		if not slot.is_empty() and Companion.is_food(slot["id"]):
			_treats += int(slot["count"])
	for i in _buttons.size():
		var move: String = DogBattle.MOVES[i]
		var text: String = LABELS[move]
		if move == "treat":
			text += " x%d" % _treats
		var selected := _menu_open and i == _index
		_buttons[i].text = ("> " if selected else "  ") + text
		_buttons[i].visible = _menu_open
		var colour := Color(1, 0.86, 0.4) if selected else Color(0.9, 0.9, 0.95)
		if not _move_allowed(move):
			colour = Color(0.5, 0.5, 0.55)
		_buttons[i].add_theme_color_override("font_color", colour)
	var level := int(_game.flags.get("brownie_level", 1))
	_fill_panel(_foe_panel, battle.foe, "")
	_fill_panel(_brownie_panel, battle.brownie, "Lv %d" % level)


func _fill_panel(panel: Control, fighter: Dictionary, extra: String) -> void:
	panel.set_meta("fighter", fighter)
	panel.set_meta("extra", extra)
	panel.queue_redraw()


func _stat_panel(at: Vector2) -> Control:
	var panel := Control.new()
	panel.position = at
	panel.size = Vector2(420, 96)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.draw.connect(
		func():
			if not panel.has_meta("fighter"):
				return
			var fighter: Dictionary = panel.get_meta("fighter")
			var font := ThemeDB.fallback_font
			panel.draw_rect(Rect2(Vector2.ZERO, panel.size), Color(0.08, 0.05, 0.12, 0.85))
			var title := "%s  %s" % [fighter["name"], panel.get_meta("extra")]
			panel.draw_string(font, Vector2(18, 36), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
			var ratio := float(fighter["hp"]) / float(fighter["max_hp"])
			var bar := Rect2(18, 52, 300, 22)
			panel.draw_rect(bar, Color(0.25, 0.2, 0.3))
			var fill := Color(0.4, 0.85, 0.4) if ratio > 0.5 else Color(0.95, 0.75, 0.25)
			if ratio <= 0.25:
				fill = Color(0.95, 0.35, 0.3)
			panel.draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), fill)
			var hp_text := "%d/%d" % [fighter["hp"], fighter["max_hp"]]
			panel.draw_string(font, Vector2(330, 72), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
	)
	add_child(panel)
	return panel


func _sprite_rect(at: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.position = at
	rect.size = Vector2(240, 190)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect
