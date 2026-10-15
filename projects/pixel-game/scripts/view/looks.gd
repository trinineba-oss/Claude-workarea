class_name Looks
extends RefCounted
## Pixel-art sprite sheets for the 2.5D view: which sheet draws what (data/looks.json) and how
## each sheet is laid out (assets/characters/sheets.json, written by tools/lpc_build.py and
## tools/pixel_animals.py). Frames are 64x64; directional animations have four rows: up, left,
## down, right.

const LOOKS_PATH := "res://data/looks.json"
const SHEETS_PATH := "res://assets/characters/sheets.json"
const DIRECTIONS := ["up", "left", "down", "right"]

static var _looks: Dictionary
static var _sheets: Dictionary


## The sheet name for a 2D node, or "".
static func sheet_for(node: Node) -> String:
	var looks := _load_looks()
	var key := ""
	if node is Player:
		key = "player"
	elif node is Companion:
		key = "companion"
	elif node is Npc:
		key = "npc:" + str(node.character_id)
	elif node is TopDog:
		key = "dog:" + str(node.dog_id)
	elif node is Enemy:
		key = node.get_script().get_global_name()
	return looks.get(key, "")


## {"row", "frames", "rows"} for one animation of a sheet, or {} if it has none.
static func anim(sheet: String, name: String) -> Dictionary:
	return _load_sheets().get("characters", {}).get(sheet, {}).get(name, {})


static func texture(sheet: String) -> Texture2D:
	return load("res://assets/characters/%s.png" % sheet)


## The row offset for a facing (Vector2) in a four-direction animation.
static func direction_index(facing: Vector2) -> int:
	if absf(facing.x) > absf(facing.y):
		return 1 if facing.x < 0.0 else 3
	return 0 if facing.y < 0.0 else 2


static func _load_looks() -> Dictionary:
	if _looks == null or _looks.is_empty():
		_looks = JSON.parse_string(FileAccess.get_file_as_string(LOOKS_PATH))
		_looks.erase("_note")
	return _looks


static func _load_sheets() -> Dictionary:
	if _sheets == null or _sheets.is_empty():
		_sheets = JSON.parse_string(FileAccess.get_file_as_string(SHEETS_PATH))
	return _sheets
