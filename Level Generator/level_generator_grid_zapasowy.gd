@tool

class_name LevelGeneratorZapasowy extends Node3D

@export var GroundScene: PackedScene
@export var ObstacleScene: PackedScene 

@export var Hud: PackedScene
@export var Camera: PackedScene
@export var Light: PackedScene
@export var GenLevelButton: PackedScene

@export var AStarNpc: PackedScene
@export var Goal: PackedScene 

@export_range(10, 50, 1) var map_width:int = 11: set = set_width
@export_range(10, 50, 1) var map_depth:int = 11: set = set_depth
# Called when the node enters the scene tree for the first time.

var obstacle_density :float = 1.0
var obstacle_height:float = 6.0

@export var generate_level: bool = false: set = set_generate_level

@export var save_level: bool = false: set = set_save_level
@export var level_name: String = "New Level"

@export var rng_seed:int = 0: set = set_seed, get = get_seed

var level : NavigationMap = NavigationMap.new()
var navmesh_instance: NavigationMesh

var regenerate_level: Button = Button.new()

var update_rng_value: int = 0

var start: NavigationMap.Coord
var goal: NavigationMap.Coord

var pathfindingManager: PathfindingManager = PathfindingManager.new()

var gen_level_button: Button

signal regenerate_map

func _ready():
	generate_map()
	
	#add_gen_level_button()
	get_tree().current_scene.connect(&"ready", _on_scenetree_ready)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_generate_level(bool):
	generate_map()
	_on_scenetree_ready()

func generate_map():
	print("generate")
	clear_map()
	add_level()
	level.update_map_center()
	add_ground()
	add_astar_controller()
	#add_ground_grid()
	add_obstacles()
	add_goal()
	add_hud()
	
	add_camera()
	
	add_light()
	update_rng_seed()
	notify_property_list_changed()

func _on_regenerate_map():
	generate_map()
	_on_scenetree_ready()

func _on_scenetree_ready():
	pathfindingManager.add_obstacles()
	
	add_npcs()
	print("dadadibe")
	

func add_astar_controller():
	pathfindingManager = PathfindingManager.new()
	pathfindingManager.name = "PathfindingManager"
	add_child(pathfindingManager)
	pathfindingManager.owner = self

func add_hud():
	var hud: Control = Hud.instantiate()
	add_child(hud)
	hud.owner = self

func add_gen_level_button():
	gen_level_button = GenLevelButton.instantiate()
	print("gen_level_button reg",gen_level_button)
	
	#gen_level_button.pressed.connect(regenerate_map)
	
	add_child(gen_level_button)
	gen_level_button.owner = self
	

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
		print("to delete ",node.name)
		if(node.name != "Button"):
			print("delete ",node.name)
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
	#var mesh = MeshInstance3D.new()
	#mesh.name = "MeshInstance3D"
	#mesh.scale = Vector3(4, 1, 4)
	#mesh.
	
	level.add_child(ground)
	ground.owner = self
	
	#ground.add_child(mesh)
	#mesh.owner = self
	
func add_obstacles():
	level.fill_map_coords_array()
	fill_obstacle_map()
	#print(map_coords_array)
	
	seed(rng_seed)
	
	level.map_coords_array.shuffle()
	#print(map_coords_array)
	
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

func add_npcs():
	find_best_start()
	
	var offset = Vector3(-map_width+1, 0, -map_depth+1)
	var npc_start_position = Vector3(start.x*2, 1.5, start.z*2) + offset
	var a_star_npc: CharacterBody3D= AStarNpc.instantiate()
	#var npc_size = Vector3(0, a_star.size.y/2-1, 0)
	a_star_npc.transform.origin = npc_start_position# + npc_size
	print("npc_start_position: ",npc_start_position)
	add_child(a_star_npc)
	a_star_npc.owner = self

func add_goal():
	find_best_goal()
	
	var offset = Vector3(-map_width+1, 0, -map_depth+1)
	var goal_position = Vector3(goal.x*2, 1.5, goal.z*2) + offset
	
	var goal_npc: CharacterBody3D= Goal.instantiate()
	goal_npc.transform.origin = goal_position#+ npc_size
	print("goal_position: ",goal_position)
	add_child(goal_npc)
	goal_npc.owner = self

func find_best_start():
	for x in range(map_width):
		for z in range(map_depth):
			if(level.obstacle_map[x][z] == false):
				#print(level.obstacle_map[x][z],x,z)
				start = NavigationMap.Coord.new(x,z)
				
				return

func find_best_goal():
	for x in range(map_width-1, 0, -1):
		for z in range(map_depth-1, 0, -1):
			if(level.obstacle_map[x][z] == false):
				#print(level.obstacle_map[x][z],x,z)
				goal = NavigationMap.Coord.new(x,z)
				return

#Flood fill algorithm - change to krusal or prim
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
