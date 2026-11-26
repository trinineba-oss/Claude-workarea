class_name Companion
extends Interactable
## Evey, Chad's beagle. She washed up on the wharf with him and is at his side from the
## first step, temples included.
##
## She is a peaceful dog: she never fights. Left to herself she follows Chad, sits when he
## stands still, sniffs at buried things nearby, catches up if she falls far behind, and
## grumbles sarcastic remarks about whatever is going on (data/evey_quips.json). She never
## gets hurt. Chad can also give her orders from the dog menu (DogMenu):
##   stay()       wait right here (heavy enough to hold down a pressure plate); come() ends it
##   fetch()      bring back the nearest coin or snack, swimming if she has to
##   dig()        sniff out the nearest buried thing (DigSpot) and dig it up

enum Mode { FOLLOW, STAY, FETCH, DIG }

const TEXTURE := preload("res://assets/sprites/evey.png")
const FOLLOW_DISTANCE := 84.0
const WALK_SPEED := 250.0
const RUN_SPEED := 330.0
## Trouble this close to Chad gets a remark.
const TROUBLE_RANGE := 300.0
## Farther than this from Chad (or in another room) and she just catches up.
const CATCH_UP_DISTANCE := 560.0
## How far from Chad she looks for things to fetch or dig up.
const SEARCH_RANGE := 8.0 * WorldMap.TILE
const DIG_TIME := 1.2
## She sniffs at a buried thing this close, now and then.
const SNIFF_RANGE := 2.5 * WorldMap.TILE
const SNIFF_EVERY := 6.0
const QUIPS_PATH := "res://data/evey_quips.json"
## She speaks at most this often, and repeats one kind of remark at most this often.
const QUIP_GAP := 5.0
const QUIP_REPEAT := 25.0
## Chad standing still this long gets a remark.
const IDLE_REMARK := 14.0
const BUBBLE_SECONDS := 2.6

static var _quips: Dictionary

var joined := false
var mode := Mode.FOLLOW
## The coin or snack she is fetching or carrying.
var carrying: Pickup
## The buried thing she is digging up.
var dig_target: DigSpot
var stay_spot := Vector2.ZERO

## The last thing she said (for tests and the speech bubble).
var last_remark := ""
var _dig_time := 0.0
var _sniff_cooldown := 0.0
var _fetch_target: Pickup
var _age := 0.0
var _moving := false
var _swimming := false
var _sprite: Sprite2D
var _carried_sprite: Sprite2D
var _shape: CollisionShape2D
var _remark_label: Label
var _remark_time := 0.0
var _quip_gap := 0.0
var _said: Dictionary = {}  # event -> seconds left before she says it again
var _last_line: Dictionary = {}  # event -> last line used
# What she was watching last frame, to notice changes.
var _seen_health := -1
var _seen_level := -1
var _seen_trouble := false
var _seen_night := false
var _seen_swimming := false
var _chad_still := 0.0


func _ready() -> void:
	super()
	add_to_group("companion")
	add_child(_shadow(Vector2(0.9, 0.8)))
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.offset = Vector2(0, -TEXTURE.get_height() / 2.0)
	add_child(_sprite)
	_carried_sprite = Sprite2D.new()
	_carried_sprite.visible = false
	_carried_sprite.scale = Vector2(0.7, 0.7)
	add_child(_carried_sprite)
	_shape = _feet_shape(Vector2(44, 20), Vector2(0, -8))
	add_child(_shape)
	bubble_height = TEXTURE.get_height() + 20.0
	collision_mask = 1


## She is with Chad: she follows and never blocks him.
func join() -> void:
	joined = true
	collision_layer = 0
	set_highlighted(false)


func can_interact(_flags: Dictionary) -> bool:
	return false


func on_talk(hero: Node2D) -> void:
	_sprite.flip_h = hero.global_position.x < global_position.x


## Puts her right behind Chad (after a warp, a faint or a long way behind) and back to
## following.
func catch_up(player: Player) -> void:
	position = _spot_behind(player)
	_reset_orders()


# --- orders --------------------------------------------------------------------------------


## Wait right here.
func stay() -> void:
	_reset_orders()
	mode = Mode.STAY
	stay_spot = position
	# Close to a pressure plate? She sits right on it.
	for plate: Node2D in get_tree().get_nodes_in_group("plates"):
		if plate.global_position.distance_to(position) < 56.0:
			stay_spot = plate.global_position
			position = stay_spot
	remark("stay")


## Stop staying and follow again.
func come() -> void:
	_reset_orders()
	remark("come")


## Fetch the nearest coin or snack. Returns false (and says so) if there is nothing.
func fetch() -> bool:
	var player := _player()
	var best: Pickup = null
	var best_distance := SEARCH_RANGE
	for node in get_tree().get_nodes_in_group("pickups"):
		var pickup := node as Pickup
		if pickup == null or pickup.is_queued_for_deletion() or player == null:
			continue
		var distance := pickup.global_position.distance_to(player.global_position)
		if distance < best_distance:
			best = pickup
			best_distance = distance
	if best == null:
		remark("fetch_nothing")
		return false
	_reset_orders()
	mode = Mode.FETCH
	_fetch_target = best
	remark("fetch")
	return true


## Sniff out the nearest buried thing and dig it up. Returns false if there is none nearby.
func dig() -> bool:
	var player := _player()
	var best: DigSpot = null
	var best_distance := SEARCH_RANGE
	for node in get_tree().get_nodes_in_group("dig_spots"):
		var spot := node as DigSpot
		if spot == null or spot.dug or player == null:
			continue
		var distance := spot.global_position.distance_to(player.global_position)
		if distance < best_distance:
			best = spot
			best_distance = distance
	if best == null:
		remark("dig_nothing")
		return false
	_reset_orders()
	mode = Mode.DIG
	dig_target = best
	_dig_time = 0.0
	remark("dig")
	return true


# --- behaviour ------------------------------------------------------------------------------


func _physics_process(delta: float) -> void:
	_sniff_cooldown = maxf(_sniff_cooldown - delta, 0.0)
	var game := get_tree().get_first_node_in_group("game") as Game
	var player := _player()
	_moving = false
	if game == null or player == null:
		return
	if not joined:
		return
	if player.frozen or player.health <= 0:
		return
	if mode != Mode.STAY and _too_far(player):
		catch_up(player)
		return
	match mode:
		Mode.STAY:
			position = stay_spot
		Mode.FETCH:
			_do_fetch(player, delta)
		Mode.DIG:
			_do_dig(delta)
		_:
			_do_follow(player, delta)
	_swimming = _on_water(game)
	_watch(game, player, delta)


func _process(delta: float) -> void:
	super(delta)
	_age += delta
	if _remark_label != null and _remark_label.visible:
		_remark_time -= delta
		_remark_label.modulate.a = clampf(_remark_time / 0.4, 0.0, 1.0)
		_remark_label.visible = _remark_time > 0.0
	_sprite.rotation = 0.0
	if mode == Mode.DIG and dig_target != null and _dig_time > 0.0:
		_sprite.position = Vector2(sin(_age * 40.0) * 3.0, 4.0)
		_sprite.scale = Vector2(1.06, 0.9)
	elif _moving:
		_sprite.position = Vector2(0, -absf(sin(_age * 14.0)) * 5.0)
		_sprite.scale = Vector2.ONE
	else:
		# Sitting and wagging.
		_sprite.position = Vector2.ZERO
		var squash := 0.72 if not joined else 0.86
		_sprite.scale = Vector2(1.0 + (1.0 - squash) * 0.5, squash)
		_sprite.rotation = sin(_age * 9.0) * 0.03 if joined else 0.0
	if _swimming:
		_sprite.position.y += 14.0
	_carried_sprite.visible = carrying != null
	var mouth_x := -34.0 if _sprite.flip_h else 34.0
	_carried_sprite.position = Vector2(mouth_x, _sprite.position.y - 26.0)


func _do_follow(player: Player, delta: float) -> void:
	_sniff_nearby()
	if position.distance_to(player.position) > FOLLOW_DISTANCE * 1.3:
		var far := position.distance_to(player.position) > FOLLOW_DISTANCE * 3.0
		_run_toward(_spot_behind(player), RUN_SPEED if far else WALK_SPEED, delta)


func _do_fetch(player: Player, delta: float) -> void:
	if carrying == null:
		if _fetch_target == null or not is_instance_valid(_fetch_target):
			_reset_orders()
			return
		_run_toward(_fetch_target.global_position, RUN_SPEED, delta, true)
		if global_position.distance_to(_fetch_target.global_position) < 36.0:
			_pick_up(_fetch_target)
		return
	_run_toward(player.global_position, RUN_SPEED, delta, true)
	if global_position.distance_to(player.global_position) < 60.0:
		_deliver(player)


func _do_dig(delta: float) -> void:
	if dig_target == null or not is_instance_valid(dig_target) or dig_target.dug:
		_reset_orders()
		return
	if global_position.distance_to(dig_target.global_position) > 20.0:
		_run_toward(dig_target.global_position, RUN_SPEED, delta, true)
		return
	_dig_time += delta
	if fmod(_dig_time, 0.3) < delta:
		Effects.burst(get_parent(), position + Vector2(0, -10), "poof")
	if _dig_time >= DIG_TIME:
		var game := get_tree().get_first_node_in_group("game") as Game
		dig_target.dig_up(game)
		_reset_orders()
		remark("dug")


func _pick_up(pickup: Pickup) -> void:
	carrying = pickup
	_fetch_target = null
	pickup.lifetime = 0.0
	_carried_sprite.texture = pickup.texture()
	pickup.get_parent().remove_child(pickup)


func _deliver(player: Player) -> void:
	var pickup := carrying
	carrying = null
	var room := player.get_parent()
	if pickup.collect(player):
		Effects.burst(room, player.position + Vector2(0, -40), "sparkle")
		pickup.free()
		remark("fetched")
	else:
		# Not needed right now (a snack at full health): she drops it at Chad's feet.
		var game := get_tree().get_first_node_in_group("game") as Game
		var at := game.current_room() if game != null else null
		if at != null:
			pickup.position = player.global_position + Vector2(40, 10) - at.global_position
			at.add_child(pickup)
		else:
			pickup.free()
	_reset_orders()


func _reset_orders() -> void:
	if carrying != null:
		carrying.free()
		carrying = null
	mode = Mode.FOLLOW
	_fetch_target = null
	dig_target = null
	_dig_time = 0.0


func _exit_tree() -> void:
	if carrying != null:
		carrying.free()
		carrying = null


func _too_far(player: Player) -> bool:
	var distance := position.distance_to(player.position)
	if distance > CATCH_UP_DISTANCE and mode == Mode.FOLLOW:
		return true
	var other_room := WorldMap.room_at(position) != WorldMap.room_at(player.position)
	return other_room and distance > CATCH_UP_DISTANCE * (2.0 if mode != Mode.FOLLOW else 0.5)


func _sniff_nearby() -> void:
	if _sniff_cooldown > 0.0:
		return
	for node in get_tree().get_nodes_in_group("dig_spots"):
		var spot := node as DigSpot
		if spot != null and not spot.dug:
			if spot.global_position.distance_to(global_position) < SNIFF_RANGE:
				_sniff_cooldown = SNIFF_EVERY
				remark("sniff")
				return


## Moves toward `target`, sliding along walls. When `swim` is set she also crosses water
## (fetching, digging).
func _run_toward(target: Vector2, speed: float, delta: float, swim := false) -> void:
	var to := target - global_position
	if to.length() < 4.0:
		return
	_moving = true
	if to.x != 0.0:
		_sprite.flip_h = to.x < 0.0
	var motion := to.normalized() * minf(speed * delta, to.length())
	var game := get_tree().get_first_node_in_group("game") as Game
	if swim and game != null:
		# Swimming goes by the map: anything but walls, trees and the like.
		for step in [motion, Vector2(motion.x, 0), Vector2(0, motion.y)]:
			var ahead := game.world.tile_at(Vector2i(((position + step) / WorldMap.TILE).floor()))
			if ahead == "~" or not Tiles.is_solid(ahead):
				position += step
				return
		return
	var hit := move_and_collide(motion)
	if hit != null:
		move_and_collide(hit.get_remainder().slide(hit.get_normal()))


func _on_water(game: Game) -> bool:
	return game.world.tile_at(Vector2i((position / WorldMap.TILE).floor())) == "~"


func _spot_behind(player: Player) -> Vector2:
	var game := get_tree().get_first_node_in_group("game") as Game
	for spot in [
		player.position - player.facing * FOLLOW_DISTANCE,
		player.position + player.facing.orthogonal() * FOLLOW_DISTANCE,
		player.position - player.facing.orthogonal() * FOLLOW_DISTANCE,
	]:
		var cell := Vector2i((spot / WorldMap.TILE).floor())
		if game == null or not Tiles.is_solid(game.world.tile_at(cell)):
			return spot
	return player.position


# --- grumbling -----------------------------------------------------------------------------


## Says something about `event` (a key of data/evey_quips.json), unless she spoke very
## recently or said that kind of thing a little while ago (`force` skips both). Returns the
## line, or "".
func remark(event: String, force := false) -> String:
	var lines: Array = _load_quips().get(event, [])
	if lines.is_empty():
		return ""
	if not force and (_quip_gap > 0.0 or _said.get(event, 0.0) > 0.0):
		return ""
	var options := lines.filter(func(l): return l != _last_line.get(event, ""))
	var line: String = (options if not options.is_empty() else lines).pick_random()
	_last_line[event] = line
	_said[event] = QUIP_REPEAT
	_quip_gap = QUIP_GAP
	_say(line)
	return line


static func _load_quips() -> Dictionary:
	if _quips.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(QUIPS_PATH))
		_quips = parsed if parsed is Dictionary else {}
		_quips.erase("_note")
	return _quips


## Notices what is going on around Chad and grumbles about it.
func _watch(game: Game, player: Player, delta: float) -> void:
	_quip_gap = maxf(_quip_gap - delta, 0.0)
	for event in _said.keys():
		_said[event] = maxf(_said[event] - delta, 0.0)
	if _seen_health >= 0 and player.health < _seen_health:
		remark("chad_faint" if player.health <= 0 else "chad_hurt", player.health <= 0)
	_seen_health = player.health
	if _seen_level >= 0 and player.level > _seen_level:
		remark("level_up")
	_seen_level = player.level
	var trouble := _trouble_near(player)
	if trouble and not _seen_trouble:
		remark("enemy_near")
	elif _seen_trouble and not trouble:
		remark("enemy_beaten")
	_seen_trouble = trouble
	var night := game.day_night.is_night()
	if night and not _seen_night:
		remark("night")
	_seen_night = night
	if _swimming and not _seen_swimming:
		Sfx.play("splash")
		remark("swim")
	_seen_swimming = _swimming
	_chad_still = _chad_still + delta if player.velocity.length() < 1.0 else 0.0
	if _chad_still > IDLE_REMARK:
		_chad_still = 0.0
		remark("idle")


func _trouble_near(player: Player) -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and enemy.health > 0 and not enemy.is_queued_for_deletion():
			if enemy.global_position.distance_to(player.global_position) < TROUBLE_RANGE:
				return true
	return false


## A speech line over her head for a couple of seconds.
func _say(text: String) -> void:
	if not is_inside_tree():
		return
	last_remark = text
	Sfx.play("dog", 0.12)
	if _remark_label == null:
		_remark_label = Label.new()
		_remark_label.name = "Remark"
		_remark_label.z_index = 25
		_remark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_remark_label.add_theme_font_size_override("font_size", 22)
		_remark_label.add_theme_color_override("font_color", Color(1, 0.93, 0.78))
		_remark_label.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.1))
		_remark_label.add_theme_constant_override("outline_size", 8)
		_remark_label.size = Vector2(420, 32)
		add_child(_remark_label)
	_remark_label.text = text
	_remark_label.position = Vector2(-210, -bubble_height - 24)
	_remark_label.modulate.a = 1.0
	_remark_label.visible = true
	_remark_time = BUBBLE_SECONDS


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


## The first thing in the bag a dog would eat (any food or fish), or "".
static func food_in(inventory: Inventory) -> String:
	for slot: Dictionary in inventory.slots:
		if not slot.is_empty() and is_food(slot["id"]):
			return slot["id"]
	return ""


static func is_food(id: String) -> bool:
	var item := GameData.item(id)
	return int(item.get("heal", 0)) > 0 or item.has("fish")
