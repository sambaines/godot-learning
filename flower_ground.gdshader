shader_type spatial;

// --- Uniforms (tweakable in inspector) ---
uniform vec3 grass_color : source_color = vec3(0.2, 0.5, 0.15);
uniform vec3 flower_color_a : source_color = vec3(1.0,1.0,1.0); //white
uniform vec3 flower_color_b : source_color = vec3(1.0,0.5,0.05); //orange
uniform vec3 flower_color_c : source_color = vec3(0.4,0.2,0.9); //purple
uniform vec3 centre_color : source_color = vec3(1.0,0.85,0.1);
uniform float density : hint_range(5.0,40.0) = 15.0;
uniform float flower_radius : hint_range(0.01, 0.25) = 0.07;
uniform float centre_radius : hint_range(0.005, 0.1) = 0.025;
uniform int petal_count : hint_range(4, 10) = 5;
uniform bool randomise_petals = false;
uniform float petal_split_low : hint_range(0.05, 1.0) = 0.4;
uniform float petal_split_high : hint_range(0.05, 1.0) = 0.6;

// Mask image
uniform sampler2D flower_mask;

// --- Hash function ---
// Takes a 2D cell coordinate, returns a pseudo-random 2D value (0..1)
// Position hash - gives flower placement
vec2 hash2(vec2 p) {
    p = mod(p, vec2(289.0)); // keeps input small so sin() stays accurate on metal
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}
// Color hash - completely different stants, completely independent results
float hash1_color(vec2 p) {
    p = mod(p, 289.0);
    return fract(sin(dot(p, vec2(41.83, 107.97))) * 57831.24);
}

void fragment() {
    // Sample mask before tiling - UV is still 0...1 across the whole plane
    float mask = 1.0 - texture(flower_mask, UV).r; // using minus from 1.0 inverts the texture

    // Step 1: Tile UV space into a grid
    vec2 uv = UV * density;

    // Step 2: which cell are we in, where inside it?
    vec2 cell = floor(uv);
    vec2 f = fract(uv);

    // Step 3: start with grass
    vec3 col = grass_color;

    // Step 4: check this cell and its 8 neighbours
    // (a flower in a neighbour cell might bleed over the edge into ours)
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 offset = vec2(float(x), float(y));

            // Random position for the flower in this neighbour cell
            vec2 h = hash2(cell + offset);
            vec2 center = offset + h;
            vec2 delta = f - center; // vector from flower centre to pixel

            // Distance from our pixel (f) to that flower center
            float d = length(f - center);

            // Angle from centre to this pixel
            float angle = atan(delta.y, delta.x) + h.y * 6.28; // The + h.y * 6.28 gives a random petal rotation between 0-360 per flower

            int petals = randomise_petals
                ? (4 + int(hash1_color(cell + offset + vec2(5.1, 3.7)) * 5.0))
                : petal_count;
            // Petal shape: radius pulses with angle
            // cos() produces values -1..1, we ramp to 0.6...1.0
            // so the radius shrinks in the gaps between petals
            float petal = petal_split_high + petal_split_low * cos(angle * float(petals));
            float petal_radius = flower_radius * petal;

            if (d < petal_radius && mask > 0.5) {  // <-- mask gates the flower
                // Centre dot
                if (d < centre_radius) {
                    col = centre_color;
                } else {
                    float c = hash1_color(cell + offset);
                    if (c < 0.33) {
                    col = flower_color_a;
                    } else if (c < 0.66) {
                        col = flower_color_b;
                    } else {
                        col = flower_color_c;
                    }
                }
            
            }
        }
    }
    ALBEDO = col;
}