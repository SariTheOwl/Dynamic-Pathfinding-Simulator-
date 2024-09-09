@tool
class_name NavigationMap extends NavigationRegion3D

var map_coords_array: Array = []
@export var obstacle_map: Array = []
var map_center: Coord

@export var map_width: int
@export var map_depth: int

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

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func fill_map_coords_array():
	map_coords_array = []
	for x in range(map_width):
		for z in range(map_depth):
			map_coords_array.append(Coord.new(x,z))

func update_map_center():
	map_center = Coord.new(map_width/2,map_depth/2)
