extends Button


@onready var levelGenerator = self.get_node("../../LevelGenerator")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_pressed():
	levelGenerator.regenerate_map()
