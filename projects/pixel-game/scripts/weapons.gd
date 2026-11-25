class_name Weapons
extends RefCounted
## Chad's weapons, read from data/weapons.json: each has a combo of moves, a durability (how
## many hits before it breaks; 0 never breaks), a kind (slash or blunt: what it can break in
## the world), a look (how the swing is drawn), a throw damage and a charged spin.

const PATH := "res://data/weapons.json"
const FISTS := "fists"
## How many weapons Chad can carry (not counting his fists).
const POUCH := 5

static var _data: Dictionary


static func all() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {}
		_data.erase("_note")
	return _data


static func has(id: String) -> bool:
	return all().has(id)


static func get_weapon(id: String) -> Dictionary:
	return all().get(id, all().get(FISTS, {}))


static func display_name(id: String) -> String:
	return str(get_weapon(id).get("name", id.capitalize()))


static func combo(id: String) -> Array:
	return get_weapon(id).get("combo", [])


static func charge(id: String) -> Dictionary:
	return get_weapon(id).get("charge", {})


static func durability(id: String) -> int:
	return int(get_weapon(id).get("durability", 0))


static func kind(id: String) -> String:
	return str(get_weapon(id).get("kind", "blunt"))


static func look(id: String) -> String:
	return str(get_weapon(id).get("look", "fist"))


static func throw_damage(id: String) -> int:
	return int(get_weapon(id).get("throw", 0))


static func icon(id: String) -> Texture2D:
	var path := "res://assets/items/%s.png" % id
	return load(path) if ResourceLoader.exists(path) else null
