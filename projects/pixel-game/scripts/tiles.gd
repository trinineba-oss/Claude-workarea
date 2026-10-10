class_name Tiles
extends RefCounted
## Legend for the ASCII room maps in data/rooms, and the invisible collision tile set.
##
##   .  grass        ,  grass with flowers   s  sand    p  dirt path    =  paving / stone floor
##   w  dock planks  r  road                 @  player start (dock planks)
##   ~  water   #  rock wall   b  bush   T  tree   c  crate   o  bollard   (these are solid)

const SIZE := 64
## Ground material per character; "" means "take it from the neighbours" (see ground_at).
const GROUND := {
	".": "grass",
	",": "grass",
	"s": "sand",
	"@": "wood",
	"p": "dirt",
	"=": "stone",
	"w": "wood",
	"r": "road",
	"~": "water",
	"#": "",
	"b": "",
	"T": "",
	"c": "",
	"o": "",
}
## Characters that also place a scenery sprite.
const SCENERY := {
	",": "flowers", "#": "rock", "b": "bush", "T": "tree", "c": "crate", "o": "bollard"
}
const SOLID := ["~", "#", "b", "T", "c", "o"]

static var _tileset: TileSet


static func is_known(ch: String) -> bool:
	return GROUND.has(ch)


static func is_solid(ch: String) -> bool:
	return ch in SOLID


static func scenery(ch: String) -> String:
	return SCENERY.get(ch, "")


## Ground material under the tile at (x, y). Scenery tiles (rocks, bushes, trees) take the
## most common walkable ground around them, so a bush on the beach stands on sand.
static func ground_at(lines: PackedStringArray, x: int, y: int) -> String:
	var own: String = GROUND[lines[y][x]]
	if own != "":
		return own
	var counts := {}
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if ny < 0 or ny >= lines.size() or nx < 0 or nx >= lines[ny].length():
			continue
		var ground: String = GROUND.get(lines[ny][nx], "")
		if ground != "" and ground != "water":
			counts[ground] = counts.get(ground, 0) + 1
	var best := "grass"
	var best_count := 0
	for ground in counts:
		if counts[ground] > best_count:
			best = ground
			best_count = counts[ground]
	return best


## One invisible, fully solid tile used to give solid map cells their collision.
static func collision_tileset() -> TileSet:
	if _tileset != null:
		return _tileset
	var ts := TileSet.new()
	ts.tile_size = Vector2i(SIZE, SIZE)
	ts.add_physics_layer()
	var source := TileSetAtlasSource.new()
	var blank := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	source.texture = ImageTexture.create_from_image(blank)
	source.texture_region_size = Vector2i(SIZE, SIZE)
	source.create_tile(Vector2i.ZERO)
	ts.add_source(source, 0)
	var half := SIZE / 2.0
	var data := source.get_tile_data(Vector2i.ZERO, 0)
	data.add_collision_polygon(0)
	data.set_collision_polygon_points(
		0,
		0,
		PackedVector2Array(
			[Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]
		)
	)
	_tileset = ts
	return ts
