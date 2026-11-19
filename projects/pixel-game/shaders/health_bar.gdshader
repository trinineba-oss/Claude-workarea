// An enemy's health bar, floating over its head: the remaining health, a pale chunk for the
// damage just taken (it drains away after a hit), a dark backing and border. Always on top.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, shadows_disabled;

uniform float fill = 1.0;
uniform float trail = 1.0;
uniform float alpha = 1.0;

void vertex() {
	// Upright, turned to the camera around the vertical axis (like a FIXED_Y billboard),
	// keeping the node's scale.
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
	vec2 uv = UV;
	float border = step(uv.x, 0.03) + step(0.97, uv.x) + step(uv.y, 0.2) + step(0.8, uv.y);
	vec3 colour = vec3(0.1, 0.05, 0.08);
	if (border < 0.5) {
		if (uv.x < fill) {
			colour = mix(vec3(1.0, 0.45, 0.3), vec3(0.85, 0.15, 0.15), uv.y);
		} else if (uv.x < trail) {
			colour = vec3(1.0, 0.95, 0.82);
		} else {
			colour = vec3(0.24, 0.13, 0.16);
		}
	}
	ALBEDO = colour;
	ALPHA = alpha;
}
