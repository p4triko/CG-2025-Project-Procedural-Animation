extends ColorRect

@export var enabled: bool = true
@export var use_indexed_colors: bool = false
@export var default_palette: ColorPalette = ColorPalette.new()
@export var primary_palette: int = 0
@export var secondary_palette: int = 0
@export var weight: float = 0:
	set(v):
		weight = v
		material.set_shader_parameter("weight", weight)
@export var palettes: Array[ColorPalette] = []

## Var palette length?

var original_code: String = ""
func _ready() -> void:
	# Save original shader code
	var shader = preload("res://shaders/palette/color_palette_swapper.gdshader")
	original_code = shader.code
	
	# Edit preprocessor code
	var code = original_code
	if use_indexed_colors:
		code = "#define USE_INDEXED_COLORS" + "\n" + code
	
	var d_palette: String = ""
	var p_palette: String = ""
	var s_palette: String = ""
	var palette_size = default_palette.colors.size()
	for i in range(palette_size):
		d_palette += "vec3(%s, %s, %s)," % [default_palette.colors[i].r, default_palette.colors[i].g, default_palette.colors[i].b]
		if palettes[primary_palette].colors.size() > i: 
			p_palette += "vec3(%s, %s, %s)," % [palettes[primary_palette].colors[i].r, palettes[primary_palette].colors[i].g, palettes[primary_palette].colors[i].b]
		else:
			p_palette += "vec3(0),"
		if palettes[secondary_palette].colors.size() > i: 
			s_palette += "vec3(%s, %s, %s)," % [palettes[secondary_palette].colors[i].r, palettes[secondary_palette].colors[i].g, palettes[secondary_palette].colors[i].b]
		else:
			s_palette += "vec3(0),"
	d_palette = d_palette.left(-1)
	p_palette = p_palette.left(-1)
	s_palette = s_palette.left(-1)
	
	code = code.replace("__palette_d__", "const vec3[%s] palette_d = vec3[](%s)" % [palette_size, d_palette])
	code = code.replace("__palette_s__", "const vec3[%s] palette_s = vec3[](%s)" % [palette_size, s_palette])
	code = code.replace("__palette_p__", "const vec3[%s] palette_p = vec3[](%s)" % [palette_size, p_palette])
	
	code = "#define PREPROCESSED\n" + code
	shader.code = code
	
