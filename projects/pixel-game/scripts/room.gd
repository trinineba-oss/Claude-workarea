class_name Room
extends Node2D
## One screen of the world: a tile layer built from the room's ASCII map, plus its objects
## (enemies and pickups). Leaving and re-entering a room rebuilds it, so enemies come back.

var coords := Vector2i.ZERO


func build(room_coords: Vector2i, lines: PackedStringArray, things: Array = []) -> void:
	coords = room_coords
	position = WorldMap.room_origin(coords)
	var layer := TileMapLayer.new()
	layer.name = "Tiles"
	layer.tile_set = Tiles.tileset()
	for y in lines.size():
		for x in lines[y].length():
			var ch := lines[y][x]
			layer.set_cell(Vector2i(x, y), 0, Vector2i(Tiles.atlas_index(ch), 0))
	add_child(layer)
	for thing in things:
		var node := Entities.create(thing["kind"])
		var cell: Vector2i = thing["cell"]
		node.position = (Vector2(cell) + Vector2(0.5, 0.5)) * WorldMap.TILE
		add_child(node)
