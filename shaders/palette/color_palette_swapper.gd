extends ColorRect

@export var enabled: bool = true:
	set(v):
		enabled = v
		visible = enabled
@export var default_palette: int = 0
@export var primary_palette: int = 0
@export var secondary_palette: int = 0
@export_range(0, 1, 0.000001) var interpolation_weight: float = 0:
	set(v):
		interpolation_weight = v
		material.set_shader_parameter("weight", interpolation_weight)
@export var palettes: Array[ColorPalette] = []

@export_group("Fine tuning")
#@export_enum("Ignore", "Nearest", "Interpolate Hue") var not_matching_color_behavior = 0
@export_range(0, 1, 0.001) var hue_shift: float = 0:
	set(v):
		hue_shift = v
		material.set_shader_parameter("hue_shift", hue_shift)
@export_range(-1, 1, 0.001) var saturation_shift: float = 0:
	set(v):
		saturation_shift = v
		material.set_shader_parameter("saturation_shift", saturation_shift)
@export_range(-1, 1, 0.001) var value_shift: float = 0:
	set(v):
		value_shift = v
		material.set_shader_parameter("value_shift", value_shift)

var original_code: String = ""
func _ready() -> void:
	# Save original shader code
	var shader = preload("res://shaders/palette/color_palette_swapper.gdshader")
	original_code = shader.code
	
	# Edit preprocessor code
	var code = original_code
	#code = "#define not_matching_color_behavior_stuff" + "\n" + code
	var d_palette: String = ""
	var p_palette: String = ""
	var s_palette: String = ""
	var palette_size = palettes[default_palette].colors.size() if palettes.size() > default_palette && palettes[default_palette] != null && palettes[default_palette].colors.size() != 0 else 1
	for i in range(palette_size):
		if palettes.size() > default_palette && palettes[default_palette] != null && palettes[default_palette].colors.size() > i: 
			d_palette += "vec3(%s, %s, %s)," % [palettes[default_palette].colors[i].r, palettes[default_palette].colors[i].g, palettes[default_palette].colors[i].b]
		else:
			d_palette += "vec3(0),"
		if palettes.size() > primary_palette && palettes[primary_palette] != null && palettes[primary_palette].colors.size() > i: 
			p_palette += "vec3(%s, %s, %s)," % [palettes[primary_palette].colors[i].r, palettes[primary_palette].colors[i].g, palettes[primary_palette].colors[i].b]
		else:
			p_palette += "vec3(0),"
		if palettes.size() > secondary_palette && palettes[secondary_palette] != null && palettes[secondary_palette].colors.size() > i: 
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

func _process(_delta: float) -> void:
	enabled = Global.palette_enabled
