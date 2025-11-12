extends Polygon2D

func _ready():
	# Automatically create collision shape and add it as sibling to current node
	var collision_polygon := CollisionPolygon2D.new()
	collision_polygon.polygon = polygon
	var parent := get_parent()
	parent.ready.connect(parent.add_child.bind(collision_polygon), CONNECT_ONE_SHOT)
