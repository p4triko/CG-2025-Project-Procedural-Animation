@tool
extends Node

var draw_surfaces: bool = false
var draw_bones: bool = false
var draw_nodes: bool = false

var restart_queued: bool = false
var palette_enabled: bool = true
var original_shader_code: String = ""

func reset_scene():
	draw_surfaces = false
	draw_bones = false
	draw_nodes = false
	palette_enabled = true
