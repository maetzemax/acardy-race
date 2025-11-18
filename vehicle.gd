extends VehicleBody3D

var throttle: float = 0.0
var steering_input: float = 0.0
var current_gear: int = 1  # 1 = Vorwärts, -1 = Rückwärts

@onready var wheel_front_left: VehicleWheel3D = $WheelFrontLeft
@onready var wheel_front_right: VehicleWheel3D = $WheelFrontRight
@onready var wheel_rear_left: VehicleWheel3D = $WheelRearLeft
@onready var wheel_rear_right: VehicleWheel3D = $WheelRearRight
@onready var engine_sound: AudioStreamPlayer = $AudioStreamPlayer

@export_group("Speed")
@export var acceleration: float = 120
@export var max_engine_power: float = 300.0
@export var vehicle_linear_velocity: float = 0.0

@export_group("Steering & Brake")
@export var steering_speed = 1.5
@export var max_steering_angle = 0.65
@export var normal_brake_force: float = 3.0

@export_group("Supension Settings")
@export var wheel_friction: float = 10.5
@export var suspension_stiff_value: float = 0.0

# Friction-Werte für verschiedene Untergründe
var friction_values = {
	"track": 1.00,
	"grass": 0.2,
}

@export_group("Stability Control")
@export var roll_influence: float = 0.1
var anti_roll_torque: Vector3
var downforce: Vector3
@export var anti_roll_force: float = 50.0
@export var anti_pitch_force: float = 80.0
@export var downforce_factor: float = 20.0
@export var downforce_front_bias: float = 0.55

@export_group("Engine Sound")
@export var min_pitch: float = 0.8
@export var max_pitch: float = 2.0
@export var min_volume: float = -10.0
@export var max_volume: float = 0.0

# Input Deadzones
var input_steering_deadzone: float = 0.0
var input_accelerate_deadzone: float = 0.05
var input_brake_deadzone: float = 0.05
var brake_strength: float = 0.0


func _physics_process(delta: float):
	_handle_friction()
	
	for wheel in [wheel_front_left, wheel_front_right]:
		wheel.suspension_stiffness = suspension_stiff_value
		
	for wheel in [wheel_rear_left, wheel_rear_right]:
		wheel.suspension_stiffness = suspension_stiff_value
	
	_handle_vehicle_control(delta)
	_handle_vehicle_velocity()
	_handle_anti_roll()
	_handle_brake()
	_handle_engine_sound()


func _handle_vehicle_control(delta):
	# Separate Inputs für Gas und Bremse
	var accelerate_input = Input.get_action_strength("accelerate")
	var brake_input = Input.get_action_strength("brake")
	var steering_raw = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	
	# Deadzone anwenden und remappen (0.0-deadzone wird zu 0%, deadzone-1.0 wird zu 0%-100%)
	accelerate_input = _apply_deadzone_remap(accelerate_input, input_accelerate_deadzone)
	brake_input = _apply_deadzone_remap(brake_input, input_brake_deadzone)
	steering_raw = _apply_deadzone_remap(steering_raw, input_steering_deadzone)
	
	brake_strength = brake_input
	
	if Input.is_action_just_pressed("shift_up"):
		current_gear = 1  # Vorwärts
		print("Gang: Vorwärts")
	elif Input.is_action_just_pressed("shift_down"):
		current_gear = -1  # Rückwärts
		print("Gang: Rückwärts")
	
	# Throttle mit Gang multiplizieren
	throttle = accelerate_input * current_gear
	
	steering_input = steering_raw
	steering = move_toward(steering, steering_input * max_steering_angle, delta * steering_speed)


func _handle_vehicle_velocity():
	vehicle_linear_velocity = linear_velocity.length()
	
	engine_force = throttle * acceleration


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


func _handle_friction():
	"""Passt Friction dynamisch basierend auf Untergrund an"""
	for wheel in [wheel_front_left, wheel_front_right, wheel_rear_left, wheel_rear_right]:
		if wheel == null:
			continue
		
		var surface_type = _detect_surface(wheel)
		var friction = friction_values.get(surface_type, wheel_friction)
		
		# Hinterräder leicht weniger Friction für besseres Handling
		if wheel == wheel_rear_left or wheel == wheel_rear_right:
			friction -= 0.02
		
		wheel.wheel_friction_slip = friction


func _detect_surface(wheel: VehicleWheel3D) -> String:
	"""Detektiert Oberfläche unter dem Rad via Raycast"""
	var space_state = get_world_3d().direct_space_state
	var ray_origin = wheel.global_position
	var ray_end = ray_origin + Vector3.DOWN * 1.0
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.get("collider")
		if collider:
			# Prüfe Gruppen
			if collider.is_in_group("grass"):
				return "grass"
			elif collider.is_in_group("track"):
				return "track"
	
	return "track"  # Default


func _apply_deadzone_remap(input_value: float, deadzone: float) -> float:
	"""
	Wendet Deadzone an und remappt den Wert:
	- Werte unter deadzone → 0.0
	- Werte von deadzone bis 1.0 → linear auf 0.0 bis 1.0 gemappt
	"""
	var abs_value = abs(input_value)
	var sign_value = sign(input_value)
	
	if abs_value < deadzone:
		return 0.0
	
	# Remap von [deadzone, 1.0] zu [0.0, 1.0]
	var remapped = (abs_value - deadzone) / (1.0 - deadzone)
	return remapped * sign_value


func set_input_deadzones(steering_dz: float, accelerate_dz: float, brake_dz: float):
	"""Wird vom Input Settings UI aufgerufen"""
	input_steering_deadzone = steering_dz
	input_accelerate_deadzone = accelerate_dz
	input_brake_deadzone = brake_dz
	print("Deadzones gesetzt: Steering=%.2f, Accelerate=%.2f, Brake=%.2f" % [steering_dz, accelerate_dz, brake_dz])


func _handle_engine_sound():
	"""Passt Engine Sound an Geschwindigkeit und Throttle an"""
	if engine_sound == null:
		return
	
	if not engine_sound.playing:
		engine_sound.play()
	
	var speed_factor = clamp(vehicle_linear_velocity / 30.0, 0.0, 1.0)  # 0-30 m/s
	var throttle_factor = abs(throttle)
	
	var rpm_factor = (throttle_factor * 0.7) + (speed_factor * 0.3)
	rpm_factor = clamp(rpm_factor, 0.0, 1.0)
	
	engine_sound.pitch_scale = lerp(min_pitch, max_pitch, rpm_factor)
	
	var target_volume = lerp(min_volume, max_volume, throttle_factor)
	engine_sound.volume_db = target_volume
