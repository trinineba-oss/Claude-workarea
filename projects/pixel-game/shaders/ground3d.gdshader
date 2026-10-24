// The 3D version of ground.gdshader: paints one room's floor (a 20x11 plane) by blending
// materials from the room's weights images. Same weights and materials as the 2D floor:
// R = sand, G = dirt, B = water, A = stone floor; `weights2` R = dock planks, G = road; grass
// is whatever is left over. Water is darker, glossier and drifts, with foam at the shore.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D weights_tex : filter_linear;
uniform sampler2D weights2 : filter_linear;
uniform sampler2D grass_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D sand_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D dirt_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D stone_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D water_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D wood_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D road_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
// The room's top-left corner in 2D pixels (so textures line up across rooms).
uniform vec2 room_origin = vec2(0.0);
uniform vec2 grid_size = vec2(22.0, 13.0);
uniform float tile_size = 64.0;
uniform float texture_world_size = 256.0;
uniform float sharpness = 10.0;
// The illustrated look: dark ink lines where two ground materials meet (0 = off).
uniform float ink = 0.0;
uniform vec3 ink_color : source_color = vec3(0.16, 0.11, 0.08);

varying vec2 world;
varying vec2 wuv;

float noise_at(vec2 w, float scale, float offset) {
	return texture(noise_tex, w / scale + offset).r - 0.5;
}

void vertex() {
	// The plane's UV covers the room itself; the weights images have a one-tile border.
	wuv = (UV * (grid_size - 2.0) + 1.0) / grid_size;
	world = room_origin + UV * (grid_size - 2.0) * tile_size;
}

void fragment() {
	vec4 w = texture(weights_tex, wuv);
	vec4 w2 = texture(weights2, wuv);
	vec2 tuv = world / texture_world_size;
	float big = noise_at(world, 640.0, 0.0);
	float small = noise_at(world, 160.0, 0.37);
	float grass = clamp(1.0 - (w.r + w.g + w.b + w.a + w2.r + w2.g), 0.0, 1.0)
		+ small * 0.3 - big * 0.2;
	float sand = w.r + big * 0.3 + small * 0.1;
	float dirt = w.g + noise_at(world, 220.0, 0.71) * 0.35;
	float water = w.b + big * 0.35 + small * 0.12;
	float stone = w.a;
	vec4 m = pow(max(vec4(sand, dirt, water, stone), 0.0001), vec4(sharpness));
	vec2 m2 = pow(max(w2.rg, 0.0001), vec2(sharpness));
	float g = pow(max(grass, 0.0001), sharpness);
	float total = m.x + m.y + m.z + m.w + m2.x + m2.y + g;
	m /= total;
	m2 /= total;
	g /= total;
	vec3 col = texture(grass_tex, tuv).rgb * g
		+ texture(sand_tex, tuv).rgb * m.x
		+ texture(dirt_tex, tuv).rgb * m.y
		+ texture(stone_tex, tuv).rgb * m.w
		+ texture(wood_tex, tuv).rgb * m2.x
		+ texture(road_tex, tuv).rgb * m2.y;
	vec2 drift = vec2(TIME * 0.025, TIME * 0.015);
	vec3 wc = mix(texture(water_tex, tuv * 0.7 + drift).rgb,
			texture(water_tex, tuv * 1.2 - drift * 1.5).rgb, 0.5);
	wc = mix(wc * 1.1, wc * 0.7, smoothstep(0.6, 1.0, w.b + big * 0.3));
	col *= 1.0 - smoothstep(0.15, 0.5, w.b + big * 0.3) * (1.0 - m.z) * 0.25;
	col += wc * m.z;
	float water_line = w.b + big * 0.35 + small * 0.12;
	float shore = clamp(1.0 - abs(water_line - 0.5) / 0.11, 0.0, 1.0);
	float pulse = 0.55 + 0.45 * sin(TIME * 2.2 + (world.x + world.y) * 0.02 + big * 12.0);
	col = mix(col, vec3(0.94, 0.97, 1.0), shore * pulse * 0.7);
	if (ink > 0.0) {
		// Where the two strongest materials are nearly equal, a border runs: ink it.
		float a = max(max(max(g, m.x), max(m.y, m.z)), max(max(m.w, m2.x), m2.y));
		float b = 0.0;
		b = max(b, g < a ? g : 0.0);
		b = max(b, m.x < a ? m.x : 0.0);
		b = max(b, m.y < a ? m.y : 0.0);
		b = max(b, m.z < a ? m.z : 0.0);
		b = max(b, m.w < a ? m.w : 0.0);
		b = max(b, m2.x < a ? m2.x : 0.0);
		b = max(b, m2.y < a ? m2.y : 0.0);
		float line = smoothstep(0.55, 0.9, 1.0 - (a - b));
		col = mix(col, ink_color, line * ink);
		// A soft painted shadow just inside each border.
		col *= 1.0 - smoothstep(0.3, 0.6, 1.0 - (a - b)) * 0.12 * ink;
	}
	ALBEDO = col;
	// Water is glossy (it catches the sun and the lamps); everything else is matte.
	ROUGHNESS = mix(0.95, 0.12, m.z);
	SPECULAR = mix(0.3, 0.7, m.z);
	// A gentle ripple in the water's surface normal.
	float ripple = sin(world.x * 0.09 + TIME * 1.7) * sin(world.y * 0.11 - TIME * 1.3);
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), vec3(0.5 + ripple * 0.12, 0.5 - ripple * 0.12, 1.0), m.z);
}
