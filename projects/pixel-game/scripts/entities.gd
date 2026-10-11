class_name Entities
extends RefCounted
## Things that can be placed in rooms (data/rooms/*.txt object lines) or spawned by code.
## Some kinds take an argument: `npc <x> <y> <character>`, `sign <x> <y> <conversation>`,
## `prop <x> <y> <prop>` (ids from data/characters.json, data/dialogue.json, data/props.json),
## `traffic <x> <y> <up|down|left|right>` (a lane of cars through that cell),
## `forage <x> <y> <plant>` (a plant to pick, from data/forage.json),
## `night <x> <y> <enemy>` (an enemy that comes out after dark: see NightSpawn.KINDS).
## Dungeon pieces: `locked <x> <y>` (a door that takes a small key), `gate <x> <y> <trigger>`
## (bars that open when the trigger fires), `shutter <x> <y>` (bars that close during a
## mini-boss fight), `chest <x> <y> <content>[@<trigger>]`, `block <x> <y>` (push block),
## `plate <x> <y> <trigger>`, `switch <x> <y> <trigger>`, `bigcrab <x> <y> <trigger>` (the
## mini-boss; beating it fires the trigger), `cauldron <x> <y> <trigger>` (Temple 1's boss),
## `bossdoor <x> <y>` (takes the Pepper Key), `seasoning <x> <y> <item>@<trigger>` and
## `warp <x> <y> <map>:<room>:<tile>`. `brownie <x> <y>` marks where Brownie waits to be found,
## `dig <x> <y> <reward>` buries something for her to dig up, and `topdog <x> <y> <dog>` is a
## dog that challenges her to a duel (data/dogs.json).

const PICKUP := preload("res://scenes/pickup.tscn")
const SCENES := {
	"bandit": preload("res://scenes/bandit.tscn"),
	"bigcrab": preload("res://scenes/big_crab.tscn"),
	"cauldron": preload("res://scenes/cauldron.tscn"),
	"crab": preload("res://scenes/crab.tscn"),
	"corbeau": preload("res://scenes/corbeau.tscn"),
	"dog": preload("res://scenes/pothound.tscn"),
	"soucouyant": preload("res://scenes/soucouyant.tscn"),
}
const PICKUPS := ["snack", "coin"]
const WITH_ARGUMENT := [
	"npc",
	"sign",
	"prop",
	"traffic",
	"forage",
	"night",
	"gate",
	"chest",
	"plate",
	"switch",
	"warp",
	"bigcrab",
	"cauldron",
	"seasoning",
	"dig",
	"topdog",
]
const DUNGEON := [
	"locked", "gate", "shutter", "chest", "block", "plate", "switch", "warp", "bossdoor"
]
## Markers that only note a place (the companion's home); rooms put an empty node there.
const MARKERS := ["brownie"]


static func is_known(kind: String) -> bool:
	return (
		SCENES.has(kind)
		or kind in PICKUPS
		or kind in WITH_ARGUMENT
		or kind in DUNGEON
		or kind in MARKERS
	)


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
		"chest":
			return Chest.content_problem(arg)
		"warp":
			return "" if not Game.parse_warp(arg).is_empty() else "bad warp target '%s'" % arg
		"seasoning":
			return Seasoning.argument_problem(arg)
		"dig":
			return DigSpot.reward_problem(arg)
		"topdog":
			return "" if GameData.has_dog(arg) else "unknown top dog '%s'" % arg
		"gate", "plate", "switch", "bigcrab", "cauldron":
			return "" if arg.is_valid_identifier() else "bad trigger name '%s'" % arg
		"night":
			return (
				""
				if arg in NightSpawn.KINDS
				else "night needs one of %s" % ", ".join(NightSpawn.KINDS)
			)
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
		"night":
			var spot := NightSpawn.new()
			spot.setup(arg)
			return spot
		"locked", "gate", "shutter", "bossdoor":
			var door := DungeonDoor.new()
			door.setup(kind, arg)
			return door
		"chest":
			var chest := Chest.new()
			chest.setup(arg)
			return chest
		"block":
			return PushBlock.new()
		"plate":
			var plate := Plate.new()
			plate.setup(arg)
			return plate
		"switch":
			var orb := CrystalSwitch.new()
			orb.setup(arg)
			return orb
		"warp":
			var warp := Warp.new()
			warp.setup(arg)
			return warp
		"bigcrab", "cauldron":
			var boss: Enemy = SCENES[kind].instantiate()
			boss.set("trigger_name", arg)
			return boss
		"seasoning":
			var seasoning := Seasoning.new()
			seasoning.setup(arg)
			return seasoning
		"dig":
			var buried := DigSpot.new()
			buried.setup(arg)
			return buried
		"topdog":
			var rival_dog := TopDog.new()
			rival_dog.setup(arg)
			return rival_dog
		"brownie":
			var marker := Node2D.new()
			marker.name = "BrownieHome"
			return marker
	return SCENES[kind].instantiate()
