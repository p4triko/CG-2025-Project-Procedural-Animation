#define PALETTE_D __palette_d__
#define PALETTE_S __palette_s__
#define PALETTE_P __palette_p__
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, source_color, filter_nearest;
uniform float weight = 0.0;
uniform float hue_shift = 0.0;
uniform float saturation_shift = 0.0;
uniform float value_shift = 0.0;
#ifdef PREPROCESSED
PALETTE_D;
PALETTE_S;
PALETTE_P;
#endif

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	#ifndef PREPROCESSED
	const vec3[1] palette_d = vec3[](vec3(0));
	const vec3[1] palette_s = vec3[](vec3(0));
	const vec3[1] palette_p = vec3[](vec3(0));
	#endif
	
	// Find closest color to palette
	vec3 hsv_color = rgb2hsv(texture(screen_texture, UV).rgb);
	
	int best_palette_i = -1;
	float best_palette_dist = 1000000.0;
	for (int i = 0; i < palette_d.length(); i++) {
		float dist = length(hsv_color.r - rgb2hsv(palette_d[i]).r);
		if (dist <= best_palette_dist) {
			best_palette_i = i;
			best_palette_dist = dist;
		}
	}
	COLOR.rgb = hsv2rgb(rgb2hsv(pow(mix(pow(palette_p[best_palette_i], vec3(2.2)), pow(palette_s[best_palette_i], vec3(2.2)), weight), vec3(0.45454545))) + vec3(hue_shift, saturation_shift, value_shift));
}
