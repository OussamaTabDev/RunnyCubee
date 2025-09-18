shader_type canvas_item;

// == CONFIGURABLE UNIFORMS (Editable in Inspector) ==
// Colors
uniform vec3 col1 : source_color = vec3(0.216, 0.471, 0.698); // Blue
uniform vec3 col2 : source_color = vec3(1.00, 0.329, 0.298);  // Reddish
uniform vec3 col3 : source_color = vec3(0.867, 0.910, 0.247); // Yellowish
uniform vec3 background_color : source_color = vec3(1.0);     // Default white bg

// Timing & Speed
uniform float global_speed : hint_range(0.0, 5.0, 0.1) = 1.0; // Overall animation speed

// Disk Sizes
uniform float disk_size_scale : hint_range(0.1, 3.0, 0.1) = 1.0;
uniform float disk_edge_softness : hint_range(0.001, 0.1, 0.001) = 0.008;

// Effects Intensity
uniform float vignette_intensity : hint_range(0.0, 2.0, 0.05) = 1.0;
uniform float additive_disk_intensity : hint_range(0.0, 1.0, 0.05) = 0.2;

// Grid Tiling
uniform float grid_cell_size : hint_range(0.1, 2.0, 0.05) = 0.5;

// == HELPER FUNCTION ==
float disk(vec2 r, vec2 center, float radius) {
    return 1.0 - smoothstep(
        radius - disk_edge_softness,
        radius + disk_edge_softness,
        length(r - center)
    );
}

void fragment() {
    float t = TIME * 2.0 * global_speed;
    vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 fragCoord = FRAGCOORD.xy;

    // Normalize coordinates to center and aspect-correct
    vec2 r = (2.0 * fragCoord - resolution) / resolution.y;

    // Distort with sine waves
    r *= 1.0 + 0.05 * sin(r.x * 5.0 + TIME * global_speed) + 0.05 * sin(r.y * 3.0 + TIME * global_speed);
    r *= 1.0 + 0.2 * length(r);

    float side = grid_cell_size;
    vec2 r2 = mod(r, side);
    vec2 r3 = r2 - side / 2.0;

    float i = floor(r.x / side) + 2.0;
    float j = floor(r.y / side) + 4.0;
    float ii = r.x / side + 2.0;
    float jj = r.y / side + 4.0;

    vec3 pix = background_color; // Use customizable background

    float rad, disks;

    // First disk (col2)
    rad = (0.15 + 0.05 * sin(t + ii * jj)) * disk_size_scale;
    disks = disk(r3, vec2(0.0), rad);
    pix = mix(pix, col2, disks);

    // Second animated disk (col1)
    float speed = 2.0 * global_speed;
    float tt = TIME * speed + 0.1 * i + 0.08 * j;
    const float stopEveryAngle = PI / 2.0;
    const float stopRatio = 0.7;
    float t1 = (floor(tt) + smoothstep(0.0, 1.0 - stopRatio, fract(tt))) * stopEveryAngle;

    float x = -0.07 * cos(t1 + i);
    float y = 0.055 * (sin(t1 + j) + cos(t1 + i));
    rad = (0.1 + 0.05 * sin(t + i + j)) * disk_size_scale;
    disks = disk(r3, vec2(x, y), rad);
    pix = mix(pix, col1, disks);

    // Third pulsing disk (col3) with additive color
    rad = (0.2 + 0.05 * sin(t * (1.0 + 0.01 * i))) * disk_size_scale;
    disks = disk(r3, vec2(0.0), rad);
    pix += additive_disk_intensity * col3 * disks * sin(t + i * j + i);

    // Vignette-like fade out at edges
    pix -= vignette_intensity * smoothstep(0.3, 5.5, length(r));

    // Output final color
    COLOR = vec4(pix, 1.0);
}