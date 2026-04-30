shader_type canvas_item;

// Outline parameters
uniform vec4 outline_color : source_color = vec4(1.0);
// Blinking modulates the base color.
// Set blink_time_scale to 0 if you don't want blinking.
uniform vec4 blink_color : source_color = vec4(1.0);
uniform float blink_time_scale : hint_range(0.0, 10.0, 0.1) = 0.0;

// Highlight parameters
uniform float highlight_speed : hint_range(0.0, 5.0) = 1.0;
uniform float highlight_line_width : hint_range(0.0, 0.2) = 0.15;
uniform vec4 highlight_line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float highlight_pause_duration : hint_range(0.0, 2.0) = 0.15;
uniform float highlight_offset = 2.0;
uniform int highlight_pixelate_line : hint_range(0, 1) = 1;

void fragment() {
    vec4 base_texture = texture(TEXTURE, UV);
    
    // Outline effect
    vec2 pixel_size = TEXTURE_PIXEL_SIZE;
    bool within = texture(TEXTURE, UV + pixel_size * vec2(1.0, 0.0)).a > 0.0;
    within = within || texture(TEXTURE, UV + pixel_size * vec2(1.0, 1.0)).a > 0.0;
    within = within || texture(TEXTURE, UV + pixel_size * vec2(1.0, -1.0)).a > 0.0;
    within = within || texture(TEXTURE, UV + pixel_size * vec2(0.0, -1.0)).a > 0.0;
    within = within || texture(TEXTURE, UV + pixel_size * vec2(0.0, 1.0)).a > 0.0;
    within = within || texture(TEXTURE, UV + pixel_size * vec2(-1.0, 1.0)).a > 0.0;
    within = within || texture(TEXTURE, UV + pixel_size * vec2(-1.0, -1.0)).a > 0.0;
    within = within || texture(TEXTURE, UV + pixel_size * vec2(-1.0, 0.0)).a > 0.0;
    bool outline = within && texture(TEXTURE, UV).a == 0.0;
    
    // Initialize with the base texture color
    COLOR = base_texture;
    
    // Apply blinking effect
    COLOR = mix(COLOR, COLOR * blink_color, 0.5 - 0.5 * cos(TIME * blink_time_scale));
    
    // Apply outline if needed
    COLOR = float(!outline) * COLOR + float(outline) * outline_color;
    
    // Skip fully transparent pixels that aren't part of the outline
    if (base_texture.a < 0.01 && !outline) {
        discard;
    }
    
    // If this pixel is part of the outline, we don't apply the highlight effect
    
    // Highlight effect
    // Cycle timing with pause at end
    float cycle_duration = highlight_offset + highlight_pause_duration;
    float adjusted_time = mod(TIME * highlight_speed, cycle_duration);
    
    // Line movement with pause (right to left)
    float line_position;
    if (adjusted_time <= highlight_offset) {
        line_position = highlight_offset - adjusted_time;
    } else {
        line_position = -0.3;
    }
    
    // Use UV directly for diagonal calculation
    vec2 uv_for_line = UV;
    
    // Pixelate the line position calculation (not the texture sampling)
    if (highlight_pixelate_line == 1) {
        vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
        uv_for_line = floor(UV * texture_size) / texture_size;
    }
    
    // Diagonal line rotation
    vec2 rotated_uv = vec2(uv_for_line.x + uv_for_line.y, uv_for_line.y - uv_for_line.x) * 0.5;
    float dist = abs(rotated_uv.x - line_position);
    
    // Line width and smoothness
    float line_intensity = smoothstep(highlight_line_width, 0.0, dist);
    
    // Mix color with highlight line color (respecting line_color alpha)
    COLOR.rgb = mix(COLOR.rgb, highlight_line_color.rgb, line_intensity * highlight_line_color.a);
}