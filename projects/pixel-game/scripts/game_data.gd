class_name GameData
extends RefCounted
## Read-only game content from data/*.json: conversations, characters and props.
## Loaded once and cached. Text lives in data files so it can be reviewed without code.

const DIALOGUE_PATH := "res://data/dialogue.json"
const CHARACTERS_PATH := "res://data/characters.json"
const PROPS_PATH := "res://data/props.json"

static var _dialogue: Dictionary
static var _characters: Dictionary
static var _props: Dictionary


static func conversation(id: String) -> Array:
	return _load_dialogue().get(id, [])


static func has_conversation(id: String) -> bool:
	return _load_dialogue().has(id)


static func conversation_ids() -> Array:
	return _load_dialogue().keys()


static func character(id: String) -> Dictionary:
	return _load_characters().get(id, {})


static func has_character(id: String) -> bool:
	return _load_characters().has(id)


static func character_ids() -> Array:
	return _load_characters().keys()


static func prop(id: String) -> Dictionary:
	return _load_props().get(id, {})


static func has_prop(id: String) -> bool:
	return _load_props().has(id)


static func prop_ids() -> Array:
	return _load_props().keys()


## Which conversation a character starts, given the story flags.
static func pick_dialogue(talk: Array, flags: Dictionary) -> String:
	for option: Dictionary in talk:
		if option.has("if") and not flags.get(option["if"], false):
			continue
		if option.has("unless") and flags.get(option["unless"], false):
			continue
		return option.get("dialogue", "")
	return ""


static func _load_dialogue() -> Dictionary:
	if _dialogue == null or _dialogue.is_empty():
		_dialogue = _read(DIALOGUE_PATH).get("conversations", {})
	return _dialogue


static func _load_characters() -> Dictionary:
	if _characters == null or _characters.is_empty():
		_characters = _without_notes(_read(CHARACTERS_PATH))
	return _characters


static func _load_props() -> Dictionary:
	if _props == null or _props.is_empty():
		_props = _without_notes(_read(PROPS_PATH))
	return _props


static func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("cannot read %s" % path)
		return {}
	return parsed


static func _without_notes(data: Dictionary) -> Dictionary:
	var result := {}
	for key: String in data:
		if not key.begins_with("_"):
			result[key] = data[key]
	return result
