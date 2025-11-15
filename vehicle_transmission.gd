extends Resource
class_name VehicleTransmission

## Getriebe-Konfiguration für modulares Fahrzeugsystem

@export_group("Transmission Type")
@export var transmission_name: String = "6-Speed Manual"
@export var auto_transmission: bool = true
@export var shift_time: float = 0.15  # Sekunden für Gangwechsel

@export_group("Gear Ratios")
@export var gear_ratios: Array[float] = [0.0, 4.2, 2.8, 2.0, 1.5, 1.2, 1.0]  # 0=Neutral, 1-6=Gänge
@export var final_drive_ratio: float = 4.1
@export var reverse_ratio: float = -3.5

@export_group("Auto Shift Settings")
@export var shift_up_rpm: float = 7200.0
@export var shift_down_rpm: float = 3000.0
@export var optimal_shift_rpm: float = 6500.0  # Für beste Performance

@export_group("Shift Characteristics")
@export var aggressive_shifting: bool = false  # Später hochschalten für mehr Power
@export var quick_shifter: bool = false  # Schnellere Gangwechsel


func get_gear_count() -> int:
	return gear_ratios.size() - 1  # -1 weil Index 0 = Neutral


func get_total_ratio(gear: int) -> float:
	"""Gesamtübersetzung für aktuellen Gang"""
	if gear < 0:
		return reverse_ratio * final_drive_ratio
	elif gear > 0 and gear < gear_ratios.size():
		return gear_ratios[gear] * final_drive_ratio
	return 0.0


func should_shift_up(current_rpm: float, current_gear: int) -> bool:
	"""Prüft ob hochgeschaltet werden soll"""
	if not auto_transmission or current_gear >= get_gear_count():
		return false
	
	var target_rpm = shift_up_rpm
	if aggressive_shifting:
		target_rpm += 500.0
	
	return current_rpm >= target_rpm


func should_shift_down(current_rpm: float, current_gear: int, speed: float) -> bool:
	"""Prüft ob runtergeschaltet werden soll"""
	if not auto_transmission or current_gear <= 1 or speed < 5.0:
		return false
	
	return current_rpm <= shift_down_rpm
