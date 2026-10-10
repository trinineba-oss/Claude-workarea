class_name Hotbar
extends Control
## The item bar at the bottom of the screen (the first slots of the inventory). Tap a slot or
## press 1-8 to select it; the Item button (B / X key) uses the selected item.

signal selected_changed(index: int)

const SHOWN := 8
const SLOT := 76.0
const GAP := 8.0

var selected := 0
var inventory: Inventory


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(SHOWN * (SLOT + GAP) - GAP, SLOT)
	size = custom_minimum_size


func bind(inv: Inventory) -> void:
	inventory = inv
	inventory.changed.connect(queue_redraw)
	queue_redraw()


func select(index: int) -> void:
	selected = clampi(index, 0, SHOWN - 1)
	selected_changed.emit(selected)
	queue_redraw()


func selected_id() -> String:
	return inventory.id_at(selected) if inventory != null else ""


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var n: int = event.keycode - KEY_1
		if n >= 0 and n < SHOWN:
			select(n)
	var tap: bool = event is InputEventScreenTouch and event.pressed
	var click: bool = (
		event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	)
	if tap or click:
		var local: Vector2 = event.position - global_position
		if Rect2(Vector2.ZERO, size).has_point(local):
			select(int(local.x / (SLOT + GAP)))
			get_viewport().set_input_as_handled()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for i in SHOWN:
		var rect := Rect2(Vector2(i * (SLOT + GAP), 0), Vector2(SLOT, SLOT))
		draw_rect(rect, Color(0.08, 0.05, 0.12, 0.62), true)
		var edge := Color(1, 0.8, 0.3) if i == selected else Color(1, 1, 1, 0.3)
		draw_rect(rect, edge, false, 4.0 if i == selected else 2.0)
		if inventory == null:
			continue
		var slot: Dictionary = inventory.slots[i]
		if slot.is_empty():
			continue
		var tex := GameData.item_icon(slot["id"])
		if tex != null:
			draw_texture_rect(tex, rect.grow(-10), false)
		if slot["count"] > 1:
			var at := rect.position + Vector2(SLOT - 30, SLOT - 8)
			var text := str(slot["count"])
			draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 5, Color.BLACK)
			draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
