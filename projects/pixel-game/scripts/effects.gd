class_name Effects
extends RefCounted
## One-shot effects: particle bursts ("hit" sparks, a "poof" when an enemy is beaten, a
## "sparkle" when something is collected, "dust"), sprite-sheet flourishes (assets/vfx), the
## cutlass's slash marks and floating text.

const SPARK := preload("res://assets/sprites/spark.png")
const VFX_SHEETS := "res://assets/vfx/crisp_juice/sheets.json"
const VFX_TEXTURE := "res://assets/vfx/crisp_juice/%s.png"

## Pixel effect sheets from the Ninja Adventure pack (assets/ninja/fx, CC0): texture, frames.
const SHEETS := {
	"slash_arc": [preload("res://assets/ninja/fx/slash_arc.png"), 6],
	"slash_spin": [preload("res://assets/ninja/fx/slash_spin.png"), 7],
	"smoke": [preload("res://assets/ninja/fx/smoke.png"), 6],
}
## Debris strips: each frame is a different piece.
const DEBRIS := {
	"leaf": [preload("res://assets/ninja/fx/leaf.png"), 6],
	"wood": [preload("res://assets/ninja/fx/wood.png"), 6],
	"grass": [preload("res://assets/ninja/fx/grass.png"), 6],
}

static var _vfx: Dictionary


## A short message that floats up from a point in the world and fades ("+2 Mango").
static func float_text(parent: Node, pos: Vector2, text: String, color := Color.WHITE) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var label := Label.new()
	label.text = text
	label.z_index = 20
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.14))
	label.add_theme_constant_override("outline_size", 8)
	label.position = pos + Vector2(-240, -40)
	label.size = Vector2(480, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60.0, 1.1)
	tween.tween_property(label, "modulate:a", 0.0, 1.1).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


## A sprite-sheet flourish played once at a point: "ring_shockwave_white",
## "star_burst_gold" or "coin_burst_gold". `size` in tiles; `height` in tiles above `pos`.
static func flourish(
	parent: Node, pos: Vector2, sheet_name: String, size := 1.6, height := 0.6
) -> Sprite2D:
	if parent == null or not parent.is_inside_tree():
		return null
	if _vfx.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VFX_SHEETS))
		_vfx = parsed if parsed is Dictionary else {}
	var info: Dictionary = _vfx.get(sheet_name, {})
	if info.is_empty():
		return null
	var sprite := Sprite2D.new()
	sprite.name = "Vfx_" + sheet_name
	sprite.texture = load(VFX_TEXTURE % sheet_name)
	sprite.hframes = int(info["cols"])
	sprite.vframes = int(info["rows"])
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * size * WorldMap.TILE / float(info["cell"])
	sprite.position = pos - Vector2(0, height * WorldMap.TILE)
	sprite.z_index = 20
	parent.add_child(sprite)
	var frames := int(info["frames"])
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "frame", frames - 1, frames / float(info["fps"])).from(0)
	tween.tween_callback(sprite.queue_free)
	return sprite


## A slash mark over something the cutlass hit, curving away from the swing's origin `from`
## (an animated pixel arc). The finisher's (`heavy`) is bigger and gold.
static func slash_arc(parent: Node, at: Vector2, from: Vector2, heavy: bool) -> Sprite2D:
	var away := (at - from).normalized() if at != from else Vector2.RIGHT
	var arc := play_sheet(parent, "slash_arc", at + Vector2(0, -30), 2.6 if heavy else 2.0, 0.24)
	if arc != null:
		arc.name = "SlashArc"
		# The sheet's arc bulges downwards: turn that bulge to face away from Chad.
		arc.rotation = away.angle() - PI / 2.0
		arc.modulate = Color(1.0, 0.85, 0.45) if heavy else Color.WHITE
	return arc


## The spin attack's whirl around Chad.
static func spin_slash(parent: Node, at: Vector2) -> Sprite2D:
	return play_sheet(parent, "slash_spin", at + Vector2(0, -34), 2.6, 0.32)


## Plays one of SHEETS once at a point, `size` times its pixel size, over `seconds`.
static func play_sheet(
	parent: Node, sheet_name: String, at: Vector2, size: float, seconds: float
) -> Sprite2D:
	if parent == null or not parent.is_inside_tree() or not SHEETS.has(sheet_name):
		return null
	var spec: Array = SHEETS[sheet_name]
	var sprite := Sprite2D.new()
	sprite.texture = spec[0]
	sprite.hframes = spec[1]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * size
	sprite.position = at
	sprite.z_index = 20
	parent.add_child(sprite)
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "frame", int(spec[1]) - 1, seconds).from(0)
	tween.tween_callback(sprite.queue_free)
	return sprite


## Bits flying off something hit or broken: "leaf", "wood" or "grass" pieces that burst out,
## spin, fall and fade.
static func debris(parent: Node, at: Vector2, kind: String, count := 6) -> void:
	if parent == null or not parent.is_inside_tree() or not DEBRIS.has(kind):
		return
	var spec: Array = DEBRIS[kind]
	for i in count:
		var piece := Sprite2D.new()
		piece.texture = spec[0]
		piece.hframes = spec[1]
		piece.frame = randi() % int(spec[1])
		piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		piece.scale = Vector2.ONE * 2.0
		piece.position = at + Vector2(randf_range(-10, 10), randf_range(-8, 8))
		piece.z_index = 7
		parent.add_child(piece)
		var out := Vector2.from_angle(randf() * TAU) * randf_range(30.0, 80.0)
		var up := randf_range(24.0, 56.0)
		var seconds := randf_range(0.4, 0.7)
		var tween := piece.create_tween().set_parallel(true)
		# Up and out, then down: an arc in a top-down world.
		tween.tween_property(piece, "position:x", piece.position.x + out.x, seconds)
		(
			tween
			. tween_property(
				piece, "position:y", piece.position.y + out.y * 0.5 - up, seconds * 0.4
			)
			. set_ease(Tween.EASE_OUT)
		)
		(
			tween
			. tween_property(
				piece, "position:y", piece.position.y + out.y * 0.5 + 10.0, seconds * 0.6
			)
			. set_delay(seconds * 0.4)
			. set_ease(Tween.EASE_IN)
		)
		tween.tween_property(piece, "rotation", randf_range(-4.0, 4.0), seconds)
		tween.tween_property(piece, "modulate:a", 0.0, seconds * 0.4).set_delay(seconds * 0.6)
		tween.chain().tween_callback(piece.queue_free)


## Breaks a sprite into pieces that burst outward, tumble, drop and fade (a smashed crate, a
## cut bush). The sprite itself is left alone; whoever breaks the thing removes it.
static func shatter(parent: Node, sprite: Sprite2D, pieces := 4) -> void:
	if parent == null or not parent.is_inside_tree() or sprite == null or sprite.texture == null:
		return
	var size := sprite.texture.get_size()
	var cell := (size / pieces).floor()
	var origin := (
		(parent as Node2D).to_local(sprite.global_position) if parent is Node2D else Vector2()
	)
	var top_left := sprite.offset - (size / 2.0 if sprite.centered else Vector2.ZERO)
	for y in pieces:
		for x in pieces:
			var piece := Sprite2D.new()
			piece.texture = sprite.texture
			piece.region_enabled = true
			piece.region_rect = Rect2(Vector2(x, y) * cell, cell)
			piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			piece.flip_h = sprite.flip_h
			piece.z_index = 6
			var local := top_left + (Vector2(x, y) + Vector2(0.5, 0.5)) * cell
			if sprite.flip_h:
				local.x = -local.x
			piece.position = origin + local * sprite.global_scale
			piece.scale = sprite.global_scale
			parent.add_child(piece)
			var away := (local - top_left - size / 2.0).normalized()
			if away == Vector2.ZERO:
				away = Vector2.UP
			var fly := away * randf_range(40.0, 110.0) + Vector2(0, randf_range(10.0, 40.0))
			var seconds := randf_range(0.45, 0.7)
			var tween := piece.create_tween().set_parallel(true)
			tween.tween_property(piece, "position", piece.position + fly, seconds).set_ease(
				Tween.EASE_OUT
			)
			tween.tween_property(piece, "rotation", randf_range(-3.0, 3.0), seconds)
			tween.tween_property(piece, "modulate:a", 0.0, seconds * 0.6).set_delay(seconds * 0.4)
			tween.chain().tween_callback(piece.queue_free)


static func burst(parent: Node, pos: Vector2, kind: String) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	if kind == "poof":
		play_sheet(parent, "smoke", pos, 2.4, 0.42)
		return
	var p := CPUParticles2D.new()
	p.texture = SPARK
	p.one_shot = true
	p.explosiveness = 1.0
	p.position = pos
	p.z_index = 2
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	var ramp := Gradient.new()
	match kind:
		"hit":
			p.amount = 10
			p.lifetime = 0.3
			p.initial_velocity_min = 260.0
			p.initial_velocity_max = 440.0
			p.scale_amount_min = 0.35
			p.scale_amount_max = 0.6
			ramp.set_color(0, Color(1, 1, 1, 1))
			ramp.set_color(1, Color(1, 0.85, 0.3, 0))
		"poof":
			p.amount = 14
			p.lifetime = 0.6
			p.initial_velocity_min = 60.0
			p.initial_velocity_max = 170.0
			p.damping_min = 150.0
			p.damping_max = 220.0
			p.scale_amount_min = 1.0
			p.scale_amount_max = 1.8
			ramp.set_color(0, Color(0.92, 0.9, 0.96, 0.9))
			ramp.set_color(1, Color(0.8, 0.78, 0.86, 0))
		"dust":
			p.amount = 8
			p.lifetime = 0.4
			p.initial_velocity_min = 40.0
			p.initial_velocity_max = 110.0
			p.damping_min = 120.0
			p.damping_max = 200.0
			p.scale_amount_min = 0.5
			p.scale_amount_max = 0.9
			ramp.set_color(0, Color(0.85, 0.8, 0.7, 0.8))
			ramp.set_color(1, Color(0.75, 0.7, 0.62, 0))
		_:
			p.amount = 8
			p.lifetime = 0.45
			p.initial_velocity_min = 90.0
			p.initial_velocity_max = 180.0
			p.gravity = Vector2(0, -120)
			p.scale_amount_min = 0.3
			p.scale_amount_max = 0.5
			ramp.set_color(0, Color(1, 0.95, 0.5, 1))
			ramp.set_color(1, Color(1, 0.8, 0.2, 0))
	p.color_ramp = ramp
	p.finished.connect(p.queue_free)
	p.emitting = true
	parent.add_child(p)
