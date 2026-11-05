shader_type canvas_item;
// The backdrop of the "which phone?" / QR screens: a dark room at night.
// Film grain, faint scanlines, a vignette and a dim red glow where the code
// is (like a standby light), breathing slowly.

uniform vec2 glow_at = vec2(0.7, 0.5);
uniform float glow = 0.16;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float n = hash(floor(FRAGCOORD.xy / 2.0) + floor(TIME * 24.0) * 7.31);
	float vig = smoothstep(1.15, 0.2, length((uv - vec2(0.5)) * vec2(1.25, 1.0)));
	float scan = 0.975 + 0.025 * sin(FRAGCOORD.y * 1.7);
	vec3 c = vec3(0.034, 0.035, 0.04) * vig * scan;
	float breathe = 0.85 + 0.15 * sin(TIME * 0.9);
	float d = length((uv - glow_at) * vec2(1.7, 1.0));
	c += vec3(0.55, 0.06, 0.05) * glow * breathe * smoothstep(0.55, 0.0, d);
	c += (n - 0.5) * 0.04;
	COLOR = vec4(max(c, vec3(0.0)), 1.0);
}
