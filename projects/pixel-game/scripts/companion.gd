class_name Companion
extends Interactable
## Brownie, Chad's pothound. Before she joins she lies in the shade at her spot on the road
## (`brownie <x> <y>` in a room file) and only has eyes for Chad's bag: give her some food and
## she follows him everywhere, temples included.
##
## Left to herself she runs at enemies near Chad and bites them (a bitten bandit drops what he
## stole, and she runs down any bandit making off with Chad's things), sits when Chad stands
## still, sniffs at buried things nearby, and catches up if she falls far behind. She never
## gets hurt. Chad can also give her orders from the dog menu (DogMenu):
##   sic(target)  chase that one enemy down
##   stay()       wait right here (heavy enough to hold down a pressure plate); come() ends it
##   fetch()      bring back the nearest coin or snack, swimming if she has to
##   dig()        sniff out the nearest buried thing (DigSpot) and dig it up

enum Mode { FOLLOW, STAY, SIC, FETCH, DIG }

const TEXTURE := preload("res://assets/sprites/brownie.png")
const FOLLOW_DISTANCE := 84.0
const WALK_SPEED := 250.0
const RUN_SPEED := 330.0
## Enemies this close to Chad get chased.
const GUARD_RANGE := 260.0
## A bandit carrying Chad's things gets chased this far, and faster.
const THIEF_RANGE := 700.0
const THIEF_SPEED := 400.0
const BITE_RANGE := 60.0
const BITE_COOLDOWN := 0.9
const BITE_DAMAGE := 1
## Farther than this from Chad (or in another room) and she just catches up.
const CATCH_UP_DISTANCE := 560.0
## How far from Chad she looks for things to fetch or dig up.
const SEARCH_RANGE := 8.0 * WorldMap.TILE
## A sic'd enemy farther than this from Chad is let go.
const SIC_RANGE := 900.0
const DIG_TIME := 1.2
## She sniffs at a buried thing this close, now and then.
const SNIFF_RANGE := 2.5 * WorldMap.TILE
const SNIFF_EVERY := 6.0
const FLAG := "brownie_joined"

var joined := false
var home := Vector2.ZERO
var mode := Mode.FOLLOW
## The enemy she is after, if any.
var quarry: Node2D
## The coin or snack she is fetching or carrying.
var carrying: Pickup
## The buried thing she is digging up.
var dig_target: DigSpot
var stay_spot := Vector2.ZERO

var _bite_cooldown := 0.0
var _dig_time := 0.0
var _sniff_cooldown := 0.0
var _fetch_target: Pickup
var _age := 0.0
var _moving := false
var _swimming := false
var _sprite: Sprite2D
var _carried_sprite: Sprite2D
var _shape: CollisionShape2D


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


## Brownie joins (or, from a save, has already joined): she stops blocking Chad.
func join() -> void:
	joined = true
	collision_layer = 0
	set_highlighted(false)


func can_interact(_flags: Dictionary) -> bool:
	return not joined and visible


## Talking to her before she joins: food wins her over.
func use(game: Game) -> void:
	if joined:
		return
	var food := food_in(game.inventory)
	if food == "":
		game.talk("brownie_hungry", self)
		return
	game.inventory.remove(food)
	game.flags[FLAG] = true
	join()
	Effects.burst(get_parent(), position + Vector2(0, -50), "sparkle")
	game.talk("brownie_join", self)


func on_talk(hero: Node2D) -> void:
	_sprite.flip_h = hero.global_position.x < global_position.x


## Puts her right behind Chad (after a warp, a faint or a long way behind) and back to
## following.
func catch_up(player: Player) -> void:
	position = _spot_behind(player)
	_reset_orders()


# --- orders --------------------------------------------------------------------------------


## Chase that enemy until it is beaten (or gets away).
func sic(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	_reset_orders()
	mode = Mode.SIC
	quarry = target
	_say("Grrr!")
	return true


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
	_say("*sits*")


## Stop staying and follow again.
func come() -> void:
	_reset_orders()
	_say("Woof!")


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
		_say("Nothing to fetch")
		return false
	_reset_orders()
	mode = Mode.FETCH
	_fetch_target = best
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
		_say("Sniff... nothing here")
		return false
	_reset_orders()
	mode = Mode.DIG
	dig_target = best
	_dig_time = 0.0
	return true


## Enemies she could be sent after, nearest to Chad first.
func targets() -> Array:
	var player := _player()
	if player == null:
		return []
	var found := get_tree().get_nodes_in_group("enemies").filter(
		func(e):
			return (
				e.health > 0
				and not e.is_queued_for_deletion()
				and e.global_position.distance_to(player.global_position) < SIC_RANGE * 0.7
			)
	)
	found.sort_custom(
		func(a, b):
			return (
				a.global_position.distance_to(player.global_position)
				< b.global_position.distance_to(player.global_position)
			)
	)
	return found


# --- behaviour ------------------------------------------------------------------------------


func _physics_process(delta: float) -> void:
	_bite_cooldown = maxf(_bite_cooldown - delta, 0.0)
	_sniff_cooldown = maxf(_sniff_cooldown - delta, 0.0)
	var game := get_tree().get_first_node_in_group("game") as Game
	var player := _player()
	_moving = false
	if game == null or player == null:
		return
	if not joined:
		var here := game.map_id == Game.OVERWORLD
		if visible != here:
			visible = here
			_shape.set_deferred("disabled", not here)
		position = home
		return
	if player.frozen or player.health <= 0:
		return
	if mode != Mode.STAY and _too_far(player):
		catch_up(player)
		return
	match mode:
		Mode.STAY:
			_guard_spot(delta)
		Mode.SIC:
			_do_sic(player, delta)
		Mode.FETCH:
			_do_fetch(player, delta)
		Mode.DIG:
			_do_dig(delta)
		_:
			_do_follow(player, delta)
	_swimming = _on_water(game)


func _process(delta: float) -> void:
	super(delta)
	_age += delta
	_sprite.rotation = 0.0
	if mode == Mode.DIG and dig_target != null and _dig_time > 0.0:
		_sprite.position = Vector2(sin(_age * 40.0) * 3.0, 4.0)
		_sprite.scale = Vector2(1.06, 0.9)
	elif _moving:
		_sprite.position = Vector2(0, -absf(sin(_age * 14.0)) * 5.0)
		_sprite.scale = Vector2.ONE
	else:
		# Lying in the shade before she joins; sitting and wagging after.
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
	quarry = _pick_quarry(player)
	if quarry != null:
		var thief: bool = quarry is Bandit and quarry.has_loot()
		_run_toward(quarry.global_position, THIEF_SPEED if thief else RUN_SPEED, delta)
		if global_position.distance_to(quarry.global_position) < BITE_RANGE:
			_bite(quarry)
		return
	_sniff_nearby()
	if position.distance_to(player.position) > FOLLOW_DISTANCE * 1.3:
		var far := position.distance_to(player.position) > FOLLOW_DISTANCE * 3.0
		_run_toward(_spot_behind(player), RUN_SPEED if far else WALK_SPEED, delta)


func _do_sic(player: Player, delta: float) -> void:
	if quarry == null or not is_instance_valid(quarry):
		_reset_orders()
		return
	var target := quarry as Enemy
	var gone := target == null or target.health <= 0
	if gone or target.global_position.distance_to(player.global_position) > SIC_RANGE:
		_reset_orders()
		return
	_run_toward(target.global_position, THIEF_SPEED, delta, true)
	if global_position.distance_to(target.global_position) < BITE_RANGE:
		_bite(target)


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


## Staying: she does not move, but still snaps at anything that comes right up to her.
func _guard_spot(_delta: float) -> void:
	position = stay_spot
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and enemy.health > 0:
			if enemy.global_position.distance_to(global_position) < BITE_RANGE:
				_bite(enemy)


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
		Effects.float_text(room, position + Vector2(0, -80), "Good girl!", Color(1, 0.95, 0.7))
		pickup.free()
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
	quarry = null
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
				_say("Sniff sniff?")
				return


func _pick_quarry(player: Player) -> Node2D:
	var best: Node2D = null
	var best_distance := GUARD_RANGE
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.health <= 0 or enemy.is_queued_for_deletion():
			continue
		var distance := enemy.global_position.distance_to(player.global_position)
		if enemy is Bandit and enemy.has_loot() and distance < THIEF_RANGE:
			return enemy
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best


func _bite(enemy: Node2D) -> void:
	if _bite_cooldown > 0.0 or not enemy.has_method("take_hit"):
		return
	_bite_cooldown = BITE_COOLDOWN
	enemy.take_hit(BITE_DAMAGE, global_position)
	Effects.burst(enemy.get_parent(), enemy.position + Vector2(0, -30), "hit")
	_say("Woof!")


## Moves toward `target`, sliding along walls. When `swim` is set she also crosses water
## (fetching, digging, chasing).
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


func _say(text: String) -> void:
	if is_inside_tree():
		Effects.float_text(get_parent(), position + Vector2(0, -80), text, Color(1, 0.9, 0.7))


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
