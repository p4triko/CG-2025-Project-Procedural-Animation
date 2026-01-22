# This script file contains code adapted from tentacle-arm-showcase
# Copyright (c) 2025 Smitner Studio UG
# MIT License
# Repo: https://github.com/Smitner-Studio/tentacle-arm-showcase
# Modifications were made by one of the contributors of this CG project p4triko *Patrick*, 2025/2026

extends Node2D

@onready var line_2d: Line2D = $Line2D 
@onready var tip_point: Marker2D = $Line2D/Tip
@export var apply_waviness: bool = true

@export_group("Behavior Settings")
@export var follows_mouse: bool = false
@export var detection: float = 400
@export var enemy: CharacterBody2D # In that the case the player is the enemy.
@export var hostile: bool = false

# Assign which direction the tentacle faces by default, for example maybe want it to wonder in the ceiling.d
@export_range(-360, 360) var rest_angle: float = 90.0

@export_group("Tentacle Settings")
@export var max_length: float = 300.0
@export var num_segments: int = 30
@export var ik_iterations: int = 3

@export_group("Wave Settings")
@export_range(0.0, 50.0, 0.5) var wave_amplitude: float = 5.0
@export_range(0.0, 5, 0.1) var wave_frequency: float = 2.0
@export_range(0.0, 10.0, 0.1) var wave_speed: float = 3.0

@export_group("Attack Smoothing")
@export_range(0.0, 30.0, 0.1) var snap_speed: float = 10.0
@export_range(0.0, 30.0, 0.1) var return_speed: float = 6.0

var aim_target: Vector2
var was_aiming = false

var segments: Array[Vector2] = []
var segment_lengths: Array[float] = []
var wave_time: float = 0.0

func _ready():
	aim_target = calculate_pos()
	var segment_len = max_length / num_segments 
	
	for i in range(num_segments + 1):
		segments.append(global_position)
		if i < num_segments:
			segment_lengths.append(segment_len)
			
	line_2d.clear_points()
	for i in range(num_segments + 1):
		line_2d.add_point(Vector2.ZERO)

func _process(delta: float) -> void:
	var target: Vector2 = calculate_pos() # Fallback to idle state.
	var aiming = false # Is the tentacle aiming towards the mouse or the player. Mouse is more for testing purposes.

	if follows_mouse:
		aiming = true
		# Tentacle will aim at the mouse, but not stretching outside the maximum length.
		target = set_and_clamp_to_length(get_global_mouse_position())

	elif hostile and enemy != null:
		# Distance between enemy / player and the tentacle.
		var dist_enemy = global_position.distance_to(enemy.global_position)
		if dist_enemy < detection:
			aiming = true
			target = set_and_clamp_to_length(enemy.global_position)
		else:
			# Player is not in range, so we return back to idle state.
			target = calculate_pos()
	else:
		# Nothing is really happening, neither attacking / following, lets just idle around.
		target = calculate_pos()

	# How quickly should the tentacle respond.
	var chase_factor: float = 0.0

	if aiming:
		chase_factor = snap_speed
	else: 
		chase_factor = return_speed

	# Frame independent smoothing, exponential decay.
	var alpha = 1.0 - exp(-chase_factor * delta)
	aim_target = aim_target.lerp(target, alpha)

	solve_ik(aim_target)

	if apply_waviness and not aiming:
		apply_waves(delta)

	update_line_visuals()

	if tip_point:
		tip_point.global_position = segments[-1]

	queue_redraw()

# Set and also clamp the length so the tentacle doesnt stretch outside it's contraints.
func set_and_clamp_to_length(target: Vector2) -> Vector2:
	var dir = target - global_position
	if dir.length() > max_length:
		return global_position + dir.normalized() * max_length
	return target # Already in reach, so we don't need to do anything.

# Return the idle position for the tip of the tentacle.
func calculate_pos() -> Vector2:
	var rad = deg_to_rad(rest_angle)
	var dir = Vector2.RIGHT.rotated(rad)
	return global_position + (dir * max_length * 0.9)

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
			segments[i + 1] = segments[i] + dir * segment_lengths[i]

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

func _draw():
	#draw_circle(to_local(tip_point.global_position), 250.0, Color.RED, false)
	pass