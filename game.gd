extends Node3D

@onready var navmap = $NavigationRegion3D

# Called when the node enters the scene tree for the first time.
func _ready():
	print(navmap.map_depth)
	print(navmap.map_width)
	print(navmap.obstacle_map)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
