extends Resource
class_name VehiclePreset

## Fahrzeug-Preset für verschiedene Fahrzeugtypen

@export_group("Vehicle Info")
@export var preset_name: String = "Sport Car"
@export var description: String = "Balanced performance vehicle"

@export_group("Physics")
@export var mass: float = 1200.0
@export var center_of_mass_offset: Vector3 = Vector3(0, -0.3, 0)

@export_group("Performance")
@export var engine: VehicleEngine
@export var transmission: VehicleTransmission

@export_group("Handling")
@export var max_steering_angle: float = 0.65
@export var steering_speed: float = 1.5
@export var wheel_friction: float = 10.5

@export_group("Braking")
@export var normal_brake_force: float = 5.0
@export var handbrake_force: float = 10.0
@export var handbrake_rear_friction: float = 0.5

@export_group("Suspension")
@export var suspension_stiffness: float = 40.0
@export var suspension_damping: float = 2500.0
@export var anti_roll_force: float = 30.0

@export_group("Aerodynamics")
@export var downforce_factor: float = 100.0
@export var drag_coefficient: float = 0.35
