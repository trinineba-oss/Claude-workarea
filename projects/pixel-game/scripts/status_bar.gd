class_name StatusBar
extends Control
## Health ("doubles", two halves each) and money, drawn at the top left.

const STEP := 11.0
const BARA := Color("eec470")
const BARA_EDGE := Color("6e461e")
const CURRY := Color("e26e1e")
const EMPTY := Color(0.2, 0.15, 0.2, 0.7)

var _health := 6
var _max_health := 6
var _money := 0


func _draw() -> void:
	for i in _max_health / 2:
		_draw_double(Vector2(5.0 + i * STEP, 6.0), clampi(_health - i * 2, 0, 2))
	var font := ThemeDB.fallback_font
	draw_string(
		font, Vector2(2, 25), "TT$ %d" % _money, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.BLACK
	)
	draw_string(
		font, Vector2(1, 24), "TT$ %d" % _money, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE
	)


func set_health(health: int, max_health: int) -> void:
	_health = health
	_max_health = max_health
	queue_redraw()


func set_money(money: int) -> void:
	_money = money
	queue_redraw()


func _draw_double(center: Vector2, halves: int) -> void:
	draw_circle(center + Vector2(0, 2), 4.5, BARA_EDGE if halves > 0 else EMPTY)
	if halves > 0:
		draw_circle(center + Vector2(0, 2), 3.5, BARA)
		draw_rect(Rect2(center + Vector2(-3, 1), Vector2(6, 2)), CURRY)
	draw_circle(center + Vector2(0, -2), 4.5, BARA_EDGE if halves > 1 else EMPTY)
	if halves > 1:
		draw_circle(center + Vector2(0, -2), 3.5, BARA)
