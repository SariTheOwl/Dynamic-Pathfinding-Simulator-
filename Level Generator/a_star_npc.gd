@tool
extends GenericNpc


func _ready():
	#pass
	target = goal.global_transform.origin * Vector3(1,1,1)
	update_path()

func get_algorithm() -> String:
	# Override this method in derived NPC classes (A*, D*, etc.)
	return "AStar"
