class_name NightSpawn
extends Node2D
## A spot where something comes out after dark (`night <x> <y> <kind>` in a room file). It
## appears once per night, never under a lamp or right on top of Chad, and slips away at dawn.

const KINDS := ["bandit", "dog", "soucouyant", "corbeau"]
## Chad has to be at least this far away for something to appear.
const MIN_PLAYER_DISTANCE := 260.0

var kind := ""
var enemy: Enemy

var _spawned_tonight := false


func setup(what: String) -> void:
	kind = what


func _physics_process(_delta: float) -> void:
	var night := DayNight.current != null and DayNight.current.is_night()
	if not night:
		_spawned_tonight = false
		if is_instance_valid(enemy):
			enemy.leave()
		enemy = null
		return
	if _spawned_tonight or NightLight.is_lit(get_tree(), global_position):
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and player.global_position.distance_to(global_position) < MIN_PLAYER_DISTANCE:
		return
	_spawned_tonight = true
	enemy = Entities.create(kind)
	enemy.position = position
	get_parent().add_child(enemy)
	enemy.appear()
