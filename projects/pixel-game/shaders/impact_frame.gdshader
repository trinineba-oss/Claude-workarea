// The finisher's impact frame: for a moment the whole screen turns to stark ink on paper.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float threshold = 0.36;
uniform vec3 ink : source_color = vec3(0.08, 0.03, 0.06);
uniform vec3 paper : source_color = vec3(1.0, 0.95, 0.85);

void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb;
	float light = dot(c, vec3(0.3, 0.59, 0.11));
	COLOR = vec4(mix(ink, paper, step(threshold, light)), 1.0);
}
