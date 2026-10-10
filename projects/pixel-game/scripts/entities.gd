class_name Entities
extends RefCounted
## Things that can be placed in rooms (data/rooms/*.txt object lines) or spawned by code.
## Some kinds take an argument: `npc <x> <y> <character>`, `sign <x> <y> <conversation>`,
## `prop <x> <y> <prop>` (ids from data/characters.json, data/dialogue.json, data/props.json),
## `traffic <x> <y> <up|down|left|right>` (a lane of cars through that cell),
## `forage <x> <y> <plant>` (a plant to pick, from data/forage.json).

const PICKUP := preload("res://scenes/pickup.tscn")
const SCENES := {
	"corbeau": preload("res://scenes/corbeau.tscn"),
	"dog": preload("res://scenes/pothound.tscn"),
}
const PICKUPS := ["snack", "coin"]
const WITH_ARGUMENT := ["npc", "sign", "prop", "traffic", "forage"]


static func is_known(kind: String) -> bool:
	return SCENES.has(kind) or kind in PICKUPS or kind in WITH_ARGUMENT


static func needs_argument(kind: String) -> bool:
	return kind in WITH_ARGUMENT


## Why `arg` is not valid for `kind`, or "" when it is.
static func argument_problem(kind: String, arg: String) -> String:
	if not needs_argument(kind):
		return "" if arg == "" else "%s takes no argument" % kind
	if arg == "":
		return "%s needs an id" % kind
	match kind:
		"npc":
			return "" if GameData.has_character(arg) else "unknown character '%s'" % arg
		"sign":
			return "" if GameData.has_conversation(arg) else "unknown conversation '%s'" % arg
		"prop":
			return "" if GameData.has_prop(arg) else "unknown prop '%s'" % arg
		"traffic":
			return "" if Traffic.DIRECTIONS.has(arg) else "traffic needs up, down, left or right"
		"forage":
			return "" if GameData.has_forage(arg) else "unknown forage '%s'" % arg
	return ""


static func create(kind: String, arg: String = "") -> Node2D:
	if kind in PICKUPS:
		var pickup: Pickup = PICKUP.instantiate()
		pickup.kind = kind
		return pickup
	match kind:
		"npc":
			var npc := Npc.new()
			npc.setup(arg)
			return npc
		"sign":
			var sign_node := Signpost.new()
			sign_node.setup(arg)
			return sign_node
		"prop":
			var prop := Prop.new()
			prop.setup(arg)
			return prop
		"traffic":
			var lane := Traffic.new()
			lane.setup(arg)
			return lane
		"forage":
			var plant := Forage.new()
			plant.setup(arg)
			return plant
	return SCENES[kind].instantiate()
