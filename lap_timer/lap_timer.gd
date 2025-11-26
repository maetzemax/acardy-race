extends Node

## Lap Timer Manager - verbindet Checkpoints mit UI

@export var laptime_service: LaptimeService

@export var vehicle: VehicleBody3D

var current_lap_time: float = 0.0
var lap_started: bool = false

func _ready():
	var checkpoints = get_tree().get_nodes_in_group("lap_checkpoints")
	
	for checkpoint in checkpoints:
		if checkpoint.has_signal("lap_completed"):
			checkpoint.lap_completed.connect(_on_lap_completed)


func _process(delta: float) -> void:
	current_lap_time += delta
	

func _on_lap_completed(crossing_vehicle: Node3D):
	if crossing_vehicle != vehicle:
		return
	
	if not lap_started:
		lap_started = true
	else:
		if current_lap_time < laptime_service.best_lap_time:
			laptime_service.best_lap_time = current_lap_time
			laptime_service.set_leaderboard_laptime(current_lap_time)
		
		laptime_service.last_lap_time = current_lap_time
		current_lap_time = 0
		
		await get_tree().create_timer(1.0).timeout
		laptime_service.load_best_time()
