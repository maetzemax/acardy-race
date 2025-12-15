extends RigidBody3D
class_name RayCastCar

var throttle: float = 0.0
var steering_input: float = 0.0

@export_group("Engine")
@export var acceleration = 3200.0  # Schnellere Beschleunigung für Formel-Auto
@export var max_speed = 64.0  # ~230 km/h (64 m/s)
@export var accel_curve: Curve

@export_group("Steering")
@export var wheels: Array[RayCastWheel]
@export var skid_marks: Array[GPUParticles3D]
@export var tire_turn_speed = 1.0  # Etwas langsamer für schwereres Gefühl
@export var tire_max_turn_degrees = 11.0  # Leicht reduziert

@export_group("Handling")
@export var front_grip_multiplier: float = 1.4  # Noch mehr Grip vorne!
@export var rear_grip_multiplier: float = 1.2  # Auch hinten deutlich mehr
@export var brake_grip_front: float = 1.6
@export var brake_grip_rear: float = 0.6
@export var centrifugal_force_multiplier: float = 1.5  # Reduziert - war zu stark
@export var skid_threshold: float = 0.40

@export_group("Engine Sound")
@export var min_pitch: float = 0.8
@export var max_pitch: float = 2.2
@export var min_volume: float = -20
@export var max_volume: float = -18

@export_group("Camera")
@export var cockpit_camera: Camera3D
@export var chase_camera: Camera3D

@export_group("Debug")
@export var show_debug = false

@onready var total_wheels = wheels.size()
@onready var engine_sound: AudioStreamPlayer = $AudioStreamPlayer

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

var motor_input: float = 0
var hand_break = false
var is_slipping = false


func _get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - to_global(center_of_mass))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("handbreak"):
		hand_break = true
		is_slipping = true
	elif event.is_action_released("handbreak"):
		hand_break = false


func _basic_steering_rotation(wheel: RayCastWheel, delta: float) -> void:
	if not wheel.is_steer: return

	wheel.rotation.y = move_toward(wheel.rotation.y, steering_input * deg_to_rad(tire_max_turn_degrees), delta * tire_turn_speed)


func _ready():
	set_input_deadzones()


func _physics_process(delta: float) -> void:
	if show_debug: DebugDraw3D.draw_arrow_ray(global_position, linear_velocity, 0.5, Color.GREEN, 0.05)
	
	_handle_vehicle_control(delta)
	_handle_engine_sound()
	
	# Fliehkraft in Kurven
	_apply_centrifugal_force()
	
	if brake_strength > 0:
		motor_input = -brake_strength
	elif throttle > 0:
		motor_input = throttle
	else:
		motor_input = 0

	var id = 0
	var grounded = false
	for wheel in wheels:
		wheel.apply_wheel_physics(self)
		_basic_steering_rotation(wheel, delta)

		wheel.is_braking = brake_strength > 0

		# Skid marks - angepasster Threshold
		skid_marks[id].global_position = wheel.get_collision_point() + Vector3.UP * 0.01
		skid_marks[id].look_at(skid_marks[id].global_position + global_basis.z)
		
		if not hand_break and wheel.grip_factor < skid_threshold:  # Geändert von 0.05
			is_slipping = false
			skid_marks[id].emitting = false
		elif not hand_break:
			is_slipping = false
			skid_marks[id].emitting = true

		if hand_break and not skid_marks[id].emitting:
			skid_marks[id].emitting = true

		if wheel.is_colliding():
			grounded = true

		id += 1

	if grounded:
		center_of_mass = Vector3(0, -0.1, 0)  # Leicht nach unten = schwerer Gefühl
	else:
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN*0.6  # Tiefer für bessere Stabilität in der Luft


func _handle_vehicle_control(_delta):
	var throttle_input = Input.get_action_strength("throttle")
	var brake_input = Input.get_action_strength("brake")
	var steering_raw = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	
	throttle_input = _apply_deadzone_remap(throttle_input, input_throttle_deadzone)
	brake_input = _apply_deadzone_remap(brake_input, input_brake_deadzone)
	steering_raw = _apply_deadzone_remap(steering_raw, input_steering_deadzone)
	
	throttle = throttle_input
	brake_strength = brake_input
	steering_input = steering_raw


func _handle_engine_sound():
	if engine_sound == null:
		return
	
	if not engine_sound.playing:
		engine_sound.play()
	
	# RPM-basierte Audio-Berechnung
	var rpm_factor = linear_velocity.length() / max_speed
	rpm_factor = clamp(rpm_factor, 0.0, 1.0)
	
	# Pitch basiert auf RPM
	engine_sound.pitch_scale = lerp(min_pitch, max_pitch, rpm_factor)
	
	# Volume basiert auf Throttle
	var throttle_factor = abs(throttle)
	var target_volume = lerp(min_volume, max_volume, throttle_factor)
	engine_sound.volume_db = target_volume


func _apply_deadzone_remap(input_value: float, deadzone: float) -> float:
	var abs_value = abs(input_value)
	var sign_value = sign(input_value)
	
	if abs_value < deadzone:
		return 0.0
	
	var remapped = (abs_value - deadzone) / (1.0 - deadzone)
	return remapped * sign_value


func set_input_deadzones():
	var deadzone: DeadzoneSettings = OptionsService.get_deadzone_settings()
	
	if not deadzone:
		return
	
	input_throttle_deadzone = deadzone.throttle
	input_brake_deadzone = deadzone.brake
	input_steering_deadzone = deadzone.steer


func is_off_track() -> bool:
	return wheels[0].is_off_track and wheels[1].is_off_track and wheels[2].is_off_track and wheels[3].is_off_track


func next_perspective():
	if chase_camera.current:
		cockpit_camera.make_current()
	else:
		chase_camera.make_current()


func _apply_centrifugal_force():
	# Berechne Fliehkraft basierend auf Geschwindigkeit und Lenkung
	var speed = linear_velocity.length()
	
	if speed < 5.0:  # Nur bei ausreichender Geschwindigkeit
		return
	
	# Berechne die Zentrifugalkraft: F = m * v² / r
	# r (Kurvenradius) wird über den Lenkwinkel approximiert
	if abs(steering_input) > 0.1:
		var lateral_velocity = global_basis.x.dot(linear_velocity)
		
		# Zentrifugalkraft nach außen (seitlich)
		var centrifugal = global_basis.x * lateral_velocity * centrifugal_force_multiplier * speed * abs(steering_input)
		
		apply_central_force(centrifugal)
		
		if show_debug: 
			DebugDraw3D.draw_arrow_ray(global_position, centrifugal/mass, 0.5, Color.ORANGE, 0.05)
