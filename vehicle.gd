extends VehicleBody3D

# Modulares System
@export var use_preset: bool = false
@export var vehicle_preset: VehiclePreset
@export var custom_engine: VehicleEngine
@export var custom_transmission: VehicleTransmission

var throttle: float = 0.0
var steering_input: float = 0.0

@onready var wheel_front_left: VehicleWheel3D = $WheelFrontLeft
@onready var wheel_front_right: VehicleWheel3D = $WheelFrontRight
@onready var wheel_rear_left: VehicleWheel3D = $WheelRearLeft
@onready var wheel_rear_right: VehicleWheel3D = $WheelRearRight

# Engine & Transmission (werden aus Preset oder Custom geladen)
var engine: VehicleEngine
var transmission: VehicleTransmission

@export_group("Speed")
@export var acceleration: float = 120
@export var max_engine_power: float = 300.0  # PS/Leistung des Motors (erhöht für bessere Performance)
@export var power_to_weight_ratio: float = 0.25  # 300 PS / 1200 kg (etwas sportlicher)
@export var vehicle_linear_velocity: float = 0.0

@export_group("Steering & Brake")
@export var steering_speed = 1.5
@export var max_steering_angle = 0.65
@export var normal_brake_force: float = 3.0  # Normale Bremse (S-Taste)
@export var handbrake_force: float = 8.0  # Handbremse (Space)
@export var handbrake_rear_friction: float = 0.5  # Reduzierte Reibung hinten beim Driften
var handbrake: bool = false
var is_braking: bool = false
var brake_input: float = 0.0  # Neue Variable für smooth brake input (0-1)

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
@export var max_rpm: float = 7000.0  # Realistischer für Straßenauto
@export var idle_rpm: float = 1000.0
@export var gear_ratios: Array[float] = [0.0, 3.6, 2.4, 1.8, 1.4, 1.1, 0.9]  # Bessere Staffelung
@export var final_drive_ratio: float = 3.7  # Etwas höher für bessere Performance
@export var auto_transmission: bool = true
@export var shift_up_rpm: float = 6500.0
@export var shift_down_rpm: float = 2500.0
@export var torque_curve_peak: float = 0.70  # Peak bei 70% (4900 RPM)

var current_gear: int = 1
var current_rpm: float = 1000.0


func _ready():
	_load_vehicle_configuration()


func _load_vehicle_configuration():
	"""Lädt Konfiguration aus Preset oder erstellt Standard-Module"""
	if use_preset and vehicle_preset != null:
		# Lade aus Preset
		if vehicle_preset.engine:
			engine = vehicle_preset.engine
		if vehicle_preset.transmission:
			transmission = vehicle_preset.transmission
		
		# Übernehme andere Preset-Werte
		mass = vehicle_preset.mass
		max_steering_angle = vehicle_preset.max_steering_angle
		steering_speed = vehicle_preset.steering_speed
		normal_brake_force = vehicle_preset.normal_brake_force
		handbrake_force = vehicle_preset.handbrake_force
	else:
		# Benutze Custom oder erstelle Standard
		if custom_engine:
			engine = custom_engine
		if custom_transmission:
			transmission = custom_transmission


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
	brake_input = Input.get_action_strength("brake")  # 0.0 bis 1.0 für smooth braking
	is_braking = brake_input > 0.01  # Kleine Toleranz
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
	# Realistisches Drehmoment-System mit Power Curve
	var rpm_percent = (current_rpm - idle_rpm) / (max_rpm - idle_rpm)
	rpm_percent = clamp(rpm_percent, 0.0, 1.0)
	
	# Realistische Drehmoment-Kurve (Peak bei 75% RPM)
	var torque_multiplier = 1.0 - abs(rpm_percent - torque_curve_peak) / torque_curve_peak
	torque_multiplier = clamp(torque_multiplier * 1.5, 0.3, 1.0)  # Min 30%, Max 100%
	
	# RPM Limiter - Stark reduzierte Leistung bei über 95% max RPM
	var rpm_limiter = 1.0
	if rpm_percent > 0.95:  # Bei 95% (7600 RPM von 8000)
		# Dramatischer Abfall der Leistung
		rpm_limiter = max(0.05, 1.0 - (rpm_percent - 0.95) * 20.0)  # Bis auf 5% reduziert
	elif rpm_percent > 0.90:  # Bei 90% beginnt Leistungsabfall
		rpm_limiter = 1.0 - (rpm_percent - 0.90) * 2.0  # Sanfter Übergang
	
	var gear_ratio = 1.0
	if current_gear > 0 and current_gear < gear_ratios.size():
		gear_ratio = gear_ratios[current_gear]
	
	# Realistische Kraftberechnung: PS * Drehmoment * Gang * Gewichtsverhältnis * RPM-Limiter
	var base_force = max_engine_power * power_to_weight_ratio * 70.0  # Erhöht von 50.0 auf 70.0 für bessere höhere Gänge
	var effective_power = base_force * torque_multiplier * gear_ratio * rpm_limiter
	
	# Reduziere Kraft bei sehr hohen Geschwindigkeiten (Luftwiderstand)
	var speed_limiter = 1.0
	if vehicle_linear_velocity > 25.0:  # Luftwiderstand ab 25 m/s (~90 km/h)
		speed_limiter = max(0.25, 1.0 - (vehicle_linear_velocity - 25.0) * 0.015)  # Sanfter
	
	engine_force = throttle * effective_power * speed_limiter


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
	# Normale Bremse (alle 4 Räder) mit smooth input
	if is_braking:
		brake = brake_input * normal_brake_force  # Smooth 0-100%
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
