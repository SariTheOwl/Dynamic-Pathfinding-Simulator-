@tool

extends Node3D

@export var GroundScene: PackedScene
@export var ObstacleScene: PackedScene 

@export_range(1, 50, 1) var map_width:int = 11: set = set_width
@export_range(1, 50, 1) var map_depth:int = 11: set = set_depth
# Called when the node enters the scene tree for the first time.

@export_range(0, 1, 0.05) var obstacle_density :float = 0.2: set = set_obstacle_density

@export_range(1.0, 6.0, 2) var obstacle_max_height:float = 2.0: set = set_max_obs_height
@export_range(1.0, 6.0, 2) var obstacle_min_height:float = 2.0: set = set_min_obs_height

@export var rng_seed:int = 12345: set = set_seed

@export var generate_level: bool = false: set = set_generate_level

@export var save_level: bool = false: set = set_save_level
@export var level_name: String = "New Level"

var map_coords_array: Array = []
var obstacle_map: Array = []
var map_center: Coord
var level : NavigationRegion3D
var navmesh_instance: NavigationMesh

var start: Coord
var goal: Coord

var directions: Array  = [Vector3(1, 0, 0), Vector3(-1, 0 ,0),
				  Vector3(0, 0, 1), Vector3(0, 0, -1)]
var maze = []

class Coord:
	var x: int
	var z: int
	
	func _init(x,z):
		self.x = x
		self.z = z
	
	func _to_string():
		return "("+ str(x) + "," + str(z) +")"
	
	func equals(coord):
		return coord.x == self.x and coord.z == self.z

func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_generate_level(bool):
	generate_map()

func generate_map():
	clear_map()
	add_level()
	add_ground()
	make_maze()
	add_obstacles()
	level.bake_navigation_mesh(false)


func clear_map():
	for node in get_children():
		node.free()

func add_level():
	level = NavigationRegion3D.new()
	level.name = "NavigationRegion3D"
	add_child(level)
	# add nav mesh
	level.navigation_mesh = NavigationMesh.new()
	level.navigation_mesh.border_size = 0.5
	level.navigation_mesh.filter_ledge_spans = true

	level.owner = self

func set_save_level(bool):
	var packed_secene = PackedScene.new()
	for child in level.get_children():
		child.owner = level
	packed_secene.pack(level)
	var scene_resource_path = "res://Level/GeneratedLevels/%s.tscn" % level_name
	ResourceSaver.save(packed_secene, scene_resource_path, 0)

func add_ground():
	var ground:CSGBox3D = GroundScene.instantiate()
	ground.size = Vector3(map_width*2, 1 ,map_depth*2) 
	level.add_child(ground)
	ground.owner = self

func add_obstacles2():
	fill_map_coords_array()
	fill_obstacle_map()
	#print(map_coords_array)
	
	seed(rng_seed)
	
	map_coords_array.shuffle()
	#print(map_coords_array)
	
	var num_obstacles = map_coords_array.size() * obstacle_density
	var current_obstacle_count = 0
	
	if num_obstacles > 0:
		for coord in map_coords_array.slice(0, num_obstacles - 1):
			
			if not start.equals(coord):
				#create_obstacle_at(coord.x, coord.z)
				current_obstacle_count += 1
				obstacle_map[coord.x][coord.z] = true
				if map_is_fully_accessible(current_obstacle_count):
					create_obstacle_at(coord.x, coord.z)
				else:
					current_obstacle_count -= 1
					obstacle_map[coord.x][coord.z] = false

func add_obstacles():
	for i in range(map_depth):
		for j in range(map_width):
			if maze[i][j] == 1:
				create_obstacle_at(i,j)

#Flood fill algorithm - change to krusal or prim
func map_is_fully_accessible(current_obstacle_count):
	var checked_tiles = []
	for x in range(map_width):
		checked_tiles.append([])
		for z in range(map_depth):
			checked_tiles[x].append(false)
	var coords_to_check = [start]
	checked_tiles[start.x][start.z] = true
	var accessible_tile_count = 1
	
	while coords_to_check:
		var current_tile: Coord = coords_to_check.pop_front()
		for offset_x in [-1 , 0 ,  1]:
			for offset_z in [-1 , 0 ,  1]:
				if offset_x == 0 or offset_z == 0: #non-diagonal neioghbor
					var neighbor = Coord.new(current_tile.x + offset_x, current_tile.z + offset_z)
					if on_the_map(neighbor):
						if not checked_tiles[neighbor.x][neighbor.z]:
							if not obstacle_map[neighbor.x][neighbor.z]:
								checked_tiles[neighbor.x][neighbor.z] = true
								coords_to_check.append(neighbor)
								accessible_tile_count += 1
	var target_accessible_tile_count = map_width * map_depth - current_obstacle_count
	if target_accessible_tile_count == accessible_tile_count:
		return true
	else:
		return false

func make_maze():
	maze = []
	# Initialize maze with walls (1)
	for i in range(map_depth):
		maze.append([])
		for j in range(map_width):
			maze[i].append(1)
	
	# Start DFS from the start position
	generate_maze(start.x, start.z)
	
	# Ensure outer walls are completely filled
	for i in range(map_width):
		maze[0][i] = 1
		maze[map_depth-1][i] = 1

	for j in range(map_depth):
		maze[j][0] = 1
		maze[j][map_width-1] = 1
	
	print(maze)


func generate_maze(x, z):
	maze[z][x] = 0  # Mark the current cell as a path (0)
	
	
	directions.shuffle()
	
	for dir in directions:
		var neighboor = Vector3(x + int(dir.x) * 2,0, z + int(dir.z) * 2)
		
		# Check if the new position is within bounds and is a wall
		if on_the_map(neighboor):
			# Break the wall between the current cell and the new cell
			maze[z + int(dir.z)][x + int(dir.x)] = 0
			# Recursively generate the maze from the new position
			generate_maze(neighboor.x, neighboor.z)

func on_the_map(neighboor):
	return neighboor.x >=0 and neighboor.x < map_width and neighboor.z >=0 and neighboor.z < map_depth

func create_obstacle_at(x,z):
	var obstacle_position = Vector3(x*2, 1.5, z*2)
	obstacle_position +=Vector3(-map_width+1, 0, -map_depth+1)
	var new_obstacle: CSGBox3D = ObstacleScene.instantiate()
	new_obstacle.size.y = get_obstacle_height()
	new_obstacle.transform.origin = obstacle_position + Vector3(0, new_obstacle.size.y/2-1, 0) 
	level.add_child(new_obstacle)
	new_obstacle.owner = self

func set_obstacle_density(value:float):
	obstacle_density = value
	generate_map()

func fill_map_coords_array():
	map_coords_array = []
	for x in range(map_width):
		for z in range(map_depth):
			map_coords_array.append(Coord.new(x,z))

func fill_obstacle_map():
	obstacle_map = []
	for x in range(map_width):
		obstacle_map.append([])
		for z in range(map_depth):
			obstacle_map[x].append(false)

func set_width(value:int):
	map_width = make_even(value, map_width)
	update_map_center()
	update_npc_start()
	update_map_goal()

func set_depth(value:int):
	map_depth = make_even(value, map_depth)
	update_map_center()
	update_npc_start()
	update_map_goal()

func update_map_center():
	map_center = Coord.new(map_width/2,map_depth/2)

func update_map_goal():
	goal = Coord.new(-map_width,map_depth)

func update_npc_start():
	start = Coord.new(map_width-1,map_depth-1)
	print(start)

func make_even(new_int,old_int):
	if new_int % 2 == 1:
		if new_int > old_int:
			return new_int + 1
		else:
			return new_int - 1
	else:
		return new_int

func set_seed(value:int):
	rng_seed = value

func set_max_obs_height(value:float):
	obstacle_max_height = value
	generate_map()

func set_min_obs_height(value:float):
	obstacle_min_height = value
	generate_map()

func get_obstacle_height():
	return randf_range(obstacle_min_height, obstacle_max_height)
