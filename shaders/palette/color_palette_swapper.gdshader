shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, source_color;
uniform vec3[8] palette_1 : source_color;
uniform vec3[8] palette_2 : source_color;
uniform float weight = 0.0;

void fragment() {
	COLOR = texture(screen_texture, UV);
}

