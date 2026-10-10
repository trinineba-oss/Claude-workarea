class_name Wires
extends Node2D
## Sagging overhead power lines, drawn above everything else in the room.

const COLOR := Color(0.12, 0.1, 0.14, 0.85)
const SAG := 34.0

var _spans: Array = []


func _ready() -> void:
	z_index = 8


func add_span(from: Vector2, to: Vector2) -> void:
	for offset in [-22.0, 0.0, 22.0]:
		_spans.append([from + Vector2(offset, 0), to + Vector2(offset, 0)])
	queue_redraw()


func _draw() -> void:
	for span in _spans:
		var a: Vector2 = span[0]
		var b: Vector2 = span[1]
		var points := PackedVector2Array()
		for i in 17:
			var t := i / 16.0
			var sag := 4.0 * t * (1.0 - t) * SAG * (1.0 + a.distance_to(b) / 600.0)
			points.append(a.lerp(b, t) + Vector2(0, sag))
		draw_polyline(points, COLOR, 2.0, true)
