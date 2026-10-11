class_name StatusBar
extends Control
## Health ("doubles", two halves each), money and the clock, drawn at the top left, plus
## small keys while in a dungeon.

const DOUBLE := preload("res://assets/sprites/snack.png")
const COIN := preload("res://assets/sprites/coin.png")
const KEY := preload("res://assets/sprites/key.png")
const BOSS_KEY := preload("res://assets/sprites/pepper_key.png")
const STEP := 56.0
const EMPTY := Color(0.1, 0.06, 0.14, 0.45)
const FONT_SIZE := 30

var _health := 6
var _max_health := 6
var _money := 0
var _hour := 7.0
var _day := 1
var _keys := -1
var _boss_key := false


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
	var clock_at := Vector2(0, money_at.y + COIN.get_height() + 12)
	_draw_clock(clock_at)
	if _keys >= 0:
		var key_at := clock_at + Vector2(0, 42)
		draw_texture(KEY, key_at)
		var key_text := "x %d" % _keys
		var key_text_at := key_at + Vector2(KEY.get_width() + 8, KEY.get_height() * 0.78)
		draw_string_outline(
			font,
			key_text_at,
			key_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			26,
			6,
			Color(0.1, 0.06, 0.14)
		)
		draw_string(font, key_text_at, key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
		if _boss_key:
			draw_texture(BOSS_KEY, key_at + Vector2(96, -4))


func set_health(health: int, max_health: int) -> void:
	_health = health
	_max_health = max_health
	queue_redraw()


func set_time(hour: float) -> void:
	_hour = hour
	queue_redraw()


func set_day(day: int) -> void:
	_day = day
	queue_redraw()


## Small keys held in this dungeon (-1 hides the counter, outdoors), and the boss key.
func set_keys(count: int, boss_key := false) -> void:
	_keys = count
	_boss_key = boss_key
	queue_redraw()


func set_money(money: int) -> void:
	_money = money
	queue_redraw()


func _draw_clock(at: Vector2) -> void:
	var centre := at + Vector2(18, 16)
	if DayNight.night_amount_at(_hour) > 0.5:
		draw_circle(centre, 13.0, Color(0.95, 0.94, 0.82))
		draw_circle(centre + Vector2(6, -4), 11.0, Color(0.1, 0.08, 0.2))
	else:
		draw_circle(centre, 11.0, Color(1.0, 0.82, 0.25))
		for i in 8:
			var d := Vector2.from_angle(i * TAU / 8.0)
			draw_line(centre + d * 14.0, centre + d * 19.0, Color(1.0, 0.82, 0.25), 3.0)
	var font := ThemeDB.fallback_font
	var text := "Day %d  %s" % [_day, DayNight.clock_text(_hour)]
	var text_at := at + Vector2(44, 26)
	draw_string_outline(
		font, text_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 6, Color(0.1, 0.06, 0.14)
	)
	draw_string(font, text_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
