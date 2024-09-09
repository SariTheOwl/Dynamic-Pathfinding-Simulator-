@tool

class_name LevelGenerator extends Node3D

@export var GroundScene: PackedScene
@export var ObstacleScene: PackedScene 

@export var Hud: PackedScene
@export var Camera: PackedScene
@export var Light: PackedScene

@export var AStarNpc: PackedScene
@export var DStarNpc: PackedScene
@export var DStarLiteNpc: PackedScene
@export var LPAStarNpc: PackedScene
@export var Goal: PackedScene 

@export_range(10, 50, 1) var map_width:int = 12: set = set_width
@export_range(10, 50, 1) var map_depth:int = 12: set = set_depth
# Called when the node enters the scene tree for the first time.

var obstacle_density :float = 1.0
var obstacle_height:float = 3.0

@export var generate_level: bool = false: set = set_generate_level

@export var save_level: bool = false: set = set_save_level
@export var level_name: String = "New Level"

@export var rng_seed:int = 0: set = set_seed, get = get_seed

var level : NavigationMap = NavigationMap.new()
var navmesh_instance: NavigationMesh

var regenerate_level: Button = Button.new()

var update_rng_value: int = 0

var pathfindingManager: PathfindingManager = PathfindingManager.new()

var gen_level_button: Button

func _ready():
	generate_map()
	get_tree().current_scene.connect(&"ready", _on_scenetree_ready)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_generate_level(bool):
	generate_map()
	_on_scenetree_ready()

func generate_map():
	clear_map()
	add_level()
	level.update_map_center()
	add_ground()
	add_astar_controller()
	#add_ground_grid()
	add_obstacles()
	
	add_camera()
	
	add_light()
	update_rng_seed()
	notify_property_list_changed()

func regenerate_map():
	generate_map()
	_on_scenetree_ready()

func _on_scenetree_ready():
	pathfindingManager.prepare_npc(map_width, map_depth, level.obstacle_map, Goal, AStarNpc, DStarNpc, DStarLiteNpc, LPAStarNpc, Hud)
	pathfindingManager._update_npcs_path()
	

func add_astar_controller():
	pathfindingManager = PathfindingManager.new()
	pathfindingManager.name = "PathfindingManager"
	add_child(pathfindingManager)
	pathfindingManager.owner = self
	
func add_camera():
	var camera: Camera3D= Camera.instantiate()
	camera.transform.origin = Vector3(0, map_width+map_depth, 0) 
	add_child(camera)
	camera.owner = self

func add_light():
	var light: DirectionalLight3D = Light.instantiate()
	light.transform.origin = Vector3(0, map_width+map_depth, 0) 
	add_child(light)
	light.owner = self

func clear_map():
	for node in get_children():
		if(node.name != "Button"):
			node.free()

func add_level():
	level = NavigationMap.new()
	level.name = "NavigationRegion3D"
	add_child(level)
	# add nav mesh
	
	level.owner = self
	level.map_depth = map_depth
	level.map_width = map_width
	level.navigation_mesh = NavigationMesh.new()
	level.navigation_mesh.border_size = 0.5
	level.navigation_mesh.filter_ledge_spans = true

func set_save_level(bool):
	var packed_secene = PackedScene.new()
	for child in level.get_children():
		child.owner = level
	packed_secene.pack(level)
	var scene_resource_path = "res://Level/GeneratedLevels/%s.tscn" % level_name
	ResourceSaver.save(packed_secene, scene_resource_path, 0)
	
	level_name = increment_string(level_name)

func increment_string(string: String):
	var regex = RegEx.new()
	regex.compile("\\d+$")
	var result = regex.search(string)
	var num = "0"
	if result:
		num = result.get_string()
	
	return string.trim_suffix(num) + str(int(num)+1)

func add_ground():
	var ground:CSGBox3D = GroundScene.instantiate()
	ground.size = Vector3(map_width*2, 1 ,map_depth*2) 

	level.add_child(ground)
	ground.owner = self

func add_obstacles():
	level.fill_map_coords_array()
	fill_obstacle_map()

	seed(rng_seed)
	
	level.map_coords_array.shuffle()
	
	var num_obstacles = level.map_coords_array.size() * obstacle_density
	var current_obstacle_count = 0
	
	if num_obstacles > 0:
		for coord in level.map_coords_array.slice(0, num_obstacles - 1):
			
			if not level.map_center.equals(coord):
				#create_obstacle_at(coord.x, coord.z)
				current_obstacle_count += 1
				level.obstacle_map[coord.x][coord.z] = true
				if map_is_fully_accessible(current_obstacle_count):
					create_obstacle_at(coord.x, coord.z)
				else:
					current_obstacle_count -= 1
					level.obstacle_map[coord.x][coord.z] = false


#Flood fill algorithm 
func map_is_fully_accessible(current_obstacle_count):
	var checked_tiles = []
	for x in range(map_width):
		checked_tiles.append([])
		for z in range(map_depth):
			checked_tiles[x].append(false)
	var coords_to_check = [level.map_center]
	checked_tiles[level.map_center.x][level.map_center.z] = true
	var accessible_tile_count = 1
	
	while coords_to_check:
		var current_tile: NavigationMap.Coord = coords_to_check.pop_front()
		for offset_x in [-1 , 0 ,  1]:
			for offset_z in [-1 , 0 ,  1]:
				if offset_x == 0 or offset_z == 0: #non-diagonal neioghbor
					var neighbor = NavigationMap.Coord.new(current_tile.x + offset_x, current_tile.z + offset_z)
					if on_the_map(neighbor):
						if not checked_tiles[neighbor.x][neighbor.z]:
							if not level.obstacle_map[neighbor.x][neighbor.z]:
								checked_tiles[neighbor.x][neighbor.z] = true
								coords_to_check.append(neighbor)
								accessible_tile_count += 1
	var target_accessible_tile_count = map_width * map_depth - current_obstacle_count
	if target_accessible_tile_count == accessible_tile_count:
		return true
	else:
		return false

func on_the_map(neighboor):
	return neighboor.x >=0 and neighboor.x < map_width and neighboor.z >=0 and neighboor.z < map_depth

func create_at(x,z,obj):
	var obstacle_position = Vector3(x*2, 1.5, z*2)
	obstacle_position +=Vector3(-map_width+1, 0, -map_depth+1)
	print(obstacle_position)
	var new_obstacle: CSGBox3D = obj.instantiate()
	level.add_child(new_obstacle)
	new_obstacle.owner = self

func create_obstacle_at(x,z):
	var obstacle_position = Vector3(x*2, 1.5, z*2)
	obstacle_position +=Vector3(-map_width+1, 0, -map_depth+1)
	#print(obstacle_position)
	var new_obstacle: CSGBox3D = ObstacleScene.instantiate()
	new_obstacle.size.y = obstacle_height
	new_obstacle.transform.origin = obstacle_position + Vector3(0, new_obstacle.size.y/2-1, 0) 
	level.add_child(new_obstacle)
	new_obstacle.owner = self
	pathfindingManager.obstacle_to_add(new_obstacle)
	

func fill_obstacle_map():
	level.obstacle_map = []
	for x in range(map_width):
		level.obstacle_map.append([])
		for z in range(map_depth):
			level.obstacle_map[x].append(false)

func set_width(value:int):
	map_width = make_even(value, map_width)
	level.update_map_center()

func set_depth(value:int):
	map_depth = make_even(value, map_depth)
	level.update_map_center()

func make_even(new_int,old_int):
	if new_int % 2 == 1:
		if new_int > old_int:
			return new_int + 1
		else:
			return new_int - 1
	else:
		return new_int

func set_seed(value:int):
	if  update_rng_value != value:
		update_rng_value = value - 1
		rng_seed = update_rng_value
		generate_map()

func get_seed():
	return update_rng_value

func update_rng_seed():
	var old_val =  update_rng_value
	var new_val = update_rng_value + 1 
	if old_val != new_val:
		update_rng_value = new_val
		return update_rng_value
