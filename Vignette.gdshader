shader_type canvas_item;

uniform float alpha : hint_range(0.0, 1.0) = 0.15;  // Reduced strength
uniform float inner_radius : hint_range(0.0, 1.0) = 0.4;  // Larger soft center
uniform float outer_radius : hint_range(0.0, 1.0) = 0.9;  // Softer edge
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

vec3 overlay(vec3 base, vec3 blend) {
    return mix(base * blend * 2.0, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), step(0.5, base));
}

void fragment() {
    vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    
    float x = abs(UV.x - 0.5) * 2.0;
    float y = abs(UV.y - 0.5) * 2.0;
    float dist = sqrt(x * x + y * y);
    float fade = smoothstep(inner_radius, outer_radius, dist);
    
    vec3 vignette_color = vec3(0.0);
    vec3 blended = overlay(screen_color, vignette_color);
    vec3 final_color = mix(screen_color, blended, fade * alpha);
    
    COLOR = vec4(final_color, 1.0);
}