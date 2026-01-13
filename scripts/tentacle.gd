# This script file contains code adapted from tentacle-arm-showcase
# Copyright (c) 2025 Smitner Studio UG
# MIT License
# Repo: https://github.com/Smitner-Studio/tentacle-arm-showcase
# Modifications were made by one of the contributors of this CG project p4triko *Patrick*, 2025/2026

extends Node2D

@onready var line_2d: Line2D = $Line2D 
@onready var tip_point: Marker2D = $Line2D/Tip

@export_group("Behavior Settings")
@export var follows_mouse: bool = false

# Assign which direction the tentacle faces by default, for example maybe want it to wonder in the ceiling.
@export_range(-360, 360) var rest_angle: float = 90.0

@export_group("Tentacle Settings")
@export var max_length: float = 300.0
@export var num_segments: int = 30
@export var ik_iterations: int = 3

@export_group("Wave Settings")
@export_range(0.0, 50.0, 0.5) var wave_amplitude: float = 5.0
@export_range(0.0, 5, 0.1) var wave_frequency: float = 2.0
@export_range(0.0, 10.0, 0.1) var wave_speed: float = 3.0

var segments: Array[Vector2] = []
var segment_lengths: Array[float] = []
var wave_time: float = 0.0

func _ready():
	var segment_len = max_length / num_segments 
	
	for i in range(num_segments + 1):
		segments.append(global_position)
		if i < num_segments:
			segment_lengths.append(segment_len)
			
	line_2d.clear_points()
	for i in range(num_segments + 1):
		line_2d.add_point(Vector2.ZERO)

func _process(delta: float) -> void:
	var target_pos: Vector2
	
	if follows_mouse:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var direction: Vector2 = mouse_pos - global_position
		if direction.length() > max_length:
			target_pos = global_position + direction.normalized() * max_length
		else:
			target_pos = mouse_pos
	else:
		var rad = deg_to_rad(rest_angle)
		var dir = Vector2.RIGHT.rotated(rad)
		target_pos = global_position + (dir * max_length * 0.9)

	solve_ik(target_pos)
	apply_waves(delta)
	
	# Pinning
	if follows_mouse:
		segments[-1] = target_pos
		
	update_line_visuals()

	if tip_point:
		tip_point.global_position = segments[-1]

func solve_ik(target: Vector2) -> void:
	segments[-1] = target # Snap tip to the target

	# For better approximation we do multiple passes
	for _iter in range(ik_iterations):

		# Backward pass
		for i in range(num_segments - 1, -1, -1):
			var dir = (segments[i] - segments[i + 1]).normalized()
			segments[i] = segments[i + 1] + dir * segment_lengths[i]
	
		# Forward pass and lets re-anchor the start point.
		segments[0] = global_position 

		for i in range(num_segments):
			var dir = (segments[i + 1] - segments[i]).normalized()
			segments[i+1] = segments[i] + dir * segment_lengths[i]

func apply_waves(delta: float) -> void:
	if wave_amplitude <= 0: return
	wave_time += delta * wave_speed
	
	var total_len = max_length
	var current_len = 0.0
	
	for i in range(1, num_segments + 1):
		current_len += segment_lengths[i - 1]
		var t = current_len / total_len
		
		var dir = (segments[i] - segments[i - 1]).normalized()
		var perp = dir.orthogonal() # Perpencicular wave
		
		var phase = wave_time + (t * wave_frequency * TAU)
		var offset = sin(phase) * (wave_amplitude * t)
		
		segments[i] += perp * offset

func update_line_visuals():
	for i in range(segments.size()):
		var local_pos = line_2d.to_local(segments[i])
		line_2d.set_point_position(i, local_pos)
