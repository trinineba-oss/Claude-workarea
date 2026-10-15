// Tilt-shift for the 2.5D view: a sharp band across the middle of the screen, a soft blur
// above and below it (like looking at a miniature).
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform float focus_y = 0.52;
uniform float band = 0.27;
uniform float strength = 2.0;

void fragment() {
	float d = max(abs(SCREEN_UV.y - focus_y) - band, 0.0);
	float lod = clamp(d * 8.0, 0.0, 1.0) * strength;
	COLOR = vec4(textureLod(screen, SCREEN_UV, lod).rgb, 1.0);
}
