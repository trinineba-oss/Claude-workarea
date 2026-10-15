class_name RoomView
extends Node3D
## One room in 3D: its floor (ground3d.gdshader, from the same weights as the 2D floor) and
## its scenery tiles as real shapes: rock blocks, painted walls, fences, trees, bushes, crates
## and bollards. Shapes of a kind share one MultiMesh per room, so a room is a handful of
## draw calls. Built from Room.map_lines; the room's own objects get their own views.

const PX := View3D.PX
const ROCK := Color(0.62, 0.6, 0.6)
const TRUNK := Color(0.42, 0.29, 0.19)
const LEAVES: Array[Color] = [
	Color(0.24, 0.52, 0.27), Color(0.31, 0.6, 0.3), Color(0.2, 0.44, 0.25)
]
const WALLS: Array[Color] = [
	Color(0.93, 0.83, 0.62),
	Color(0.75, 0.88, 0.86),
	Color(0.95, 0.74, 0.7),
	Color(0.84, 0.86, 0.94)
]

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}

var room: Room


func build(source: Room, indoors: bool) -> void:
	room = source
	name = "RoomView_%d_%d" % [room.coords.x, room.coords.y]
	position = View3D.to_3d(room.position)
	var filler_rock := room.filler and room.map_lines.size() > 0 and room.map_lines[0][0] == "#"
	if not filler_rock:
		_add_floor()
	if room.filler:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(room.coords) + 17
	var spots := {}  # kind -> Array of [Transform3D, Color]
	var wall_colour: Color = WALLS[rng.randi_range(0, WALLS.size() - 1)]
	for y in room.map_lines.size():
		var row := room.map_lines[y]
		for x in row.length():
			var at := Vector3(x + 0.5, 0.0, y + 0.5)
			match row[x]:
				"#":
					var h := (
						rng.randf_range(0.9, 1.25) if not indoors else rng.randf_range(1.3, 1.6)
					)
					var tint := ROCK * rng.randf_range(0.85, 1.08)
					_put(
						spots, "rock", at + Vector3(0, h / 2.0, 0), Vector3(1.0, h, 1.0), tint, rng
					)
				"W":
					_put(
						spots,
						"wall",
						at + Vector3(0, 0.7, 0),
						Vector3(1.0, 1.4, 1.0),
						wall_colour,
						null
					)
					_put(
						spots,
						"cap",
						at + Vector3(0, 1.43, 0),
						Vector3(1.04, 0.08, 1.04),
						Color(0.85, 0.84, 0.8),
						null
					)
				"F":
					_put(
						spots,
						"post",
						at + Vector3(-0.45, 0.6, 0),
						Vector3(0.07, 1.2, 0.07),
						Color(0.6, 0.62, 0.66),
						null
					)
					_put(
						spots,
						"mesh",
						at + Vector3(0, 0.6, 0),
						Vector3(1.0, 1.1, 0.03),
						Color(0.7, 0.72, 0.76),
						null
					)
				"T":
					_add_tree(spots, at, rng)
				"b":
					for i in 3:
						var r := rng.randf_range(0.32, 0.45)
						var off := Vector3(
							rng.randf_range(-0.22, 0.22), r * 0.8, rng.randf_range(-0.2, 0.2)
						)
						var leaf: Color = LEAVES[rng.randi_range(0, 2)]
						_put(spots, "ball", at + off, Vector3.ONE * r * 2.0, leaf, null)
				"c":
					var tint := Color(0.66, 0.48, 0.3) * rng.randf_range(0.9, 1.1)
					_put(spots, "crate", at + Vector3(0, 0.4, 0), Vector3(0.8, 0.8, 0.8), tint, rng)
				"o":
					_put(
						spots,
						"bollard",
						at + Vector3(0, 0.3, 0),
						Vector3(0.36, 0.6, 0.36),
						Color(0.25, 0.26, 0.3),
						null
					)
				",":
					for i in 3:
						var flower: Color = [
							Color(1, 0.45, 0.6), Color(1, 1, 1), Color(1, 0.85, 0.3)
						][i]
						var off := Vector3(
							rng.randf_range(-0.35, 0.35), 0.05, rng.randf_range(-0.35, 0.35)
						)
						_put(spots, "petal", at + off, Vector3.ONE * 0.12, flower, null)
	for kind: String in spots:
		_add_multimesh(kind, spots[kind])
	_add_wires()


func _put(
	spots: Dictionary, kind: String, at: Vector3, size: Vector3, colour: Color, rng: Variant
) -> void:
	var basis := Basis.from_scale(size)
	if rng != null:
		basis = Basis(Vector3.UP, (rng as RandomNumberGenerator).randf_range(-0.12, 0.12)) * basis
	if not spots.has(kind):
		spots[kind] = []
	spots[kind].append([Transform3D(basis, at), colour])


func _add_tree(spots: Dictionary, at: Vector3, rng: RandomNumberGenerator) -> void:
	var tall := rng.randf_range(0.85, 1.15)
	_put(
		spots,
		"trunk",
		at + Vector3(0, 0.75 * tall, 0),
		Vector3(0.28, 1.5 * tall, 0.28),
		TRUNK,
		null
	)
	for i in 4:
		var r := rng.randf_range(0.5, 0.72) * tall
		var off := Vector3(
			rng.randf_range(-0.35, 0.35),
			(1.75 + rng.randf_range(0.0, 0.7)) * tall,
			rng.randf_range(-0.3, 0.3)
		)
		var leaf: Color = LEAVES[rng.randi_range(0, 2)]
		_put(spots, "ball", at + off, Vector3(r * 2.0, r * 1.7, r * 2.0), leaf, null)


func _add_multimesh(kind: String, items: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _mesh(kind)
	mm.instance_count = items.size()
	for i in items.size():
		mm.set_instance_transform(i, items[i][0])
		mm.set_instance_color(i, items[i][1])
	var node := MultiMeshInstance3D.new()
	node.name = kind
	node.multimesh = mm
	node.material_override = _material(kind)
	if kind in ["petal", "mesh"]:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)


## Power lines between the poles' crossbars: three sagging wires per span, each a chain of
## thin straight pieces.
func _add_wires() -> void:
	var wires: Wires = null
	for child in room.get_children():
		if child is Wires:
			wires = child
	if wires == null or wires.lines.is_empty():
		return
	var top := PropModel.POLE_HEIGHT - 0.04
	var spots := {"wire": []}
	for span: Array in wires.lines:
		var a := Vector3(span[0].x * PX, top, (span[0].y - Prop.POLE_TOP) * PX)
		var b := Vector3(span[1].x * PX, top, (span[1].y - Prop.POLE_TOP) * PX)
		var along := b - a
		var side := along.cross(Vector3.UP).normalized() * 0.34
		var sag := 0.3 * (1.0 + along.length() / 9.0)
		for offset: float in [-1.0, 0.0, 1.0]:
			var points: Array[Vector3] = []
			for i in 13:
				var t := i / 12.0
				var dip := 4.0 * t * (1.0 - t) * sag
				points.append(a.lerp(b, t) + side * offset + Vector3(0, -dip, 0))
			for i in points.size() - 1:
				var p := points[i]
				var q := points[i + 1]
				var basis := Basis.looking_at(q - p).scaled_local(
					Vector3(0.012, 0.012, p.distance_to(q))
				)
				spots["wire"].append([Transform3D(basis, (p + q) / 2.0), Color(0.16, 0.15, 0.17)])
	_add_multimesh("wire", spots["wire"])


func _add_floor() -> void:
	var ground := room.get_node_or_null("Ground") as Sprite2D
	if ground == null:
		return
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "Floor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(WorldMap.COLS, WorldMap.ROWS)
	floor_mesh.mesh = plane
	floor_mesh.position = Vector3(WorldMap.COLS / 2.0, 0.0, WorldMap.ROWS / 2.0)
	var source := ground.material as ShaderMaterial
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/ground3d.gdshader")
	for param: String in Room.GROUND_TEXTURES:
		mat.set_shader_parameter(param, Room.GROUND_TEXTURES[param])
	mat.set_shader_parameter("weights_tex", ground.texture)
	mat.set_shader_parameter("weights2", source.get_shader_parameter("weights2"))
	mat.set_shader_parameter("room_origin", room.position)
	mat.set_shader_parameter("grid_size", source.get_shader_parameter("grid_size"))
	mat.set_shader_parameter("tile_size", float(WorldMap.TILE))
	floor_mesh.material_override = mat
	floor_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(floor_mesh)


static func _mesh(kind: String) -> Mesh:
	if _meshes.has(kind):
		return _meshes[kind]
	var mesh: Mesh
	match kind:
		"ball", "petal":
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			sphere.radial_segments = 12 if kind == "ball" else 6
			sphere.rings = 7 if kind == "ball" else 3
			mesh = sphere
		"trunk", "bollard":
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.38 if kind == "trunk" else 0.5
			cyl.bottom_radius = 0.5
			cyl.height = 1.0
			cyl.radial_segments = 8 if kind == "trunk" else 12
			mesh = cyl
		_:
			var box := BoxMesh.new()
			box.size = Vector3.ONE
			mesh = box
	_meshes[kind] = mesh
	return mesh


static func _material(kind: String) -> Material:
	if _materials.has(kind):
		return _materials[kind]
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	match kind:
		"rock":
			mat.albedo_texture = preload("res://assets/textures/stone.png")
			mat.uv1_triplanar = true
			mat.uv1_scale = Vector3.ONE * 0.5
		"crate":
			mat.albedo_texture = preload("res://assets/textures/wood.png")
			mat.uv1_triplanar = true
			mat.uv1_scale = Vector3.ONE * 0.4
		"mesh":
			mat.albedo_texture = preload("res://assets/sprites/fence.png")
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		"bollard":
			mat.roughness = 0.4
			mat.metallic = 0.3
	_materials[kind] = mat
	return mat
