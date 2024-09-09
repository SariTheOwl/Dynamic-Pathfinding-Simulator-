@tool
class_name GroundGrid extends StaticBody3D

@export var generate_ground_tool: bool = false: set = set_generate_ground
@onready var mesh_instance : MeshInstance3D  = self.get_node("MeshInstance3D")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	mesh_instance.scale =  Vector3(1,0.25,1)
	#mesh_instance.custom_aabb
	var mesh = mesh_instance.mesh
	print("Mesh surface count: " + str(mesh.get_surface_count()))
	var mdt = MeshDataTool.new()
	if mdt.create_from_surface(mesh, 0) == OK:  # Check pass
		print("Ok!!")
		print(mdt.get_vertex_count())
	else:
		print("Fail...")
	
	#mesh_instance.mesh.set("size", Vector3(size.x,1,size.z))
	
	mesh_instance.create_convex_collision()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func clear_map():
	for node in get_children():
		print(node.name)
		node.queue_free()

func set_generate_ground(bool):
	generate_ground()

func generate_ground():
	clear_map()
	

func update_size(size:Vector3):
	print(mesh_instance.get_children())
	mesh_instance.mesh.set("size", Vector3(size.x,1,size.z))
	
	mesh_instance.create_convex_collision()
