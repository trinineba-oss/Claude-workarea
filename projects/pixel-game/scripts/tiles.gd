class_name Tiles
extends RefCounted
## Tile legend for the ASCII room maps in data/rooms, and the shared TileSet.
##
## Legend: . grass   , flowers   s sand   p path   = stone floor   @ player start (sand)
##         ~ water   # rock   b bush   T tree   (the last four are solid)

const SIZE := 16
const ATLAS := preload("res://assets/tiles/overworld.png")
const COUNT := 9
## character -> atlas column. Keep in sync with tools/gen_art.py.
const INDEX := {
	".": 0,
	"s": 1,
	"~": 2,
	"#": 3,
	"b": 4,
	"T": 5,
	"p": 6,
	",": 7,
	"=": 8,
	"@": 1,
}
const SOLID := ["~", "#", "b", "T"]

static var _tileset: TileSet


static func is_known(ch: String) -> bool:
	return INDEX.has(ch)


static func is_solid(ch: String) -> bool:
	return ch in SOLID


static func atlas_index(ch: String) -> int:
	return INDEX[ch]


## The shared tile set: one atlas row, with full-tile collision on solid tiles.
static func tileset() -> TileSet:
	if _tileset != null:
		return _tileset
	var ts := TileSet.new()
	ts.tile_size = Vector2i(SIZE, SIZE)
	ts.add_physics_layer()
	var source := TileSetAtlasSource.new()
	source.texture = ATLAS
	source.texture_region_size = Vector2i(SIZE, SIZE)
	for i in COUNT:
		source.create_tile(Vector2i(i, 0))
	ts.add_source(source, 0)
	var half := SIZE / 2.0
	var square := PackedVector2Array(
		[Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]
	)
	for ch in SOLID:
		var data := source.get_tile_data(Vector2i(INDEX[ch], 0), 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, square)
	_tileset = ts
	return ts
