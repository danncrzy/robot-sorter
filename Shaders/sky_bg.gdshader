shader_type canvas_item;

// ── Attach to Bg (TextureRect) ──────────────────────────────
// Creates a slow-drifting parallax cloud atmosphere on top of
// whatever texture Bg already has.  Tune uniforms in Inspector.

uniform float  speed        : hint_range(0.0, 0.2)  = 0.018;
uniform float  cloud_scale  : hint_range(1.0, 10.0) = 4.5;
uniform float  cloud_soft   : hint_range(0.0, 1.0)  = 0.55;
uniform vec4   cloud_color  : source_color           = vec4(1.0, 1.0, 1.0, 0.18);
uniform vec4   sky_tint     : source_color           = vec4(0.53, 0.81, 0.98, 0.28);

// Smooth value noise helper
float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i + vec2(0,0)), hash(i + vec2(1,0)), u.x),
		mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), u.x),
		u.y
	);
}

// 4-octave fBm
float fbm(vec2 p) {
	float v = 0.0, a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p  = p * 2.1 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// Drift UV over time for two cloud layers.
	vec2 drift1 = UV * cloud_scale + vec2(TIME * speed,        TIME * speed * 0.4);
	vec2 drift2 = UV * cloud_scale * 1.6 + vec2(TIME * speed * 0.6, TIME * speed * 0.25);

	float c1 = smoothstep(cloud_soft, 1.0, fbm(drift1));
	float c2 = smoothstep(cloud_soft + 0.15, 1.0, fbm(drift2)) * 0.5;
	float clouds = clamp(c1 + c2, 0.0, 1.0);

	// Sky tint overlay.
	vec4 col = mix(tex, tex + sky_tint, sky_tint.a);
	// Cloud layer.
	col = mix(col, cloud_color, clouds * cloud_color.a);
	col.a = tex.a;

	COLOR = col;
}
