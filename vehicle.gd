extends VehicleBody3D

var throttle: float = 0.0
var steering_input: float = 0.0

@onready var wheel_front_left: VehicleWheel3D = $WheelFrontLeft
@onready var wheel_front_right: VehicleWheel3D = $WheelFrontRight
@onready var wheel_rear_left: VehicleWheel3D = $WheelRearLeft
@onready var wheel_rear_right: VehicleWheel3D = $WheelRearRight

@export_group("Speed")
@export var acceleration: float = 120
@export var vehicle_linear_velocity: float = 0.0

@export_group("Steering & Brake")
@export var steering_speed = 1.5
@export var max_steering_angle = 0.65
@export var handbrake_force = 5.0
var handbrake: bool = false

@export_group("Supension Settings")
@export var wheel_friction: float = 10.5
@export var suspension_stiff_value: float = 0.0

@export_group("Stability Control")
@export var roll_influence: float = 0.5
var anti_roll_torque: Vector3
var downforce: Vector3
@export var anti_roll_force: float = 20
@export var downforce_factor: float = 50.0


func _physics_process(delta: float):
	for wheel in [wheel_front_left, wheel_front_right, wheel_rear_left, wheel_rear_right]:
		wheel.wheel_friction_slip = wheel_friction
		wheel.suspension_stiffness = suspension_stiff_value
	
	_handle_vehicle_control(delta)
	_handle_vehicle_velocity()
	_handle_anti_roll()
	_handle_handbrake()


func _handle_vehicle_control(delta):
	throttle = Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
	steering_input = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	handbrake = Input.is_action_pressed("handbrake")
	
	steering = move_toward(steering, steering_input * max_steering_angle, delta * steering_speed)


func _handle_vehicle_velocity():
	vehicle_linear_velocity = linear_velocity.length()
	# Bessere Geschwindigkeits-Skalierung: mehr Kraft bei niedrigen Geschwindigkeiten
	var speed_factor = 1.0 - min(vehicle_linear_velocity / 30.0, 0.7)
	
	engine_force = throttle * acceleration * speed_factor


func _handle_anti_roll():
	anti_roll_torque = -global_transform.basis.z * global_rotation.z * anti_roll_force
	apply_torque(anti_roll_torque)
	
	# Downforce nach UNTEN drücken (y-Achse), nicht z-Achse
	downforce = -global_transform.basis.y * vehicle_linear_velocity * downforce_factor 
	apply_central_force(downforce)
	
	for wheel in [wheel_front_left, wheel_front_right, wheel_rear_left, wheel_rear_right]:
		wheel.wheel_roll_influence = roll_influence

func _handle_handbrake():
	if handbrake:
		brake = handbrake_force
	else:
		brake = 0.0
