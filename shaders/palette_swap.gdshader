shader_type canvas_item;

uniform vec3[8] reference_palette : source_color;
uniform vec3[8] palette : source_color;

void fragment() {
	for (int i = 0; i < 8; i++) {
		if (abs(COLOR.b - reference_palette[i].b) < 0.01) {
			COLOR.rgb = palette[i];
			break;
		}
	}
}
