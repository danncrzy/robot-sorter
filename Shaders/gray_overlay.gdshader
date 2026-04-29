
shader_type canvas_item;

// Fog parameters
uniform float fog_strength : hint_range(0.0, 1.0) = 0.7;
uniform float noise_scale : hint_range(0.1, 10.0) = 3.0;
uniform float noise_speed : hint_range(0.0, 2.0) = 0.1;
uniform vec2 noise_direction = vec2(1.0, 0.5);

// Vignette parameters
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_size : hint_range(0.1, 2.0) = 0.8;

// Simple noise function
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Fractal Brownian Motion for layered noise
float fbm(vec2 uv) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for(int i = 0; i < 4; i++) {
        value += amplitude * noise(uv * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

void fragment() {
    vec2 uv = UV;
    
    // Scrolling noise over time
    vec2 noise_uv = uv * noise_scale + noise_direction * TIME * noise_speed;
    float fog_noise = fbm(noise_uv);
    
    // Create vignette effect (darker at edges)
    vec2 center = uv - vec2(0.5);
    float vignette = length(center) / vignette_size;
    vignette = smoothstep(0.0, 1.0, vignette);
    vignette = pow(vignette, 2.0) * vignette_strength;
    
    // Combine fog and vignette
    float darkness = fog_strength * (0.7 + fog_noise * 0.3);
    darkness += vignette;
    darkness = clamp(darkness, 0.0, 1.0);
    
    // Output black with calculated alpha
    COLOR = vec4(0.0, 0.0, 0.0, darkness);
}