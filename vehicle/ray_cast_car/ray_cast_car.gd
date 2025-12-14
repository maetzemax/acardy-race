extends RigidBody3D
class_name RayCastCar

@export var wheels: Array[RayCastWheel]
@export var acceleration := 600.0
@export var max_speed := 20.0
@export var accel_curve : Curve
@export var tire_turn_speed := 2.0
@export var tire_max_turn_degrees := 25

@export var skid_marks: Array[GPUParticles3D]
@export var show_debug := false

@onready var total_wheels := wheels.size()

var motor_input := 0
var hand_break := false
var is_slipping := false

func _get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - to_global(center_of_mass))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("handbreak"):
		hand_break = true
		is_slipping = true
	elif event.is_action_released("handbreak"):
		hand_break = false

	if event.is_action_pressed("throttle"):
		motor_input = 1
	elif event.is_action_released("throttle"):
		motor_input = 0

	if event.is_action_pressed("brake"):
		motor_input = -1
	elif event.is_action_released("brake"):
		motor_input = 0


func _basic_steering_rotation(wheel: RayCastWheel, delta: float) -> void:
	if not wheel.is_steer: return

	var turn_input = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	wheel.rotation.y = move_toward(wheel.rotation.y, turn_input * deg_to_rad(tire_max_turn_degrees), delta * tire_turn_speed)


func _physics_process(delta: float) -> void:
	if show_debug: DebugDraw3D.draw_arrow_ray(global_position, linear_velocity, 0.5, Color.GREEN, 0.05)

	var id := 0
	var grounded := false
	for wheel in wheels:
		wheel.apply_wheel_physics(self)
		_basic_steering_rotation(wheel, delta)

		if Input.is_action_pressed("brake"):
			wheel.is_braking = true
		else:
			wheel.is_braking = false

		# Skid marks
		skid_marks[id].global_position = wheel.get_collision_point() + Vector3.UP * 0.01
		skid_marks[id].look_at(skid_marks[id].global_position + global_basis.z)

		if not hand_break and wheel.grip_factor < 0.2:
			is_slipping = false
			skid_marks[id].emitting = false

		if hand_break and not skid_marks[id].emitting:
			skid_marks[id].emitting = true

		if wheel.is_colliding():
			grounded = true

		id += 1

	if grounded:
		center_of_mass = Vector3.ZERO
	else:
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN*0.5
