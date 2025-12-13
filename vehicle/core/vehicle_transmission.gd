class_name VehicleTransmission
extends Node

var _current_rpm: float = 0.0

@export_group("RPM Settings")
@export var idle_rpm: int = 1500  # Höherer Leerlauf für Rennmotor
@export var min_rpm: int = 1500  # Mindest-RPM höher
@export var max_rpm: int = 12000  # Formel-Auto RPM
@export var rpm_lerp_speed: float = 8.0  # Schnellere RPM-Reaktion

@export_group("Transmission")
@export var final_drive_ratio: float = 10.5  # Noch höher für sehr kurze Gänge
@export var gear_ratios: Array[float] = [
	-2.5,  # Reverse (Index 0)
	0.0,   # Neutral (Index 1)
	3,   # 1st gear (Index 2) - max ~45-50 km/h
	2,   # 2nd gear - max ~65 km/h
	1.3,   # 3rd gear - max ~90 km/h
	1,  # 4th gear - max ~120 km/h
	0.7,  # 5th gear - max ~160 km/h
	0.5,  # 6th gear - max ~220+ km/h
]

@export_group("Wheel")
@export var wheel_radius: float = 0.48  # Dein tatsächlicher Radradius

var current_gear: int = 2  # Start in 1st gear (Index 2)

# Gibt die aktuelle Engine RPM basierend auf Radgeschwindigkeit zurück
func get_current_rpm() -> float:
	return _current_rpm

# Berechnet RPM aus Radgeschwindigkeit (m/s)
func calculate_rpm_from_wheel_speed(wheel_speed_mps: float, delta: float) -> float:
	# Wenn im Leerlauf oder Neutral
	if current_gear <= 1:
		_current_rpm = lerp(_current_rpm, float(idle_rpm), delta * rpm_lerp_speed)
		return _current_rpm
	
	# Radgeschwindigkeit in RPM umrechnen
	# wheel_speed (m/s) -> wheel RPM: (speed / circumference) * 60
	var wheel_circumference = 2.0 * PI * wheel_radius
	var wheel_rpm = (wheel_speed_mps / wheel_circumference) * 60.0
	
	# Wenn Räder stehen, zurück zum Leerlauf
	if abs(wheel_rpm) < 0.1:
		_current_rpm = lerp(_current_rpm, float(idle_rpm), delta * rpm_lerp_speed * 2.0)
		return _current_rpm
	
	# Engine RPM = Wheel RPM * Gear Ratio * Final Drive
	var current_gear_ratio = abs(gear_ratios[current_gear])  # abs() für Reverse
	var target_rpm = abs(wheel_rpm) * current_gear_ratio * final_drive_ratio
	
	# RPM begrenzen
	target_rpm = clamp(target_rpm, float(min_rpm), float(max_rpm))
	
	# Smooth lerp zu target RPM
	_current_rpm = lerp(_current_rpm, target_rpm, delta * rpm_lerp_speed)
	
	return _current_rpm

# Berechnet übertragene Kraft
func calculate_transfered_force(engine_force: float, throttle_strength: float) -> float:
	if current_gear == 1:  # Nur Neutral gibt keine Kraft
		return 0.0
	
	var current_gear_ratio = gear_ratios[current_gear]  # Mit Vorzeichen für Reverse
	
	# Kraft mit Gangübersetzung und Achsübersetzung multiplizieren
	var power = engine_force * throttle_strength * abs(current_gear_ratio) * final_drive_ratio
	
	# RPM-basierter Kraftmultiplikator (Motor liefert weniger Kraft bei zu hohen/niedrigen RPM)
	var rpm_efficiency = calculate_rpm_efficiency()
	power *= rpm_efficiency
	
	# Vorzeichen für Rückwärtsgang
	if current_gear == 0:  # Reverse
		power = -abs(power)  # Kraft negativ für Rückwärts
	
	return power

# Berechnet Motoreffizienz basierend auf aktueller RPM
func calculate_rpm_efficiency() -> float:
	# Formel-Auto: Starke Power ab niedrigen RPM
	var rpm_range = float(max_rpm - min_rpm)
	var normalized_rpm = (_current_rpm - float(min_rpm)) / rpm_range
	
	var efficiency: float
	
	# Unter 2000 RPM - sehr schwach (idle/stall Bereich)
	if _current_rpm < 2000.0:
		efficiency = (_current_rpm - float(idle_rpm)) / (2000.0 - float(idle_rpm)) * 0.5
		efficiency = max(0.1, efficiency)
	# 2000-4000 RPM - schneller Anstieg
	elif _current_rpm < 4000.0:
		var progress = (_current_rpm - 2000.0) / 2000.0
		efficiency = 0.5 + (progress * 0.4)  # 50% bis 90%
	# 4000-10000 RPM - volle Power
	elif _current_rpm < 10000.0:
		efficiency = 1.0
	# 10000-11500 RPM - noch gut
	elif _current_rpm < 11500.0:
		var progress = (_current_rpm - 10000.0) / 1500.0
		efficiency = 1.0 - (progress * 0.2)  # 100% bis 80%
	# Über 11500 RPM - Limiter-Bereich
	else:
		var progress = (_current_rpm - 11500.0) / 500.0
		efficiency = 0.05 - (progress * 0.5)  # 80% bis 30%
	
	return clamp(efficiency, 0.1, 1.0)

# Automatische Gangwechsel-Logik (optional)
func should_shift_up() -> bool:
	# Bei 11000 RPM hochschalten (knapp vor Limiter)
	return _current_rpm > float(max_rpm) * 0.92 and current_gear < gear_ratios.size() - 1

func should_shift_down() -> bool:
	# Runter bei 4000 RPM
	return _current_rpm < 4000.0 and current_gear > 2

func shift_up() -> void:
	if current_gear < gear_ratios.size() - 1:
		current_gear += 1
		print("Shifted UP to gear: ", current_gear - 1)  # -1 wegen Reverse/Neutral

func shift_down() -> void:
	if current_gear > 2:  # Nicht unter 1st gear
		current_gear -= 1
		print("Shifted DOWN to gear: ", current_gear - 1)

# Gibt aktuellen Gang als String zurück (für UI)
func get_gear_display() -> String:
	match current_gear:
		0: return "R"
		1: return "N"
		_: return str(current_gear - 1)
