@tool
extends GenericNpc

func get_algorithm() -> String:
	# Override this method in derived NPC classes (A*, D*, etc.)
	return "DStar"