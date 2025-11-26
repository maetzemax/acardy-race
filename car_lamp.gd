extends SpotLight3D

var cycle_controller: CycleController

func _ready():
	cycle_controller = get_tree().get_first_node_in_group("CycleController")
	
	cycle_controller.day_started.connect(_on_day_started)
	cycle_controller.night_started.connect(_on_night_started)


func _on_day_started():
	visible = false


func _on_night_started():
	visible = true
