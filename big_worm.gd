@tool
class_name Worm extends SimRoot

@export_tool_button("Generate worm") var a = func(): generate_worm()
var joint_texture = preload("res://assets/images/worm_joint_texture.tres")
var bone_texture = preload("res://assets/images/worm_bone_texture.tres")
@export var texture_scale: float = 1
var _texture_scale = 0
@export var texture_ratio: float = 32.525
@export_exp_easing() var thickness_falloff: float = 0.05
@export_exp_easing() var length_falloff: float = 0.05

func delete_bones():
	for i in get_children():
		remove_child(i)
		i.queue_free()

var curr_seq: int = 0
func build_sequence(seq, curr_node = self, curr_texture_scale = texture_scale, curr_length = 20):
	var seq_len = seq.length()
	while seq_len > curr_seq:
		curr_seq += 1
		match(seq[curr_seq-1]):
			"A", "O", "F":
				var new_node = SimNode.new()
				new_node.bone_texture = bone_texture
				new_node.bone_texture_y_scale = curr_texture_scale / texture_ratio
				new_node.joint_texture = joint_texture
				new_node.joint_texture_scale = curr_texture_scale
				new_node.distance_range = Vector2(curr_length, curr_length)
				match(seq[curr_seq-1]):
					"A": # Main anchor, there should be only one for a worm to work
						new_node.is_anchored = true
						new_node.is_top_level = false
					"O": # Free rotation
						new_node.angle_sway = 1
					"F":
						new_node.angle_sway = 0.05
				curr_node.add_child(new_node)
				new_node.owner = get_tree().edited_scene_root
				curr_node = new_node
				curr_texture_scale *= 1 - thickness_falloff
				curr_length *= 1 - length_falloff
			"[":
				build_sequence(seq, curr_node, curr_texture_scale)
			"]":
				return
			"r":
				curr_node.target_angle += 0.1
			"l":
				curr_node.target_angle -= 0.1
			"T":
				curr_texture_scale *= 1 - thickness_falloff * 8
			"t":
				curr_texture_scale /= 1 - thickness_falloff * 8
			_:
				pass

# Which symbol gets replaces with what, first number is weight (doesn't need to add up to 1)
var rules = {
	"|": [
		[5, "F|"],
		[1, "T[Fr>][Fl<]tF|"],
		[0.2, "T[Fr>]tF|"],
		[0.2, "T[Fl<]tF|"]
	],
	">": [
		[1, "Frr+"],
	],
	"<": [
		[1, "Fll-"],
	],
	"+": [
		[0.3, "Frx+"],
		[0.3, "+"],
		[1, "FFFrx+"],
	],
	"-": [
		[1, "Flx-"],
		[0.2, "-"],
		[1, "FFFlx-"],
	],
	"}": [
		[1, "llll+"],
	],
	"{": [
		[1, "rrrr-"],
	],
	"x": [
		[10, ""],
		[1, "[Frr]"],
		[1, "[Fll]"],
	],
	"F": [
		[5, "F"],
		[1, "Fr"],
		[1, "Fl"]
	],
}
func get_random_rule(ruletype: String):
	# Choosing correct rule set based on type
	var total_weight: float = 0
	var ruleset = rules[ruletype]
	for rule in ruleset:
		total_weight += rule[0]
	
	# Choosing rule from the ruleset
	var rand: float = randf()
	var weight_sum: float = 0
	for rule in ruleset:
		weight_sum += rule[0] / total_weight
		if rand <= weight_sum:
			return rule[1]
	return ruleset[-1][1] # Just in case

func perform_replacement(sequence: String, type: String, ruletype: String):
	var new_sequence = ""
	for c in sequence:
		if c == type:
			new_sequence += get_random_rule(ruletype)
		else:
			new_sequence += c
	return new_sequence

func generate_sequence():
	var sequence: String = "AO|"
	for i in range(50):
		sequence = perform_replacement(sequence, "|", "|")
	sequence = perform_replacement(sequence, ">", ">")
	sequence = perform_replacement(sequence, "<", "<")
	for i in range(5):
		sequence = perform_replacement(sequence, "+", "+")
		sequence = perform_replacement(sequence, "-", "-")
	sequence = perform_replacement(sequence, "+", "}")
	sequence = perform_replacement(sequence, "-", "{")
	for i in range(3):
		sequence = perform_replacement(sequence, "+", "+")
		sequence = perform_replacement(sequence, "-", "-")
	for i in range(5):
		sequence = perform_replacement(sequence, "x", "x")
	sequence = perform_replacement(sequence, "F", "F")
	return sequence

func generate_worm():
	delete_bones()
	curr_seq = 0
	_texture_scale = texture_scale
	var seq = generate_sequence()
	build_sequence(seq)

func _ready() -> void:
	generate_worm()
