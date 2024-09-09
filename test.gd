@tool
class_name AStarManager extends Node3D

@export var should_draw_cubes: bool = true

var grid_step :float = 2.0
var grid_y :float = 1.5
var points :Dictionary = {}
var astar =  AStarAlgorithm.new()
var d_star = DStarAlgorithm.new()

var cube_mesh = BoxMesh.new()
var red_material = StandardMaterial3D.new()
var green_material = StandardMaterial3D.new()
var blue_material = StandardMaterial3D.new()
var obstacle_map: Array = []

var pathfindLine: Node3D
var pathfindNodes: Node3D

func _ready() -> void:
	var pathables = get_tree().get_nodes_in_group("pathable")
	red_material.albedo_color = Color.RED
	green_material.albedo_color = Color.GREEN
	blue_material.albedo_color = Color.BLUE
	cube_mesh.size = Vector3(0.25, 0.25, 0.25)
	add_line_and_nodes()
	_add_points(pathables)
	_connect_points()

func _add_points(pathables: Array):

	for pathable in pathables:
		var ground:CSGBox3D = pathable
		
		print("aabb: ",ground.get_aabb())
		var start_point = Vector3(-ground.size.x/2,0,-ground.size.z/2)
		
		print("start_point: ",start_point)
		var x_steps = ground.size.x/ grid_step
		var z_steps = ground.size.z/ grid_step
		
		for x in x_steps:
			for z in z_steps:
				var offset_point = Vector3(grid_step/2, 1.5, grid_step/2)
				var next_point = start_point + Vector3(x * grid_step, 0 , z * grid_step) + offset_point
				_add_point(next_point)
		


func clear_map():
	for node in get_children():
		print(node.name)
		node.queue_free()


func _add_point(point: Vector3):
	point.y = grid_y
	
	var id = astar.get_available_point_id()
	astar.add_point(id, point)
	d_star.add_point(id, point)
	points[world_to_astar(point)] = id
	_create_nav_cube(point)

func _create_nav_cube(pos: Vector3):
	if should_draw_cubes:
		var cube = MeshInstance3D.new()
		cube.mesh = cube_mesh
		cube.material_override = red_material
		pathfindNodes.add_child(cube)
		cube.owner = self
		pos.y = grid_y
		cube.global_transform.origin = pos

func _create_nav_line(pos1: Vector3, pos2: Vector3, lineToEdit: Node3D):
	if should_draw_cubes:
		var cube = MeshInstance3D.new()
		var immediate_mesh = ImmediateMesh.new()
		cube.mesh = immediate_mesh
		cube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, blue_material)
		immediate_mesh.surface_add_vertex(pos1)
		immediate_mesh.surface_add_vertex(pos2)
		immediate_mesh.surface_end()

		#cube.material_override = red_material
		lineToEdit.add_child(cube)
		cube.owner = self

func draw_path(pathVectors: PackedVector3Array, algorithm: String):
	var lineToEdit = pathfindLine.get_node(algorithm + "Line")
	for node in lineToEdit.get_children():
		print(node.name)
		node.queue_free()
	for x in range(pathVectors.size()-1, 0, -1):
		print("vector ", x ,":",pathVectors[x],pathVectors[x-1])
		_create_nav_line(pathVectors[x],pathVectors[x-1],lineToEdit)

func add_line_and_nodes():
	pathfindLine = Node3D.new()
	pathfindLine.name = "Line"

	pathfindNodes = Node3D.new()
	pathfindNodes.name = "Nodes"

	var aStarLine = Node3D.new() 
	var dStarLine = Node3D.new() 
	var dStarLiteLine = Node3D.new() 
	var lpaStarLine = Node3D.new() 

	aStarLine.name = "AStarLine"
	dStarLine.name = "DStarLine"
	dStarLiteLine.name = "DStarLiteLine"
	lpaStarLine.name = "LPAStarLine"

	add_child(pathfindLine)

	pathfindLine.add_child(aStarLine)
	pathfindLine.add_child(dStarLine)
	pathfindLine.add_child(dStarLiteLine)
	pathfindLine.add_child(lpaStarLine)

	add_child(pathfindNodes)

func _connect_points():
	for point in points:
		var pos_str = point.split(",")
		var world_pos:Vector3 = Vector3(float(pos_str[0]), float(pos_str[1]), float(pos_str[2]))
		var adjacent_points = _get_adjacent_points(world_pos)
		
		var current_id = points[point]
		for neighbor_id in adjacent_points:
			if not astar.are_points_connected(current_id, neighbor_id):
				astar.connect_points(current_id, neighbor_id)
				d_star.connect_points(current_id, neighbor_id)
				if should_draw_cubes:
					pathfindNodes.get_child(current_id).material_override = green_material
					pathfindNodes.get_child(neighbor_id).material_override = green_material


func _get_adjacent_points(world_point: Vector3) -> Array:
	var adjacent_points = []
	var search_coords = [-grid_step, 0, grid_step]
	for x in search_coords:
		for z in search_coords:
			var search_offset = Vector3(x, 0, z)
			if search_offset == Vector3.ZERO:
				continue

			var potential_neighbor = world_to_astar(world_point + search_offset)
			if points.has(potential_neighbor):
				adjacent_points.append(points[potential_neighbor])
	return adjacent_points

func obstacle_added(obstacle: Node3D):
	var normalized_origin = obstacle.global_transform.origin
	normalized_origin.y = grid_y
	var adjacent_points: Array = []
	var point_key = world_to_astar(normalized_origin)
	var astar_id = points[point_key]
	adjacent_points.append(astar_id)
	for point in adjacent_points:
		if not astar.is_point_disabled(point):
			astar.set_point_disabled(point, true)
			d_star.set_point_disabled(point, true)
			#var d_star_npc = self.get_node("/root/LevelGenerator/D_Star_Npc")
			#print("d_star_npc",d_star_npc)
			#d_star_npc.update_path() 
			var d_star_npc = get_parent().get_node("D_Star_Npc")
			d_star_npc.update_path() 
			if should_draw_cubes:
				pathfindNodes.get_child(point).material_override = red_material

func obstacle_init(obstacle: Node3D):
	var normalized_origin = obstacle.global_transform.origin
	normalized_origin.y = grid_y
	var adjacent_points: Array = []
	var point_key = world_to_astar(normalized_origin)
	var astar_id = points[point_key]
	adjacent_points.append(astar_id)
	for point in adjacent_points:
		if not astar.is_point_disabled(point):
			astar.set_point_disabled(point, true)
			d_star.set_point_disabled(point, true)
			if should_draw_cubes:
				pathfindNodes.get_child(point).material_override = red_material


func obstacle_to_add(obstacle: Node3D):
	obstacle_map.append(obstacle)

func add_obstacles():
	for obstacle in obstacle_map:
		obstacle_init(obstacle)
	obstacle_map = []

func handle_obstacle_removed(obstacle: Node3D):
	var normalized_origin = obstacle.global_transform.origin
	normalized_origin.y = grid_y
	var adjacent_points: Array = []
	var point_key = world_to_astar(normalized_origin)
	var astar_id = points[point_key]
	adjacent_points.append(astar_id)
	for point in adjacent_points:
		if astar.is_point_disabled(point):
			astar.set_point_disabled(point, false)
			d_star.set_point_disabled(point, false)
			#var d_star_npc = self.get_node("/root/LevelGenerator/D_Star_Npc")
			var d_star_npc = get_parent().get_node("D_Star_Npc")
			d_star_npc.update_path() 
			if should_draw_cubes:
				pathfindNodes.get_child(point).material_override = green_material

func find_path(from: Vector3, to: Vector3, algorithm: String) -> Array:
	var path_vectors
	if algorithm == "AStar":
		path_vectors = astar.find_path(from, to)
	if algorithm == "DStar":
		var d_star_npc = get_parent().get_node("D_Star_Npc")
		path_vectors = d_star.find_path(from, to)
	draw_path(path_vectors, algorithm)
	print("path:", path_vectors)
	return path_vectors

func world_to_astar(world: Vector3) -> String:
	var x = snapped(world.x, grid_step)
	var y = snapped(world.y, grid_step)
	var z = snapped(world.z, grid_step)
	
	return "%d,%d,%d" % [x,y,z]