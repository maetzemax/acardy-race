extends VehicleBody3D

var throttle: float = 0.0
var steering_input: float = 0.0

@onready var wheel_front_left: VehicleWheel3D = $WheelFrontLeft
@onready var wheel_front_right: VehicleWheel3D = $WheelFrontRight
@onready var wheel_rear_left: VehicleWheel3D = $WheelRearLeft
@onready var wheel_rear_right: VehicleWheel3D = $WheelRearRight

@export_group("Speed")
@export var acceleration: float = 120
@export var max_engine_power: float = 300.0  # PS/Leistung des Motors (erhöht für bessere Performance)
@export var vehicle_linear_velocity: float = 0.0

@export_group("Steering & Brake")
@export var steering_speed = 1.5
@export var max_steering_angle = 0.65
@export var normal_brake_force: float = 3.0  # Normale Bremse (S-Taste)
var is_braking: bool = false

@export_group("Supension Settings")
@export var wheel_friction: float = 10.5
@export var suspension_stiff_value: float = 0.0

@export_group("Stability Control")
@export var roll_influence: float = 0.1  # Niedriger = weniger Wippen
var anti_roll_torque: Vector3
var downforce: Vector3
@export var anti_roll_force: float = 50.0  # Erhöht für weniger Wippen
@export var anti_pitch_force: float = 80.0  # Verhindert Wippen beim Beschleunigen/Bremsen
@export var downforce_factor: float = 20.0  # Reduziert - war zu stark bei hoher Geschwindigkeit
@export var downforce_front_bias: float = 0.55  # 55% vorne, 45% hinten für Balance


func _physics_process(delta: float):
	for wheel in [wheel_front_left, wheel_front_right, wheel_rear_left, wheel_rear_right]:
		wheel.wheel_friction_slip = wheel_friction
		wheel.suspension_stiffness = suspension_stiff_value
	
	_handle_vehicle_control(delta)
	_handle_vehicle_velocity()
	_handle_anti_roll()
	_handle_brake()


func _handle_vehicle_control(delta):
	# Separate Inputs für Gas und Bremse
	var accelerate_input = Input.get_action_strength("accelerate")
	is_braking = Input.is_action_pressed("brake")
	
	# Throttle nur Gas, keine Bremse mehr
	throttle = accelerate_input
	
	steering_input = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	steering = move_toward(steering, steering_input * max_steering_angle, delta * steering_speed)


func _handle_vehicle_velocity():
	vehicle_linear_velocity = linear_velocity.length()
	
	engine_force = throttle * acceleration


func _handle_anti_roll():
	# Berechne Neigung (Roll) auf X-Achse
	var roll_angle = global_rotation.x
	
	# Anti-Roll-Torque um Z-Achse (gegen Seitenneigung)
	anti_roll_torque = -global_transform.basis.z * roll_angle * anti_roll_force
	apply_torque(anti_roll_torque)
	
	# Anti-Pitch: Verhindert Nicken beim Beschleunigen/Bremsen (Rotation um X-Achse)
	var pitch_angle = global_rotation.z  # Nicken vorwärts/rückwärts
	var anti_pitch_torque = -global_transform.basis.x * pitch_angle * anti_pitch_force
	apply_torque(anti_pitch_torque)
	
	# Balancierte Downforce: Mehr vorne um Heck-Aufsetzen zu verhindern
	var speed_squared = vehicle_linear_velocity * vehicle_linear_velocity
	var total_downforce = speed_squared * downforce_factor * 0.01
	
	# Vorne mehr Downforce (55%)
	var front_downforce_pos = (wheel_front_left.global_position + wheel_front_right.global_position) / 2.0
	var front_force = -global_transform.basis.y * total_downforce * downforce_front_bias
	apply_force(front_force, front_downforce_pos - global_position)
	
	# Hinten weniger Downforce (45%)
	var rear_downforce_pos = (wheel_rear_left.global_position + wheel_rear_right.global_position) / 2.0
	var rear_force = -global_transform.basis.y * total_downforce * (1.0 - downforce_front_bias)
	apply_force(rear_force, rear_downforce_pos - global_position)
	
	for wheel in [wheel_front_left, wheel_front_right, wheel_rear_left, wheel_rear_right]:
		wheel.wheel_roll_influence = roll_influence

func _handle_brake():
	# Normale Bremse (alle 4 Räder)
	if is_braking:
		brake = normal_brake_force
	else:
		brake = 0.0
