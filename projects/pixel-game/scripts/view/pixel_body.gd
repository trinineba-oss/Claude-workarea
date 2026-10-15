class_name PixelBody
extends Sprite3D
## An animated pixel-art body for a character in the 2.5D view (a sheet from Looks). It reads
## what the 2D character is doing and picks the animation and facing to match: walking or
## standing, Chad's cutlass swing and flinch, Evey sitting (Stay) or biting, fliers flapping.
## Squash, flashes and blinks are copied from the 2D sprite, and so is a flier's height.

## World units per sheet pixel: a 46 px tall LPC person stands about 1.25 tiles tall.
const SCALE := 0.029
## Feet sit this many pixels above the bottom of a 64 px frame.
const FOOT := 4.0
const WALK_FPS := 10.0
const IDLE_FPS := 2.5
## Moving slower than this (2D pixels per second) counts as standing still.
const MOVING := 18.0
## How close (2D px) Chad has to be for people and top dogs to turn to him.
const LOOK_RANGE := 230.0

var sheet := ""
var anim_name := "idle"
## How many times bigger than the sheet's usual size (the Big Blue Crab).
var size := 1.0
var facing := Vector2.DOWN

var _time := 0.0
var _last := Vector2.INF
var _fliers := false
## Seconds left in which the body counts as moving (frames can pass without a physics step).
var _moving_hold := 0.0
var _velocity := Vector2.ZERO


func setup(sheet_name: String, source: Node2D) -> void:
	sheet = sheet_name
	texture = Looks.texture(sheet)
	size = Looks.size_for(source)
	hframes = int(texture.get_width() / 64.0)
	vframes = int(texture.get_height() / 64.0)
	pixel_size = SCALE
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	shaded = true
	double_sided = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_fliers = source is Corbeau
	if source is TopDog or source is Companion:
		facing = Vector2.RIGHT


## `body` is the 2D sprite this replaces (for squash, flashes and height); may be null.
func update(source: Node2D, body: Sprite2D, delta: float) -> void:
	var pos := source.global_position
	var velocity := _velocity
	var moving := false
	if source is CharacterBody2D:
		# A character body knows its own velocity: no guessing from positions.
		velocity = source.velocity
		moving = velocity.length() > MOVING
	else:
		if _last != Vector2.INF and delta > 0.0 and pos != _last:
			velocity = (pos - _last) / delta
		if velocity.length() > MOVING and pos != _last:
			_moving_hold = 0.12
			_velocity = velocity
		else:
			_moving_hold -= delta
			if _moving_hold <= 0.0:
				_velocity = Vector2.ZERO
		moving = _moving_hold > 0.0
		velocity = _velocity
	_last = pos
	_time += delta
	_choose(source, velocity, moving)
	_show_frame(source, velocity)
	var lift := 0.0
	if body != null:
		visible = body.visible
		modulate = body.modulate * body.self_modulate
		scale = Vector3(absf(body.scale.x), absf(body.scale.y), 1.0)
		if _fliers:
			lift = -body.position.y * View3D.PX
	position = Vector3(0, (32.0 - FOOT) * SCALE * scale.y + lift, 0)


func _choose(source: Node2D, velocity: Vector2, moving: bool) -> void:
	if moving and absf(velocity.x) + absf(velocity.y) > 0.0:
		facing = velocity
	var next := "walk" if moving else "idle"
	if source is Player:
		facing = source.facing
		match source.state:
			Player.State.ATTACK:
				next = "slash"
			Player.State.HURT:
				next = "hurt"
		if source.health <= 0:
			next = "hurt"
	elif source is Companion:
		if source.mode == Companion.Mode.STAY:
			next = "sit"
		elif float(source.get("_bite_cooldown")) > Companion.BITE_COOLDOWN - 0.3:
			next = "bite"
	elif source is Npc or source is TopDog:
		var player := source.get_tree().get_first_node_in_group("player") as Node2D
		if player != null and not moving:
			var to := player.global_position - source.global_position
			if to.length() < LOOK_RANGE:
				facing = Vector2(signf(to.x), 0) if source is TopDog else to
	elif _fliers or source is Soucouyant:
		next = "walk"
	if Looks.anim(sheet, next).is_empty():
		next = "walk" if moving else "idle"
	if next != anim_name:
		anim_name = next
		_time = 0.0


func _show_frame(source: Node2D, velocity: Vector2) -> void:
	var layout := Looks.anim(sheet, anim_name)
	if layout.is_empty():
		layout = Looks.anim(sheet, "walk")
		if layout.is_empty():
			return
	var frames: int = layout["frames"]
	var col := 0
	match anim_name:
		"walk":
			var speed := clampf(velocity.length() / 180.0, 0.7, 1.7)
			if frames == 9:
				col = 1 + int(_time * WALK_FPS * speed) % 8  # LPC: frame 0 is the standing pose
			else:
				col = int(_time * WALK_FPS * speed) % frames
		"idle":
			col = int(_time * IDLE_FPS) % frames
		"slash":
			var left: float = source.get("_state_time")
			col = int(clampf(1.0 - left / Player.ATTACK_TIME, 0.0, 0.999) * frames)
		"hurt":
			col = frames - 1 if source.get("health") == 0 else int(_time * 18.0) % frames
		"bite":
			col = mini(int(_time * 10.0), frames - 1)
		_:
			col = 0
	var row: int = layout["row"]
	if int(layout["rows"]) == 4:
		row += Looks.direction_index(facing)
	frame = row * hframes + mini(col, hframes - 1)
