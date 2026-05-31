shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec3 paint_color : source_color = vec3(0.9, 0.9, 0.82);
uniform sampler2D noise_texture : repeat_enable;
uniform float noise_scale = 8.0;
uniform float wear_amount = 0.35;
uniform float edge_softness = 0.15;

void fragment() {
    vec2 noise_uv = UV * noise_scale;
    float noise_value = texture(noise_texture, noise_uv).r;

    float paint_alpha = smoothstep(
        wear_amount,
        wear_amount + edge_softness,
        noise_value
    );

    if (paint_alpha < 0.45) {
        discard;
    }

    ALBEDO = paint_color;
    METALLIC = 0.0;
    ROUGHNESS = 1.0;
}