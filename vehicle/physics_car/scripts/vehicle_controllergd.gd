extends Node3D
## Controls any [Vehicle] node using custom-defined input maps.
class_name VehicleController

## The [Vehicle] that this vehicle controller will send
## input values to. Required for the vehicle controller to work properly.
@export var vehicle_node : Vehicle

@export_group("Input Maps", "string_")
## The name of the input map used for this vehicle's brakes input.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_brake_input: String = "brake"
## The name of the input map used for steering this vehicle left.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_steer_left: String = "turn_left"
## The name of the input map used for steering this vehicle right.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_steer_right: String = "turn_right"
## The name of the input map used for this vehicle's throttle input.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_throttle_input: String = "throttle"
## The name of the input map used for this vehicle's handbrake input.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_handbrake_input: String = "handbrake"
## The name of the input map used for this vehicle's clutch input.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_clutch_input: String = "clutch"
## The name of the input map used for enabling or disabling
## the transmission of this vehicle.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_toggle_transmission: String = "toggle_transmission"
## The name of the input map used for shifting up a gear when
## manual transmission is enabled.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_shift_up: String = "shift_up"
## The name of the input map used for shifting down a gear when
## manual transmission is enabled.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_shift_down: String = "shift_down"

var input_steering_deadzone: float = 0.0
var input_throttle_deadzone: float = 0.0
var input_brake_deadzone: float = 0.0


func _ready():
	load_input_deadzones()

func _physics_process(_delta):
	if string_brake_input != "":
		var brake_input = Input.get_action_strength(string_brake_input)
		brake_input = _apply_deadzone_remap(brake_input, input_brake_deadzone)
		vehicle_node.brake_input = brake_input

	if string_steer_left != "" and string_steer_right != "":
		var steering_raw = Input.get_action_strength(string_steer_left) - Input.get_action_strength(string_steer_right)
		steering_raw = _apply_deadzone_remap(steering_raw, input_steering_deadzone)
		vehicle_node.steering_input = steering_raw

	if string_throttle_input != "":
		var throttle_input = Input.get_action_strength(string_throttle_input)
		throttle_input = _apply_deadzone_remap(throttle_input, input_throttle_deadzone)
		vehicle_node.throttle_input = pow(throttle_input, 2.0)

	if string_handbrake_input != "":
		vehicle_node.handbrake_input = Input.get_action_strength(string_handbrake_input)
	
	if string_clutch_input != "":
		vehicle_node.clutch_input = clampf(Input.get_action_strength(string_clutch_input) + Input.get_action_strength(string_handbrake_input), 0.0, 1.0)
	
	if string_toggle_transmission != "":
		if Input.is_action_just_pressed(string_toggle_transmission):
			vehicle_node.automatic_transmission = not vehicle_node.automatic_transmission
	
	if string_shift_up != "":
		if Input.is_action_just_pressed(string_shift_up):
			vehicle_node.manual_shift(1)
	
	if string_shift_down != "":
		if Input.is_action_just_pressed(string_shift_down):
			vehicle_node.manual_shift(-1)
	
	# Reverse gear logic

	if vehicle_node.current_gear == -1:
		vehicle_node.brake_input = Input.get_action_strength(string_throttle_input)
		vehicle_node.throttle_input = Input.get_action_strength(string_brake_input)


func _apply_deadzone_remap(input_value: float, deadzone: float) -> float:
	var abs_value = abs(input_value)
	var sign_value = sign(input_value)
	
	if abs_value < deadzone:
		return 0.0
	
	var remapped = (abs_value - deadzone) / (1.0 - deadzone)
	return remapped * sign_value


func load_input_deadzones():
	var deadzone: DeadzoneSettings = OptionsService.get_deadzone_settings()
	
	if not deadzone:
		return
	
	input_throttle_deadzone = deadzone.throttle
	input_brake_deadzone = deadzone.brake
	input_steering_deadzone = deadzone.steer
