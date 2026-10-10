class_name Room
extends Node2D
## One screen of the world, built from its ASCII map: a blended ground (shaders/ground.gdshader),
## invisible collision for solid tiles, depth-sorted scenery, and the room's objects (enemies
## and pickups). Leaving and re-entering a room rebuilds it, so enemies come back.

const GROUND_SHADER := preload("res://shaders/ground.gdshader")
const GROUND_TEXTURES := {
	"grass_tex": preload("res://assets/textures/grass.png"),
	"sand_tex": preload("res://assets/textures/sand.png"),
	"dirt_tex": preload("res://assets/textures/dirt.png"),
	"stone_tex": preload("res://assets/textures/stone.png"),
	"water_tex": preload("res://assets/textures/water.png"),
	"noise_tex": preload("res://assets/textures/noise.png"),
	"wood_tex": preload("res://assets/textures/wood.png"),
	"road_tex": preload("res://assets/textures/road.png"),
}
## Ground material -> [colour in the first weights image, colour in the second].
const WEIGHTS := {
	"grass": [Color(0, 0, 0, 0), Color(0, 0, 0, 0)],
	"sand": [Color(1, 0, 0, 0), Color(0, 0, 0, 0)],
	"dirt": [Color(0, 1, 0, 0), Color(0, 0, 0, 0)],
	"water": [Color(0, 0, 1, 0), Color(0, 0, 0, 0)],
	"stone": [Color(0, 0, 0, 1), Color(0, 0, 0, 0)],
	"wood": [Color(0, 0, 0, 0), Color(1, 0, 0, 0)],
	"road": [Color(0, 0, 0, 0), Color(0, 1, 0, 0)],
}
const SHADOW := preload("res://assets/sprites/shadow.png")
## kind -> [texture, position in the tile relative to its centre, sprite offset, shadow scale]
## The sprite offset puts the art's base (trunk, foot of the wall) on the node's origin, which
## is what depth sorting uses.
const SCENERY := {
	"tree":
	[preload("res://assets/sprites/tree.png"), Vector2(0, 22), Vector2(0, -72), Vector2(1.5, 1.1)],
	"bush":
	[preload("res://assets/sprites/bush.png"), Vector2(0, 20), Vector2(0, -27), Vector2(1.2, 0.9)],
	"rock":
	[preload("res://assets/sprites/rock.png"), Vector2(0, 32), Vector2(0, -41), Vector2.ZERO],
	"crate":
	[preload("res://assets/sprites/crate.png"), Vector2(0, 28), Vector2(0, -35), Vector2(1.0, 0.8)],
	"bollard":
	[
		preload("res://assets/sprites/bollard.png"),
		Vector2(0, 16),
		Vector2(0, -27),
		Vector2(0.7, 0.6)
	],
	"fence":
	[preload("res://assets/sprites/fence.png"), Vector2(0, 30), Vector2(0, -39), Vector2.ZERO],
	"wall":
	[preload("res://assets/sprites/wall.png"), Vector2(0, 32), Vector2(0, -41), Vector2.ZERO],
}
const FLOWERS := preload("res://assets/sprites/flowers.png")

var coords := Vector2i.ZERO


func build(room_coords: Vector2i, lines: PackedStringArray, things: Array = []) -> void:
	coords = room_coords
	position = WorldMap.room_origin(coords)
	y_sort_enabled = true
	add_child(_make_ground(lines))
	add_child(_make_collision(lines))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coords)
	for y in lines.size():
		for x in lines[y].length():
			var kind := Tiles.scenery(lines[y][x])
			if kind != "":
				_add_scenery(kind, Vector2i(x, y), rng)
	for thing in things:
		var node := Entities.create(thing["kind"], thing.get("arg", ""))
		node.position = _cell_centre(thing["cell"])
		add_child(node)
	_add_wires()


## Power lines between utility poles (props with id "pole"): along each row of poles, and
## across the road to the nearest pole on the other side.
func _add_wires() -> void:
	var poles: Array[Vector2] = []
	for child in get_children():
		if child is Prop and child.prop_id == "pole":
			poles.append(child.position + Vector2(0, Prop.POLE_TOP))
	if poles.size() < 2:
		return
	var wires := Wires.new()
	poles.sort_custom(func(a, b): return a.x < b.x)
	var tile := float(WorldMap.TILE)
	for i in poles.size():
		for j in range(i + 1, poles.size()):
			var a := poles[i]
			var b := poles[j]
			var same_row := absf(a.y - b.y) < tile
			var near_along := same_row and b.x - a.x < tile * 8.0
			var near_across := not same_row and absf(b.x - a.x) < tile * 2.5
			if near_along or near_across:
				wires.add_span(a, b)
	add_child(wires)


func _make_ground(lines: PackedStringArray) -> Sprite2D:
	var weights := Image.create(WorldMap.COLS, WorldMap.ROWS, false, Image.FORMAT_RGBA8)
	var weights2 := Image.create(WorldMap.COLS, WorldMap.ROWS, false, Image.FORMAT_RGBA8)
	for y in lines.size():
		for x in lines[y].length():
			var pair: Array = WEIGHTS[Tiles.ground_at(lines, x, y)]
			weights.set_pixel(x, y, pair[0])
			weights2.set_pixel(x, y, pair[1])
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	for param: String in GROUND_TEXTURES:
		material.set_shader_parameter(param, GROUND_TEXTURES[param])
	material.set_shader_parameter("weights2", ImageTexture.create_from_image(weights2))
	material.set_shader_parameter("room_origin", position)
	material.set_shader_parameter("room_size", WorldMap.room_size())
	var ground := Sprite2D.new()
	ground.name = "Ground"
	ground.texture = ImageTexture.create_from_image(weights)
	ground.centered = false
	ground.scale = Vector2.ONE * WorldMap.TILE
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ground.z_index = -10
	ground.material = material
	return ground


func _make_collision(lines: PackedStringArray) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = "Collision"
	layer.tile_set = Tiles.collision_tileset()
	layer.visible = false
	for y in lines.size():
		for x in lines[y].length():
			if Tiles.is_solid(lines[y][x]):
				layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	return layer


func _add_scenery(kind: String, cell: Vector2i, rng: RandomNumberGenerator) -> void:
	if kind == "flowers":
		for i in 2:
			var flower := Sprite2D.new()
			flower.texture = FLOWERS
			flower.position = (
				_cell_centre(cell) + Vector2(rng.randf_range(-18, 18), rng.randf_range(-18, 18))
			)
			flower.z_index = -5
			add_child(flower)
		return
	var spec: Array = SCENERY[kind]
	var node := Node2D.new()
	node.name = "%s_%d_%d" % [kind, cell.x, cell.y]
	node.position = _cell_centre(cell) + spec[1]
	if spec[3] != Vector2.ZERO:
		var shadow := Sprite2D.new()
		shadow.texture = SHADOW
		shadow.scale = spec[3]
		shadow.z_index = -4
		node.add_child(shadow)
	var sprite := Sprite2D.new()
	sprite.texture = spec[0]
	sprite.offset = spec[2]
	sprite.flip_h = rng.randf() < 0.5 and kind in ["tree", "bush"]
	node.add_child(sprite)
	add_child(node)


static func _cell_centre(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * WorldMap.TILE
