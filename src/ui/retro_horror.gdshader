shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float pixel_size : hint_range(1.0, 10.0) = 3.0;
uniform float color_depth : hint_range(2.0, 32.0) = 8.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.25;
uniform float vignette_intensity : hint_range(0.0, 2.0) = 1.2;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.85;
uniform float noise_strength : hint_range(0.0, 0.2) = 0.015;

vec2 uv_scale(vec2 uv, vec2 size, float p_size) {
    vec2 steps = size / p_size;
    return floor(uv * steps) / steps;
}

float hash(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    // 1. Pixelation
    vec2 size = vec2(textureSize(screen_texture, 0));
    vec2 pixelated_uv = uv_scale(UV, size, pixel_size);
    
    // 2. Sample screen
    vec4 color = texture(screen_texture, pixelated_uv);
    
    // 3. Color Depth Reduction (Banding)
    color.rgb = floor(color.rgb * color_depth) / color_depth;
    
    // 4. Subtle Film Noise
    float n = (hash(pixelated_uv + TIME) - 0.5) * noise_strength;
    color.rgb += vec3(n);
    
    // 5. Scanlines
    float scanline = sin(pixelated_uv.y * size.y * 3.14159 / pixel_size) * 0.5 + 0.5;
    color.rgb -= scanline * scanline_strength * color.rgb;
    
    // 6. Vignette
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    float vignette = smoothstep(0.8, 0.8 - vignette_intensity * 0.4, dist);
    color.rgb = mix(color.rgb, color.rgb * vignette, vignette_opacity);
    
    COLOR = color;
}
