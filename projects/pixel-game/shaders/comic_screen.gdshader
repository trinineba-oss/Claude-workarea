// A comic-book look for the 2.5D view (a mockup, off by default): the whole picture is redrawn
// as a printed comic panel. Bold ink where colours and shapes change, flat colour bands
// instead of smooth shading, halftone dots in the shadows, stronger colour, paper grain.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_linear;
// Ink lines: thickness in screen pixels, and how big a change in colour draws a line.
uniform float line_width = 1.4;
uniform float line_threshold = 0.2;
uniform float line_softness = 0.1;
uniform vec3 ink : source_color = vec3(0.07, 0.05, 0.05);
// Flat colour: how many light bands, and how much bolder the colours get.
uniform float bands = 4.0;
uniform float saturation = 1.3;
// Halftone dots in the shadows: cell size in screen pixels, and how dark a tone gets dots.
uniform float dot_size = 5.0;
uniform float dot_below = 0.38;
uniform vec3 paper : source_color = vec3(1.0, 0.97, 0.9);

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 sample_at(vec2 uv) {
	return texture(screen, uv).rgb;
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * line_width;
	vec3 c = sample_at(SCREEN_UV);
	// A light blur first, so fine texture (sand grains, grass blades) reads as flat colour.
	vec2 s1 = SCREEN_PIXEL_SIZE * 1.5;
	vec3 soft = (c * 4.0 + sample_at(SCREEN_UV + vec2(s1.x, 0.0))
			+ sample_at(SCREEN_UV - vec2(s1.x, 0.0)) + sample_at(SCREEN_UV + vec2(0.0, s1.y))
			+ sample_at(SCREEN_UV - vec2(0.0, s1.y))) / 8.0;

	// Ink: a Sobel edge on colour (not just brightness, so a red truck on grey road gets a line).
	vec3 tl = sample_at(SCREEN_UV + vec2(-px.x, -px.y));
	vec3 tc = sample_at(SCREEN_UV + vec2(0.0, -px.y));
	vec3 tr = sample_at(SCREEN_UV + vec2(px.x, -px.y));
	vec3 ml = sample_at(SCREEN_UV + vec2(-px.x, 0.0));
	vec3 mr = sample_at(SCREEN_UV + vec2(px.x, 0.0));
	vec3 bl = sample_at(SCREEN_UV + vec2(-px.x, px.y));
	vec3 bc = sample_at(SCREEN_UV + vec2(0.0, px.y));
	vec3 br = sample_at(SCREEN_UV + vec2(px.x, px.y));
	vec3 gx = (tr + 2.0 * mr + br) - (tl + 2.0 * ml + bl);
	vec3 gy = (bl + 2.0 * bc + br) - (tl + 2.0 * tc + tr);
	// Mostly brightness edges (shapes), a little colour (a red truck on a grey road).
	vec3 w = vec3(0.299, 0.587, 0.114);
	float edge_l = length(vec2(dot(gx, w), dot(gy, w)));
	float edge_c = length(vec2(length(gx), length(gy))) * 0.35;
	float edge = max(edge_l, edge_c) * 0.25;
	float line = smoothstep(line_threshold, line_threshold + line_softness, edge);

	// Flat colour: keep the hue, put the brightness into a few bands, push the saturation.
	float l = luma(soft);
	float banded = (floor(l * bands) + 0.5) / bands;
	banded = mix(banded, l, 0.35);
	vec3 flat_col = soft * (banded / max(l, 0.001));
	flat_col = mix(vec3(luma(flat_col)), flat_col, saturation);

	// Halftone: a 45° dot screen, dots growing as the tone darkens.
	vec2 p = FRAGCOORD.xy;
	vec2 rot = vec2(p.x + p.y, p.x - p.y) * 0.70710678 / dot_size;
	vec2 cell = fract(rot) - 0.5;
	float shade = clamp((dot_below - l) / dot_below, 0.0, 1.0);
	// No dots on warm browns (faces, hands, Evey's coat): they would read as dirt.
	float warm = smoothstep(0.04, 0.12, soft.r - soft.b) * step(soft.b, soft.g);
	shade *= 1.0 - warm;
	float radius = sqrt(shade) * 0.55;
	float dot_mask = 1.0 - smoothstep(radius - 0.08, radius + 0.08, length(cell));
	flat_col = mix(flat_col, flat_col * 0.45, dot_mask * step(0.001, shade));

	// Paper: a warm tint in the lights and a little grain.
	float grain = fract(sin(dot(floor(p), vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
	flat_col = mix(flat_col, flat_col * paper, smoothstep(0.5, 1.0, l));
	flat_col += grain * 0.025;

	COLOR = vec4(mix(flat_col, ink, line), 1.0);
}
