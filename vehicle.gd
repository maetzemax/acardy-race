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
@export var normal_brake_force: float = 3.0  # Normale Bremse (S-Taste)
@export var handbrake_force: float = 8.0  # Handbremse (Space)
@export var handbrake_rear_friction: float = 0.5  # Reduzierte Reibung hinten beim Driften
var handbrake: bool = false
var is_braking: bool = false

@export_group("Supension Settings")
@export var wheel_friction: float = 10.5
@export var suspension_stiff_value: float = 0.0
@export var suspension_damping: float = 2500.0  # Dämpfung gegen Wippen

@export_group("Stability Control")
@export var roll_influence: float = 0.1  # Niedriger = weniger Wippen
var anti_roll_torque: Vector3
var downforce: Vector3
@export var anti_roll_force: float = 50.0  # Erhöht für weniger Wippen
@export var downforce_factor: float = 50.0

@export_group("Transmission (Gänge)")
@export var max_rpm: float = 6000.0
@export var idle_rpm: float = 800.0
@export var gear_ratios: Array[float] = [0.0, 3.5, 2.4, 1.8, 1.3, 1.0, 0.8]  # 0=Neutral, 1-6=Gänge
@export var final_drive_ratio: float = 3.8
@export var auto_transmission: bool = true
@export var shift_up_rpm: float = 5500.0
@export var shift_down_rpm: float = 2500.0

var current_gear: int = 1
var current_rpm: float = 1000.0


func _physics_process(delta: float):
	for wheel in [wheel_front_left, wheel_front_right, wheel_rear_left, wheel_rear_right]:
		wheel.wheel_friction_slip = wheel_friction
		wheel.suspension_stiffness = suspension_stiff_value
		# Dämpfung für weniger Wippen
		wheel.damping_compression = suspension_damping / 1000.0
		wheel.damping_relaxation = suspension_damping / 1000.0
	
	_handle_vehicle_control(delta)
	_handle_transmission(delta)
	_handle_vehicle_velocity()
	_handle_anti_roll()
	_handle_handbrake()


func _handle_vehicle_control(delta):
	# Separate Inputs für Gas und Bremse
	var accelerate_input = Input.get_action_strength("accelerate")
	is_braking = Input.is_action_pressed("brake")
	handbrake = Input.is_action_pressed("handbrake")
	
	# Throttle nur Gas, keine Bremse mehr
	throttle = accelerate_input
	
	steering_input = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	
	# Manuelle Gangschaltung (optional)
	if not auto_transmission:
		if Input.is_action_just_pressed("shift_up") and current_gear < gear_ratios.size() - 1:
			current_gear += 1
		if Input.is_action_just_pressed("shift_down") and current_gear > 1:
			current_gear -= 1
	
	steering = move_toward(steering, steering_input * max_steering_angle, delta * steering_speed)


func _handle_transmission(_delta):
	vehicle_linear_velocity = linear_velocity.length()
	
	# RPM basierend auf Geschwindigkeit und Gang berechnen
	if current_gear > 0 and gear_ratios[current_gear] > 0:
		var wheel_rpm = (vehicle_linear_velocity * 60.0) / (2.0 * PI * 0.3)  # 0.3 = wheel radius
		current_rpm = wheel_rpm * gear_ratios[current_gear] * final_drive_ratio
		current_rpm = clamp(current_rpm, idle_rpm, max_rpm)
	else:
		current_rpm = idle_rpm
	
	# Automatische Gangschaltung
	if auto_transmission and throttle > 0.1:
		if current_rpm >= shift_up_rpm and current_gear < gear_ratios.size() - 1:
			current_gear += 1
		elif current_rpm <= shift_down_rpm and current_gear > 1 and vehicle_linear_velocity > 5.0:
			current_gear -= 1

func _handle_vehicle_velocity():
	# Kraftübertragung mit Gangsystem
	var rpm_factor = (current_rpm - idle_rpm) / (max_rpm - idle_rpm)
	rpm_factor = clamp(rpm_factor, 0.2, 1.0)
	
	var gear_ratio = 1.0
	if current_gear > 0 and current_gear < gear_ratios.size():
		gear_ratio = gear_ratios[current_gear]
	
	# Kraft = Grundbeschleunigung * Gang-Ratio * RPM-Effizienz
	var effective_power = acceleration * gear_ratio * rpm_factor
	engine_force = throttle * effective_power


func _handle_anti_roll():
	# Berechne Neigung (Roll) auf X-Achse
	var roll_angle = global_rotation.x
	
	# Anti-Roll-Torque um Z-Achse (gegen Seitenneigung)
	anti_roll_torque = -global_transform.basis.z * roll_angle * anti_roll_force
	apply_torque(anti_roll_torque)
	
	# Downforce nach UNTEN drücken (y-Achse), nicht z-Achse
	# Mehr Downforce bei höherer Geschwindigkeit
	var speed_squared = vehicle_linear_velocity * vehicle_linear_velocity
	downforce = -global_transform.basis.y * speed_squared * downforce_factor * 0.1
	apply_central_force(downforce)
	
	for wheel in [wheel_front_left, wheel_front_right, wheel_rear_left, wheel_rear_right]:
		wheel.wheel_roll_influence = roll_influence

func _handle_handbrake():
	# Normale Bremse (alle 4 Räder)
	if is_braking:
		brake = normal_brake_force
	else:
		brake = 0.0
	
	# Handbremse (blockiert hauptsächlich Hinterräder für Drifts)
	if handbrake:
		# Starke Bremskraft
		brake = handbrake_force
		
		# Reduziere Reibung an Hinterrädern für besseres Driften
		wheel_rear_left.wheel_friction_slip = wheel_friction * handbrake_rear_friction
		wheel_rear_right.wheel_friction_slip = wheel_friction * handbrake_rear_friction
	else:
		# Normale Reibung wiederherstellen
		wheel_rear_left.wheel_friction_slip = wheel_friction
		wheel_rear_right.wheel_friction_slip = wheel_friction
