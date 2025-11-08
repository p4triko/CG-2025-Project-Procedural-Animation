# TODO
# Additional constraints:
# - Angle constraint, will make sure that angle between 2 bones is in some range, or side (uses 2 previous joint positions)
# - Middle angle constraint, will make sure that current bone is perpendicular to two other bones (uses 1 previous and 1 next joint positions)
# - Maybe, on that makes angles even, will make an arch out of the chain (uses 3 previous joint positions)
# - Maybe, one that stretches the distance constraint

# Visualisation:
# - Ability to add sprites to follor the bone
# - Better debug bone visuals

@tool
class_name IKJoint
extends Node2D

@export_group("Acnhor")
@export var is_anchored: bool = false

@export_group("Distance")
## Works only if it has IKJoint parent
@export var distance_range: Vector2 = Vector2(1, 1);

func apply_distance_constraint(parent: IKJoint):
	var idk_vector = global_position - parent.global_position
	var idk_vector_length = idk_vector.length()
	idk_vector = idk_vector.normalized()
	global_position = parent.global_position + idk_vector * clampf(idk_vector_length, parent.distance_range.x, parent.distance_range.y)

func constraint_wave(origin):
	if !is_anchored:
		apply_distance_constraint(origin)
	for neighbour in get_children() + [get_parent()]:
		if neighbour is IKJoint && neighbour != origin:
			neighbour.constraint_wave(self)

func chain_update():
	for child in get_children():
		if child is IKJoint:
			child.chain_update()
	if is_anchored:
		constraint_wave(self)

func _ready() -> void:
	top_level = true

func _physics_process(_delta: float) -> void:
	if get_parent() is not IKJoint: # Root of the tree
		chain_update()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint():
		if get_parent() is IKJoint:
			draw_circle(Vector2.ZERO, lerpf(distance_range.y, distance_range.x, 0.5), Color(0.769, 0.388, 0.0, 1.0), false, max(0.1, abs(distance_range.x - distance_range.y)), true)
			draw_line(Vector2.ZERO, get_parent().global_position - global_position, Color(), 0.5)
		if is_anchored:
			draw_circle(Vector2.ZERO, 1, Color(0.918, 0.167, 0.0, 1.0), true)
		else:
			draw_circle(Vector2.ZERO, 1, Color(0.339, 0.584, 0.0, 1.0), true)
