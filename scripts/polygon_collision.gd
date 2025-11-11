extends Polygon2D

func _ready():
	# Automatically create collision shape and add it as sibling to current node
	var collision_polygon := CollisionPolygon2D.new()
	collision_polygon.polygon = polygon
	get_parent().add_child.call_deferred(collision_polygon)
