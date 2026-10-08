shader_type canvas_item;
// Screen glitch used for "the phone is wrong" moments.
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float intensity = 0.0;
uniform float seed = 0.0;

float rnd(float x) { return fract(sin(x * 12.9898 + seed) * 43758.5453); }

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = floor(TIME * 24.0);
	float row = floor(UV.y * 48.0);
	float r = rnd(row + t);
	float shift = (r > 1.0 - intensity * 0.55) ? (rnd(row * 3.1 + t) - 0.5) * 0.1 * intensity : 0.0;
	uv.x += shift;
	float ca = 0.007 * intensity;
	vec3 col;
	col.r = texture(screen_tex, uv + vec2(ca, 0.0)).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - vec2(ca, 0.0)).b;
	float n = rnd(dot(floor(FRAGCOORD.xy / 2.0), vec2(1.0, 57.0)) + t);
	col = mix(col, vec3(n), 0.14 * intensity);
	float blk = rnd(floor(UV.y * 14.0) * 7.0 + floor(UV.x * 6.0) + t * 3.0);
	if (blk > 1.0 - intensity * 0.07) {
		col = vec3(rnd(t), rnd(t + 1.0), rnd(t + 2.0)) * 0.5;
	}
	COLOR = vec4(col, 1.0);
}
