class_name DayNight
extends Node
## The game clock. Tints the world through dawn, day, dusk and night (the HUD is not
## affected), and tells night lights how strong to shine.

signal minute_changed(hour: float)

## Real seconds for a full 24-hour day.
const SECONDS_PER_DAY := 720.0
## Hour -> world tint. Interpolated in between; wraps at midnight.
const TINTS := [
	[0.0, Color(0.3, 0.34, 0.58)],
	[5.0, Color(0.36, 0.38, 0.62)],
	[6.5, Color(1.0, 0.76, 0.6)],
	[8.5, Color(1.0, 1.0, 1.0)],
	[16.5, Color(1.0, 1.0, 1.0)],
	[18.0, Color(1.0, 0.72, 0.54)],
	[19.5, Color(0.56, 0.44, 0.7)],
	[21.0, Color(0.3, 0.34, 0.58)],
	[24.0, Color(0.3, 0.34, 0.58)],
]

## The clock currently in play, for lights and other nodes that react to the time.
static var current: DayNight

## 0.0 to 24.0.
var hour := 7.0
var seconds_per_day := SECONDS_PER_DAY

var _modulate: CanvasModulate
var _last_minute := -1


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


func _ready() -> void:
	_modulate = CanvasModulate.new()
	add_child(_modulate)
	set_hour(hour)


func _process(delta: float) -> void:
	set_hour(hour + 24.0 * delta / seconds_per_day)


func set_hour(value: float) -> void:
	hour = fposmod(value, 24.0)
	if _modulate != null:
		_modulate.color = tint_at(hour)
	var minute := int(hour * 60.0)
	if minute != _last_minute:
		_last_minute = minute
		minute_changed.emit(hour)


## How dark it is: 0 in daylight, 1 at night, ramping through dawn and dusk.
func night_amount() -> float:
	return night_amount_at(hour)


func is_night() -> bool:
	return night_amount() > 0.5


static func night_amount_at(h: float) -> float:
	if h < 5.0 or h >= 19.5:
		return 1.0
	if h < 6.5:
		return 1.0 - (h - 5.0) / 1.5
	if h >= 17.5:
		return (h - 17.5) / 2.0
	return 0.0


static func tint_at(h: float) -> Color:
	for i in TINTS.size() - 1:
		var a: Array = TINTS[i]
		var b: Array = TINTS[i + 1]
		if h >= a[0] and h <= b[0]:
			return (a[1] as Color).lerp(b[1], (h - a[0]) / (b[0] - a[0]))
	return Color.WHITE


static func clock_text(h: float) -> String:
	var total := int(h * 60.0)
	var hours := (total / 60) % 24
	var shown := hours % 12
	return "%d:%02d %s" % [12 if shown == 0 else shown, total % 60, "AM" if hours < 12 else "PM"]
