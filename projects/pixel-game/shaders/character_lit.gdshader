// Painted characters (PixelBody) lit as rounded figures instead of flat cards: the sheet's
// normal map (tools/painted_sheets.py makes it from each figure's shape) lets the sun, moon,
// lamps and torches shade them, and a soft rim light lifts their edges off the ground.
// Stands upright facing the camera like a FIXED_Y billboard; Sprite3D supplies the frame's
// UVs and its modulate (hit flashes, fades) as COLOR.
shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha, diffuse_burley, specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
// 1 when the sprite is mirrored (facing left): the normals' left and right swap too.
uniform float flip = 0.0;
uniform float normal_strength = 1.7;
uniform float rim = 0.8;
uniform float rim_tint = 0.4;
// Keeps the side away from the light from going muddy.
uniform float wrap = 0.12;
// Form shading: how much the edges of a figure darken as they turn away (reads as roundness
// even in flat light).
uniform float form = 0.32;

void vertex() {
	// Upright, turned to the camera around the vertical axis (what FIXED_Y billboards do),
	// keeping the sprite's scale.
	vec3 side = normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz));
	vec3 fwd = normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0)));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(side * length(MODEL_MATRIX[0].xyz), 0.0),
			vec4(vec3(0.0, 1.0, 0.0) * length(MODEL_MATRIX[1].xyz), 0.0),
			vec4(fwd * length(MODEL_MATRIX[2].xyz), 0.0),
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	vec3 n = texture(normal_tex, UV).rgb;
	float facing_us = clamp(n.z * 2.0 - 1.0, 0.0, 1.0);
	ALBEDO = tex.rgb * COLOR.rgb * mix(1.0 - form, 1.0, smoothstep(0.35, 0.95, facing_us));
	// Soft edges: the depth prepass covers the solid inside, the rim blends.
	ALPHA = tex.a * COLOR.a;
	n.x = mix(n.x, 1.0 - n.x, flip);
	NORMAL_MAP = n;
	NORMAL_MAP_DEPTH = normal_strength;
	ROUGHNESS = 0.9;
	RIM = rim;
	RIM_TINT = rim_tint;
	BACKLIGHT = vec3(wrap);
}
