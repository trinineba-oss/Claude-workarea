shader_type spatial;
// One-shot hit spark: a star of rays and a flash.
// Ported to a 3D billboard from VFX 2D Free by heyheythere
// (https://heyheythere.itch.io/vfx-2d-free), CC BY 4.0: the effect itself is unchanged; it now
// draws on a camera-facing quad in the 2.5D view instead of a 2D rect.
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

#define VFX_CORE vec4(1.0, 1.0, 0.95, 1.0)
#define VFX_MID vec4(1.0, 0.85, 0.3, 1.0)
#define VFX_EDGE vec4(1.0, 0.4, 0.1, 0.0)
#include "vfx_common.gdshaderinc"


void vertex() {
	// Face the camera, keeping the quad's own size.
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s,
			INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
}

void fragment() {
	vec2 uv = vfx_uv(UV);
	vec2 p = vfx_p(uv);
	float t = progress;
	float r = length(p);
	float a = atan(p.y, p.x) / VFX_TAU * 9.0 + seed * 3.7;
	float sector = floor(a);
	float across = (fract(a) - 0.5) * r * VFX_TAU / 9.0;
	float len = mix(0.5, 1.0, vfx_hash1(sector + floor(seed * 13.0))) * mix(0.5, 1.0, sqrt(t));
	float along = clamp(r / len, 0.0, 1.0);
	float ray = smoothstep(0.07 * (1.0 - along) + vfx_px() * 0.5, 0.0, abs(across)) * step(r, len);
	float flash = exp(-r * 5.0) * (1.0 - t) * 1.3;
	float glow = exp(-r * 3.0) * 0.3 * (1.0 - t);
	vec4 c = vfx_ramp((ray * (1.0 - along * 0.7) + flash) * 1.2 + glow);
	c.a = max(c.a, 0.7) * clamp(ray + flash + glow, 0.0, 1.0) * pow(1.0 - t, 1.2);
	vec4 col = vfx_finish(c, UV);
	ALBEDO = col.rgb;
	ALPHA = col.a;
}
