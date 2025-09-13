shader_type canvas_item;

// Parameters
uniform vec4 fill_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Red by default
uniform float blur_strength : hint_range(0.0, 50.0) = 10.0;

void fragment() {
    // Get normalized position within the rect (0 to 1)
    vec2 uv = UV;

    // Define soft edges using smoothstep
    float margin = blur_strength / 100.0; // Adjust based on resolution
    float left = smoothstep(0.0, margin, uv.x);
    float right = 1.0 - smoothstep(1.0 - margin, 1.0, uv.x);
    float top = smoothstep(0.0, margin, uv.y);
    float bottom = 1.0 - smoothstep(1.0 - margin, 1.0, uv.y);

    // Combine edges
    float alpha = left * right * top * bottom;

    // Apply color and alpha
    COLOR = fill_color;
    COLOR.a *= alpha;
}