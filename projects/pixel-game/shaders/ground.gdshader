// Paints a whole room's floor in one pass. TEXTURE is a tiny per-room "weights" image (one
// texel per tile, sampled with linear filtering): R = sand, G = dirt, B = water, A = stone
// floor; `weights2` adds R = dock planks, G = road; grass is whatever is left over.
// Man-made materials (stone, planks, road) get no noise, so their edges stay straight. The weights are wobbled with noise, sharpened
// and renormalised, so neighbouring materials meet along soft, organic edges without any
// third material bleeding in between. Water drifts, darkens with depth, and foams at the shore.
shader_type canvas_item;

uniform sampler2D grass_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D sand_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D dirt_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D stone_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D water_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D wood_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D road_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform sampler2D weights2 : filter_linear;
uniform vec2 room_origin = vec2(0.0);
uniform vec2 room_size = vec2(1280.0, 704.0);
uniform float texture_world_size = 256.0;
// Higher = crisper borders between materials.
uniform float sharpness = 10.0;

float noise_at(vec2 world, float scale, float offset) {
	return texture(noise_tex, world / scale + offset).r - 0.5;
}

void fragment() {
	vec4 w = texture(TEXTURE, UV);
	vec4 w2 = texture(weights2, UV);
	vec2 world = room_origin + UV * room_size;
	vec2 tuv = world / texture_world_size;

	// Weights for grass, sand, dirt, water, stone; each nudged by its own noise.
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

	// Water: two layers drifting in different directions, deeper further from shore.
	vec2 drift = vec2(TIME * 0.025, TIME * 0.015);
	vec3 wc = mix(texture(water_tex, tuv * 0.7 + drift).rgb,
			texture(water_tex, tuv * 1.2 - drift * 1.5).rgb, 0.5);
	wc = mix(wc * 1.12, wc * 0.78, smoothstep(0.6, 1.0, w.b + big * 0.3));
	// Damp ground near the water line, then the water itself.
	col *= 1.0 - smoothstep(0.15, 0.5, w.b + big * 0.3) * (1.0 - m.z) * 0.22;
	col += wc * m.z;

	// Foam: a band where land and water meet, pulsing gently.
	float water_line = w.b + big * 0.35 + small * 0.12;
	float shore = clamp(1.0 - abs(water_line - 0.5) / 0.11, 0.0, 1.0);
	float pulse = 0.55 + 0.45 * sin(TIME * 2.2 + (world.x + world.y) * 0.02 + big * 12.0);
	col = mix(col, vec3(0.94, 0.97, 1.0), shore * pulse * 0.75);

	COLOR = vec4(col, 1.0);
}
