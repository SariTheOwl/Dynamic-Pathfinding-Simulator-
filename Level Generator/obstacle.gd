@tool
extends CSGBox3D



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func die(position:Vector3):
	var pathfindingManager:PathfindingManager = self.get_parent().get_parent().get_node("PathfindingManager")
	pathfindingManager.handle_obstacle_removed(self)
	queue_free()
