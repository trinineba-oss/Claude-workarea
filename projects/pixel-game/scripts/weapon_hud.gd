class_name WeaponHud
extends Control
## The weapon in Chad's hand, top left under the clock: its icon, its name and a bar for the
## hits it has left (red when it is about to break). Fists show no bar: they never break.

const BAR := Vector2(96, 8)

var _id := Weapons.FISTS
var _wear := 0
var _durability := 0
var _icon: TextureRect


func _ready() -> void:
	name = "WeaponHud"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(20, 156)
	size = Vector2(260, 56)
	_icon = TextureRect.new()
	_icon.position = Vector2(2, 2)
	_icon.size = Vector2(48, 48)
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)


func show_weapon(id: String, wear: int, durability: int) -> void:
	_id = id
	_wear = wear
	_durability = durability
	if _icon != null:
		_icon.texture = Weapons.icon(id)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(52, 52)), Color(0.08, 0.05, 0.12, 0.6))
	draw_rect(Rect2(Vector2.ZERO, Vector2(52, 52)), Color(1, 1, 1, 0.5), false, 2.0)
	var font := ThemeDB.fallback_font
	draw_string_outline(
		font,
		Vector2(62, 22),
		Weapons.display_name(_id),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		22,
		6,
		Color(0.1, 0.06, 0.14)
	)
	draw_string(font, Vector2(62, 22), Weapons.display_name(_id), HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	if _durability <= 0:
		return
	var at := Vector2(62, 34)
	var left := clampf(float(_wear) / _durability, 0.0, 1.0)
	var colour := Color(0.95, 0.3, 0.25) if left < 0.25 else Color(0.95, 0.85, 0.4)
	draw_rect(Rect2(at - Vector2(2, 2), BAR + Vector2(4, 4)), Color(0.1, 0.06, 0.14))
	draw_rect(Rect2(at, Vector2(roundf(BAR.x * left / 2.0) * 2.0, BAR.y)), colour)
