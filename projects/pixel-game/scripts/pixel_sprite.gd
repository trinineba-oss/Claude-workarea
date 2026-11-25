class_name PixelSprite
extends Sprite2D
## An animated pixel-art body for a character (a sheet from Looks), drawn in place of its plain
## 2D sprite. It sits under that sprite, so it inherits its bob, squash, tilt, fades and
## blinks, and reads what the character is doing to pick the animation and facing: walking or
## standing, Chad's cutlass swing and flinch, Evey sitting (Stay) or digging, fliers flapping.
## It also adds the hit reactions: enemies flash white, squash and lean back when hit, and
## Chad leaves fading afterimages while he rolls.

## Screen pixels per sheet pixel: the pixel grid is 2x (a 64 px tile is 32 art pixels).
const ART_SCALE := 2.0
## Feet sit this many pixels above the bottom of a frame.
const FOOT := 4.0
const IDLE_FPS := 2.5
## How far (px) one full walk or run cycle carries a person; the cycle follows the distance
## moved, so feet don't slide. Dogs take shorter strides.
const CYCLE_PX := {"walk": 150.0, "run": 190.0}
const DOG_STRIDE := 0.75
## A dog moving faster than this (px a second) gallops, if its sheet has a "run".
const RUN_SPEED := 290.0
## Chad breaks into a run above this speed, if his sheet has a "run".
const PERSON_RUN := 200.0
## Evey left standing (or staying) this long lies down, and this long falls asleep.
const LIE_AFTER := 8.0
const SLEEP_AFTER := 16.0
## Turning between side-on and up/down needs this much more of one than the other, so moving
## along a diagonal doesn't flicker between the two.
const TURN_MARGIN := 1.25
## Moving slower than this (px a second) counts as standing still.
const MOVING := 18.0
## How close (px) Chad has to be for people and top dogs to turn to him.
const LOOK_RANGE := 230.0
## Hit reactions: the white flash, the squash and lean, and roll afterimages.
const FLASH_TIME := 0.09
const SQUASH_TIME := 0.22
const LEAN_PX := 8.0
const GHOST_EVERY := 0.04
const GHOST_FADE := 0.24
const GHOST_TINT := Color(0.55, 0.85, 1.0)
const FLASH_SHADER := preload("res://shaders/pixel_flash.gdshader")

var sheet := ""
var anim_name := "idle"
var facing := Vector2.DOWN
## The character this draws.
var source: Node2D

var _size := 1.0
var _time := 0.0
## Walk and run cycles advance by distance, through this phase (in frames).
var _phase := 0.0
## Row family for mirrored sheets: "up", "side" or "down"; and whether to flip for facing left.
var _dir := "down"
var _flip := false
var _last := Vector2.INF
var _moving_hold := 0.0
var _velocity := Vector2.ZERO
var _still := 0.0
var _flash := 0.0
var _ghost_clock := 0.0
var _squash := 0.0
var _away := Vector2.ZERO
var _last_health := -1
var _ghost_mat: ShaderMaterial


func setup(sheet_name: String, character: Node2D) -> void:
	sheet = sheet_name
	source = character
	name = "PixelSprite"
	texture = Looks.texture(sheet)
	_size = Looks.size_for(character)
	var cell := float(Looks.frame_size(sheet))
	hframes = int(texture.get_width() / cell)
	vframes = int(texture.get_height() / cell)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = true
	offset = Vector2(0, -(cell / 2.0 - FOOT))
	material = ShaderMaterial.new()
	material.shader = FLASH_SHADER
	if character is TopDog or character is Companion:
		facing = Vector2.RIGHT
	_apply_scale()


func _process(delta: float) -> void:
	if source == null or not is_instance_valid(source):
		return
	var pos := source.global_position
	var velocity := _velocity
	var moving := false
	if source is CharacterBody2D:
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
	_choose(velocity, moving, delta)
	_advance(velocity, delta)
	_show_frame()
	_react_to_hits(delta)
	_apply_scale()
	if source is Player and source.state == Player.State.DODGE:
		_ghost_clock -= delta
		if _ghost_clock <= 0.0:
			_ghost_clock = GHOST_EVERY
			spawn_ghost()
	else:
		_ghost_clock = 0.0


func _apply_scale() -> void:
	var s := _squash * _squash
	scale = Vector2(1.0 + 0.3 * s, 1.0 - 0.26 * s) * ART_SCALE * _size
	position = _away * LEAN_PX * s


func _choose(velocity: Vector2, moving: bool, delta: float) -> void:
	if moving and absf(velocity.x) + absf(velocity.y) > 0.0:
		facing = velocity
	var next := "walk" if moving else "idle"
	if source is Player:
		facing = velocity if moving else source.facing
		match source.state:
			Player.State.ATTACK:
				# The move's own animation (a jab is a thrust, a hook a halfslash...).
				next = str(source.current_move.get("anim", "slash"))
				if not _has(next):
					next = "slash"
				facing = source.aim
			Player.State.CHARGE:
				next = "charge"
				facing = source.aim
			Player.State.DODGE:
				next = "roll" if _has("roll") else "walk"
				facing = velocity
			Player.State.HURT:
				next = "hurt"
			Player.State.NORMAL:
				if moving and velocity.length() > PERSON_RUN and _has("run"):
					next = "run"
				elif not moving and source.pose_time > 0.0 and _has(source.pose):
					next = source.pose
				elif not moving and source.weapon_id() == Weapons.FISTS and _trouble_near():
					next = "combat_idle"  # fists up
		if source.health <= 0:
			next = "faint" if _has("faint") else "hurt"
	elif source is Companion:
		_still = 0.0 if moving else _still + delta
		if bool(source.get("_swimming")) and _has("swim"):
			next = "swim"
		elif source.mode == Companion.Mode.STAY:
			next = "lie" if _still > LIE_AFTER * 1.5 and _has("lie") else "sit"
		elif not moving and source.mode == Companion.Mode.DIG and _has("dig"):
			next = "dig"
		elif not moving and _still > SLEEP_AFTER and _has("sleep"):
			next = "sleep"
		elif not moving and _still > LIE_AFTER and _has("lie"):
			next = "lie"
	elif source is Npc or source is TopDog:
		var player := source.get_tree().get_first_node_in_group("player") as Node2D
		if player != null and not moving:
			var to := player.global_position - source.global_position
			if to.length() < LOOK_RANGE:
				facing = Vector2(signf(to.x), 0) if source is TopDog else to
	elif source is Corbeau or source is Soucouyant:
		next = "walk"
	if next == "walk" and velocity.length() > RUN_SPEED and _has("run"):
		next = "run"
	if next == "charge" and _has("backslash"):
		pass  # the wind-up frame of the backslash, held (see _show_frame)
	elif Looks.anim(sheet, next).is_empty():
		next = "walk" if moving else "idle"
	if next != anim_name:
		var striding := next in ["walk", "run"] and anim_name in ["walk", "run"]
		anim_name = next
		_time = 0.0
		if not striding:
			_phase = 0.0
	_turn(facing)


func _trouble_near() -> bool:
	for node in source.get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node2D
		if enemy != null and enemy.global_position.distance_to(source.global_position) < 360.0:
			return true
	return false


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
func _advance(velocity: Vector2, delta: float) -> void:
	if not anim_name in CYCLE_PX:
		return
	var layout := Looks.anim(sheet, anim_name)
	if layout.is_empty():
		return
	var dog := source is Companion or source is TopDog or source is Pothound
	var cycle: float = CYCLE_PX[anim_name] * (DOG_STRIDE if dog else 1.0)
	_phase += velocity.length() * delta / cycle * _row_frames(layout)


## Frames in the row being shown (rows of a mirrored sheet can differ in length).
func _row_frames(layout: Dictionary) -> int:
	if layout.has("counts") and bool(layout.get("mirror", false)):
		return int(layout["counts"][["up", "side", "down"].find(_dir)])
	return int(layout["frames"])


func _show_frame() -> void:
	var layout := Looks.anim(sheet, "backslash" if anim_name == "charge" else anim_name)
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
		"slash", "thrust", "halfslash", "backslash":
			var left: float = source.get("_state_time")
			col = int(clampf(1.0 - left / float(source.get("attack_time")), 0.0, 0.999) * frames)
		"charge":
			col = 2 + int(_time * 12.0) % 2  # wound up, trembling
		"combat_idle":
			col = int(_time * 3.0) % frames
		"roll":
			var left: float = source.get("_state_time")
			col = int(clampf(1.0 - left / Player.DODGE_TIME, 0.0, 0.999) * frames)
		"hurt":
			col = frames - 1 if source.get("health") == 0 else int(_time * 18.0) % frames
		"eat":
			col = mini(int(_time * 3.5), frames - 1)
		"fish":
			var step := int(_time * 6.0)
			col = step if step < frames - 2 else frames - 2 + int(_time * 2.0) % 2
		"swim":
			col = int(_time * 6.0) % frames
		"sleep":
			col = 0 if _time < 1.5 else frames - 1
		"dig", "sniff":
			col = int(_time * (8.0 if anim_name == "dig" else 3.0)) % frames
		_:
			col = 0
	var row: int = layout["row"]
	flip_h = false
	if bool(layout.get("mirror", false)):
		row += ["up", "side", "down"].find(_dir)
		flip_h = _flip
	elif int(layout["rows"]) == 4:
		row += Looks.direction_index(facing)
	frame = row * hframes + mini(col, hframes - 1)


## Starts the white hit flash.
func flash(seconds := FLASH_TIME) -> void:
	_flash = maxf(_flash, seconds)


func is_flashing() -> bool:
	return _flash > 0.0


## Enemies: a blow (health going down) flashes them white, squashes them and leans them back,
## away from Chad.
func _react_to_hits(delta: float) -> void:
	_squash = maxf(_squash - delta / SQUASH_TIME, 0.0)
	if source is Enemy:
		var health: int = source.health
		if _last_health >= 0 and health < _last_health:
			flash()
			_squash = 1.0
			var hero := source.get_tree().get_first_node_in_group("player") as Node2D
			if hero != null:
				_away = (source.global_position - hero.global_position).normalized()
		_last_health = health
	_flash = maxf(_flash - delta, 0.0)
	(material as ShaderMaterial).set_shader_parameter("amount", 1.0 if _flash > 0.0 else 0.0)


## A fading, tinted copy of the current frame left where the body is now (Chad's roll).
func spawn_ghost() -> Sprite2D:
	var room := source.get_parent() as Node2D
	if room == null or not is_inside_tree():
		return null
	if _ghost_mat == null:
		_ghost_mat = ShaderMaterial.new()
		_ghost_mat.shader = FLASH_SHADER
		_ghost_mat.set_shader_parameter("tint", GHOST_TINT)
		_ghost_mat.set_shader_parameter("amount", 0.55)
	var ghost := Sprite2D.new()
	ghost.name = "Afterimage"
	ghost.texture = texture
	ghost.hframes = hframes
	ghost.vframes = vframes
	ghost.frame = frame
	ghost.flip_h = flip_h
	ghost.offset = offset
	ghost.texture_filter = texture_filter
	ghost.material = _ghost_mat
	ghost.modulate = Color(1, 1, 1, 0.5)
	ghost.z_index = -1
	room.add_child(ghost)
	ghost.global_transform = global_transform
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, GHOST_FADE)
	tween.tween_callback(ghost.queue_free)
	return ghost
