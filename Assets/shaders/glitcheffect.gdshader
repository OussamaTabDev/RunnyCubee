shader_type canvas_item;

uniform sampler2D sprite_texture : source_color, hint_default_white;

// Motion blur trail settings
uniform int trail_samples : hint_range(3, 15) = 8; // number of blur layers
uniform float trail_length : hint_range(0.0, 1.0) = 0.3; // how far back the trail goes
uniform float trail_falloff : hint_range(0.1, 0.9) = 0.6; // how quickly trail fades
uniform vec2 motion_direction  = vec2(-1.0, 0.0); // trail direction
uniform float motion_speed : hint_range(0.0, 5.0) = 1.0; // speed multiplier
uniform bool animate_motion  = false; // auto-animate the motion

// Optional effects
uniform float blur_strength : hint_range(0.0, 0.1) = 0.02; // blur each layer slightly
uniform bool additive_blend  = true; // additive blending for glow

vec4 sample_texture_with_blur(vec2 uv, float blur_amount) {
    if (blur_amount <= 0.0) {
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            return vec4(0.0);
        }
        return texture(sprite_texture, uv);
    }

    // Simple blur sampling
    vec4 color = vec4(0.0);
    float total_weight = 0.0;

    int blur_samples = 4;
    for (int i = 0; i < blur_samples; i++) {
        for (int j = 0; j < blur_samples; j++) {
            vec2 offset = vec2(float(i - blur_samples/2), float(j - blur_samples/2)) * blur_amount;
            vec2 sample_uv = uv + offset;

            if (sample_uv.x >= 0.0 && sample_uv.x <= 1.0 && sample_uv.y >= 0.0 && sample_uv.y <= 1.0) {
                float weight = 1.0;
                color += texture(sprite_texture, sample_uv) * weight;
                total_weight += weight;
            }
        }
    }

    if (total_weight > 0.0) {
        return color / total_weight;
    } else {
        return vec4(0.0);
    }
}

void fragment() {
    vec4 final_color = vec4(0.0);

    // Calculate motion offset (for animated motion)
    vec2 base_motion_offset = vec2(0.0);
    if (animate_motion) {
        base_motion_offset = motion_direction * TIME * motion_speed * 0.1;
    }

    // Sample multiple layers for motion blur effect
    for (int i = 0; i < trail_samples; i++) {
        float layer_progress = float(i) / float(trail_samples - 1);

        // Calculate position offset for this layer (motion blur trail)
        vec2 trail_offset = motion_direction * trail_length * layer_progress;
        vec2 sample_uv = UV + trail_offset + base_motion_offset;

        // Calculate alpha falloff for this layer
        float alpha_mult = pow(trail_falloff, layer_progress * 2.0);

        // Calculate blur amount (later layers are more blurred)
        float blur_amount = blur_strength * layer_progress;

        // Sample the texture at this layer
        vec4 layer_color = sample_texture_with_blur(sample_uv, blur_amount);
        layer_color.a *= alpha_mult;

        // Blend layers
        if (i == 0) {
            // First layer (current frame) is the base
            final_color = layer_color;
        } else {
            if (additive_blend) {
                // Additive blending for glow effect
                final_color.rgb += layer_color.rgb * layer_color.a;
                final_color.a = max(final_color.a, layer_color.a);
            } else {
                // Alpha blending
                final_color = mix(final_color, layer_color, layer_color.a);
            }
        }
    }

    // Apply base color modulation
    COLOR = final_color * COLOR;
}