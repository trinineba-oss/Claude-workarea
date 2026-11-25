class_name WeaponThrow
extends Node2D
## A weapon Chad threw: it spins through the air the way he aimed, hits the first enemy in
## its path for the weapon's throw damage (and a hit's wear), stops at walls, then lands as
## a pickup to be collected again (unless it broke).

const SPEED := 720.0
const RANGE := 6.0 * WorldMap.TILE
const HIT_RADIUS := 44.0

var weapon_id := ""
var wear := 0
var direction := Vector2.RIGHT

var _travelled := 0.0
var _thrower: Node2D
var _sprite: Sprite2D
var _done := false


func setup(id: String, hits_left: int, aim: Vector2, thrower: Node2D) -> void:
	weapon_id = id
	wear = hits_left
	direction = aim.normalized() if aim != Vector2.ZERO else Vector2.RIGHT
	_thrower = thrower
	name = "Thrown_" + id
	z_index = 8
	_sprite = Sprite2D.new()
	_sprite.texture = Weapons.icon(id)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	if _done:
		return
	var step := direction * SPEED * delta
	position += step
	_travelled += step.length()
	_sprite.rotation += delta * 18.0
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.health <= 0:
			continue
		if enemy.global_position.distance_to(global_position + Vector2(0, 36)) < HIT_RADIUS:
			var damage := Weapons.throw_damage(weapon_id)
			enemy.hit_force = 1.6
			if enemy.take_hit(damage, global_position):
				var room := enemy.get_parent()
				Effects.burst(room, enemy.position + Vector2(0, -30), "hit")
				Effects.float_text(
					room, enemy.position + Vector2(0, -70), str(damage), Color(1, 0.95, 0.5)
				)
				Juice.hit_stop(get_tree(), 0.06)
				Juice.shake(0.12)
			wear -= 1
			_land()
			return
	if _travelled >= RANGE or _hits_wall():
		_land()


func _hits_wall() -> bool:
	var game := get_tree().get_first_node_in_group("game") as Game
	if game == null:
		return false
	var feet := global_position + Vector2(0, 36)
	var ch := game.world.tile_at(Vector2i((feet / WorldMap.TILE).floor()))
	return Tiles.is_solid(ch) and ch != "~"


## Falls to the ground: a pickup again, or pieces if it broke.
func _land() -> void:
	_done = true
	var room := get_parent()
	if wear <= 0:
		Effects.float_text(
			room,
			position + Vector2(0, -40),
			"%s broke!" % Weapons.display_name(weapon_id),
			Color(1, 0.6, 0.45)
		)
		Effects.burst(room, position, "hit")
	else:
		var pickup: Pickup = Entities.create("weapon", weapon_id)
		pickup.wear = wear
		var at := global_position - direction * 20.0 + Vector2(0, 36)
		var game := get_tree().get_first_node_in_group("game") as Game
		var holder: Node2D = room as Node2D
		if game != null and game.current_room() != null:
			holder = game.current_room()
		pickup.position = holder.to_local(at)
		holder.add_child.call_deferred(pickup)
	queue_free()
