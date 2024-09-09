extends CharacterBody2D

const speed = 100
var dir : Vector2


# Called when the node enters the scene tree for the first time.
func _pshycics_process(_delta: float):
	velocity = dir * speed
	move_and_slide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _unhandled_input(event):
	dir.x = Input.get_axis("ui_left","ui_right")
	dir.y = Input.get_axis("ui_up","ui_down")
	dir = dir.normalized()
