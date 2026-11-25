class_name Effects
extends RefCounted
## One-shot effects: particle bursts ("hit" sparks, a "poof" when an enemy is beaten, a
## "sparkle" when something is collected, "dust"), sprite-sheet flourishes (assets/vfx), the
## cutlass's slash marks and floating text.

const SPARK := preload("res://assets/sprites/spark.png")
const VFX_SHEETS := "res://assets/vfx/crisp_juice/sheets.json"
const VFX_TEXTURE := "res://assets/vfx/crisp_juice/%s.png"

static var _vfx: Dictionary
static var _crescent: Texture2D


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


## A crescent slash mark over something the cutlass hit, bulging away from the swing's origin
## `from`: it flares out and fades. The finisher's (`heavy`) is bigger and gold.
static func slash_arc(parent: Node, at: Vector2, from: Vector2, heavy: bool) -> Sprite2D:
	if parent == null or not parent.is_inside_tree():
		return null
	var arc := Sprite2D.new()
	arc.name = "SlashArc"
	arc.texture = _crescent_texture()
	arc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arc.modulate = Color(1.0, 0.85, 0.4) if heavy else Color(0.9, 0.96, 1.0)
	arc.z_index = 20
	var away := (at - from).normalized() if at != from else Vector2.RIGHT
	arc.rotation = away.angle()
	arc.position = at + Vector2(0, -30)
	var size := 2.4 if heavy else 1.6
	arc.scale = Vector2.ONE * size
	parent.add_child(arc)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	arc.material = mat
	var tween := arc.create_tween().set_parallel(true)
	tween.tween_property(arc, "scale", Vector2.ONE * size * 1.5, 0.16).set_ease(Tween.EASE_OUT)
	tween.tween_property(arc, "modulate:a", 0.0, 0.2).set_delay(0.04)
	tween.chain().tween_callback(arc.queue_free)
	return arc


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


## A small pixel-art crescent (made once): an arc of a ring whose centre sits off the left
## edge, so it bulges towards +x, thickest in the middle and tapering at the tips.
static func _crescent_texture() -> Texture2D:
	if _crescent != null:
		return _crescent
	var size := 32
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var centre := Vector2(-10.0, size / 2.0)
	for y in size:
		for x in size:
			var offset := Vector2(x + 0.5, y + 0.5) - centre
			var spread := absf(offset.angle()) / 0.62
			var thick := 4.5 * (1.0 - spread * spread)
			var edge := absf(offset.length() - 29.0)
			var a := 1.0 if thick > 0.0 and edge < thick else 0.0
			image.set_pixel(x, y, Color(1, 1, 1, a))
	_crescent = ImageTexture.create_from_image(image)
	return _crescent


static func burst(parent: Node, pos: Vector2, kind: String) -> void:
	if parent == null or not parent.is_inside_tree():
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
