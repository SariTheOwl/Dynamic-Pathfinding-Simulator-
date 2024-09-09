extends Node3D

@export var Enemy : PackedScene
@export var num_enemies = 3
@export var seconds_between_spawns = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	var enemy = Enemy.instantiate()
	var scene_root = get_parent()
	scene_root.add_child(enemy)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
