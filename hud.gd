class_name PathfindingHud extends Control

@onready var AStarGrid = $GridContainer/AStarGrid
@onready var DStarGrid = $GridContainer/DStarGrid
@onready var DStarLiteGrid = $GridContainer/DStarLiteGrid
@onready var LPAStarGrid = $GridContainer/LPAStarGrid
@onready var WallsChangedGrid = $GridContainer/WallsChangedGrid

var AStarTimer:Stopwatch
var DStarTimer:Stopwatch
var DStarLiteTimer:Stopwatch
var LPAStarTimer:Stopwatch
var walls_changed_count:int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	AStarTimer = Stopwatch.new()
	DStarTimer = Stopwatch.new()
	DStarLiteTimer = Stopwatch.new()
	LPAStarTimer = Stopwatch.new()

	add_child(AStarTimer)
	add_child(DStarTimer)
	add_child(DStarLiteTimer)
	add_child(LPAStarTimer)

	AStarTimer.owner = self
	DStarTimer.owner = self
	DStarLiteTimer.owner = self
	LPAStarTimer.owner = self
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_clock("AStar")
	update_clock("DStar")
	update_clock("DStarLite")
	update_clock("LPAStar")

func update_nodes_calculated(nodes_count:int, algorithm: String):
	if algorithm == "AStar":
		var count = AStarGrid.get_node("NodesCalculated")
		count.text = str(nodes_count)
	elif algorithm == "DStar":
		var count = DStarGrid.get_node("NodesCalculated")
		count.text = str(nodes_count)
	elif algorithm == "DStarLite":
		var count = DStarLiteGrid.get_node("NodesCalculated")
		count.text = str(nodes_count)
	elif algorithm == "LPAStar":
		var count = LPAStarGrid.get_node("NodesCalculated")
		count.text = str(nodes_count)

func update_walls_changed_count():
	walls_changed_count += 1
	var count = WallsChangedGrid.get_node("WallsChangedCount")
	count.text = str(walls_changed_count)

func update_clock(algorithm: String):
	if algorithm == "AStar":
		var count = AStarGrid.get_node("Time")
		count.text = AStarTimer.time_to_string()
	elif algorithm == "DStar":
		var count = DStarGrid.get_node("Time")
		count.text = DStarTimer.time_to_string()
	elif algorithm == "DStarLite":
		var count = DStarLiteGrid.get_node("Time")
		count.text = DStarLiteTimer.time_to_string()
	elif algorithm == "LPAStar":
		var count = LPAStarGrid.get_node("Time")
		count.text = LPAStarTimer.time_to_string()

func stop_clock(algorithm: String):
	print("stop_clock", algorithm)
	if algorithm == "AStar":
		AStarTimer.stoppped = true
	elif algorithm == "DStar":
		DStarTimer.stoppped = true
	elif algorithm == "DStarLite":
		DStarLiteTimer.stoppped = true
	elif algorithm == "LPAStar":
		LPAStarTimer.stoppped = true
