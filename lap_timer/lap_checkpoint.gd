extends Area3D

## Start/Ziel Checkpoint für Rundenzeiten

@export var is_start_finish: bool = true  # Start/Ziel-Linie
@export var checkpoint_number: int = 0    # Optional: Für Zwischenpunkte

signal checkpoint_crossed(vehicle: Node3D)
signal lap_completed(vehicle: Node3D)


func _ready():
	body_entered.connect(_on_body_entered)
	
	# Visual Feedback (optional)
	if is_start_finish:
		print("Start/Ziel-Linie aktiviert")


func _on_body_entered(body: Node3D):
	# Prüfe ob es ein Vehicle ist
	if body is VehicleBody3D:
		print("Checkpoint überquert: ", body.name)
		checkpoint_crossed.emit(body)
		
		if is_start_finish:
			lap_completed.emit(body)
