// An ink outline for the illustrated look: the mesh drawn again, pushed out along its normals,
// inside out, in one dark colour. Used as a material overlay (Illustrated.stylize).
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec4 ink : source_color = vec4(0.12, 0.08, 0.07, 1.0);
// Outline thickness in world units (before the object's own scale).
uniform float width = 0.03;

void vertex() {
	VERTEX += normalize(NORMAL) * width;
}

void fragment() {
	ALBEDO = ink.rgb;
}
