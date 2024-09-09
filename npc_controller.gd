extends Node3D

signal obstacle_should_spawn(location)

@export var Target: CharacterBody3D
@onready var astar = self.get_parent().get_node("AStar")
@onready var npc = self.get_parent().get_node("NPC_AStar")

# Called when the node enters the scene tree for the first time.
func _ready():
	var target = Target.position
	npc.update_path(astar.find_path(npc.global_transform.origin), target)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
