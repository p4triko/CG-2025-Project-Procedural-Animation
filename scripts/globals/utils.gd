@tool
class_name Utils extends Object

# Says if some action (for example rendering) should be visible right now
static func check_debug_enum(value: int):
	match value:
		0: return true
		1: return Engine.is_editor_hint()
		2: return false
