class_name DStarAlgorithm extends AStar3D

var nodes_calculated:int = 0

func find_path(from: Vector3, to: Vector3) -> Array:
	var start_id = get_closest_point2(from)
	var end_id  = get_closest_point2(to)
	var path_vectors = get_point_path2(start_id, end_id)
	print("path D:", path_vectors)
	return path_vectors

func get_closest_point2(to_position: Vector3, bool = false) -> int:
	var closest_point_id = -1
	var closest_distance = INF

	for point_id in get_point_ids():
		var point_position = get_point_position(point_id)
		var distance = to_position.distance_squared_to(point_position)
		
		if distance < closest_distance:
			closest_distance = distance
			closest_point_id = point_id
	
	return closest_point_id

func get_point_path2(from_id: int, to_id: int, bool = false) -> PackedVector3Array:
	if not has_point(from_id) or not has_point(to_id):
		return []
	
	var path = [get_point_position(from_id)]
	var open_set = [from_id]
	var came_from = {}
	var g_score = {}
	g_score[from_id] = 0
	
	while open_set.size() > 0:
		var current = open_set.pop_front()
		nodes_calculated = nodes_calculated + 1;
		if current == to_id:
			while current in came_from:
				path.insert(1, get_point_position(current))
				current = came_from[current]
			path.append(get_point_position(to_id))

			return path
		
		for neighbor_id in get_point_connections(current):
			if is_point_disabled(neighbor_id):
				continue
			var current_pos = get_point_position(current)
			var neighbor_pos = get_point_position(neighbor_id)
			
			if current_pos.x != neighbor_pos.x and current_pos.z != neighbor_pos.z:
				continue
			
			var tentative_g_score = g_score[current] + get_point_position(current).distance_to(get_point_position(neighbor_id))
			
			if neighbor_id not in g_score or tentative_g_score < g_score[neighbor_id]:
				came_from[neighbor_id] = current
				g_score[neighbor_id] = tentative_g_score
				open_set.append(neighbor_id)
	
	return []
