# TODO
# Additional constraints:
# - Angle constraint, will make sure that angle between 2 bones is in some range, or side (uses 2 previous joint positions)
# - Middle angle constraint, will make sure that current bone is perpendicular to two other bones (uses 1 previous and 1 next joint positions)
# - Maybe, on that makes angles even, will make an arch out of the chain (uses 3 previous joint positions)
# - Maybe, one that stretches the distance constraint
#
# Visualisation:
# - Ability to add sprites to follor the bone
# - Better debug bone visuals
#
# System for interpolating smoothly the joing positions:
# - Just interpolating node towards end position
# - Interpolating joing without changing distance - interpolating the angle
# For both of those there has to be some interpolation system like here https://www.youtube.com/watch?v=KPoeNZZ6H4s
# For that _physics_process non-linear interpolation should be used. 
# Increasing _physics_process fps will look better, but not great for performance.
# If we decide to not increase _physics_process fps, then we will have to also 
# add _process linear interpolation, that will be just visual.

@tool
@icon("res://assets/images/SimNode_icon.png")
class_name SimNode
extends Node2D

@export_group("Acnhor")
@export var is_anchored: bool = false

@export_group("Distance")
## Works only if it has IKJoint parent
@export var distance_range: Vector2 = Vector2(10, 10);

@export_group("Visuals")
@export var draw_distance_constraint: bool = false

# Returns joint that has variables for contraints between some two neighbour joints
func get_neighbour_joint_data(joint: SimNode): 
	return self if get_parent() == joint else joint

func apply_distance_constraint(origin: SimNode):
	var distance = get_neighbour_joint_data(origin).distance_range
	var idk_vector = global_position - origin.global_position
	var idk_vector_length = idk_vector.length()
	idk_vector = idk_vector.normalized()
	global_position = origin.global_position + idk_vector * clampf(idk_vector_length, distance.y, distance.x)

func constraint_wave(origin):
	if !is_anchored:
		apply_distance_constraint(origin)
	for neighbour in get_children() + [get_parent()]:
		if neighbour is SimNode && neighbour != origin:
			neighbour.constraint_wave(self)

func chain_update():
	for child in get_children():
		if child is SimNode:
			child.chain_update()
	if is_anchored:
		constraint_wave(self)

func _ready() -> void:
	top_level = true

func _physics_process(_delta: float) -> void:
	if get_parent() is not SimNode: # Root of the tree
		chain_update()
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint():
		seed(hash(get_path()))
		var bone_color = Color(randf(), randf(), randf(), 1.0)
		if get_parent() is SimNode:
			#draw_circle(Vector2.ZERO, lerpf(distance_range.y, distance_range.x, 0.5), bone_color, false, max(0.2, abs(distance_range.x - distance_range.y)), false)
			draw_circle(get_parent().global_position - global_position, lerpf(distance_range.y, distance_range.x, 0.5), bone_color, false, max(0.2, abs(distance_range.x - distance_range.y)), false)
			draw_line(Vector2.ZERO, get_parent().global_position - global_position, bone_color, 0.5)
			draw_circle(Vector2.ZERO, 1, bone_color, true)
		if is_anchored:
			draw_circle(Vector2.ZERO, 0.5, Color(0.918, 0.167, 0.0, 1.0), true)
		else:
			draw_circle(Vector2.ZERO, 0.5, Color(0.339, 0.584, 0.0, 1.0), true)
