static func build_floor(caller_node, offset_x, offset_y):
	var floor = CSGPolygon3D.new()
	var polygon_vectors = [
		Vector2(0, 0), Vector2(0, 655.25), Vector2(655.25, 655.25), Vector2(655.25, 0)
	]
	floor.polygon = polygon_vectors
	floor.depth = 0.1
	floor.use_collision = true
	await floor.call_deferred("rotate", Vector3(1, 0, 0), deg_to_rad(90))
	await floor.call_deferred("translate", Vector3(offset_x, offset_y, 1))
	await caller_node.call_deferred("add_child", floor)
