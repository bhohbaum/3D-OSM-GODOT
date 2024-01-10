const CREATE_CSGPOLYGON3D = preload("res://src/common/create_csgpolygon3d.gd")


# helper for Path3D
static func create_path3d(path, offset_x, offset_y) -> Path3D:
	var path3d = Path3D.new()
	var curve = Curve3D.new()

	for point in path:
		curve.add_point((point / 100) + Vector3(offset_x, 0, offset_y))

	path3d.curve = curve
	return path3d


# entry point
static func generate_paths(path_points, caller_node, color, offset_x, offset_y, width = null):
	var road_width = 2 if not width else width
	var path_polygon = [
		Vector2(-(road_width / 2), 1),
		Vector2(-(road_width / 2), 1.5),
		Vector2(road_width / 2, 1.5),
		Vector2(road_width / 2, 1)
	]

	for path in path_points:
		var path3d = create_path3d(path, offset_x, offset_y)
		await caller_node.call_deferred("add_child", path3d)
		#await caller_node.call_deferred("add_child", Thread.new().start(await caller_node.call_deferred.bind(path3d)))

		var polygon: CSGPolygon3D = CREATE_CSGPOLYGON3D.create_polygon(color, path_polygon)
		polygon.mode = CSGPolygon3D.MODE_PATH
		polygon.path_interval = 0.5
		polygon.use_collision = true
		if polygon != null && polygon.get_indexed("path") != null && path3d != null:
			var pc: Path3D = path3d
			await polygon.call_deferred("_set", "path", Thread.new().start(await pc.call_deferred.bind("get_path")))
			await caller_node.call_deferred("add_child", polygon)
			#await caller_node.call_deferred("add_child", Thread.new().start(await caller_node.call_deferred.bind(polygon)))

