class_name Effects
extends RefCounted
## One-shot particle bursts: "hit" sparks, a "poof" when an enemy is beaten, a "sparkle"
## when something is collected.

const SPARK := preload("res://assets/sprites/spark.png")


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
	label.position = pos + Vector2(-120, -40)
	label.size = Vector2(240, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60.0, 1.1)
	tween.tween_property(label, "modulate:a", 0.0, 1.1).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


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
