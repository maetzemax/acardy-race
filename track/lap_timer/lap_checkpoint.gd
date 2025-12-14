extends Area3D

@export var is_start_finish: bool = true
@export var checkpoint_number: int = 0

signal checkpoint_crossed(vehicle: Node3D, checkpoint_number: int)
signal lap_completed(vehicle: Node3D)


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D):
	if body is RigidBody3D:
		if is_start_finish:
			lap_completed.emit(body)
		else:
			checkpoint_crossed.emit(body, checkpoint_number)
