extends Resource
class_name VehicleEngine

## Motor-Konfiguration für modulares Fahrzeugsystem

@export_group("Engine Performance")
@export var engine_name: String = "Standard Engine"
@export var max_power_hp: float = 400.0  # PS
@export var max_rpm: float = 8000.0
@export var idle_rpm: float = 1000.0
@export var torque_curve_peak: float = 0.75  # Bei welchem % des max_rpm

@export_group("Torque Curve")
@export var low_rpm_torque: float = 0.5  # Drehmoment bei niedrigen RPM (0-50%)
@export var mid_rpm_torque: float = 1.0  # Drehmoment bei mittleren RPM (50-75%)
@export var high_rpm_torque: float = 0.8  # Drehmoment bei hohen RPM (75-100%)

@export_group("Engine Characteristics")
@export var responsiveness: float = 1.0  # Wie schnell der Motor reagiert
@export var fuel_efficiency: float = 1.0  # Für später (Kraftstoffsystem)
@export var rpm_limiter_start: float = 0.90  # Bei welchem % RPM der Limiter startet (90%)
@export var rpm_hard_limit: float = 0.95  # Bei welchem % RPM kaum noch Leistung (95%)


func calculate_torque_multiplier(current_rpm: float) -> float:
	"""Berechnet Drehmoment basierend auf RPM"""
	var rpm_percent = (current_rpm - idle_rpm) / (max_rpm - idle_rpm)
	rpm_percent = clamp(rpm_percent, 0.0, 1.0)
	
	var torque: float = 0.0
	
	# Drehmoment-Kurve in 3 Bereichen
	if rpm_percent < 0.5:
		# Low RPM (0-50%)
		torque = lerp(0.3, low_rpm_torque, rpm_percent * 2.0)
	elif rpm_percent < torque_curve_peak:
		# Mid RPM (50-75%)
		var t = (rpm_percent - 0.5) / (torque_curve_peak - 0.5)
		torque = lerp(low_rpm_torque, mid_rpm_torque, t)
	else:
		# High RPM (75-100%)
		var t = (rpm_percent - torque_curve_peak) / (1.0 - torque_curve_peak)
		torque = lerp(mid_rpm_torque, high_rpm_torque, t)
	
	return clamp(torque, 0.3, 1.0)


func calculate_rpm_limiter(current_rpm: float) -> float:
	"""Berechnet RPM-Limiter Effekt - reduziert Leistung bei zu hohen RPM"""
	var rpm_percent = (current_rpm - idle_rpm) / (max_rpm - idle_rpm)
	rpm_percent = clamp(rpm_percent, 0.0, 1.0)
	
	if rpm_percent > rpm_hard_limit:
		# Dramatischer Abfall - Motor kann nicht mehr höher drehen
		return max(0.05, 1.0 - (rpm_percent - rpm_hard_limit) * 20.0)
	elif rpm_percent > rpm_limiter_start:
		# Sanfter Übergang zum Limit
		var t = (rpm_percent - rpm_limiter_start) / (rpm_hard_limit - rpm_limiter_start)
		return lerp(1.0, 0.3, t)
	
	return 1.0


func get_engine_force(throttle: float, current_rpm: float, power_to_weight: float) -> float:
	"""Berechnet die finale Motor-Kraft"""
	var torque = calculate_torque_multiplier(current_rpm)
	var rpm_limit = calculate_rpm_limiter(current_rpm)
	var base_force = max_power_hp * power_to_weight * 100.0 * responsiveness
	return throttle * base_force * torque * rpm_limit
