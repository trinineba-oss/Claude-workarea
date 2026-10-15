class_name View3D
extends Node3D
## Draws the game in 2.5D. The game itself still runs in 2D (movement, collisions, combat,
## doors, saving: all of it, and all of it tested); this node hides the 2D drawing and shows
## the same world in 3D instead: every Room gets a RoomView (floor and scenery), and every
## character, prop, pickup and light gets an EntityView that follows its 2D twin each frame.
## It also owns the tilted camera, the sky, sun, moon and fog (driven by the game clock), a
## tilt-shift blur, and 3D versions of the floating texts and particle bursts (see Effects).
##
## One 2D pixel is PX units in 3D, so a 64 px tile is 1 unit; 2D (x, y) is 3D (x, z).

const PX := 1.0 / 64.0
## The world's canvas layer bit that the viewport stops drawing (the 2D world is hidden).
const HIDDEN_LAYER := 1 << 19
const CAMERA_DISTANCE := 15.0
const CAMERA_PITCH := deg_to_rad(50.0)
const CAMERA_FOV := 32.0
const CAMERA_SMOOTHING := 6.0
## How far the camera's aim stays inside the edges of the world (or the room, indoors).
const VIEW_MARGIN := Vector2(7.0, 3.0)
const INDOOR_MARGIN := Vector2(7.0, 2.4)

## The view in play (Effects draws its floating texts here).
static var current: View3D

var camera: Camera3D
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var environment: Environment

var _game: Game
var _sky: ProceduralSkyMaterial
var _rooms: Dictionary = {}  # Room -> RoomView
var _entities: Dictionary = {}  # Node2D -> EntityView
var _cutlass: MeshInstance3D
var _aim := Vector3.ZERO
var _snap := true


static func to_3d(pos: Vector2, height := 0.0) -> Vector3:
	return Vector3(pos.x * PX, height, pos.y * PX)


static func to_2d(pos: Vector3) -> Vector2:
	return Vector2(pos.x, pos.z) / PX


func setup(game: Game) -> void:
	_game = game


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null
	get_viewport().canvas_cull_mask |= HIDDEN_LAYER


func _ready() -> void:
	name = "View3D"
	# Hide the 2D world (the HUD lives on its own canvas layers, so it stays).
	_game.visibility_layer = HIDDEN_LAYER
	get_viewport().canvas_cull_mask &= ~HIDDEN_LAYER
	_make_environment()
	_make_camera()
	_make_post()
	_make_cutlass()
	get_tree().node_added.connect(_on_node_added)
	for node in _game.find_children("*", "", true, false):
		_on_node_added(node)


func _process(delta: float) -> void:
	# Keys may be freed nodes (rooms are freed at once on a jump), so the loops stay untyped.
	for room in _rooms.keys():
		if not is_instance_valid(room) or room.is_queued_for_deletion():
			_rooms[room].queue_free()
			_rooms.erase(room)
	for node in _entities.keys():
		var view: EntityView = _entities[node]
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			view.queue_free()
			_entities.erase(node)
		else:
			view.sync()
	_update_sky()
	_update_camera(delta)
	_update_cutlass()


## Jumps the camera to Chad (after a warp or a long jump), instead of gliding there.
func snap_camera() -> void:
	_snap = true


func room_views() -> Array:
	return _rooms.keys().filter(func(r): return is_instance_valid(r)).map(func(r): return _rooms[r])


func entity_view(node: Node2D) -> EntityView:
	return _entities.get(node)


## A short message floating up from a 2D world point (Effects.float_text uses this).
func float_text(world: Vector2, text: String, colour: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 56
	label.outline_size = 16
	label.modulate = colour
	label.outline_modulate = Color(0.1, 0.06, 0.14)
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = to_3d(world, 1.4)
	add_child(label)
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 0.9, 1.1)
	tween.tween_property(label, "modulate:a", 0.0, 1.1).set_delay(0.4)
	tween.tween_property(label, "outline_modulate:a", 0.0, 1.1).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


## A one-shot burst of particles at a 2D world point: "hit", "poof" or "sparkle".
func burst(world: Vector2, kind: String) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = false
	p.position = to_3d(world, 0.6)
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 0.18
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = preload("res://assets/sprites/spark.png")
	quad.material = mat
	p.mesh = quad
	p.direction = Vector3.UP
	p.spread = 180.0
	p.gravity = Vector3.ZERO
	var ramp := Gradient.new()
	match kind:
		"hit":
			p.amount = 12
			p.lifetime = 0.3
			p.initial_velocity_min = 3.5
			p.initial_velocity_max = 6.5
			ramp.set_color(0, Color(1, 1, 1, 1))
			ramp.set_color(1, Color(1, 0.85, 0.3, 0))
		"poof":
			p.amount = 16
			p.lifetime = 0.6
			p.initial_velocity_min = 0.8
			p.initial_velocity_max = 2.4
			p.damping_min = 2.0
			p.damping_max = 3.0
			p.scale_amount_min = 1.6
			p.scale_amount_max = 2.8
			ramp.set_color(0, Color(0.92, 0.9, 0.96, 0.9))
			ramp.set_color(1, Color(0.8, 0.78, 0.86, 0))
		_:
			p.amount = 10
			p.lifetime = 0.5
			p.initial_velocity_min = 1.2
			p.initial_velocity_max = 2.6
			p.gravity = Vector3(0, 2.0, 0)
			ramp.set_color(0, Color(1, 0.95, 0.5, 1))
			ramp.set_color(1, Color(1, 0.8, 0.2, 0))
	p.color_ramp = ramp
	p.finished.connect(p.queue_free)
	add_child(p)
	p.emitting = true


func _on_node_added(node: Node) -> void:
	if not _game.is_ancestor_of(node):
		return
	if node is Room:
		node.ready.connect(_add_room.bind(node), CONNECT_ONE_SHOT | CONNECT_DEFERRED)
		if node.is_node_ready():
			_add_room(node)
	elif _wants_view(node) and not _entities.has(node):
		var view := EntityView.new()
		view.setup(node)
		add_child(view)
		_entities[node] = view


## Untyped: by the time this deferred call runs, the room may already be freed.
func _add_room(room) -> void:
	if not is_instance_valid(room) or room.is_queued_for_deletion() or _rooms.has(room):
		return
	var view := RoomView.new()
	view.build(room, _game.is_indoors())
	add_child(view)
	_rooms[room] = view


static func _wants_view(node: Node) -> bool:
	return (
		node is Player
		or node is Enemy
		or node is Interactable
		or node is Pickup
		or node is Car
		or node is PushBlock
		or node is Plate
		or node is DigSpot
		or node is CrystalSwitch
		or node is Boomerang
		or node is CallalooBlob
	)


# --- camera --------------------------------------------------------------------------------


func _make_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = CAMERA_FOV
	camera.far = 120.0
	add_child(camera)
	camera.make_current()


func _update_camera(delta: float) -> void:
	var player := _game.get_node("Player") as Node2D
	var target := to_3d(player.position)
	var rect: Rect2
	var margin := VIEW_MARGIN
	if _game.is_indoors():
		rect = Rect2(WorldMap.room_origin(_game.coords) * PX, WorldMap.room_size() * PX)
		margin = INDOOR_MARGIN
	else:
		var bounds := _game.world.bounds()
		var size := WorldMap.room_size() * PX
		rect = Rect2(Vector2(bounds.position) * size, Vector2(bounds.size) * size)
	var lo := rect.position + margin
	var hi := rect.end - margin
	target.x = clampf(target.x, lo.x, maxf(lo.x, hi.x)) if hi.x > lo.x else rect.get_center().x
	target.z = clampf(target.z, lo.y, maxf(lo.y, hi.y)) if hi.y > lo.y else rect.get_center().y
	if _snap:
		_aim = target
		_snap = false
	else:
		_aim = _aim.lerp(target, 1.0 - exp(-CAMERA_SMOOTHING * delta))
	var back := Vector3(0, sin(CAMERA_PITCH), cos(CAMERA_PITCH)) * CAMERA_DISTANCE
	camera.position = _aim + back
	camera.look_at(_aim + Vector3(0, 0.4, 0), Vector3.UP)


# --- sky, sun, moon --------------------------------------------------------------------------


func _make_environment() -> void:
	environment = Environment.new()
	var sky := Sky.new()
	_sky = ProceduralSkyMaterial.new()
	sky.sky_material = _sky
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_bloom = 0.06
	environment.glow_hdr_threshold = 0.95
	environment.fog_enabled = true
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.1
	environment.adjustment_contrast = 1.04
	var world_env := WorldEnvironment.new()
	world_env.environment = environment
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 45.0
	add_child(sun)
	moon = DirectionalLight3D.new()
	moon.name = "Moon"
	moon.light_color = Color(0.55, 0.62, 1.0)
	moon.rotation_degrees = Vector3(-55, 30, 0)
	add_child(moon)


func _update_sky() -> void:
	var clock := _game.day_night
	var night := clock.night_amount()
	if _game.is_indoors():
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0.02, 0.015, 0.03)
		environment.ambient_light_color = Color(0.5, 0.42, 0.58)
		environment.ambient_light_energy = 0.42
		environment.fog_light_color = Color(0.08, 0.05, 0.1)
		environment.fog_density = 0.02
		environment.glow_intensity = 0.9
		sun.visible = false
		moon.visible = false
		return
	environment.background_mode = Environment.BG_SKY
	sun.visible = night < 0.98
	moon.visible = night > 0.02
	# The sun rises in the east at 6, is high at noon and sets in the west at 18.
	var t := clampf((clock.hour - 6.0) / 12.0, 0.0, 1.0)
	var elevation := deg_to_rad(8.0 + sin(t * PI) * 52.0)
	var azimuth := deg_to_rad(lerpf(-70.0, 70.0, t))
	sun.rotation = Vector3(-elevation, azimuth, 0)
	var low := 1.0 - sin(t * PI)
	sun.light_color = Color(1.0, 0.97, 0.9).lerp(Color(1.0, 0.6, 0.38), low * low)
	sun.light_energy = (1.0 - night) * 0.95
	moon.light_energy = night * 0.35
	var tint := DayNight.tint_at(clock.hour)
	environment.ambient_light_color = tint.lerp(Color(0.62, 0.7, 0.92), 0.45)
	environment.ambient_light_energy = lerpf(0.32, 0.4, night)
	environment.glow_intensity = lerpf(0.35, 1.0, night)
	environment.fog_light_color = tint.lerp(Color(0.8, 0.86, 1.0), 0.3) * lerpf(1.0, 0.4, night)
	environment.fog_density = lerpf(0.0015, 0.01, night)
	environment.tonemap_exposure = lerpf(0.82, 1.05, night)
	_sky.sky_top_color = Color(0.28, 0.5, 0.88).lerp(Color(0.05, 0.06, 0.16), night)
	_sky.sky_horizon_color = (
		Color(0.72, 0.84, 0.98)
		. lerp(Color(1.0, 0.55, 0.38), low * (1.0 - night))
		. lerp(Color(0.16, 0.13, 0.3), night)
	)
	_sky.ground_horizon_color = _sky.sky_horizon_color.darkened(0.2)
	_sky.ground_bottom_color = Color(0.1, 0.1, 0.12)


# --- the cutlass ------------------------------------------------------------------------------


func _make_cutlass() -> void:
	_cutlass = MeshInstance3D.new()
	_cutlass.name = "Cutlass"
	var blade := BoxMesh.new()
	blade.size = Vector3(0.07, 0.03, 0.85)
	_cutlass.mesh = blade
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.93, 0.95, 1.0)
	mat.metallic = 0.8
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.55, 0.7)
	_cutlass.material_override = mat
	_cutlass.visible = false
	add_child(_cutlass)


## The 2D cutlass is drawn with lines; here it is a blade sweeping round Chad at hip height.
func _update_cutlass() -> void:
	var cutlass := _game.get_node_or_null("Player/Cutlass") as Cutlass
	if cutlass == null or not cutlass.visible:
		_cutlass.visible = false
		return
	var elapsed: float = cutlass.get("_elapsed")
	var duration: float = cutlass.get("_duration")
	var dir: Vector2 = cutlass.get("_dir")
	var t := clampf(elapsed / duration, 0.0, 1.0)
	var angle := dir.angle() - Cutlass.SWEEP / 2.0 + Cutlass.SWEEP * ease(t, 0.5)
	var reach := Vector2.from_angle(angle)
	var centre := to_3d(cutlass.global_position, 0.55)
	_cutlass.visible = true
	_cutlass.position = centre + Vector3(reach.x, 0, reach.y) * 0.6
	_cutlass.look_at(centre + Vector3(reach.x, 0, reach.y) * 2.0, Vector3.UP)


# --- post-processing ----------------------------------------------------------------------------


func _make_post() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TiltShift"
	layer.layer = 4
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/tilt_shift.gdshader")
	rect.material = mat
	layer.add_child(rect)
