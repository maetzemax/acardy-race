extends Control

## Debug UI für Fahrzeug-Informationen
@export var laptime_service: LaptimeService
@export var laptimer: Node3D
@export var vehicle: VehicleBody3D

# UI Elemente
@export var speed_label: Label
@export var throttle_bar: ProgressBar
@export var brake_bar: ProgressBar
@export var steering_bar: ProgressBar
@export var lap_time_label: Label
@export var best_time_label: Label
@export var local_best_time_label: Label
@export var last_time_label: Label
@export var delta_label: Label

var delta_display_timer: float = 0.0
var delta_initialized: bool = false
var last_delta_value: float = 0.0


func _ready():
	if delta_label:
		delta_label.visible = false


func _input(event):
	# Szene neuladen bei P-Taste
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		get_tree().reload_current_scene()


func _process(delta):
	if vehicle == null or laptime_service == null:
		return

	_maybe_trigger_delta_flash(laptime_service.current_delta)
	_update_delta_visibility(delta)
	
	if laptimer.lap_started:
		lap_time_label.text = _format_time(laptimer.current_lap_time)
	else:
		lap_time_label.text = "Start/Ziel passieren"
		
	best_time_label.text = _format_time(laptime_service.best_lap_time)
	last_time_label.text = _format_time(laptime_service.last_lap_time)
	local_best_time_label.text = _format_time(laptime_service.local_best_lap_time)
	
	# Geschwindigkeit in km/h
	var speed_ms = vehicle.linear_velocity.length()
	var speed_kmh = speed_ms * 3.6
	speed_label.text = "%d km/h" % speed_kmh
	
	# Farbe basierend auf Geschwindigkeit
	if speed_kmh < 100:
		speed_label.add_theme_color_override("font_color", Color.WHITE)
	elif speed_kmh < 150:
		speed_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		speed_label.add_theme_color_override("font_color", Color.RED)
	
	delta_label.text = ("+" if laptime_service.current_delta > 0 else "-") + _format_time(abs(laptime_service.current_delta))
	
	if laptime_service.current_delta < 0:
		delta_label.add_theme_color_override("font_color", Color.GREEN)
	elif laptime_service.current_delta > 0:
		delta_label.add_theme_color_override("font_color", Color.RED)
	else:
		delta_label.add_theme_color_override("font_color", Color.WHITE)

	throttle_bar.value = Input.get_action_strength("accelerate") * 100.0
	brake_bar.value = Input.get_action_strength("brake") * 100.0
	
	# Lenkung (-100 bis +100, zeigen wir als 0-100 mit Mitte bei 50)
	if vehicle.steering:
		var steering_percent = (vehicle.steering / vehicle.max_steering_angle) * 50.0 + 50.0
		steering_bar.value = steering_percent


func _format_time(time_seconds: float) -> String:
	"""Formatiert Zeit als M:SS.mmm"""
	var minutes = int(time_seconds / 60)
	var seconds = int(time_seconds) % 60
	var milliseconds = int((time_seconds - int(time_seconds)) * 1000)
	return "%d:%02d.%03d" % [minutes, seconds, milliseconds]


func _maybe_trigger_delta_flash(delta_value: float) -> void:
	if not delta_initialized or not is_equal_approx(delta_value, last_delta_value):
		delta_initialized = true
		last_delta_value = delta_value
		delta_display_timer = 3.0
		if delta_label:
			delta_label.visible = true


func _update_delta_visibility(delta_time: float) -> void:
	if delta_display_timer > 0.0:
		delta_display_timer = max(delta_display_timer - delta_time, 0.0)
		if delta_display_timer == 0.0 and delta_label:
			delta_label.visible = false
