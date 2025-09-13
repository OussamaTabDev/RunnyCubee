shader_type canvas_item;

// === Parameters ===
uniform float squash_stretch_x : hint_range(0.1, 3.0) = 1.0;     // Horizontal scale
uniform float squash_stretch_y : hint_range(0.1, 3.0) = 1.0;     // Vertical scale
uniform vec2 anchor = vec2(0.5, 0.5);                // Pivot in UV (0-1)
uniform float bend_curve : hint_range(-2.0, 2.0) = 0.0;          // Curve strength (- = concave, + = convex)
uniform float bend_axis : hint_range(0.0, 1.0) = 0.0;            // 0 = vertical bend (Y), 1 = horizontal bend (X)
uniform vec2 texture_size = vec2(64.0, 64.0);

void vertex() {
    // UV relative to anchor
    vec2 uv_relative = UV - anchor;

    // Base linear squash/stretch
    vec2 scale_delta = vec2(squash_stretch_x - 1.0, squash_stretch_y - 1.0);
    vec2 linear_offset = uv_relative * vec2(texture_size.x, texture_size.y) * scale_delta;

    // Curved deformation (parabolic warp)
    vec2 curved_offset = vec2(0.0);

    if (bend_curve != 0.0) {
        float u = uv_relative.x; // horizontal UV offset
        float v = uv_relative.y; // vertical UV offset

        if (bend_axis < 0.5) {
            // === Vertical Bend (curve along Y axis) ===
            // X position affected by Y^2
            float parabola = bend_curve * v * v;
            curved_offset.x = parabola * texture_size.x;
        } else {
            // === Horizontal Bend (curve along X axis) ===
            // Y position affected by X^2
            float parabola = bend_curve * u * u;
            curved_offset.y = parabola * texture_size.y;
        }
    }

    // Combine linear + curved deformation
    VERTEX += linear_offset + curved_offset;
}

shader_type canvas_item;

// Parameters
uniform float squash_stretch_x : hint_range(0.1, 3.0) = 1.0;
uniform float squash_stretch_y : hint_range(0.1, 3.0) = 1.0;
uniform vec2 anchor : hint_vec2 = vec2(0.5); // Smooth pivot (UV space)
uniform vec2 texture_size = vec2(64.0, 64.0);
uniform float warp_amount : hint_range(0.0, 1.0) = 0.5; // 0 = linear, 1 = full warp
uniform float bulge_curve : hint_range(-2.0, 2.0) = 0.8; // Warp style: negative = inward, positive = bulge

void vertex() {
    // UV position relative to anchor
    vec2 uv_relative = UV - anchor;

    // Non-linear warp: apply curve to the offset
    // We'll use a power-based curve with smooth control
    vec2 warp_factor = vec2(
        pow(abs(uv_relative.x), bulge_curve) * sign(uv_relative.x),
        pow(abs(uv_relative.y), bulge_curve) * sign(uv_relative.y)
    );

    // Blend between linear and warped offset
    vec2 final_offset_uv = mix(uv_relative, warp_factor, warp_amount);

    // Apply squash/stretch scale to the warped offset
    vec2 scale_delta = vec2(squash_stretch_x - 1.0, squash_stretch_y - 1.0);
    vec2 pixel_offset = final_offset_uv * scale_delta * texture_size;

    VERTEX += pixel_offset;
}