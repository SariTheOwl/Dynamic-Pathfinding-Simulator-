class_name DStarLiteAlgorithm extends AStar3D

var g = {}
var rhs = {}
var km: float = 0  # Heuristic modifier
var goal_id: int = -1  # Goal point ID
var start_id: int = -1  # Start point ID
var last_id:int = -1
var start_position:Vector3
var goal_position:Vector3
var U: Priority_util.PriorityQueue
var nodes_calculated:int = 0
var nodes_to_add:int = 0

class KeyValue:
	var key: Vector3
	var value: float

	func _init(k, v):
		self.key = k
		self.value = v

	func compare(other: KeyValue) -> bool:
		if self.key < other.key:
			return true
		elif self.key == other.key:
			return self.value < other.value
		return false

# Prepare and reset the D* Lite algorithm for a new search
func prepare():
	for point_id in get_point_ids():
		g[get_point_position(point_id)] = INF
		rhs[get_point_position(point_id)] = INF
	last_id = start_id
	rhs[get_point_position(goal_id)] = 0
	km = 0
	start_position = get_point_position(start_id)
	goal_position = get_point_position(goal_id)
	U = Priority_util.PriorityQueue.new()
	U.insert(goal_position, Priority_util.Priority.new(_heuristic(start_position,goal_position), 0))

func contain(u: Vector3):
	return u in self.U.vertices_in_heap

func _sort_open_set_by_key(a: KeyValue, b: KeyValue) -> bool:
	return a.key < b.key or (a.key == b.key and a.value < b.value)

# Calculate heuristic (Euclidean distance)
func _heuristic(a: Vector3, b: Vector3) -> float:
	return a.distance_to(b)

# Calculate priority key for a node
func _calculate_key(s: Vector3) -> Priority_util.Priority:
	var g_rhs_min = min(g[s], rhs[s])
	return Priority_util.Priority.new(g_rhs_min + km + _heuristic(start_position, s), g_rhs_min)

func cost(from_id:int, to_id:int):
	if not is_point_disabled(from_id) or not is_point_disabled(to_id):
		return _heuristic(get_point_position(from_id), get_point_position(to_id))
	else:
		return INF

func update_vertex(u: Vector3):
	if g[u] != rhs[u] and self.contain(u):
		U.update(u,_calculate_key(u))
	elif g[u] != rhs[u] and not self.contain(u):
		U.insert(u,_calculate_key(u))
	elif g[u] == rhs[u] :
		U.remove_at(u)

# Main method to compute the shortest path
func compute_shortest_path():
	return []
	# while U.top_key() < _calculate_key(start_position) or rhs[start_position] > g[start_position]:
	# 	var u = U.top()
	# 	var k_old = U.top_key()
	# 	var k_new = _calculate_key(u)

	# 	if k_old < k_new:
	# 		U.update(u,k_new)
	# 	elif g[u] > rhs[u]:
	# 		g[u] = rhs[u]
	# 		U.remove(u)
	# 		var pred = sensed

# Get the closest point ID on the grid to a given position
func get_closest_point2(position: Vector3) -> int:
	var closest_point_id = -1
	var closest_distance = INF

	for point_id in get_point_ids():
		var point_position = get_point_position(point_id)
		var distance = position.distance_squared_to(point_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_point_id = point_id

	return closest_point_id


func find_path(from: Vector3, to: Vector3) -> Array:
	var start_id = get_closest_point2(from)
	var end_id  = get_closest_point2(to)
	var path_vectors = get_point_path2(start_id, end_id)
	print("path D:", path_vectors)
	return path_vectors

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
		nodes_to_add = nodes_to_add +1
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
# func find_path(from: Vector3, to: Vector3) -> Array:
# 	# if start_id == -1 or goal_id == -1:
# 	# 	return []
	
# 	# #compute_shortest_path()
# 	# var path
# 	# var path_vectors = path
# 	# print("path D*: ", path_vectors)
# 	# return path_vectors
# 	return []

# # Respond to an obstacle being added
# func handle_obstacle_added(obstacle_position: Vector3):
# 	km += _heuristic(start_id, goal_id)  # Increment heuristic modifier when obstacles change

# # Respond to an obstacle being removed
# func handle_obstacle_removed(obstacle_position: Vector3):
# 	km += _heuristic(start_id, goal_id)  # Increment heuristic modifier
