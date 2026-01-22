#define PALETTE_D __palette_d__
#define PALETTE_S __palette_s__
#define PALETTE_P __palette_p__
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, source_color;
uniform float weight = 0.0;
#ifdef PREPROCESSED
PALETTE_D;
PALETTE_S;
PALETTE_P;
#endif

void fragment() {
	#ifdef USE_INDEXED_COLORS
	#else
	#endif
	COLOR = texture(screen_texture, UV);
}

