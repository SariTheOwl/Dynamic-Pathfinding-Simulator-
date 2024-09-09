@tool
class_name PathfindingManager extends Node3D

@export var should_draw_cubes: bool = true
@onready 
var grid_step :float = 2.0
var grid_y :float = 1.5
var points :Dictionary = {}
var a_star = AStarAlgorithm.new()
var d_star = DStarAlgorithm.new()
var d_star_lite = DStarLiteAlgorithm.new()
var lpa_star = LPAStarAlgorithm.new()

var hud = PathfindingHud.new()

var cube_mesh = BoxMesh.new()
var red_material = StandardMaterial3D.new()
var green_material = StandardMaterial3D.new()
var blue_material = StandardMaterial3D.new()
var obstacle_map: Array = []
var map_width: int
var map_depth: int

var obstacle_coords: Array = []

var pathfindLine: Node3D
var pathfindNodes: Node3D

var start: NavigationMap.Coord
var goal: NavigationMap.Coord

var goal_position: Vector3

var AStarNpc: PackedScene
var DStarNpc: PackedScene
var DStarLiteNpc: PackedScene
var LPAStarNpc: PackedScene
var GoalScene: PackedScene
var HUDScene: PackedScene

# Manager Initialization
func _ready() -> void:
	_initialize_mesh_and_materials()
	_initialize_pathfinding_structures()


func prepare_npc(width:int, depth: int, obstacle_coord: Array, goal_init: PackedScene, aStarNpc_init: PackedScene
, dStarNpc_init: PackedScene, dStarLiteNpc_init: PackedScene, lpaStarScene_init: PackedScene, hud_init: PackedScene):
	map_width = width
	map_depth = depth
	obstacle_coords = obstacle_coord
	AStarNpc = aStarNpc_init
	DStarNpc = dStarNpc_init
	DStarLiteNpc = dStarLiteNpc_init
	LPAStarNpc = lpaStarScene_init
	GoalScene = goal_init
	HUDScene = hud_init
	add_hud()
	add_goal()
	add_obstacles()
	add_npcs()


func add_hud():
	hud = HUDScene.instantiate()
	add_child(hud)
	hud.owner = self

# Initialize pathfinding nodes and lines for visual representation
func _initialize_pathfinding_structures():
	var pathables = get_tree().get_nodes_in_group("pathable")
	add_line_and_nodes()
	_add_points(pathables)
	_connect_points()

# Setup mesh and materials for visualization
func _initialize_mesh_and_materials():
	red_material.albedo_color = Color.RED
	green_material.albedo_color = Color.GREEN
	blue_material.albedo_color = Color.BLUE
	cube_mesh.size = Vector3(0.25, 0.25, 0.25)

# Add pathfinding points based on level layout
func _add_points(pathables: Array):
	for pathable in pathables:
		var ground: CSGBox3D = pathable
		var start_point = Vector3(-ground.size.x/2, 0, -ground.size.z/2)
		var x_steps = ground.size.x / grid_step
		var z_steps = ground.size.z / grid_step
		
		for x in x_steps:
			for z in z_steps:
				var offset_point = Vector3(grid_step / 2, grid_y, grid_step / 2)
				var next_point = start_point + Vector3(x * grid_step, 0, z * grid_step) + offset_point
				_add_point(next_point)

# Add a single point to the pathfinding algorithms
func _add_point(point: Vector3):
	point.y = grid_y
	var id = a_star.get_available_point_id()
	a_star.add_point(id, point)
	d_star.add_point(id, point)
	d_star_lite.add_point(id, point)
	lpa_star.add_point(id, point)
	points[world_to_astar(point)] = id
	_create_nav_cube(point)

# Create a visual representation of pathfinding nodes (cubes)
func _create_nav_cube(pos: Vector3):
	if should_draw_cubes:
		var cube = MeshInstance3D.new()
		cube.mesh = cube_mesh
		cube.material_override = red_material
		pathfindNodes.add_child(cube)
		cube.owner = self
		pos.y = grid_y
		cube.global_transform.origin = pos

# Connect pathfinding points in the graph
func _connect_points():
	for point in points:
		var pos_str = point.split(",")
		var world_pos: Vector3 = Vector3(float(pos_str[0]), float(pos_str[1]), float(pos_str[2]))
		var adjacent_points = _get_adjacent_points(world_pos)
		
		var current_id = points[point]
		for neighbor_id in adjacent_points:
			if not a_star.are_points_connected(current_id, neighbor_id):
				a_star.connect_points(current_id, neighbor_id)
				d_star.connect_points(current_id, neighbor_id)
				d_star_lite.connect_points(current_id, neighbor_id)
				lpa_star.connect_points(current_id, neighbor_id)
				if should_draw_cubes:
					pathfindNodes.get_child(current_id).material_override = green_material
					pathfindNodes.get_child(neighbor_id).material_override = green_material

# Get adjacent points for connections
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

func obstacle_to_add(obstacle: Node3D):
	obstacle_map.append(obstacle)

func add_obstacles():
	for obstacle in obstacle_map:
		obstacle_init(obstacle)
	obstacle_map = []

func obstacle_init(obstacle: Node3D):
	var normalized_origin = obstacle.global_transform.origin
	normalized_origin.y = grid_y
	var adjacent_points: Array = []
	var point_key = world_to_astar(normalized_origin)
	var astar_id = points[point_key]
	adjacent_points.append(astar_id)
	for point in adjacent_points:
		if not a_star.is_point_disabled(point):
			a_star.set_point_disabled(point, true)
			d_star.set_point_disabled(point, true)
			d_star_lite.set_point_disabled(point, true)
			lpa_star.set_point_disabled(point, true)
			if should_draw_cubes:
				pathfindNodes.get_child(point).material_override = red_material

# Handle obstacle addition
func obstacle_added(obstacle: Node3D):
	var normalized_origin = obstacle.global_transform.origin
	normalized_origin.y = grid_y
	var point_key = world_to_astar(normalized_origin)
	var astar_id = points[point_key]

	if not a_star.is_point_disabled(astar_id):
		a_star.set_point_disabled(astar_id, true)
		d_star.set_point_disabled(astar_id, true)
		d_star_lite.set_point_disabled(astar_id, true)
		lpa_star.set_point_disabled(astar_id, true)
		hud.update_walls_changed_count()
		_update_npcs_path()
		if should_draw_cubes:
			pathfindNodes.get_child(astar_id).material_override = red_material

# Notify NPCs to update path after obstacle changes
func _update_npcs_path():
	var npcs = get_tree().get_nodes_in_group("NPCs")
	for npc in npcs:
		if npc.get_algorithm() != "AStar":
			npc.update_path()

# Handle obstacle removal
func handle_obstacle_removed(obstacle: Node3D):
	var normalized_origin = obstacle.global_transform.origin
	normalized_origin.y = grid_y
	var point_key = world_to_astar(normalized_origin)
	var astar_id = points[point_key]

	if a_star.is_point_disabled(astar_id):
		a_star.set_point_disabled(astar_id, false)
		d_star.set_point_disabled(astar_id, false)
		d_star_lite.set_point_disabled(astar_id, false)
		lpa_star.set_point_disabled(astar_id, false)
		hud.update_walls_changed_count()
		_update_npcs_path()
		if should_draw_cubes:
			pathfindNodes.get_child(astar_id).material_override = green_material

# Draw path for visual representation
func draw_path(path_vectors: PackedVector3Array, algorithm: String):
	var lineToEdit = pathfindLine.get_node(algorithm + "Line")
	for node in lineToEdit.get_children():
		node.queue_free()
	for x in range(path_vectors.size()-1, 0, -1):
		_create_nav_line(path_vectors[x], path_vectors[x-1], lineToEdit)

# Create a visual line for path representation
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

		lineToEdit.add_child(cube)
		cube.owner = self

# Add lines and nodes for pathfinding debug visualization
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

	pathfindLine.add_child(aStarLine)
	pathfindLine.add_child(dStarLine)
	pathfindLine.add_child(dStarLiteLine)
	pathfindLine.add_child(lpaStarLine)

	add_child(pathfindLine)
	add_child(pathfindNodes)

# Find path using specified algorithm (A* or D*)
func find_path(from: Vector3, to: Vector3, algorithm: String) -> Array:
	var path_vectors = []
	if algorithm == "AStar":
		path_vectors = a_star.find_path(from, to)
		hud.update_nodes_calculated(a_star.nodes_calculated,"AStar")
	elif algorithm == "DStar":
		path_vectors = d_star.find_path(from, to)
		hud.update_nodes_calculated(d_star.nodes_calculated,"DStar")
	elif algorithm == "DStarLite":
		path_vectors = d_star_lite.find_path(from, to)
		update_d_lite_nodes_calculated()
		hud.update_nodes_calculated(d_star_lite.nodes_calculated,"DStarLite")
	elif algorithm == "LPAStar":
		path_vectors = lpa_star.find_path(from, to)
		update_lpa_nodes_calculated()
		hud.update_nodes_calculated(lpa_star.nodes_calculated,"LPAStar")
	draw_path(path_vectors, algorithm)
	return path_vectors

# Utility: Convert world coordinates to AStar-compatible string key
func world_to_astar(world: Vector3) -> String:
	var x = snapped(world.x, grid_step)
	var y = snapped(world.y, grid_step)
	var z = snapped(world.z, grid_step)
	return "%d,%d,%d" % [x, y, z]

func add_npcs():
	find_best_start()
	
	var offset = Vector3(-map_width+1, 0, -map_depth+1)
	var npc_start_position = Vector3(start.x*2, 1.5, start.z*2) + offset

	# d_star_lite.goal_id =  d_star.get_closest_point2(goal_position)
	# d_star_lite.start_id =  d_star.get_closest_point2(npc_start_position)
	# d_star_lite.prepare()
	#d_star.came_from[goal]

	var a_star_npc: CharacterBody3D = AStarNpc.instantiate()
	var d_star_npc: CharacterBody3D = DStarNpc.instantiate()
	var d_star_lite_npc: CharacterBody3D = DStarLiteNpc.instantiate()
	var lpa_star_npc: CharacterBody3D = LPAStarNpc.instantiate()
	
	#var npc_size = Vector3(0, a_star.size.y/2-1, 0)
	a_star_npc.transform.origin = npc_start_position# + npc_size
	d_star_npc.transform.origin = npc_start_position# + npc_size
	d_star_lite_npc.transform.origin = npc_start_position# + npc_size
	lpa_star_npc.transform.origin = npc_start_position# + npc_size

	add_child(a_star_npc)
	add_child(d_star_npc)
	add_child(d_star_lite_npc)
	add_child(lpa_star_npc)
	
	a_star_npc.owner = self
	d_star_npc.owner = self
	d_star_lite_npc.owner = self
	lpa_star_npc.owner = self

func update_d_lite_nodes_calculated():
	if(d_star_lite.nodes_calculated == 0):
		d_star_lite.nodes_calculated = d_star_lite.nodes_calculated + d_star_lite.nodes_to_add
		d_star_lite.nodes_to_add = 0
	else:
		d_star_lite.nodes_calculated = d_star_lite.nodes_calculated + d_star_lite.nodes_to_add/8
		d_star_lite.nodes_to_add = 0

func update_lpa_nodes_calculated():
	if(lpa_star.nodes_calculated == 0):
		lpa_star.nodes_calculated = lpa_star.nodes_calculated + lpa_star.nodes_to_add
		lpa_star.nodes_to_add = 0
	else:
		lpa_star.nodes_calculated = lpa_star.nodes_calculated + lpa_star.nodes_to_add/6
		lpa_star.nodes_to_add = 0

func add_goal():
	find_best_goal()
	
	var offset = Vector3(-map_width+1, 0, -map_depth+1)
	goal_position = Vector3(goal.x*2, 1.5, goal.z*2) + offset
	
	var goal_npc: CharacterBody3D = GoalScene.instantiate()
	goal_npc.transform.origin = goal_position#+ npc_size
	print("goal_position: ",goal_position)
	add_child(goal_npc)
	goal_npc.owner = self

func find_best_start():
	for x in range(map_width):
		for z in range(map_depth):
			if(obstacle_coords[x][z] == false):
				#print(level.obstacle_map[x][z],x,z)
				start = NavigationMap.Coord.new(x,z)
				
				return

func find_best_goal():
	for x in range(map_width-1, 0, -1):
		for z in range(map_depth-1, 0, -1):
			if(obstacle_coords[x][z] == false):
				#print(level.obstacle_map[x][z],x,z)
				goal = NavigationMap.Coord.new(x,z)
				return

func stop_clock(algorithm: String):
	hud.stop_clock(algorithm)
