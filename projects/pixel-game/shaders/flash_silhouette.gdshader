// A character frame recoloured towards one colour: the white flash when an enemy is hit
// (amount 1) and Chad's tinted afterimages during a roll. Billboards like character_lit;
// Sprite3D supplies the frame's UVs and its modulate as COLOR (fades).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
uniform float amount = 1.0;

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
	vec4 tex = texture(albedo_tex, UV);
	ALBEDO = mix(tex.rgb, tint.rgb, amount);
	ALPHA = tex.a * COLOR.a;
}
