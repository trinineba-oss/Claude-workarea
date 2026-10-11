class_name Companion
extends Interactable
## Brownie, Chad's pothound. Before she joins she lies in the shade at her spot on the road
## (`brownie <x> <y>` in a room file) and only has eyes for Chad's bag: give her some food and
## she follows him everywhere, temples included. She runs at enemies near Chad and bites them
## (a bitten bandit drops what he stole, and she runs down any bandit making off with Chad's
## things), and sits when Chad stands still. She never gets hurt,
## and if she falls far behind she catches up.

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
const FLAG := "brownie_joined"

var joined := false
var home := Vector2.ZERO
## The enemy she is after, if any.
var quarry: Node2D

var _bite_cooldown := 0.0
var _age := 0.0
var _moving := false
var _sprite: Sprite2D
var _shape: CollisionShape2D


func _ready() -> void:
	super()
	add_to_group("companion")
	add_child(_shadow(Vector2(0.9, 0.8)))
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.offset = Vector2(0, -TEXTURE.get_height() / 2.0)
	add_child(_sprite)
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
	var food := _food_in(game.inventory)
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


## Puts her right behind Chad (after a warp, a faint or a long way behind).
func catch_up(player: Player) -> void:
	position = _spot_behind(player)
	quarry = null


func _physics_process(delta: float) -> void:
	_bite_cooldown = maxf(_bite_cooldown - delta, 0.0)
	var game := get_tree().get_first_node_in_group("game") as Game
	var player := get_tree().get_first_node_in_group("player") as Player
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
	if (
		position.distance_to(player.position) > CATCH_UP_DISTANCE
		or (
			WorldMap.room_at(position) != WorldMap.room_at(player.position)
			and position.distance_to(player.position) > CATCH_UP_DISTANCE / 2.0
		)
	):
		catch_up(player)
		return
	quarry = _pick_quarry(player)
	if quarry != null:
		var thief: bool = quarry is Bandit and quarry.has_loot()
		_run_toward(quarry.global_position, THIEF_SPEED if thief else RUN_SPEED, delta)
		if global_position.distance_to(quarry.global_position) < BITE_RANGE:
			_bite(quarry)
		return
	var spot := _spot_behind(player)
	if position.distance_to(player.position) > FOLLOW_DISTANCE * 1.3:
		var far := position.distance_to(player.position) > FOLLOW_DISTANCE * 3.0
		_run_toward(spot, RUN_SPEED if far else WALK_SPEED, delta)


func _process(delta: float) -> void:
	super(delta)
	_age += delta
	if _moving:
		_sprite.position.y = -absf(sin(_age * 14.0)) * 5.0
		_sprite.scale = Vector2.ONE
	else:
		# Lying in the shade before she joins; sitting and wagging after.
		_sprite.position.y = 0.0
		var squash := 0.72 if not joined else 0.86
		_sprite.scale = Vector2(1.0 + (1.0 - squash) * 0.5, squash)
		_sprite.rotation = sin(_age * 9.0) * 0.03 if joined else 0.0


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
	Effects.float_text(get_parent(), position + Vector2(0, -80), "Woof!", Color(1, 0.9, 0.7))


func _run_toward(target: Vector2, speed: float, delta: float) -> void:
	var to := target - global_position
	if to.length() < 4.0:
		return
	_moving = true
	if to.x != 0.0:
		_sprite.flip_h = to.x < 0.0
	var motion := to.normalized() * minf(speed * delta, to.length())
	var hit := move_and_collide(motion)
	if hit != null:
		move_and_collide(hit.get_remainder().slide(hit.get_normal()))


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


static func _food_in(inventory: Inventory) -> String:
	for slot: Dictionary in inventory.slots:
		if slot.is_empty():
			continue
		var item := GameData.item(slot["id"])
		if int(item.get("heal", 0)) > 0 or item.has("fish"):
			return slot["id"]
	return ""
