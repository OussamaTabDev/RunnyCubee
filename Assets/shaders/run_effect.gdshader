shader_type canvas_item;
render_mode unshaded;

// Parameters
uniform vec4 cloth_color : source_color = vec4(0.8, 0.1, 0.1, 1.0);
uniform float max_wave_offset : hint_range(0.0, 1.0) = 0.3;   // Max shift as fraction of width (0.3 = 30%)
uniform float wave_frequency : hint_range(0.5, 10.0) = 3.0;
uniform float wave_speed : hint_range(0.0, 10.0) = 4.0;
uniform float flutter_amount : hint_range(0.0, 1.0) = 0.7;
uniform float speed_influence = 1.0;
uniform float global_opacity : hint_range(0.0, 1.0) = 1.0;

// Fade controls
uniform bool invert_fade = false; // If true, fade from left to right

void fragment() {
    vec2 uv = UV;

    // Falloff: top = no wave, bottom = full wave
    float vertical_falloff = uv.y;

    float t = TIME * wave_speed;

    // Main sine wave
    float wave = sin(t + uv.y * wave_frequency * 2.0) * (1.0 - vertical_falloff);

    // Flutter (chaotic detail)
    float flutter = sin(t * 1.5 + uv.y * 20.0) * sin(t * 0.7) * flutter_amount * (1.0 - vertical_falloff);

    // Total offset in UV space (0.0 to 1.0 range)
    float offset = (wave + flutter) * speed_influence;

    // 🔒 Clamp the offset so it doesn't go beyond safe bounds
    offset = clamp(offset, -max_wave_offset, max_wave_offset);

    // Distorted UV
    vec2 warped_uv = uv;
    warped_uv.x += offset;

    // Only show if inside [0, 1] in X
    float inside = step(0.0, warped_uv.x) * step(warped_uv.x, 1.0);

    // === Fade from right to left (or inverted) ===
    float fade = invert_fade ? uv.x : (1.0 - uv.x); // Right→Left = 1..0, Left→Right = 0..1

    // Final color
    COLOR = cloth_color;
    COLOR.a *= inside * global_opacity * fade; // Apply directional fade
}