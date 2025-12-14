class_name VehicleTransmission
extends Node

var _current_rpm: float = 0.0

@export_group("RPM Settings")
@export var idle_rpm: int = 1500
@export var min_rpm: int = 1500
@export var max_rpm: int = 12000
@export var rpm_lerp_speed: float = 8.0 

@export_group("Transmission")
@export var final_drive_ratio: float = 6.0
@export var gear_ratios: Array[float] = [
	-2.5,  # Reverse (Index 0)
	0.0,   # Neutral (Index 1)
	4,
	2.3,
	1.7,
	1.3,
	1.1,
	0.8,
]

@export_group("Wheel")
@export var wheel_radius: float = 0.37

var current_gear: int = 2


func get_current_rpm() -> float:
	return _current_rpm


func calculate_rpm_from_wheel_speed(wheel_speed_mps: float, delta: float) -> float:
	if current_gear <= 1:
		_current_rpm = lerp(_current_rpm, float(idle_rpm), delta * rpm_lerp_speed)
		return _current_rpm

	var wheel_circumference = 2.0 * PI * wheel_radius
	var wheel_rpm = (wheel_speed_mps / wheel_circumference) * 60.0
	
	if abs(wheel_rpm) < 0.1:
		_current_rpm = lerp(_current_rpm, float(idle_rpm), delta * rpm_lerp_speed * 2.0)
		return _current_rpm
	

	var current_gear_ratio = abs(gear_ratios[current_gear])
	var target_rpm = abs(wheel_rpm) * current_gear_ratio * final_drive_ratio
	
	target_rpm = clamp(target_rpm, float(min_rpm), float(max_rpm))
	_current_rpm = lerp(_current_rpm, target_rpm, delta * rpm_lerp_speed)
	
	return _current_rpm


func calculate_transfered_force(engine_force: float, throttle_strength: float) -> float:
	if current_gear == 1:
		return 0.0
	
	var current_gear_ratio = gear_ratios[current_gear]
	
	var power = engine_force * throttle_strength * abs(current_gear_ratio) * final_drive_ratio
	
	var rpm_efficiency = calculate_rpm_efficiency()
	power *= rpm_efficiency
	
	if current_gear == 0:
		power = -abs(power)
	
	return power


func calculate_rpm_efficiency() -> float:
	var efficiency: float
	
	if _current_rpm < 2000.0:
		efficiency = (_current_rpm - float(idle_rpm)) / (2000.0 - float(idle_rpm)) * 0.5
		efficiency = max(0.1, efficiency)
	elif _current_rpm < 4000.0:
		var progress = (_current_rpm - 2000.0) / 2000.0
		efficiency = 0.5 + (progress * 0.4)
	elif _current_rpm < 10000.0:
		efficiency = 1.0
	elif _current_rpm < 11500.0:
		var progress = (_current_rpm - 10000.0) / 1500.0
		efficiency = 1.0 - (progress * 0.2)
	else:
		var progress = (_current_rpm - 11500.0) / 500.0
		efficiency = 0.05 - (progress * 0.5)
	
	return clamp(efficiency, 0.1, 1.0)


func should_shift_up() -> bool:
	return _current_rpm > float(max_rpm) * 0.92 and current_gear < gear_ratios.size() - 1


func should_shift_down() -> bool:
	return _current_rpm < 4000.0 and current_gear > 2


func shift_up() -> void:
	if current_gear < gear_ratios.size() - 1:
		current_gear += 1


func shift_down() -> void:
	if current_gear != 0:
		current_gear -= 1


func get_gear_display() -> String:
	match current_gear:
		0: return "R"
		1: return "N"
		_: return str(current_gear - 1)
