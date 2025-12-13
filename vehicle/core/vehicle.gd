extends VehicleBody3D

var throttle: float = 0.0
var steering_input: float = 0.0

@onready var wheel_front_left: VehicleWheel3D = $WheelFrontLeft
@onready var wheel_front_right: VehicleWheel3D = $WheelFrontRight
@onready var wheel_rear_left: VehicleWheel3D = $WheelRearLeft
@onready var wheel_rear_right: VehicleWheel3D = $WheelRearRight
@onready var engine_sound: AudioStreamPlayer = $AudioStreamPlayer

@export_group("Speed")
@export var acceleration: float = 120
@export var vehicle_linear_velocity: float = 0.0

@export_group("Transmission")
@export var transmission: VehicleTransmission
@export var use_automatic_transmission: bool = true  # Auto-Gangwechsel

@export_group("Steering & Brake")
@export var steering_speed = 1.5
@export var max_steering_angle = 0.65
@export var normal_brake_force: float = 3.0

@export_group("Supension Settings")
@export var suspension_stiff_value: float = 200.0

@export_group("Stability Control")
@export var roll_influence: float = 0.1
var anti_roll_torque: Vector3
var downforce: Vector3
@export var anti_roll_force: float = 50.0
@export var anti_pitch_force: float = 200.0
@export var downforce_factor: float = 120.0
@export var downforce_front_bias: float = 0.5

@export_group("Engine Sound (RPM-based)")
@export var min_pitch: float = 0.8
@export var max_pitch: float = 2.2
@export var min_volume: float = -10.0
@export var max_volume: float = 0.0

@export_group("Controller Vibration")
@export var vibration_enabled: bool = true
@export var engine_vibration_strength: float = 0.15
@export var collision_vibration_strength: float = 0.8
@export var collision_vibration_duration: float = 0.3
@export var offroad_vibration_strength: float = 0.4

# Input Deadzones
var input_steering_deadzone: float = 0.0
var input_throttle_deadzone: float = 0.0
var input_brake_deadzone: float = 0.0
var brake_strength: float = 0.0

# Vibration state
var collision_vibration_timer: float = 0.0
var last_collision_impulse: float = 0.0

# RPM state
var current_engine_rpm: float = 0.0


func _ready():
	set_input_deadzones()


func _physics_process(delta: float):
	for wheel in [wheel_front_left, wheel_front_right]:
		wheel.suspension_stiffness = suspension_stiff_value
		
	for wheel in [wheel_rear_left, wheel_rear_right]:
		wheel.suspension_stiffness = suspension_stiff_value
	
	_handle_vehicle_control(delta)
	_handle_vehicle_velocity()
	_handle_rpm_calculation(delta)
	_handle_vehicle_transmission()
	_handle_automatic_shifting()
	_handle_anti_roll()
	_handle_brake()
	_handle_engine_sound()
	_handle_controller_vibration(delta)


func _handle_vehicle_control(delta):
	var throttle_input = Input.get_action_strength("throttle")
	var brake_input = Input.get_action_strength("brake")
	var steering_raw = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	
	throttle_input = _apply_deadzone_remap(throttle_input, input_throttle_deadzone)
	brake_input = _apply_deadzone_remap(brake_input, input_brake_deadzone)
	steering_raw = _apply_deadzone_remap(steering_raw, input_steering_deadzone)
	
	brake_strength = brake_input
	
	# Gangwechsel-Logik mit Rückwärtsgang
	if Input.is_action_just_pressed("shift_up"):
		if transmission.current_gear == 0:  # Von Reverse zu Neutral
			transmission.current_gear = 1
			print("Gang: Neutral")
		elif transmission.current_gear == 1:  # Von Neutral zu 1st
			transmission.current_gear = 2
			print("Gang: 1")
		elif not use_automatic_transmission:  # Normale Hochschaltung
			transmission.shift_up()
	
	elif Input.is_action_just_pressed("shift_down"):
		if transmission.current_gear == 2:  # Von 1st zu Neutral
			transmission.current_gear = 1
			print("Gang: Neutral")
		elif transmission.current_gear == 1:  # Von Neutral zu Reverse
			transmission.current_gear = 0
			print("Gang: Rückwärts")
		elif not use_automatic_transmission:  # Normale Runterschaltung
			transmission.shift_down()
	
	# Throttle anwenden - im Rückwärtsgang Motor umkehren
	if transmission.current_gear == 0:  # Reverse
		throttle = -throttle_input  # Negativer Throttle für Rückwärts
	else:
		throttle = throttle_input
	
	steering_input = steering_raw
	steering = move_toward(steering, steering_input * max_steering_angle, delta * steering_speed)


func _handle_vehicle_velocity():
	vehicle_linear_velocity = linear_velocity.length()


func _handle_rpm_calculation(delta: float):
	if transmission == null:
		return
	
	# Durchschnittliche Rad-Geschwindigkeit berechnen (nur Antriebsräder = Hinterräder)
	var rear_wheel_speed = (wheel_rear_left.get_rpm() + wheel_rear_right.get_rpm()) / 2.0
	
	# Von wheel RPM zu m/s umrechnen
	var wheel_circumference = 2.0 * PI * transmission.wheel_radius
	var wheel_speed_mps = (rear_wheel_speed / 60.0) * wheel_circumference
	
	# RPM aus Radgeschwindigkeit berechnen
	current_engine_rpm = transmission.calculate_rpm_from_wheel_speed(wheel_speed_mps, delta)


func _handle_vehicle_transmission():
	if transmission == null:
		engine_force = acceleration * throttle
		return
	
	engine_force = transmission.calculate_transfered_force(acceleration, throttle)


func _handle_automatic_shifting():
	if not use_automatic_transmission or transmission == null:
		return
	
	# Nur schalten wenn Gas gegeben wird (nicht beim Bremsen)
	if throttle > 0.1:
		if transmission.should_shift_up():
			transmission.shift_up()
		elif transmission.should_shift_down() and vehicle_linear_velocity > 3.0:
			transmission.shift_down()


func _handle_anti_roll():
	var roll_angle = global_rotation.x
	
	anti_roll_torque = -global_transform.basis.z * roll_angle * anti_roll_force
	apply_torque(anti_roll_torque)
	
	var pitch_angle = global_rotation.z
	var anti_pitch_torque = -global_transform.basis.x * pitch_angle * anti_pitch_force
	apply_torque(anti_pitch_torque)
	
	var speed_squared = vehicle_linear_velocity * vehicle_linear_velocity
	var total_downforce = speed_squared * downforce_factor * 0.01
	
	var front_downforce_pos = (wheel_front_left.global_position + wheel_front_right.global_position) / 2.0
	var front_force = -global_transform.basis.y * total_downforce * downforce_front_bias
	apply_force(front_force, front_downforce_pos - global_position)
	
	var rear_downforce_pos = (wheel_rear_left.global_position + wheel_rear_right.global_position) / 2.0
	var rear_force = -global_transform.basis.y * total_downforce * (1.0 - downforce_front_bias)
	apply_force(rear_force, rear_downforce_pos - global_position)
	
	for wheel in [wheel_front_left, wheel_front_right, wheel_rear_left, wheel_rear_right]:
		wheel.wheel_roll_influence = roll_influence

func _handle_brake():
	brake = brake_strength * normal_brake_force


func _apply_deadzone_remap(input_value: float, deadzone: float) -> float:
	var abs_value = abs(input_value)
	var sign_value = sign(input_value)
	
	if abs_value < deadzone:
		return 0.0
	
	var remapped = (abs_value - deadzone) / (1.0 - deadzone)
	return remapped * sign_value


func set_input_deadzones():
	var deadzone: DeadzoneSettings = OptionsService.get_deadzone_settings()
	input_throttle_deadzone = deadzone.throttle
	input_brake_deadzone = deadzone.brake
	input_steering_deadzone = deadzone.steer


func _handle_engine_sound():
	if engine_sound == null or transmission == null:
		return
	
	if not engine_sound.playing:
		engine_sound.play()
	
	# RPM-basierte Audio-Berechnung
	var rpm_factor = (current_engine_rpm - float(transmission.min_rpm)) / float(transmission.max_rpm - transmission.min_rpm)
	rpm_factor = clamp(rpm_factor, 0.0, 1.0)
	
	# Pitch basiert auf RPM
	engine_sound.pitch_scale = lerp(min_pitch, max_pitch, rpm_factor)
	
	# Volume basiert auf Throttle
	var throttle_factor = abs(throttle)
	var target_volume = lerp(min_volume, max_volume, throttle_factor)
	engine_sound.volume_db = target_volume


func is_off_track() -> bool:
	return wheel_front_left.is_off_track and wheel_front_right.is_off_track and wheel_rear_left.is_off_track and wheel_rear_right.is_off_track


func _handle_controller_vibration(delta: float):
	if not vibration_enabled:
		return
	
	if collision_vibration_timer > 0.0:
		collision_vibration_timer -= delta
		var fade = collision_vibration_timer / collision_vibration_duration
		var intensity = last_collision_impulse * collision_vibration_strength * fade
		Input.start_joy_vibration(0, intensity, intensity, delta)
		return
	
	var offroad_wheels = 0
	for wheel in [wheel_front_left, wheel_front_right, wheel_rear_left, wheel_rear_right]:
		if wheel.is_off_track:
			offroad_wheels += 1
	
	if offroad_wheels > 0 and vehicle_linear_velocity > 2.0:
		var offroad_factor = float(offroad_wheels) / 4.0
		var speed_factor = clamp(vehicle_linear_velocity / 20.0, 0.0, 1.0)
		var rumble = offroad_vibration_strength * offroad_factor * speed_factor
		var variation = sin(Time.get_ticks_msec() * 0.02) * 0.1
		Input.start_joy_vibration(0, rumble + variation, rumble, delta)
		return
	
	# RPM-basierte Engine Vibration
	var rpm_factor = clamp(current_engine_rpm / float(transmission.max_rpm), 0.0, 1.0)
	var throttle_vibration = abs(throttle) * engine_vibration_strength
	var engine_rumble = (throttle_vibration * 0.7) + (rpm_factor * engine_vibration_strength * 0.3)
	
	Input.start_joy_vibration(0, engine_rumble * 0.5, engine_rumble * 0.3, delta)


# Debug Info abrufen
func get_debug_info() -> Dictionary:
	if transmission == null:
		return {}
	
	return {
		"rpm": int(current_engine_rpm),
		"gear": transmission.get_gear_display(),
		"speed_kmh": int(vehicle_linear_velocity * 3.6),
		"throttle": snappedf(throttle, 0.01)
	}
