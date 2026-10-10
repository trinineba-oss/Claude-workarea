class_name NightLight
extends PointLight2D
## A light that fades in after dusk and out at dawn (truck windows, street lamps, headlights).

static var _texture: GradientTexture2D

var base_energy := 1.0


static func make(color: Color, size: float, energy := 1.0) -> NightLight:
	var light := NightLight.new()
	light.texture = _soft_texture()
	light.color = color
	light.texture_scale = size / 256.0
	light.base_energy = energy
	light.energy = 0.0
	light.visible = false
	return light


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
