class_name Effects
extends RefCounted
## One-shot particle bursts: "hit" sparks, a "poof" when an enemy is beaten, a "sparkle"
## when something is collected.

const SPARK := preload("res://assets/sprites/spark.png")


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
	parent.add_child.call_deferred(p)
