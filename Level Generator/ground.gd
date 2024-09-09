@tool
extends CSGBox3D

@export var ObstacleScene: PackedScene 

var obstacle_height:float = 3.0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func die(position:Vector3):
	create_obstacle(position)
	

func create_obstacle(position:Vector3):
	var x = int(ceil(position.x))
	var z = int(ceil(position.z))
	if(x % 2 == 0):
		x = x-1
	if(z % 2 == 0):
		z = z-1
		
	var obstacle_position =Vector3(x ,1.5, z)
	var new_obstacle: CSGBox3D = ObstacleScene.instantiate()
	new_obstacle.size.y = obstacle_height
	new_obstacle.transform.origin = obstacle_position + Vector3(0, new_obstacle.size.y/2-1, 0) 
	self.get_parent().add_child(new_obstacle)
	var pathfindingManager:PathfindingManager = self.get_parent().get_parent().get_node("PathfindingManager")
	pathfindingManager.obstacle_added(new_obstacle)
