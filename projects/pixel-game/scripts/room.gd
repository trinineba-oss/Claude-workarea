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
}
const WEIGHTS := {
	"grass": Color(0, 0, 0, 0),
	"sand": Color(1, 0, 0, 0),
	"dirt": Color(0, 1, 0, 0),
	"water": Color(0, 0, 1, 0),
	"stone": Color(0, 0, 0, 1),
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
		var node := Entities.create(thing["kind"])
		node.position = _cell_centre(thing["cell"])
		add_child(node)


func _make_ground(lines: PackedStringArray) -> Sprite2D:
	var weights := Image.create(WorldMap.COLS, WorldMap.ROWS, false, Image.FORMAT_RGBA8)
	for y in lines.size():
		for x in lines[y].length():
			weights.set_pixel(x, y, WEIGHTS[Tiles.ground_at(lines, x, y)])
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	for param: String in GROUND_TEXTURES:
		material.set_shader_parameter(param, GROUND_TEXTURES[param])
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
	sprite.flip_h = rng.randf() < 0.5 and kind != "rock"
	node.add_child(sprite)
	add_child(node)


static func _cell_centre(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * WorldMap.TILE
