class_name StatusBar
extends Control
## Health ("doubles", two halves each) and money, drawn at the top left.

const DOUBLE := preload("res://assets/sprites/snack.png")
const COIN := preload("res://assets/sprites/coin.png")
const STEP := 56.0
const EMPTY := Color(0.1, 0.06, 0.14, 0.45)
const FONT_SIZE := 30

var _health := 6
var _max_health := 6
var _money := 0


func _draw() -> void:
	var size := DOUBLE.get_size()
	for i in _max_health / 2:
		var at := Vector2(i * STEP, 0)
		var halves := clampi(_health - i * 2, 0, 2)
		draw_texture(DOUBLE, at, EMPTY)
		if halves == 2:
			draw_texture(DOUBLE, at)
		elif halves == 1:
			var half := Rect2(Vector2.ZERO, Vector2(size.x / 2.0, size.y))
			draw_texture_rect_region(DOUBLE, Rect2(at, half.size), half)
	var font := ThemeDB.fallback_font
	var money_at := Vector2(0, size.y + 10)
	draw_texture(COIN, money_at)
	var text_at := money_at + Vector2(COIN.get_width() + 8, COIN.get_height() * 0.8)
	var text := "TT$ %d" % _money
	draw_string_outline(
		font, text_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 6, Color(0.1, 0.06, 0.14)
	)
	draw_string(font, text_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)


func set_health(health: int, max_health: int) -> void:
	_health = health
	_max_health = max_health
	queue_redraw()


func set_money(money: int) -> void:
	_money = money
	queue_redraw()
