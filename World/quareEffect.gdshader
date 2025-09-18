shader_type canvas_item;

// ========== USER CONTROLS ==========
uniform float speed : hint_range(0.0, 5.0) = 0.7;
uniform float y_spread : hint_range(0.0, 5.0) = 1.6;
uniform int num_blocks : hint_range(1, 200) = 70;
uniform float pulse_strength : hint_range(0.0, 2.0) = 1.0;
uniform float pulse_frequency : hint_range(0.1, 10.0) = 2.0;   // How fast the global pulse beats
uniform vec4 left_color : source_color = vec4(0.6, 0.0, 0.3, 1.0);   // Right side
uniform vec4 right_color : source_color = vec4(0.0, 0.3, 0.6, 1.0);  // Left side
uniform bool use_gradient  = false;
uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float distortion_amount : hint_range(0.0, 1.0) = 0.04;
uniform bool show_blocks = true;
uniform float direction_bias : hint_range(-1.0, 1.0) = 0.0; // -1 = left, +1 = right

// ========== INTERNAL FUNCTIONS ==========
float rand(float x) {
    return fract(sin(x) * 4358.5453123);
}

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5357);
}

float box(vec2 p, vec2 b, float r) {
    return length(max(abs(p) - b, 0.0)) - r;
}

// Replace audio with smooth time-based pulse using sine + noise
float sample_pulse() {
    // Base rhythmic pulse
    float t = TIME * pulse_frequency;
    float sine_pulse = 0.5 + 0.5 * sin(t);
    
    // Add some organic variation with noise
    float noise_mod = 0.5 + 0.5 * sin(TIME * 0.37);
    noise_mod *= rand(vec2(floor(t * 0.5), 0.0));
    
    return (sine_pulse * 0.7 + noise_mod * 0.3) * pulse_strength;
}

// ========== MAIN ==========
void fragment() {
    float pulse = sample_pulse();
    
    vec2 uv = UV - 0.5; // Centered UV
    float aspect = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    uv.x *= aspect; // Correct aspect ratio

    // Base color: left/right or gradient
    vec3 base_color;
    if (use_gradient) {
        base_color = mix(left_color.rgb, right_color.rgb, UV.x);
    } else {
        base_color = UV.x > 0.5 ? right_color.rgb : left_color.rgb;
    }

    // Initialize output color
    vec3 color = background_color.rgb + pulse * base_color * 0.5 * (0.9 - cos(uv.x * 8.0));

    // Generate blocks
    for (int i = 0; i < num_blocks; i++) {
        float z = 1.0 - 0.7 * rand(float(i) * 1.4333); // Depth: 0=far, 1=near
        float tick_time = TIME * z * speed + float(i) * 1.23753;
        float tick = floor(tick_time);

        // Position with direction bias
        float side_sign = sign(uv.x + direction_bias);
        if (abs(side_sign) < 0.01) side_sign = 1.0; // Avoid zero

        vec2 pos = vec2(
            0.6 * aspect * (rand(tick) - 0.5),
            side_sign * y_spread * (0.5 - fract(tick_time))
        );
        pos.x += 0.24 * sign(pos.x); // Move aside
        if (abs(pos.x) < 0.1) pos.x += sign(pos.x) * 0.1; // Avoid center overlap

        // Size varies with depth and randomness
        vec2 size = 1.8 * z * vec2(0.04, 0.04 + 0.1 * rand(tick + 0.2));

        // Box SDF
        float b = box(uv - pos, size, 0.01);
        float dust = z * smoothstep(0.22, 0.0, b) * pulse * 0.5;

        if (show_blocks) {
            float block = 0.2 * z * smoothstep(0.002, 0.0, b);
            float shine = 0.6 * z * pulse * smoothstep(-0.002, b, 0.007);
            color += dust * base_color + block * vec3(z) + shine;
        } else {
            color += dust * base_color;
        }
    }

    // Add noise distortion
    color -= rand(uv) * distortion_amount;

    // Output
    COLOR = vec4(color, 1.0);
}