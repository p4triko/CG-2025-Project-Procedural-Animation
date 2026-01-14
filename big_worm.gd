@tool
class_name Worm extends SimRoot

@export_tool_button("Generate worm") var a = func(): generate_worm()

var joint_texture = preload("res://assets/images/worm_joint_texture.tres")
var bone_texture = preload("res://assets/images/worm_bone_texture.tres")
var texture_scale = 50

func delete_bones():
	for i in get_children():
		remove_child(i)
		i.queue_free()

var curr_seq: int = 0
func build_sequence(seq, curr_node = self):
	var seq_len = seq.length()
	while seq_len > curr_seq:
		curr_seq += 1
		match(seq[curr_seq-1]):
			"A": # Main anchor, there should be only one for a worm to work
				var new_node = SimNode.new()
				new_node.is_anchored = true
				new_node.is_top_level = false
				#new_node.joint_texture = joint_texture
				#new_node.joint_texture_scale = texture_scale
				curr_node.add_child(new_node)
				new_node.owner = get_tree().edited_scene_root 
				
				curr_node = new_node
			"O": # Free rotation
				var new_node = SimNode.new()
				new_node.distance_range = Vector2(20, 20)
				new_node.target_angle = 0
				new_node.angle_sway = 1
				#new_node.joint_texture = joint_texture
				#new_node.joint_texture_scale = texture_scale
				curr_node.add_child(new_node)
				new_node.owner = get_tree().edited_scene_root 
				
				curr_node = new_node
			"F":
				var new_node = SimNode.new()
				new_node.distance_range = Vector2(20, 20)
				new_node.target_angle = 0
				new_node.angle_sway = 0.05
				#new_node.joint_texture = joint_texture
				#new_node.joint_texture_scale = texture_scale
				new_node.bone_texture = bone_texture
				new_node.bone_texture_y_scale = 0.1
				curr_node.add_child(new_node)
				new_node.owner = get_tree().edited_scene_root 
				
				curr_node = new_node
			"[":
				build_sequence(seq, curr_node)
			"]":
				return
			"r":
				curr_node.target_angle += 0.2
			"l":
				curr_node.target_angle -= 0.2
			_:
				pass

# Which symbol gets replaces with what, first number is weight (doesn't need to add up to 1)
var rules = {
	"-": [
		[1, "F-"],
		[0.1, "-"],
		[0.5, "[Fr/][Fl/]F-"]
	],
	"/": [
		[1, "F/"],
		[0.3, "/"]
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

func perform_replacement(sequence: String, ruletype: String):
	var new_sequence = ""
	for c in sequence:
		if c == ruletype:
			new_sequence += get_random_rule(ruletype)
		else:
			new_sequence += c
	return new_sequence

func generate_sequence():
	var sequence: String = "AO-"
	for i in range(50):
		sequence = perform_replacement(sequence, "-")
	for i in range(10):
		sequence = perform_replacement(sequence, "/")
	return sequence

func generate_worm():
	delete_bones()
	
	curr_seq = 0
	var seq = generate_sequence()
	print(seq)
	build_sequence(seq)

func _ready() -> void:
	generate_worm()
