// A "modern digital art" look for the 2.5D view (a mockup, off by default), in the spirit of
// today's painterly indie games: soft painted shading (no flat bands, no dots), a warm bloom
// around highlights, colour grading with warm lights and cool coloured shadows, thin outlines
// tinted from the colours they sit on (not black ink), and the tilt-shift's soft focus.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
// Soft focus: a sharp band across the middle, softly blurred above and below.
uniform float focus_y = 0.52;
uniform float band = 0.3;
uniform float blur = 1.6;
// Bloom: how bright a colour must be to glow, and how strongly.
uniform float bloom_threshold = 0.82;
uniform float bloom_strength = 0.35;
// Grading: warm highlights, cool shadows, and a gentle S-curve.
uniform vec3 shadow_tint : source_color = vec3(0.32, 0.36, 0.62);
uniform vec3 highlight_tint : source_color = vec3(1.0, 0.92, 0.78);
uniform float grade = 0.5;
uniform float saturation = 1.18;
uniform float contrast = 1.08;
// Painterly smoothing (a light blend with a softened copy) and tinted outlines.
uniform float paint = 0.45;
uniform float outline = 0.55;
uniform float outline_threshold = 0.16;
uniform float vignette = 0.28;

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float d = max(abs(uv.y - focus_y) - band, 0.0);
	float lod = clamp(d * 8.0, 0.0, 1.0) * blur;
	vec3 c = textureLod(screen, uv, lod).rgb;

	// Painterly: soften small texture noise towards a slightly blurred copy, keeping edges.
	vec3 soft = textureLod(screen, uv, lod + 1.2).rgb;
	float detail = abs(luma(c) - luma(soft));
	c = mix(c, soft, paint * (1.0 - smoothstep(0.05, 0.18, detail)));

	// Tinted outlines: where brightness changes sharply, darken towards a deep shade of the
	// colour itself, the way a digital painter draws coloured line art.
	vec2 px = SCREEN_PIXEL_SIZE * 1.2;
	float l_r = luma(textureLod(screen, uv + vec2(px.x, 0.0), lod).rgb);
	float l_l = luma(textureLod(screen, uv - vec2(px.x, 0.0), lod).rgb);
	float l_u = luma(textureLod(screen, uv - vec2(0.0, px.y), lod).rgb);
	float l_d = luma(textureLod(screen, uv + vec2(0.0, px.y), lod).rgb);
	float edge = length(vec2(l_r - l_l, l_d - l_u));
	float line = smoothstep(outline_threshold, outline_threshold + 0.12, edge) * outline;
	vec3 line_col = c * c * 0.45 + vec3(0.03, 0.02, 0.06);
	c = mix(c, line_col, line);

	// Bloom: a wide, soft glow from the bright parts of the picture.
	vec3 wide = textureLod(screen, uv, 4.0).rgb * 0.5 + textureLod(screen, uv, 5.5).rgb * 0.5;
	vec3 glow = max(wide - vec3(bloom_threshold), vec3(0.0)) / (1.0 - bloom_threshold);
	// Glow only from small bright spots (lamps, signs), not from wide bright ground: a large
	// bright area is bright in the sharp picture too, so it gets little extra.
	float spot = clamp(luma(wide) - luma(c) + 0.25, 0.0, 1.0);
	c += glow * highlight_tint * bloom_strength * spot;

	// Grading: cool coloured shadows, warm highlights, a gentle S-curve, richer colour.
	float l = luma(c);
	vec3 graded = mix(c * mix(vec3(1.0), shadow_tint * 1.9, 1.0 - smoothstep(0.0, 0.5, l)),
			c * highlight_tint * 1.08, smoothstep(0.45, 1.0, l));
	c = mix(c, graded, grade);
	c = (c - 0.5) * contrast + 0.5;
	c = mix(vec3(luma(c)), c, saturation);
	// Soft shoulder: keep bright sand and sky from clipping to white.
	// (on brightness only, so warm sand stays warm instead of turning grey).
	float lb = luma(c);
	float lc = lb > 0.75 ? 0.75 + (lb - 0.75) / (1.0 + (lb - 0.75) * 3.0) : lb;
	c *= lc / max(lb, 0.001);

	// A soft vignette to frame the scene.
	vec2 v = uv - 0.5;
	c *= 1.0 - vignette * smoothstep(0.35, 0.85, length(v * vec2(1.25, 1.0)));

	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
