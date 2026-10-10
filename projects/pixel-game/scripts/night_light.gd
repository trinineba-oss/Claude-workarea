class_name NightLight
extends PointLight2D
## A light that fades in after dusk and out at dawn (truck windows, street lamps, headlights).
## Fixed lamps are "safe": bandits will not step into their light (see is_lit()).

## How much of the glow's radius counts as lit for safety (the bright middle of it).
const SAFE_FRACTION := 0.4

static var _texture: GradientTexture2D

var base_energy := 1.0
## Keeps bandits away while it shines (street lamps, food trucks, the gas station).
var safe := false


static func make(color: Color, size: float, energy := 1.0) -> NightLight:
	var light := NightLight.new()
	light.texture = _soft_texture()
	light.color = color
	light.texture_scale = size / 256.0
	light.base_energy = energy
	light.energy = 0.0
	light.visible = false
	return light


func _ready() -> void:
	if safe:
		add_to_group("safe_lights")


## True when a safe lamp is shining on `pos` (only at night; by day nothing is lit).
static func is_lit(tree: SceneTree, pos: Vector2) -> bool:
	if DayNight.current == null or not DayNight.current.is_night():
		return false
	for node in tree.get_nodes_in_group("safe_lights"):
		var light := node as NightLight
		if light.global_position.distance_to(pos) < light.safe_radius():
			return true
	return false


## Radius of the bright, safe part of the glow, in pixels.
func safe_radius() -> float:
	return texture_scale * 256.0 * SAFE_FRACTION


func _process(_delta: float) -> void:
	var night := DayNight.current.night_amount() if DayNight.current != null else 0.0
	energy = base_energy * night
	visible = energy > 0.01


static func _soft_texture() -> GradientTexture2D:
	if _texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		_texture = GradientTexture2D.new()
		_texture.gradient = gradient
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(1.0, 0.5)
		_texture.width = 256
		_texture.height = 256
	return _texture
