class_name PropModel
extends Node3D
## A solid 3D model for a 2D thing that is drawn flat in 2D: food trucks, cars, utility poles,
## shops, the gas station, the boat, the cave mouth, signs and torches, and the temple's
## chests, doors and gates, push blocks, plates and crystal switches. Built from MeshBuilder
## shapes in code (no model files). The model sits at the 2D node's origin (its feet) and
## follows the thing's state: a chest's lid opens, gates sink into the floor, a switch's orb
## turns blue, a car turns to the way it drives.

const F := MeshBuilder.Finish
const TRUCKS := {
	"truck_red": Color(0.84, 0.17, 0.15),
	"truck_yellow": Color(0.98, 0.76, 0.18),
	"truck_orange": Color(0.95, 0.5, 0.14),
	"truck_teal": Color(0.08, 0.58, 0.6),
	"truck_purple": Color(0.55, 0.3, 0.72),
}
const CARS := {
	"car_white": Color(0.92, 0.93, 0.95),
	"car_red": Color(0.8, 0.12, 0.12),
	"car_blue": Color(0.16, 0.36, 0.78),
	"car_grey": Color(0.52, 0.55, 0.6),
}
const SHOPS := {
	"shop_blue": [Color(0.5, 0.7, 0.88), Color(0.15, 0.35, 0.65)],
	"shop_pink": [Color(0.95, 0.64, 0.74), Color(0.8, 0.25, 0.45)],
	"shop_cream": [Color(0.96, 0.9, 0.74), Color(0.3, 0.55, 0.3)],
}
const DARK := Color(0.08, 0.08, 0.1)
const TYRE := Color(0.1, 0.1, 0.11)
const CHROME := Color(0.8, 0.82, 0.86)
const WHITE := Color(0.95, 0.95, 0.93)
const WINDOW := Color(0.22, 0.3, 0.38)
const LAMP := Color(1.0, 0.86, 0.55)
const BRASS := Color(0.85, 0.66, 0.25)
const SIGN_TEXT := Color(0.25, 0.12, 0.08)
## Utility poles are this tall: Prop.POLE_TOP, where the wires hang.
const POLE_HEIGHT := -Prop.POLE_TOP / 64.0

var kind := ""

## Moving parts, by kind.
var _lid: Node3D
var _inside: Node3D
var _up: Node3D
var _down: Node3D
var _flame: Node3D
var _time := 0.0


## A model for `node`, or null when it has none (it stays a sprite).
static func make(node: Node2D) -> PropModel:
	var model := PropModel.new()
	model.name = "Model"
	if node is Prop:
		model._build_prop(node.prop_id, GameData.prop(node.prop_id), node)
	elif node is Car:
		model._build_car(node._sprite.texture.resource_path.get_file().get_basename())
	elif node is Forage:
		model._build_forage(node.forage_id)
	elif node is Signpost:
		model._build_sign()
	elif node is Chest:
		model._build_chest()
	elif node is DungeonDoor:
		model._build_door(node)
	elif node is PushBlock:
		model._build_block()
	elif node is Plate:
		model._build_plate()
	elif node is CrystalSwitch:
		model._build_switch()
	if model.kind == "":
		model.free()
		return null
	return model


## Follows the 2D thing's state each frame.
func refresh(source: Node2D, delta: float) -> void:
	_time += delta
	match kind:
		"car":
			var velocity: Vector2 = source.velocity
			if velocity != Vector2.ZERO:
				rotation.y = atan2(velocity.x, velocity.y)
			visible = source.modulate.a > 0.35
		"chest":
			var opened: bool = source.opened
			var target := -1.9 if opened else 0.0
			_lid.rotation.x = move_toward(_lid.rotation.x, target, delta * 6.0)
			_inside.visible = opened
		"door":
			var sprite: Sprite2D = source._sprite
			visible = sprite.visible
			scale.y = maxf(sprite.scale.y, 0.01)
		"plate":
			var pressed: bool = source._sprite.texture == Plate.DOWN
			_up.visible = not pressed
			_down.visible = pressed
		"switch":
			var on: bool = source.is_on()
			_up.visible = not on
			_down.visible = on
			var bob := sin(_time * 2.2) * 0.04
			_up.position.y = bob
			_down.position.y = bob
		"forage":
			_up.visible = source._sprite.texture == source._full
			if _down != null:
				_down.visible = not _up.visible
		"torch":
			var flicker := 1.0 + sin(_time * 17.0) * 0.08 + sin(_time * 7.3) * 0.06
			_flame.scale = Vector3(1.0, flicker, 1.0)


func _build_prop(id: String, data: Dictionary, node: Prop) -> void:
	var sprite: String = data.get("sprite", "")
	var label: String = data.get("label", "")
	if TRUCKS.has(sprite):
		_build_truck(TRUCKS[sprite], label)
	elif CARS.has(sprite):
		_build_parked_car(CARS[sprite])
	elif SHOPS.has(sprite):
		_build_shop(SHOPS[sprite][0], SHOPS[sprite][1], label)
	else:
		match id:
			"pole":
				_build_pole(node)
			"gas_station":
				_build_gas_station(label)
			"yellow_building":
				_build_building()
			"boat":
				_build_boat()
			"torch":
				_build_torch()
			"cave_mouth":
				_build_cave_mouth()


# --- the street -------------------------------------------------------------------------------


func _build_truck(paint: Color, text: String) -> void:
	kind = "truck"
	var b := MeshBuilder.new()
	var z := -0.45  # the body's centre; its front faces the street (+z)
	var front := z + 0.5
	# Chassis and wheels.
	b.box(Vector3(2.75, 0.14, 0.9), Vector3(0, 0.26, z), DARK, F.METAL)
	for x: float in [-0.9, 0.95]:
		for side: float in [-0.42, 0.42]:
			var axle := Basis(Vector3.RIGHT, PI / 2.0)
			b.cylinder(0.21, 0.14, Vector3(x, 0.21, z + side), TYRE, F.CLOTH, axle)
			b.cylinder(0.1, 0.15, Vector3(x, 0.21, z + side), CHROME, F.METAL, axle)
	# Kitchen box, with a white stripe along the bottom.
	b.box(Vector3(2.15, 1.3, 1.0), Vector3(-0.32, 0.98, z), paint)
	b.box(Vector3(2.17, 0.1, 1.02), Vector3(-0.32, 0.45, z), WHITE)
	# Cab at the right with a windscreen and a side window.
	b.box(Vector3(0.6, 0.95, 0.96), Vector3(1.05, 0.8, z), paint)
	b.box(Vector3(0.62, 0.08, 0.98), Vector3(1.05, 0.45, z), WHITE)
	b.box(Vector3(0.04, 0.38, 0.8), Vector3(1.36, 1.02, z), WINDOW, F.GLASS)
	b.box(Vector3(0.36, 0.34, 0.03), Vector3(1.08, 1.02, front - 0.02), WINDOW, F.GLASS)
	b.box(Vector3(0.12, 0.08, 0.06), Vector3(1.34, 0.6, front - 0.1), LAMP, F.GLOW)
	# Serving hatch: a lit kitchen behind a steel counter, under a striped awning.
	b.box(Vector3(1.35, 0.52, 0.04), Vector3(-0.35, 1.08, front), Color(1.0, 0.8, 0.5), F.GLOW)
	b.box(Vector3(1.45, 0.06, 0.2), Vector3(-0.35, 0.8, front + 0.08), CHROME, F.METAL)
	var tilt := Basis(Vector3.RIGHT, 0.38)
	for i in 6:
		var stripe := WHITE if i % 2 == 0 else paint.lightened(0.15)
		b.box(
			Vector3(0.26, 0.035, 0.5),
			Vector3(-0.35 - 0.65 + 0.26 * i, 1.44, front + 0.2),
			stripe,
			F.CLOTH,
			tilt
		)
	# Sign board on the roof.
	b.box(Vector3(1.8, 0.42, 0.08), Vector3(-0.32, 1.88, z + 0.1), Color(0.98, 0.94, 0.82))
	b.box(Vector3(0.06, 0.3, 0.06), Vector3(-1.0, 1.66, z + 0.1), DARK, F.METAL)
	b.box(Vector3(0.06, 0.3, 0.06), Vector3(0.36, 1.66, z + 0.1), DARK, F.METAL)
	_add(b)
	_sign(text, Vector3(-0.32, 1.88, z + 0.15), 1.7)


func _build_parked_car(paint: Color) -> void:
	_car_body(paint, Vector3(0, 0, -0.75))
	kind = "parked_car"


func _build_car(texture_name: String) -> void:
	_car_body(CARS.get(texture_name, CARS["car_white"]), Vector3(0, 0, -0.25))
	kind = "car"


## A car facing +z (its headlights), centred on `at`.
func _car_body(paint: Color, at: Vector3) -> void:
	var b := MeshBuilder.new()
	b.box(Vector3(0.78, 0.3, 1.46), at + Vector3(0, 0.3, 0), paint)
	b.box(Vector3(0.68, 0.27, 0.72), at + Vector3(0, 0.58, -0.08), WINDOW, F.GLASS)
	b.box(Vector3(0.66, 0.05, 0.62), at + Vector3(0, 0.735, -0.1), paint)
	b.box(Vector3(0.8, 0.1, 0.06), at + Vector3(0, 0.22, 0.72), CHROME, F.METAL)
	b.box(Vector3(0.8, 0.1, 0.06), at + Vector3(0, 0.22, -0.72), CHROME, F.METAL)
	for side: float in [-0.25, 0.25]:
		b.box(Vector3(0.16, 0.07, 0.03), at + Vector3(side, 0.36, 0.735), LAMP, F.GLOW)
		b.box(Vector3(0.16, 0.06, 0.03), at + Vector3(side, 0.36, -0.735), Color(0.9, 0.1, 0.1))
	for x: float in [-0.38, 0.38]:
		for z: float in [-0.46, 0.46]:
			var axle := Basis(Vector3.FORWARD, PI / 2.0)
			b.cylinder(0.15, 0.1, at + Vector3(x, 0.15, z), TYRE, F.CLOTH, axle)
	_add(b)


func _build_pole(node: Prop) -> void:
	kind = "pole"
	var b := MeshBuilder.new()
	var wood := Color(0.42, 0.33, 0.25)
	b.cylinder(0.08, POLE_HEIGHT, Vector3(0, POLE_HEIGHT / 2.0, 0), wood, F.WOOD, Basis(), 0.06, 8)
	b.box(Vector3(0.1, 0.08, 0.8), Vector3(0, POLE_HEIGHT - 0.08, 0), wood, F.WOOD)
	for z: float in [-0.34, 0.0, 0.34]:
		b.cylinder(0.035, 0.1, Vector3(0, POLE_HEIGHT - 0.0, z), WHITE, F.PAINT, Basis(), -1.0, 6)
	# The lamp arm leans out over the road (the middle of the room).
	var local_y := posmod(int(node.position.y / WorldMap.TILE), WorldMap.ROWS)
	var out := 1.0 if local_y < WorldMap.ROWS / 2 else -1.0
	var arm := POLE_HEIGHT - 0.5
	b.box(Vector3(0.05, 0.05, 0.7), Vector3(0, arm, 0.35 * out), DARK, F.METAL)
	b.box(Vector3(0.22, 0.08, 0.3), Vector3(0, arm - 0.02, 0.72 * out), DARK, F.METAL)
	b.box(Vector3(0.18, 0.03, 0.24), Vector3(0, arm - 0.075, 0.72 * out), LAMP, F.GLOW)
	b.box(Vector3(0.25, 0.32, 0.2), Vector3(0, 1.9, -0.12 * out), Color(0.55, 0.57, 0.58), F.METAL)
	_add(b)


func _build_shop(wall: Color, trim: Color, text: String) -> void:
	kind = "shop"
	var b := MeshBuilder.new()
	var z := -0.6
	var front := z + 0.6
	b.box(Vector3(2.9, 2.3, 1.2), Vector3(0, 1.15, z), wall)
	b.box(Vector3(3.0, 0.14, 1.3), Vector3(0, 2.33, z), WHITE)
	# Open doorway on the left, rolled-down shutter on the right.
	b.box(Vector3(1.0, 1.3, 0.04), Vector3(-0.75, 0.65, front), Color(0.95, 0.82, 0.55), F.GLOW)
	b.box(Vector3(1.1, 0.06, 0.08), Vector3(-0.75, 1.32, front), trim)
	b.box(Vector3(1.2, 1.3, 0.05), Vector3(0.6, 0.65, front), Color(0.6, 0.62, 0.64), F.METAL)
	for i in 6:
		b.box(Vector3(1.2, 0.02, 0.06), Vector3(0.6, 0.15 + 0.2 * i, front + 0.01), DARK, F.METAL)
	# Awning and sign.
	b.box(
		Vector3(2.8, 0.05, 0.55),
		Vector3(0, 1.5, front + 0.22),
		trim,
		F.CLOTH,
		Basis(Vector3.RIGHT, 0.3)
	)
	b.box(Vector3(2.4, 0.42, 0.06), Vector3(0, 1.88, front + 0.02), Color(0.98, 0.96, 0.9))
	_add(b)
	_sign(text, Vector3(0, 1.88, front + 0.06), 2.3)


func _build_building() -> void:
	kind = "building"
	var b := MeshBuilder.new()
	var wall := Color(0.98, 0.85, 0.4)
	var z := -0.86
	var front := z + 0.9
	b.box(Vector3(5.9, 3.3, 1.8), Vector3(0, 1.65, z), wall)
	b.box(Vector3(6.0, 0.16, 1.9), Vector3(0, 3.33, z), WHITE)
	b.box(Vector3(5.92, 0.1, 1.82), Vector3(0, 1.7, z), WHITE)
	for row in 2:
		for col in 5:
			var x := -2.3 + col * 1.15
			if row == 0 and col == 2:
				# The front door.
				b.box(
					Vector3(0.75, 1.25, 0.04),
					Vector3(x, 0.63, front),
					Color(0.45, 0.28, 0.18),
					F.WOOD
				)
				continue
			var y := 0.95 if row == 0 else 2.45
			b.box(Vector3(0.72, 0.82, 0.03), Vector3(x, y, front), WHITE)
			b.box(Vector3(0.6, 0.7, 0.04), Vector3(x, y, front + 0.005), WINDOW, F.GLASS)
			b.box(Vector3(0.8, 0.06, 0.12), Vector3(x, y - 0.44, front + 0.05), WHITE)
	# A black water tank on the roof, as on so many roofs in San Fernando.
	b.cylinder(
		0.36, 0.7, Vector3(1.8, 3.76, z - 0.2), Color(0.12, 0.12, 0.13), F.PAINT, Basis(), 0.34
	)
	b.box(Vector3(0.8, 0.1, 0.8), Vector3(1.8, 3.42, z - 0.2), Color(0.5, 0.5, 0.52), F.METAL)
	_add(b)


func _build_gas_station(text: String) -> void:
	kind = "gas_station"
	var b := MeshBuilder.new()
	var z := -0.7
	# Canopy on two pillars over a pump island; Chad can walk underneath.
	b.box(Vector3(4.6, 0.26, 2.0), Vector3(0, 2.75, z), WHITE)
	b.box(Vector3(4.64, 0.14, 2.04), Vector3(0, 2.6, z), Color(0.85, 0.15, 0.15))
	b.box(Vector3(4.0, 0.02, 1.6), Vector3(0, 2.61, z), Color(1.0, 0.98, 0.9), F.GLOW)
	for x: float in [-1.8, 1.8]:
		b.box(Vector3(0.22, 2.6, 0.22), Vector3(x, 1.3, z), WHITE)
	b.box(Vector3(2.5, 0.15, 0.7), Vector3(0, 0.075, -0.36), Color(0.75, 0.75, 0.72), F.STONE)
	for x: float in [-0.65, 0.65]:
		b.box(Vector3(0.42, 0.95, 0.3), Vector3(x, 0.62, -0.36), WHITE)
		b.box(Vector3(0.43, 0.2, 0.31), Vector3(x, 0.98, -0.36), Color(0.85, 0.15, 0.15))
		b.box(Vector3(0.24, 0.16, 0.02), Vector3(x, 0.72, -0.2), Color(0.3, 0.9, 0.6), F.GLOW)
	# Price sign on a pylon at the side.
	b.box(Vector3(0.14, 2.2, 0.14), Vector3(2.2, 1.1, -0.2), CHROME, F.METAL)
	b.box(Vector3(0.9, 0.6, 0.1), Vector3(2.2, 2.35, -0.2), Color(0.85, 0.15, 0.15))
	_add(b)
	_sign(text, Vector3(2.2, 2.35, -0.14), 0.85, WHITE)


func _build_boat() -> void:
	kind = "boat"
	var b := MeshBuilder.new()
	var hull := Color(0.32, 0.55, 0.72)
	var trim := Color(0.95, 0.9, 0.78)
	var z := -0.5
	# Chad's wrecked pirogue, beached on the dock and listing to one side.
	var lean := Basis(Vector3.RIGHT, 0.16)
	b.box(Vector3(1.9, 0.42, 0.85), Vector3(-0.25, 0.22, z), hull, F.PAINT, lean)
	# Open deck inside a pale rim.
	b.box(
		Vector3(1.8, 0.04, 0.72),
		Vector3(-0.25, 0.43, z + 0.06),
		Color(0.5, 0.38, 0.26),
		F.WOOD,
		lean
	)
	for side: float in [-0.43, 0.43]:
		b.box(Vector3(1.92, 0.08, 0.06), Vector3(-0.25, 0.46, z + side + 0.07), trim, F.PAINT, lean)
	b.box(Vector3(0.06, 0.08, 0.87), Vector3(-1.2, 0.46, z + 0.07), trim, F.PAINT, lean)
	for side: float in [-1.0, 1.0]:
		var turn := Basis(Vector3.UP, side * 0.6) * lean
		b.box(Vector3(0.72, 0.42, 0.06), Vector3(0.9, 0.22, z + side * 0.22), hull, F.PAINT, turn)
	# A broken board and a hole in the side.
	b.box(Vector3(0.36, 0.2, 0.03), Vector3(-0.6, 0.24, z + 0.45), DARK, F.PAINT, lean)
	b.box(
		Vector3(0.5, 0.05, 0.12),
		Vector3(-1.45, 0.03, z + 0.55),
		hull,
		F.WOOD,
		Basis(Vector3.UP, 0.7)
	)
	# Mast and a patched sail, still looking hopeful.
	b.cylinder(0.035, 1.9, Vector3(0.1, 1.2, z), Color(0.55, 0.42, 0.3), F.WOOD, lean)
	b.box(Vector3(0.9, 0.03, 0.03), Vector3(-0.3, 0.65, z + 0.05), Color(0.55, 0.42, 0.3), F.WOOD)
	var sail := Basis(Vector3.UP, 0.25) * lean
	b.box(
		Vector3(0.8, 1.15, 0.02),
		Vector3(-0.3, 1.25, z + 0.1),
		Color(0.96, 0.93, 0.85),
		F.CLOTH,
		sail
	)
	b.box(
		Vector3(0.24, 0.24, 0.025),
		Vector3(-0.45, 1.05, z + 0.12),
		Color(0.85, 0.35, 0.25),
		F.CLOTH,
		sail
	)
	_add(b)


func _build_torch() -> void:
	kind = "torch"
	var b := MeshBuilder.new()
	b.cylinder(0.05, 1.05, Vector3(0, 0.52, 0), Color(0.4, 0.28, 0.18), F.WOOD, Basis(), 0.04, 6)
	b.cylinder(0.08, 0.16, Vector3(0, 1.1, 0), DARK, F.METAL, Basis(), 0.17, 8)
	b.box(Vector3(0.3, 0.12, 0.3), Vector3(0, 0.06, 0), Color(0.5, 0.48, 0.46), F.STONE)
	_add(b)
	var flame := MeshBuilder.new()
	flame.sphere(0.13, Vector3(0, 0.0, 0), Color(1.0, 0.55, 0.15), F.GLOW, Vector3(1, 1.7, 1), 8)
	flame.sphere(
		0.07, Vector3(0, -0.02, 0.04), Color(1.0, 0.92, 0.55), F.GLOW, Vector3(1, 1.5, 1), 8
	)
	_flame = flame.build("Flame")
	_flame.position = Vector3(0, 1.3, 0)
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_flame)


func _build_cave_mouth() -> void:
	kind = "cave_mouth"
	var b := MeshBuilder.new()
	var rock := Color(0.6, 0.57, 0.53)
	var z := -0.6
	# A dark opening between two leaning boulders under a lintel stone.
	b.box(Vector3(1.2, 1.25, 0.3), Vector3(0, 0.62, z - 0.1), Color(0.02, 0.02, 0.03))
	for side: float in [-1.0, 1.0]:
		var lean := Basis(Vector3.BACK, side * 0.12)
		b.box(Vector3(0.62, 1.45, 0.8), Vector3(side * 0.92, 0.7, z), rock, F.STONE, lean)
		b.sphere(
			0.3, Vector3(side * 1.3, 0.18, z + 0.4), rock * 0.92, F.STONE, Vector3(1, 0.65, 0.9), 8
		)
	b.box(
		Vector3(2.5, 0.48, 0.9),
		Vector3(0, 1.55, z),
		rock * 1.05,
		F.STONE,
		Basis(Vector3.BACK, 0.04)
	)
	b.sphere(0.16, Vector3(0.55, 0.1, z + 0.55), rock, F.STONE, Vector3(1, 0.7, 1), 6)
	# Hanging vines.
	for x: float in [-0.4, -0.1, 0.3]:
		b.box(
			Vector3(0.05, 0.45, 0.03), Vector3(x, 1.12, z + 0.38), Color(0.25, 0.5, 0.22), F.CLOTH
		)
	_add(b)


func _build_sign() -> void:
	kind = "sign"
	var b := MeshBuilder.new()
	var wood := Color(0.62, 0.45, 0.3)
	b.box(Vector3(0.09, 0.8, 0.09), Vector3(0, 0.4, 0), wood, F.WOOD)
	b.box(Vector3(0.72, 0.42, 0.07), Vector3(0, 0.82, 0.02), wood.lightened(0.1), F.WOOD)
	for y: float in [0.74, 0.84, 0.92]:
		b.box(Vector3(0.5, 0.025, 0.01), Vector3(0, y, 0.06), Color(0.3, 0.2, 0.12))
	_add(b)


# --- plants Chad can pick -----------------------------------------------------------------------


func _build_forage(id: String) -> void:
	var b := MeshBuilder.new()
	var fruit := MeshBuilder.new()
	var leaf := Color(0.25, 0.55, 0.25)
	match id:
		"coconut_palm":
			# A leaning trunk of rings, drooping fronds and a bunch of coconuts.
			var top := Vector3.ZERO
			for i in 7:
				var t := i / 6.0
				var at := Vector3(0.05 * i * t, 0.18 + i * 0.36, 0.0)
				var radius := lerpf(0.12, 0.07, t)
				b.cylinder(
					radius,
					0.38,
					at,
					Color(0.58, 0.45, 0.32),
					F.WOOD,
					Basis(Vector3.BACK, -0.05 * i),
					radius * 0.85,
					8
				)
				top = at + Vector3(0, 0.2, 0)
			for i in 8:
				var turn := Basis(Vector3.UP, TAU * i / 8.0 + 0.3)
				var frond := turn * Basis(Vector3.BACK, -0.5 - 0.1 * (i % 2))
				var shade := leaf.lightened(0.08 * (i % 3))
				b.box(
					Vector3(1.1, 0.03, 0.26),
					top + frond * Vector3(0.52, 0, 0),
					shade,
					F.CLOTH,
					frond
				)
			for i in 3:
				var at := top + Basis(Vector3.UP, TAU * i / 3.0) * Vector3(0.12, -0.14, 0)
				fruit.sphere(0.1, at, Color(0.45, 0.5, 0.2), F.PAINT, Vector3.ONE, 8)
		"mango_tree":
			b.cylinder(
				0.14, 1.4, Vector3(0, 0.7, 0), Color(0.42, 0.29, 0.19), F.WOOD, Basis(), 0.1, 8
			)
			var rng := RandomNumberGenerator.new()
			rng.seed = 7
			for i in 5:
				var at := Vector3(
					rng.randf_range(-0.4, 0.4),
					1.7 + rng.randf_range(0, 0.5),
					rng.randf_range(-0.3, 0.3)
				)
				var r := rng.randf_range(0.48, 0.62)
				b.sphere(
					r,
					at,
					Color(0.18, 0.45, 0.22) * rng.randf_range(0.9, 1.15),
					F.PAINT,
					Vector3(1, 0.85, 1),
					12
				)
				var dir := (
					Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 0.4), 1.0).normalized()
				)
				fruit.sphere(
					0.09,
					at + dir * r * 0.95,
					Color(0.98, 0.55, 0.15),
					F.PAINT,
					Vector3(1, 1.3, 1),
					8
				)
		"chadon_beni_patch":
			for i in 9:
				var turn := Basis(Vector3.UP, TAU * i / 9.0) * Basis(Vector3.BACK, 0.35)
				var size := Vector3(0.32, 0.02, 0.1)
				fruit.box(
					size, turn * Vector3(0.15, 0.08, 0), Color(0.3, 0.62, 0.25), F.CLOTH, turn
				)
			b.sphere(
				0.1, Vector3(0, 0.02, 0), Color(0.35, 0.28, 0.2), F.PAINT, Vector3(1.6, 0.4, 1.6), 8
			)
		"pepper_bush":
			for i in 3:
				var at := Vector3(0.15 * cos(i * 2.1), 0.25, 0.12 * sin(i * 2.1))
				b.sphere(0.22, at, leaf * (0.9 + 0.08 * i), F.PAINT, Vector3(1, 0.85, 1), 10)
			for i in 6:
				var at := Vector3(0.28 * cos(i * 1.05), 0.2 + 0.12 * (i % 2), 0.24 * sin(i * 1.05))
				var colour := Color(0.95, 0.2, 0.12) if i % 3 != 0 else Color(1.0, 0.8, 0.15)
				fruit.sphere(0.06, at, colour, F.PAINT, Vector3(1, 1.2, 1), 6)
		_:
			return
	kind = "forage"
	_add(b)
	_up = fruit.build("Fruit")
	add_child(_up)


# --- the temple -------------------------------------------------------------------------------


func _build_chest() -> void:
	kind = "chest"
	var z := 0.06
	var wood := Color(0.6, 0.38, 0.2)
	var b := MeshBuilder.new()
	b.box(Vector3(0.82, 0.42, 0.56), Vector3(0, 0.21, z), wood, F.WOOD)
	for x: float in [-0.3, 0.3]:
		b.box(Vector3(0.07, 0.43, 0.57), Vector3(x, 0.21, z), BRASS, F.METAL)
	b.box(Vector3(0.12, 0.14, 0.03), Vector3(0, 0.36, z + 0.29), BRASS, F.METAL)
	_add(b)
	var glow := MeshBuilder.new()
	glow.box(Vector3(0.7, 0.04, 0.44), Vector3(0, 0.41, z), Color(1.0, 0.92, 0.5), F.GLOW)
	_inside = glow.build("Inside")
	_inside.visible = false
	add_child(_inside)
	# The lid turns about its back edge.
	var lid := MeshBuilder.new()
	lid.box(Vector3(0.84, 0.16, 0.58), Vector3(0, 0.08, 0.29), wood.lightened(0.08), F.WOOD)
	for x: float in [-0.3, 0.3]:
		lid.box(Vector3(0.07, 0.17, 0.59), Vector3(x, 0.08, 0.29), BRASS, F.METAL)
	_lid = Node3D.new()
	_lid.name = "Lid"
	_lid.position = Vector3(0, 0.42, z - 0.29)
	_lid.add_child(lid.build("LidMesh"))
	add_child(_lid)


func _build_door(door: DungeonDoor) -> void:
	kind = "door"
	var b := MeshBuilder.new()
	var height := 1.5
	match door.mode:
		DungeonDoor.Mode.GATE, DungeonDoor.Mode.SHUTTER:
			for i in 9:
				var x := -0.45 + i * 0.237
				b.cylinder(
					0.04, height, Vector3(x, height / 2.0, 0), Color(0.3, 0.3, 0.34), F.METAL
				)
			for y: float in [0.35, 1.2]:
				b.box(Vector3(2.0, 0.08, 0.08), Vector3(0.5, y, 0), Color(0.3, 0.3, 0.34), F.METAL)
		_:
			var boss := door.mode == DungeonDoor.Mode.BOSS
			var wood := Color(0.55, 0.16, 0.12) if boss else Color(0.5, 0.33, 0.2)
			b.box(Vector3(2.0, height, 0.4), Vector3(0.5, height / 2.0, 0), wood, F.WOOD)
			for y: float in [0.3, 1.15]:
				b.box(Vector3(2.02, 0.1, 0.42), Vector3(0.5, y, 0), DARK, F.METAL)
			b.box(Vector3(0.24, 0.3, 0.06), Vector3(0.5, 0.72, 0.22), BRASS, F.METAL)
			b.box(Vector3(0.05, 0.1, 0.02), Vector3(0.5, 0.7, 0.255), DARK)
			if boss:
				# A pepper, the seal of the Pepper Key.
				b.sphere(
					0.13,
					Vector3(0.5, 1.22, 0.22),
					Color(0.95, 0.2, 0.1),
					F.GLOW,
					Vector3(1, 1.5, 0.5),
					8
				)
				b.box(
					Vector3(0.04, 0.1, 0.04), Vector3(0.5, 1.45, 0.22), Color(0.2, 0.6, 0.2), F.GLOW
				)
	_add(b)
	if not door.horizontal:
		rotation.y = -PI / 2.0


func _build_block() -> void:
	kind = "block"
	var b := MeshBuilder.new()
	var stone := Color(0.72, 0.68, 0.62)
	b.box(Vector3(0.94, 0.86, 0.94), Vector3(0, 0.43, 0), stone, F.STONE)
	b.box(Vector3(0.86, 0.08, 0.86), Vector3(0, 0.9, 0), stone.lightened(0.12), F.STONE)
	_add(b)


func _build_plate() -> void:
	kind = "plate"
	var base := MeshBuilder.new()
	base.cylinder(0.44, 0.03, Vector3(0, 0.015, 0), Color(0.45, 0.43, 0.42), F.STONE)
	_add(base)
	var up := MeshBuilder.new()
	up.cylinder(0.34, 0.08, Vector3(0, 0.07, 0), Color(0.85, 0.62, 0.25), F.METAL)
	_up = up.build("Up")
	add_child(_up)
	var down := MeshBuilder.new()
	down.cylinder(0.34, 0.03, Vector3(0, 0.035, 0), Color(0.45, 0.8, 0.45), F.METAL)
	_down = down.build("Down")
	_down.visible = false
	add_child(_down)


func _build_switch() -> void:
	kind = "switch"
	var b := MeshBuilder.new()
	var stone := Color(0.6, 0.58, 0.56)
	b.cylinder(0.3, 0.12, Vector3(0, 0.06, 0), stone, F.STONE)
	b.cylinder(0.16, 0.5, Vector3(0, 0.35, 0), stone, F.STONE, Basis(), 0.12, 8)
	b.cylinder(0.12, 0.08, Vector3(0, 0.62, 0), BRASS, F.METAL, Basis(), 0.2, 8)
	_add(b)
	var off := MeshBuilder.new()
	off.sphere(0.2, Vector3(0, 0.84, 0), Color(1.0, 0.25, 0.25), F.GLOW, Vector3.ONE, 14)
	_up = off.build("Off")
	add_child(_up)
	var on := MeshBuilder.new()
	on.sphere(0.2, Vector3(0, 0.84, 0), Color(0.35, 0.7, 1.0), F.GLOW, Vector3.ONE, 14)
	_down = on.build("On")
	_down.visible = false
	add_child(_down)


func _add(b: MeshBuilder) -> MeshInstance3D:
	var mesh := b.build("Mesh")
	add_child(mesh)
	return mesh


## Painted lettering on a sign board, facing the street.
func _sign(text: String, at: Vector3, width: float, colour := SIGN_TEXT) -> void:
	if text == "":
		return
	var label := Label3D.new()
	label.name = "Sign"
	label.text = text
	label.font_size = 64
	label.outline_size = 0
	label.modulate = colour
	label.shaded = true
	label.position = at
	label.pixel_size = minf(0.0055, width / (text.length() * 40.0))
	add_child(label)
