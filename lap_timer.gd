extends Node

## Lap Timer Manager - verbindet Checkpoints mit UI

@export var vehicle: VehicleBody3D
@export var debug_ui: Control

var lap_started: bool = false


func _ready():
	# Finde alle Checkpoints in der Szene
	var checkpoints = get_tree().get_nodes_in_group("lap_checkpoints")
	
	for checkpoint in checkpoints:
		if checkpoint.has_signal("lap_completed"):
			checkpoint.lap_completed.connect(_on_lap_completed)


func _on_lap_completed(crossing_vehicle: Node3D):
	# Prüfe ob es unser Vehicle ist
	if crossing_vehicle != vehicle:
		return
	
	if not lap_started:
		# Erste Überquerung = Start
		if debug_ui and debug_ui.has_method("start_lap"):
			debug_ui.start_lap()
		lap_started = true
	else:
		# Zweite Überquerung = Finish
		if debug_ui and debug_ui.has_method("finish_lap"):
			debug_ui.finish_lap()
		lap_started = false
		
		# Optional: Auto-Restart für nächste Runde
		await get_tree().create_timer(1.0).timeout
		if debug_ui and debug_ui.has_method("start_lap"):
			debug_ui.start_lap()
		lap_started = true
