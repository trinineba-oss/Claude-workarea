class_name MeshBuilder
extends RefCounted
## Merges simple shapes (boxes, cylinders, spheres, wedges) into one mesh with one surface per
## finish, each shape coloured with vertex colours: a whole food truck is a single mesh of a
## few surfaces instead of dozens of nodes. Sizes are in world units (one tile is one unit).

enum Finish { PAINT, METAL, GLASS, GLOW, STONE, WOOD, CLOTH }

static var _materials: Dictionary = {}

var _parts: Dictionary = {}  # Finish -> [vertices, normals, uvs, colours, indices]


func box(
	size: Vector3, at: Vector3, colour: Color, finish := Finish.PAINT, basis := Basis()
) -> MeshBuilder:
	var mesh := BoxMesh.new()
	mesh.size = size
	_add(mesh, Transform3D(basis, at), colour, finish)
	return self


## Upright cylinder (or cone, with a different top radius) centred on `at`.
func cylinder(
	radius: float,
	height: float,
	at: Vector3,
	colour: Color,
	finish := Finish.PAINT,
	basis := Basis(),
	top_radius := -1.0,
	sides := 12
) -> MeshBuilder:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	_add(mesh, Transform3D(basis, at), colour, finish)
	return self


func sphere(
	radius: float,
	at: Vector3,
	colour: Color,
	finish := Finish.PAINT,
	stretch := Vector3.ONE,
	segments := 12
) -> MeshBuilder:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = maxi(segments / 2, 3)
	_add(mesh, Transform3D(Basis.from_scale(stretch), at), colour, finish)
	return self


## A triangular prism (a roof, a boat's bow): the ridge runs along z, the point is on top.
func wedge(
	size: Vector3, at: Vector3, colour: Color, finish := Finish.PAINT, basis := Basis()
) -> MeshBuilder:
	var mesh := PrismMesh.new()
	mesh.size = size
	_add(mesh, Transform3D(basis, at), colour, finish)
	return self


func is_empty() -> bool:
	return _parts.is_empty()


func build(node_name := "Model") -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	for finish: int in _parts:
		var part: Array = _parts[finish]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = part[0]
		arrays[Mesh.ARRAY_NORMAL] = part[1]
		arrays[Mesh.ARRAY_TEX_UV] = part[2]
		arrays[Mesh.ARRAY_COLOR] = part[3]
		arrays[Mesh.ARRAY_INDEX] = part[4]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, material(finish))
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	return node


static func material(finish: int) -> Material:
	if _materials.has(finish):
		return _materials[finish]
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.6
	match finish:
		Finish.METAL:
			# Not too shiny: indoors there is little for metal to reflect.
			mat.metallic = 0.35
			mat.roughness = 0.4
		Finish.GLASS:
			mat.metallic = 0.4
			mat.roughness = 0.06
		Finish.GLOW:
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		Finish.STONE:
			mat.albedo_texture = preload("res://assets/textures/stone.png")
			mat.uv1_triplanar = true
			mat.uv1_scale = Vector3.ONE * 0.5
			mat.roughness = 0.9
		Finish.WOOD:
			mat.albedo_texture = preload("res://assets/textures/wood.png")
			mat.uv1_triplanar = true
			mat.uv1_scale = Vector3.ONE * 0.4
			mat.roughness = 0.8
		Finish.CLOTH:
			mat.roughness = 0.95
	_materials[finish] = mat
	return mat


func _add(mesh: PrimitiveMesh, xform: Transform3D, colour: Color, finish: int) -> void:
	var arrays := mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if not _parts.has(finish):
		_parts[finish] = [
			PackedVector3Array(),
			PackedVector3Array(),
			PackedVector2Array(),
			PackedColorArray(),
			PackedInt32Array()
		]
	var part: Array = _parts[finish]
	var out_verts: PackedVector3Array = part[0]
	var out_normals: PackedVector3Array = part[1]
	var out_uvs: PackedVector2Array = part[2]
	var out_colours: PackedColorArray = part[3]
	var out_indices: PackedInt32Array = part[4]
	var base := out_verts.size()
	var normal_basis := xform.basis.inverse().transposed()
	for i in verts.size():
		out_verts.append(xform * verts[i])
		out_normals.append((normal_basis * normals[i]).normalized())
		out_uvs.append(uvs[i] if i < uvs.size() else Vector2.ZERO)
		out_colours.append(colour)
	for index in indices:
		out_indices.append(base + index)
	_parts[finish] = [out_verts, out_normals, out_uvs, out_colours, out_indices]
