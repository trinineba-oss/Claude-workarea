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
	var look: Variant = _look(node)
	return look.get("sheet", "") if look is Dictionary else str(look)


## How much bigger than usual its sheet is drawn (1 unless looks.json gives a size).
static func size_for(node: Node) -> float:
	var look: Variant = _look(node)
	return float(look.get("size", 1.0)) if look is Dictionary else 1.0


## The sheet for a looks.json key ("companion", "dog:scraps"...), or "".
static func sheet_by_key(key: String) -> String:
	var look: Variant = _load_looks().get(key, "")
	return look.get("sheet", "") if look is Dictionary else str(look)


## The first frame of an animation, facing that way, as a texture for the 2D screens (the dog
## duel); null if the sheet has no such animation.
static func frame(sheet: String, anim_name: String, facing: Vector2) -> Texture2D:
	var layout := anim(sheet, anim_name)
	if layout.is_empty():
		return null
	var row: int = layout["row"]
	if int(layout["rows"]) == 4:
		row += direction_index(facing)
	var atlas := AtlasTexture.new()
	atlas.atlas = texture(sheet)
	var cell := frame_size(sheet)
	atlas.region = Rect2(0, row * cell, cell, cell)
	return atlas


static func _look(node: Node) -> Variant:
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
	var found: Variant = _load_sheets().get("characters", {}).get(sheet, {}).get(name, {})
	return found if found is Dictionary else {}


## Pixels per (square) frame: 64 unless sheets.json says otherwise ("frame").
static func frame_size(sheet: String) -> int:
	return int(_load_sheets().get("characters", {}).get(sheet, {}).get("frame", 64))


## Painted (not pixel) art, drawn with smooth filtering ("smooth" in sheets.json).
static func is_smooth(sheet: String) -> bool:
	return bool(_load_sheets().get("characters", {}).get(sheet, {}).get("smooth", false))


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
