// Soft darkening toward the screen edges.
shader_type canvas_item;

uniform float strength = 0.38;
uniform vec3 tint = vec3(0.06, 0.02, 0.10);

void fragment() {
	vec2 centred = (SCREEN_UV - 0.5) * vec2(1.0, 0.8);
	COLOR = vec4(tint, smoothstep(0.32, 0.8, length(centred)) * strength);
}
