shader_type canvas_item;
// Frosted glass: whatever is behind the panel, blurred, a little more
// saturated, under a tint. The panel's own colour (a StyleBoxFlat) only
// shapes it: its alpha gives the rounded, anti-aliased edge, and anything
// lighter than the tint (the border) is added as a highlight.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur = 3.2;
uniform vec4 tint : source_color = vec4(0.10, 0.11, 0.13, 1.0);
uniform float tint_amount = 0.55;
uniform float saturation = 1.35;
uniform float grain = 0.018;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 d = SCREEN_PIXEL_SIZE * exp2(blur) * 0.9;
	vec3 acc = textureLod(screen_tex, SCREEN_UV, blur).rgb * 0.2;
	acc += textureLod(screen_tex, SCREEN_UV + vec2(d.x, 0.0), blur).rgb * 0.1;
	acc += textureLod(screen_tex, SCREEN_UV - vec2(d.x, 0.0), blur).rgb * 0.1;
	acc += textureLod(screen_tex, SCREEN_UV + vec2(0.0, d.y), blur).rgb * 0.1;
	acc += textureLod(screen_tex, SCREEN_UV - vec2(0.0, d.y), blur).rgb * 0.1;
	acc += textureLod(screen_tex, SCREEN_UV + d * 0.7, blur).rgb * 0.1;
	acc += textureLod(screen_tex, SCREEN_UV - d * 0.7, blur).rgb * 0.1;
	acc += textureLod(screen_tex, SCREEN_UV + vec2(d.x, -d.y) * 0.7, blur).rgb * 0.1;
	acc += textureLod(screen_tex, SCREEN_UV + vec2(-d.x, d.y) * 0.7, blur).rgb * 0.1;
	float l = dot(acc, vec3(0.299, 0.587, 0.114));
	acc = mix(vec3(l), acc, saturation);
	vec3 col = mix(acc, tint.rgb, tint_amount);
	col += max(COLOR.rgb - tint.rgb, vec3(0.0));
	col += (hash(FRAGCOORD.xy) - 0.5) * grain;
	COLOR = vec4(col, COLOR.a);
}
