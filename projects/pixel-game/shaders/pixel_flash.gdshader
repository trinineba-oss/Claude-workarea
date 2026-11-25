// A pixel sprite recoloured towards one colour: the white flash when an enemy is hit
// (amount 1, tint white) and Chad's tinted afterimages during a roll.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0);
uniform float amount = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(c.rgb, tint.rgb, amount), c.a);
}
