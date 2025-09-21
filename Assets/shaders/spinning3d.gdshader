shader_type canvas_item;

// Character frame textures
uniform sampler2D frame_front : source_color, hint_default_white;
uniform sampler2D frame_3quarter_front : source_color, hint_default_white;
uniform sampler2D frame_side : source_color, hint_default_white;
uniform sampler2D frame_3quarter_back : source_color, hint_default_white;
uniform sampler2D frame_back : source_color, hint_default_white;

// Spinning animation
uniform float spin_angle : hint_range(0.0, 6.28) = 0.0;
uniform float spin_speed : hint_range(0.0, 15.0) = 5.0;
uniform bool auto_spin = true;
uniform bool smooth_interpolation  = true;

// Trail effects
uniform int trail_samples : hint_range(3, 12) = 8;
uniform float trail_length : hint_range(0.0, 1.5) = 0.6;
uniform float trail_falloff : hint_range(0.1, 0.9) = 0.7;
uniform bool additive_trails  = true;

// Juicy effects
uniform float scale_bounce : hint_range(0.0, 0.3) = 0.1; // scale variation during spin
uniform float chromatic_aberration : hint_range(0.0, 0.02) = 0.005; // color separation effect
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.8; // trail glow
uniform vec3 trail_color_tint : source_color = vec3(1.0, 0.8, 0.6); // warm trail tint

// Get the appropriate frame based on angle
vec4 sample_character_frame(vec2 uv, float angle) {
    // Normalize angle to 0-2π
    float normalized_angle = mod(angle, 6.28318);
    
    // Convert to 0-5 range for our 5 frames
    float frame_float = normalized_angle * 5.0 / 6.28318;
    int frame_index = int(frame_float);
    float frame_blend = fract(frame_float);
    
    vec4 current_frame;
    vec4 next_frame;
    
    // Sample current frame
    if (frame_index == 0) {
        current_frame = texture(frame_front, uv);
        next_frame = texture(frame_3quarter_front, uv);
    } else if (frame_index == 1) {
        current_frame = texture(frame_3quarter_front, uv);
        next_frame = texture(frame_side, uv);
    } else if (frame_index == 2) {
        current_frame = texture(frame_side, uv);
        next_frame = texture(frame_3quarter_back, uv);
    } else if (frame_index == 3) {
        current_frame = texture(frame_3quarter_back, uv);
        next_frame = texture(frame_back, uv);
    } else {
        current_frame = texture(frame_back, uv);
        next_frame = texture(frame_front, uv);
    }
    
    // Smooth interpolation between frames
    if (smooth_interpolation) {
        return mix(current_frame, next_frame, smoothstep(0.0, 1.0, frame_blend));
    } else {
        return current_frame;
    }
}

vec4 sample_with_chromatic_aberration(vec2 uv, float angle, float aberration_strength) {
    if (aberration_strength <= 0.0) {
        return sample_character_frame(uv, angle);
    }
    
    vec4 r_sample = sample_character_frame(uv + vec2(aberration_strength, 0.0), angle);
    vec4 g_sample = sample_character_frame(uv, angle);
    vec4 b_sample = sample_character_frame(uv - vec2(aberration_strength, 0.0), angle);
    
    return vec4(r_sample.r, g_sample.g, b_sample.b, g_sample.a);
}

void fragment() {
    // Calculate current spin angle
    float current_angle = spin_angle;
    if (auto_spin) {
        current_angle += TIME * spin_speed;
    }
    
    vec4 final_color = vec4(0.0);
    
    // Sample multiple trail layers
    for (int i = 0; i < trail_samples; i++) {
        float layer_progress = float(i) / float(trail_samples - 1);
        
        // Calculate angle offset for this trail layer
        float angle_offset = -trail_length * layer_progress;
        float layer_angle = current_angle + angle_offset;
        
        // Calculate scale bounce effect
        float scale_factor = 1.0 + sin(layer_angle * 2.0) * scale_bounce * (1.0 - layer_progress * 0.5);
        
        // Calculate UV with scale
        vec2 centered_uv = (UV - 0.5) / scale_factor + 0.5;
        
        // Skip if outside bounds
        if (centered_uv.x < 0.0 || centered_uv.x > 1.0 || centered_uv.y < 0.0 || centered_uv.y > 1.0) {
            continue;
        }
        
        // Sample with chromatic aberration (stronger on trail layers)
        float aberration_amount = chromatic_aberration * layer_progress;
        vec4 layer_color = sample_with_chromatic_aberration(centered_uv, layer_angle, aberration_amount);
        
        // Calculate alpha falloff
        float alpha_mult = pow(trail_falloff, layer_progress * 2.0);
        layer_color.a *= alpha_mult;
        
        // Apply trail color tint (more tinted on older frames)
        if (i > 0) {
            layer_color.rgb *= mix(vec3(1.0), trail_color_tint, layer_progress * 0.7);
            layer_color.rgb *= glow_intensity;
        }
        
        // Blend layers
        if (i == 0) {
            // First layer (current frame) is the base
            final_color = layer_color;
        } else {
            if (additive_trails) {
                // Additive blending for glow effect
                final_color.rgb += layer_color.rgb * layer_color.a;
                final_color.a = max(final_color.a, layer_color.a);
            } else {
                // Alpha blending
                float blend_factor = layer_color.a * (1.0 - final_color.a);
                final_color.rgb = final_color.rgb * final_color.a + layer_color.rgb * blend_factor;
                final_color.a = final_color.a + blend_factor;
            }
        }
    }
    
    COLOR = final_color * COLOR;
}