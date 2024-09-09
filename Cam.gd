extends Camera3D

var mouse = Vector2()

func _input(event):
	if event is InputEventMouse:
		mouse = event.position
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			get_selection()

func _physics_process(delta):
	
	if Input.is_action_pressed("ui_right"):
		self.transform.origin.z -= 1
	if Input.is_action_pressed("ui_left"):
		self.transform.origin.z += 1
	if Input.is_action_pressed("ui_up"):
		self.transform.origin.x -= 1
	if Input.is_action_pressed("ui_down"):
		self.transform.origin.x += 1

func get_selection():
	var worldspace = get_world_3d().direct_space_state
	var start = project_ray_origin(mouse)
	var end = project_position(mouse, 1000)
	var result = worldspace.intersect_ray(PhysicsRayQueryParameters3D.create(start, end))
	#print(result)
	if result and result.collider.has_method("die"):
		result.collider.die(result.position);
