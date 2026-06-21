shader_type canvas_item;

uniform sampler2D strip_texture : source_color, filter_linear, repeat_disable;
uniform float value : hint_range(0.0, 1.0) = 0.0;

uniform float window_fraction : hint_range(0.0, 1.0) = 0.2; // 128 of 512

void fragment() {
    float scroll_range = 1.0 - window_fraction;
    float window_start = clamp(value, 0.0, 1.0) * scroll_range;
    vec2 strip_uv = vec2(UV.x, window_start + UV.y * window_fraction);
    COLOR = texture(strip_texture, strip_uv);
}
