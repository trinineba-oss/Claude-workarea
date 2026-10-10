class_name Entities
extends RefCounted
## Things that can be placed in rooms (data/rooms/*.txt object lines) or spawned by code.

const PICKUP := preload("res://scenes/pickup.tscn")
const SCENES := {
	"corbeau": preload("res://scenes/corbeau.tscn"),
	"dog": preload("res://scenes/pothound.tscn"),
}
const PICKUPS := ["snack", "coin"]


static func is_known(kind: String) -> bool:
	return SCENES.has(kind) or kind in PICKUPS


static func create(kind: String) -> Node2D:
	if kind in PICKUPS:
		var pickup: Pickup = PICKUP.instantiate()
		pickup.kind = kind
		return pickup
	return SCENES[kind].instantiate()
