shader_type canvas_item;

// Base fog parameters (reduced opacity)
uniform float fog_strength : hint_range(0.0, 1.0) = 0.2;
uniform float noise_scale : hint_range(0.1, 10.0) = 5.0;  // Higher = smoother
uniform float noise_speed : hint_range(0.0, 2.0) = 0.1;
uniform vec2 noise_direction = vec2(1.0, 0.5);

// Rectangular vignette base
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.7;
uniform float rect_width : hint_range(0.0, 1.0) = 0.7;
uniform float rect_height : hint_range(0.0, 1.0) = 0.7;
uniform float edge_softness : hint_range(0.0, 0.5) = 0.25;  // Softer for smoothness

// Organic edge parameters
uniform float edge_wave_scale : hint_range(0.5, 10.0) = 4.0;  // Higher = smoother
uniform float edge_wave_strength : hint_range(0.0, 0.5) = 0.15;
uniform float edge_wave_speed : hint_range(0.0, 1.0) = 0.08;

// Asymmetry parameters
uniform float edge_chaos : hint_range(0.0, 0.3) = 0.12;
uniform float tendril_scale : hint_range(1.0, 10.0) = 6.0;  // Higher = smoother
uniform float tendril_strength : hint_range(0.0, 0.5) = 0.2;

// Pulsing/breathing effect
uniform float pulse_speed : hint_range(0.0, 2.0) = 0.3;
uniform float pulse_amount : hint_range(0.0, 0.2) = 0.05;

// Color
uniform vec4 fog_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// IMPROVED: Smoother noise functions
float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// Smooth interpolation (quintic instead of cubic for even smoother results)
vec2 smooth_interp(vec2 t) {
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float noise(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	
	// Use smoother interpolation
	vec2 u = smooth_interp(f);
	
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Smoother FBM with more octaves
float fbm(vec2 uv) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	
	// Increased octaves from 4 to 6 for smoother result
	for(int i = 0; i < 6; i++) {
		value += amplitude * noise(uv * frequency);
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	
	return value;
}

void fragment() {
	vec2 uv = UV;
	
	// === SUBTLE GLOBAL FOG (much less opacity) ===
	vec2 noise_uv = uv * noise_scale + noise_direction * TIME * noise_speed;
	float fog_noise = fbm(noise_uv);
	// Reduced and smoothed fog
	float fog_darkness = fog_strength * (0.5 + fog_noise * 0.5);
	
	// === PULSING/BREATHING RECTANGLE ===
	float pulse = sin(TIME * pulse_speed) * pulse_amount;
	float current_rect_width = rect_width + pulse;
	float current_rect_height = rect_height + pulse;
	
	vec2 centered_uv = uv - 0.5;
	
	// === SMOOTH ORGANIC EDGE WAVES ===
	float edge_time = TIME * edge_wave_speed;
	
	// Left edge wave (smoother with higher scale)
	vec2 left_wave_uv = vec2(0.0, uv.y * edge_wave_scale + edge_time);
	float left_wave = fbm(left_wave_uv) * edge_wave_strength;
	
	// Right edge wave
	vec2 right_wave_uv = vec2(100.0, uv.y * edge_wave_scale - edge_time * 0.8);
	float right_wave = fbm(right_wave_uv) * edge_wave_strength;
	
	// Top edge wave
	vec2 top_wave_uv = vec2(uv.x * edge_wave_scale + edge_time * 1.2, 50.0);
	float top_wave = fbm(top_wave_uv) * edge_wave_strength;
	
	// Bottom edge wave
	vec2 bottom_wave_uv = vec2(uv.x * edge_wave_scale - edge_time * 0.7, 150.0);
	float bottom_wave = fbm(bottom_wave_uv) * edge_wave_strength;
	
	// === SMOOTH TENDRILS ===
	vec2 tendril_uv = uv * tendril_scale + vec2(TIME * 0.05, TIME * 0.03);
	float tendril_noise = fbm(tendril_uv);
	
	// Smoother tendril falloff
	float left_tendril = tendril_noise * smoothstep(0.0, 0.5, -centered_uv.x) * tendril_strength;
	float right_tendril = tendril_noise * smoothstep(0.0, 0.5, centered_uv.x) * tendril_strength;
	float top_tendril = tendril_noise * smoothstep(0.0, 0.5, -centered_uv.y) * tendril_strength;
	float bottom_tendril = tendril_noise * smoothstep(0.0, 0.5, centered_uv.y) * tendril_strength;
	
	// === EDGE CHAOS ===
	float chaos_seed = floor(TIME * 0.5);
	float left_chaos = (noise(vec2(chaos_seed, 1.0)) - 0.5) * edge_chaos;
	float right_chaos = (noise(vec2(chaos_seed, 2.0)) - 0.5) * edge_chaos;
	float top_chaos = (noise(vec2(chaos_seed, 3.0)) - 0.5) * edge_chaos;
	float bottom_chaos = (noise(vec2(chaos_seed, 4.0)) - 0.5) * edge_chaos;
	
	// === CALCULATE DISTANCES ===
	float dist_left = -centered_uv.x * 2.0 - current_rect_width + left_wave + left_chaos + left_tendril;
	float dist_right = centered_uv.x * 2.0 - current_rect_width + right_wave + right_chaos + right_tendril;
	float dist_top = -centered_uv.y * 2.0 - current_rect_height + top_wave + top_chaos + top_tendril;
	float dist_bottom = centered_uv.y * 2.0 - current_rect_height + bottom_wave + bottom_chaos + bottom_tendril;
	
	dist_left = max(0.0, dist_left);
	dist_right = max(0.0, dist_right);
	dist_top = max(0.0, dist_top);
	dist_bottom = max(0.0, dist_bottom);
	
	// Combine edges
	float outside_x = max(dist_left, dist_right);
	float outside_y = max(dist_top, dist_bottom);
	float outside_dist = max(outside_x, outside_y);
	
	// === SMOOTH EDGE DETAIL (less pixelated) ===
	vec2 edge_detail_uv = uv * 12.0 + vec2(TIME * 0.02, TIME * 0.015);
	float edge_detail = fbm(edge_detail_uv) * 0.05;  // Reduced for subtlety
	outside_dist += edge_detail;
	
	// Extra smooth step for the vignette
	float rect_vignette = smoothstep(0.0, edge_softness, outside_dist);
	
	// Removed grain (was causing pixelation)
	rect_vignette = clamp(rect_vignette, 0.0, 1.0);
	
	// Apply strength
	rect_vignette *= vignette_strength;
	
	// === COMBINE (mostly vignette, minimal fog) ===
	float total_darkness = fog_darkness + rect_vignette;
	total_darkness = clamp(total_darkness, 0.0, 1.0);
	
	COLOR = vec4(fog_color.rgb, total_darkness);
}
