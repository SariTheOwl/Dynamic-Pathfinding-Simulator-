@tool
class_name GenericNpc extends CharacterBody3D

@onready var goal: CharacterBody3D = self.get_node("../Goal")
@onready var path_manager:PathfindingManager = get_parent()
var speed: float = 2.0
var accel = 10
var path := []
var current_target := Vector3.INF
var current_velocity := Vector3.ZERO
var finished:bool = false

var target:Vector3

func _ready():
	#pass
	target = goal.global_transform.origin * Vector3(1,1,1)


func _physics_process(delta: float) -> void:
	var new_velocity := Vector3.ZERO
	var lerp_weight = delta * 8.0
	if current_target != Vector3.INF:
		var dir_to_target = global_transform.origin.direction_to(current_target).normalized()
		new_velocity = lerp(velocity, speed * dir_to_target, lerp_weight)
		if global_transform.origin.distance_to(current_target) < 0.1:
			find_next_point_in_path()
	else:
		if position.distance_to(goal.global_transform.origin) < 2.1:
			print("kałabanga2")
			path_manager.stop_clock(get_algorithm())
		new_velocity = lerp(velocity, Vector3.ZERO, lerp_weight)
	velocity = new_velocity
	move_and_slide()

func update_path():
	# Request path from the manager
	if goal == null:
		goal = self.get_node("../Goal")
		
	var new_path = path_manager.find_path(global_transform.origin, goal.global_transform.origin, get_algorithm())
	path = new_path
	find_next_point_in_path()

func find_next_point_in_path():
	if path.size() > 0:
		var new_target = path.pop_front()
		#new_target.y = global_transform.origin.y
		current_target = new_target
		#print("current_target",current_target)
		if position.distance_to(goal.global_transform.origin) < 2.1:
			print("kałabanga2")
			path_manager.stop_clock(get_algorithm())
	else:
		print("kałabanga3 ", position.distance_to(goal.global_transform.origin))

		current_target = Vector3.INF

func get_algorithm() -> String:
	# Override this method in derived NPC classes (A*, D*, etc.)
	return "AStar"
