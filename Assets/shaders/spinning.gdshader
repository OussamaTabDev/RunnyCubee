shader_type canvas_item;

// --- Uniforms ---
uniform float rotation_degrees : hint_range(-360, 360) = 0.0;
uniform vec2 sprite_size = vec2(32.0, 32.0);

// 🌪️ MOTION BLUR CONTROLS
uniform vec2 blur_direction = vec2(-1.0, 0.0); // Direction of movement (normalized)
uniform float blur_length : hint_range(0.0, 1.0) = 0.2; // How long the blur trail is (UV space)
uniform float blur_intensity : hint_range(0.0, 1.0) = 0.8; // How strong/visible the blur is
uniform int blur_samples : hint_range(2, 32) = 12; // Quality vs performance
uniform float blur_falloff : hint_range(0.0, 5.0) = 2.0; // 1=linear, >1=eased fade

// ✨ GLOW
uniform vec4 glow_color : source_color = vec4(1.0, 0.3, 0.3, 1.0);
uniform float glow_power : hint_range(0.0, 5.0) = 1.5;

// --- Vertex ---
void vertex() {
    // 🔄 Normal 2D rotation around center (no fake 3D)
    vec2 center = sprite_size * 0.5;
    vec2 local = VERTEX - center;

    float rad = radians(rotation_degrees);
    mat2 rot = mat2(
        vec2(cos(rad), sin(rad)),
        vec2(-sin(rad), cos(rad))
    );
    VERTEX = rot * local + center;
}

// --- Fragment ---
void fragment() {
    vec4 base = texture(TEXTURE, UV);
    if (base.a < 0.1) discard;

    // 🌪️ MOTION BLUR — Directional smear
    vec4 blurred = vec4(0.0);
    float total_weight = 0.0;

    // Normalize direction just in case
    vec2 dir = normalize(blur_direction);

    for (int i = 0; i < 32; i++) { // We'll cap at 32, but use uniform for actual count
        if (i >= blur_samples) break;

        float t = float(i) / max(float(blur_samples - 1), 1.0);
        vec2 offset = -dir * blur_length * t; // Negative = blur opposite to movement
        vec4 sample = texture(TEXTURE, UV + offset);

        // Fade out with power curve (more natural than linear)
        float weight = pow(1.0 - t, blur_falloff);
        blurred += sample * weight;
        total_weight += weight;
    }

    if (total_weight > 0.0) {
        blurred /= total_weight;
    }

    // Mix sharp + blur
    vec4 final = mix(base, blurred, blur_intensity * base.a);

    // ✨ Additive glow
    vec3 glow = glow_color.rgb * glow_power * base.a;
    final.rgb += glow;

    COLOR = final;
}