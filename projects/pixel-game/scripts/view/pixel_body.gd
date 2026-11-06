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
## How far (2D px) one full walk or run cycle carries a person; the cycle follows the distance
## moved, so feet don't slide. Dogs take shorter strides.
const CYCLE_PX := {"walk": 150.0, "run": 190.0}
const DOG_STRIDE := 0.75
## A dog moving faster than this (2D px a second) gallops, if its sheet has a "run".
const RUN_SPEED := 290.0
## Turning between side-on and up/down needs this much more of one than the other, so moving
## along a diagonal doesn't flicker between the two.
const TURN_MARGIN := 1.25
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
## Walk and run cycles advance by distance, through this phase (in frames).
var _phase := 0.0
## Row family for mirrored sheets: "up", "side" or "down"; and whether to flip for facing left.
var _dir := "down"
var _flip := false
var _last := Vector2.INF
var _fliers := false
## Seconds left in which the body counts as moving (frames can pass without a physics step).
var _moving_hold := 0.0
var _velocity := Vector2.ZERO


func setup(sheet_name: String, source: Node2D) -> void:
	sheet = sheet_name
	texture = Looks.texture(sheet)
	size = Looks.size_for(source)
	var cell := float(Looks.frame_size(sheet))
	hframes = int(texture.get_width() / cell)
	vframes = int(texture.get_height() / cell)
	# Bigger frames hold finer art at the same size in the world.
	pixel_size = SCALE * 64.0 / cell
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	if Looks.is_smooth(sheet):
		# Painted art: smooth filtering and soft edges.
		texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	else:
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
	_advance(source, velocity, delta)
	_show_frame(source)
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
		# Moving: face the way he goes (diagonals too); standing: the way he last faced.
		facing = velocity if moving else source.facing
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
		elif not moving and source.mode == Companion.Mode.DIG and _has("dig"):
			next = "dig"
		elif float(source.get("_bite_cooldown")) > Companion.BITE_COOLDOWN - 0.3:
			next = "bite"
		elif not moving and _sniffing(source):
			next = "sniff"
	elif source is Npc or source is TopDog:
		var player := source.get_tree().get_first_node_in_group("player") as Node2D
		if player != null and not moving:
			var to := player.global_position - source.global_position
			if to.length() < LOOK_RANGE:
				facing = Vector2(signf(to.x), 0) if source is TopDog else to
	elif _fliers or source is Soucouyant:
		next = "walk"
	if next == "walk" and velocity.length() > RUN_SPEED and _has("run"):
		next = "run"
	if Looks.anim(sheet, next).is_empty():
		next = "walk" if moving else "idle"
	if next != anim_name:
		# Walk and run share a cycle: keep the step going when switching between them.
		var striding := next in ["walk", "run"] and anim_name in ["walk", "run"]
		anim_name = next
		_time = 0.0
		if not striding:
			_phase = 0.0
	_turn(facing)


func _has(anim: String) -> bool:
	return not Looks.anim(sheet, anim).is_empty()


## Picks the row family (up, side or down) and the flip, with a margin against flicker.
func _turn(direction: Vector2) -> void:
	var ax := absf(direction.x)
	var ay := absf(direction.y)
	if ax + ay < 0.001:
		return
	if _dir == "side":
		if ay > ax * TURN_MARGIN:
			_dir = "up" if direction.y < 0.0 else "down"
	elif ax > ay * TURN_MARGIN:
		_dir = "side"
	else:
		_dir = "up" if direction.y < 0.0 else "down"
	if ax > 0.25 * (ax + ay):
		_flip = direction.x < 0.0


## Moves walk and run cycles on by the distance travelled this frame.
func _advance(source: Node2D, velocity: Vector2, delta: float) -> void:
	if not anim_name in CYCLE_PX:
		return
	var layout := Looks.anim(sheet, anim_name)
	if layout.is_empty():
		return
	var cycle: float = CYCLE_PX[anim_name] * (DOG_STRIDE if _is_dog(source) else 1.0)
	_phase += velocity.length() * delta / cycle * _row_frames(layout)


static func _is_dog(source: Node2D) -> bool:
	return source is Companion or source is TopDog or source is Pothound


## Frames in the row being shown (rows of a mirrored sheet can differ in length).
func _row_frames(layout: Dictionary) -> int:
	if layout.has("counts") and bool(layout.get("mirror", false)):
		return int(layout["counts"][["up", "side", "down"].find(_dir)])
	return int(layout["frames"])


## Evey noses the ground while digging and for a moment after catching a buried scent.
func _sniffing(dog: Node2D) -> bool:
	if dog.mode == Companion.Mode.DIG:
		return true
	return float(dog.get("_sniff_cooldown")) > Companion.SNIFF_EVERY - 1.2


func _show_frame(source: Node2D) -> void:
	var layout := Looks.anim(sheet, anim_name)
	if layout.is_empty():
		layout = Looks.anim(sheet, "walk")
		if layout.is_empty():
			return
	var frames := _row_frames(layout)
	var col := 0
	match anim_name:
		"walk", "run":
			if frames == 9:
				col = 1 + int(_phase * 8.0 / 9.0) % 8  # LPC: frame 0 is the standing pose
			else:
				col = int(_phase) % frames
		"idle":
			col = int(_time * IDLE_FPS) % frames
		"slash":
			var left: float = source.get("_state_time")
			col = int(clampf(1.0 - left / Player.ATTACK_TIME, 0.0, 0.999) * frames)
		"hurt":
			col = frames - 1 if source.get("health") == 0 else int(_time * 18.0) % frames
		"bite":
			col = mini(int(_time * 10.0), frames - 1)
		"sniff", "dig":
			col = int(_time * (3.0 if anim_name == "sniff" else 8.0)) % frames
		_:
			col = 0
	var row: int = layout["row"]
	if bool(layout.get("mirror", false)):
		# Drawn facing right with up, side and down rows; flipped when facing left.
		row += ["up", "side", "down"].find(_dir)
		flip_h = _flip
	elif int(layout["rows"]) == 4:
		row += Looks.direction_index(facing)
		flip_h = false
	frame = row * hframes + mini(col, hframes - 1)
