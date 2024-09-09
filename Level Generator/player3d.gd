class_name GoalNPC extends CharacterBody3D

var speed = 5.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#func _physics_process(delta):
	#
	#velocity = Vector3()
	#
	#if Input.is_action_pressed("ui_right"):
		#velocity.x += 1
	#if Input.is_action_pressed("ui_left"):
		#velocity.x -= 1
	#if Input.is_action_pressed("ui_up"):
		#velocity.z -= 1
	#if Input.is_action_pressed("ui_down"):
		#velocity.z += 1
	#
	#velocity = velocity.normalized() * speed
	#
	#move_and_slide()
