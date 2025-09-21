shader_type canvas_item;

// Character rotation textures (5 key frames)
uniform sampler2D front_texture : hint_default_white;
uniform sampler2D quarter_front_texture : hint_default_white;
uniform sampler2D side_texture : hint_default_white;
uniform sampler2D quarter_back_texture : hint_default_white;
uniform sampler2D back_texture : hint_default_white;

// Rotation control
uniform float rotation_y : hint_range(0.0, 360.0) = 0.0;

// Auto-rotation settings
uniform bool auto_rotate = false;
uniform float rotation_speed : hint_range(0.1, 10.0) = 1.0; // rotations per second
uniform float ease_duration : hint_range(0.1, 5.0) = 1.0; // ease in/out duration in seconds
uniform bool start_from_quarter_front = true;

// Animation settings
uniform float blend_smoothness : hint_range(0.1, 5.0) = 2.0;
uniform bool enable_interpolation = true;

// Size normalization settings
uniform vec2 target_size = vec2(1.0, 1.0); // Target sprite size
uniform bool maintain_aspect_ratio = true;
uniform vec2 size_offset = vec2(0.0, 0.0); // Fine-tune positioning

// ───────── Directional Blur Settings ─────────
uniform bool enable_directional_blur = true;
uniform float blur_direction_degrees : hint_range(0.0, 360.0) = 0.0; // 0=right, 90=up, etc.
uniform float blur_length : hint_range(0.0, 0.2) = 0.03;
uniform int blur_samples = 8;

// ───────── Glow Effect Settings ─────────
uniform bool enable_glow = true;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.0;
uniform float glow_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float glow_spread : hint_range(0.0, 0.1) = 0.02;
uniform int glow_samples = 8;
uniform int glow_blend_mode = 0; // 0=Add, 1=Screen, 2=Overlay, 3=Multiply

// ────────────────────────────────────────────────
// Helper Functions (Declared First!)
// ────────────────────────────────────────────────

// Helper function to normalize angle to 0-360 range
float normalize_angle(float angle) {
    return mod(angle, 360.0);
}

// Easing functions
float ease_in_out_cubic(float t) {
    if (t < 0.5) {
        return 4.0 * t * t * t;
    } else {
        float p = 2.0 * t - 2.0;
        return 1.0 + p * p * p / 2.0;
    }
}

float ease_in_out_sine(float t) {
    return -(cos(3.14159265 * t) - 1.0) / 2.0;
}

// Helper function to create smooth transitions between frames
float smooth_transition(float t) {
    return t * t * (3.0 - 2.0 * t); // Smoothstep function
}

// Compute blur direction vector from user-defined angle
vec2 get_manual_blur_direction(float angle_degrees, float length) {
    float angle_rad = radians(angle_degrees);
    return vec2(cos(angle_rad), sin(angle_rad)) * length;
}

// Blend modes for glow compositing — FIXED: Uses luminance for overlay
vec4 blend_glow(vec4 base, vec4 glow, int mode) {
    if (mode == 0) {
        // Additive
        return base + glow;
    } else if (mode == 1) {
        // Screen
        return vec4(1.0 - (1.0 - base.rgb) * (1.0 - glow.rgb), base.a);
    } else if (mode == 2) {
        // Overlay - based on luminance (FIXED)
        float luminance = dot(base.rgb, vec3(0.299, 0.587, 0.114));
        vec3 blend = luminance < 0.5 ? 
                     2.0 * base.rgb * glow.rgb : 
                     1.0 - 2.0 * (1.0 - base.rgb) * (1.0 - glow.rgb);
        return vec4(blend, base.a);
    } else if (mode == 3) {
        // Multiply
        return vec4(base.rgb * glow.rgb, base.a);
    }
    // Fallback to additive
    return base + glow;
}

// ────────────────────────────────────────────────
// Core Logic Functions
// ────────────────────────────────────────────────

// Calculate automatic rotation with easing
float calculate_auto_rotation() {
    if (!auto_rotate) {
        return rotation_y;
    }
    
    float cycle_duration = 1.0 / rotation_speed;
    float current_time = mod(TIME, cycle_duration);
    float t = current_time / cycle_duration;
    
    float rotation_angle;
    
    float ease_phase = ease_duration / cycle_duration;
    ease_phase = clamp(ease_phase, 0.0, 0.5);
    
    if (t <= ease_phase) {
        float ease_t = t / ease_phase;
        float eased_progress = ease_in_out_sine(ease_t);
        rotation_angle = eased_progress * (360.0 * ease_phase);
    } else if (t >= (1.0 - ease_phase)) {
        float ease_t = (t - (1.0 - ease_phase)) / ease_phase;
        float eased_progress = ease_in_out_sine(ease_t);
        rotation_angle = 360.0 * (1.0 - ease_phase) + eased_progress * (360.0 * ease_phase);
    } else {
        rotation_angle = 360.0 * t;
    }
    
    if (start_from_quarter_front) {
        rotation_angle += 45.0;
    }
    
    return normalize_angle(rotation_angle);
}

// Normalize UV coordinates to maintain consistent size
vec2 normalize_uv(vec2 uv, sampler2D tex) {
    vec2 tex_size = vec2(textureSize(tex, 0));
    
    if (maintain_aspect_ratio && target_size.x > 0.0 && target_size.y > 0.0) {
        float tex_aspect = tex_size.x / tex_size.y;
        float target_aspect = target_size.x / target_size.y;
        
        vec2 scale;
        if (tex_aspect > target_aspect) {
            scale.x = target_size.x / tex_size.x;
            scale.y = scale.x;
        } else {
            scale.y = target_size.y / tex_size.y;
            scale.x = scale.y;
        }
        
        vec2 offset = (vec2(1.0) - (tex_size * scale) / target_size) * 0.5;
        uv = (uv - offset - size_offset / target_size) / ((tex_size * scale) / target_size);
    }
    
    return uv;
}

// Sample texture with horizontal flip option and size normalization
vec4 sample_texture_flipped(sampler2D tex, vec2 uv, bool flip_horizontal) {
    vec2 normalized_uv = normalize_uv(uv, tex);
    
    if (normalized_uv.x < 0.0 || normalized_uv.x > 1.0 || 
        normalized_uv.y < 0.0 || normalized_uv.y > 1.0) {
        return vec4(0.0);
    }
    
    if (flip_horizontal) {
        normalized_uv.x = 1.0 - normalized_uv.x;
    }
    
    return texture(tex, normalized_uv);
}

// Get the appropriate texture and blend factor for a given angle
vec4 get_character_frame(vec2 uv, float angle) {
    angle = normalize_angle(angle);
    
    vec4 result = vec4(0.0);
    
    if (angle >= 0.0 && angle < 45.0) {
        float t = angle / 45.0;
        if (enable_interpolation) t = smooth_transition(t);
        vec4 front = sample_texture_flipped(front_texture, uv, false);
        vec4 quarter_front = sample_texture_flipped(quarter_front_texture, uv, false);
        result = mix(front, quarter_front, t);
    }
    else if (angle >= 45.0 && angle < 90.0) {
        float t = (angle - 45.0) / 45.0;
        if (enable_interpolation) t = smooth_transition(t);
        vec4 quarter_front = sample_texture_flipped(quarter_front_texture, uv, false);
        vec4 side = sample_texture_flipped(side_texture, uv, false);
        result = mix(quarter_front, side, t);
    }
    else if (angle >= 90.0 && angle < 135.0) {
        float t = (angle - 90.0) / 45.0;
        if (enable_interpolation) t = smooth_transition(t);
        vec4 side = sample_texture_flipped(side_texture, uv, false);
        vec4 quarter_back = sample_texture_flipped(quarter_back_texture, uv, false);
        result = mix(side, quarter_back, t);
    }
    else if (angle >= 135.0 && angle < 180.0) {
        float t = (angle - 135.0) / 45.0;
        if (enable_interpolation) t = smooth_transition(t);
        vec4 quarter_back = sample_texture_flipped(quarter_back_texture, uv, false);
        vec4 back = sample_texture_flipped(back_texture, uv, false);
        result = mix(quarter_back, back, t);
    }
    else if (angle >= 180.0 && angle < 225.0) {
        float t = (angle - 180.0) / 45.0;
        if (enable_interpolation) t = smooth_transition(t);
        vec4 back = sample_texture_flipped(back_texture, uv, false);
        vec4 quarter_back_flip = sample_texture_flipped(quarter_back_texture, uv, true);
        result = mix(back, quarter_back_flip, t);
    }
    else if (angle >= 225.0 && angle < 270.0) {
        float t = (angle - 225.0) / 45.0;
        if (enable_interpolation) t = smooth_transition(t);
        vec4 quarter_back_flip = sample_texture_flipped(quarter_back_texture, uv, true);
        vec4 side_flip = sample_texture_flipped(side_texture, uv, true);
        result = mix(quarter_back_flip, side_flip, t);
    }
    else if (angle >= 270.0 && angle < 315.0) {
        float t = (angle - 270.0) / 45.0;
        if (enable_interpolation) t = smooth_transition(t);
        vec4 side_flip = sample_texture_flipped(side_texture, uv, true);
        vec4 quarter_front_flip = sample_texture_flipped(quarter_front_texture, uv, true);
        result = mix(side_flip, quarter_front_flip, t);
    }
    else if (angle >= 315.0 && angle <= 360.0) {
        float t = (angle - 315.0) / 45.0;
        if (enable_interpolation) t = smooth_transition(t);
        vec4 quarter_front_flip = sample_texture_flipped(quarter_front_texture, uv, true);
        vec4 front = sample_texture_flipped(front_texture, uv, false);
        result = mix(quarter_front_flip, front, t);
    }
    
    return result;
}

// ────────────────────────────────────────────────
// Fragment Shader Entry Point
// ────────────────────────────────────────────────

void fragment() {
    float final_rotation = calculate_auto_rotation();
    vec4 base_color = vec4(0.0);
    
    // Step 1: Directional Blur
    if (enable_directional_blur) {
        vec2 blur_dir = get_manual_blur_direction(blur_direction_degrees, blur_length);
        float step_size = 1.0 / float(blur_samples - 1);
        for (int i = 0; i < blur_samples; i++) {
            float t = float(i) * step_size - 0.5;
            vec2 offset_uv = UV + blur_dir * t;
            base_color += get_character_frame(offset_uv, final_rotation);
        }
        base_color /= float(blur_samples);
    } else {
        base_color = get_character_frame(UV, final_rotation);
    }
    
    // Step 2: Glow Effect
    if (enable_glow) {
        vec4 glow = vec4(0.0);
        float step_size = 1.0 / float(glow_samples - 1);
        
        for (int i = 0; i < glow_samples; i++) {
            for (int j = 0; j < glow_samples; j++) {
                float dx = (float(i) * step_size - 0.5) * 2.0;
                float dy = (float(j) * step_size - 0.5) * 2.0;
                vec2 offset = vec2(dx, dy) * glow_spread;
                vec4 sample_color = get_character_frame(UV + offset, final_rotation);
                
                float brightness = dot(sample_color.rgb, vec3(0.299, 0.587, 0.114));
                if (brightness > glow_threshold) {
                    glow += sample_color;
                }
            }
        }
        
        glow /= float(glow_samples * glow_samples);
        glow *= glow_intensity;
        glow *= glow_color;
        
        base_color = blend_glow(base_color, glow, glow_blend_mode);
    }
    
    COLOR = base_color;
}