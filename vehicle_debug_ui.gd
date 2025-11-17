extends Control

## Debug UI für Fahrzeug-Informationen

@export var vehicle: VehicleBody3D

# UI Elemente
@onready var speed_label: Label
@onready var throttle_bar: ProgressBar
@onready var brake_bar: ProgressBar
@onready var steering_bar: ProgressBar

# Farben
var color_throttle = Color(0.2, 1.0, 0.2)  # Grün
var color_brake = Color(1.0, 0.2, 0.2)      # Rot
var color_steering = Color(0.2, 0.5, 1.0)   # Blau


func _ready():
	_create_ui()


func _create_ui():
	# Container für alles
	var main_container = VBoxContainer.new()
	main_container.position = Vector2(20, 20)
	main_container.add_theme_constant_override("separation", 10)
	add_child(main_container)
	
	# Tacho (groß und prominent)
	var tacho_panel = PanelContainer.new()
	var tacho_box = VBoxContainer.new()
	tacho_panel.add_child(tacho_box)
	
	speed_label = Label.new()
	speed_label.add_theme_font_size_override("font_size", 48)
	speed_label.text = "0 km/h"
	tacho_box.add_child(speed_label)
	
	main_container.add_child(tacho_panel)
	
	# Pedal-Anzeigen
	main_container.add_child(_create_pedal_display("Gas", color_throttle))
	main_container.add_child(_create_pedal_display("Bremse", color_brake))
	main_container.add_child(_create_pedal_display("Lenkung", color_steering))


func _create_pedal_display(label_text: String, bar_color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var label = Label.new()
	label.text = label_text
	vbox.add_child(label)
	
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(300, 30)
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 0
	bar.show_percentage = true
	
	# Farbe setzen (über StyleBox)
	var style = StyleBoxFlat.new()
	style.bg_color = bar_color
	bar.add_theme_stylebox_override("fill", style)
	
	vbox.add_child(bar)
	
	# Speichere Referenz
	if label_text == "Gas":
		throttle_bar = bar
	elif label_text == "Bremse":
		brake_bar = bar
	elif label_text == "Lenkung":
		steering_bar = bar
	
	return panel


func _process(_delta):
	if vehicle == null:
		return
	
	# Geschwindigkeit in km/h
	var speed_ms = vehicle.linear_velocity.length()
	var speed_kmh = speed_ms * 3.6
	speed_label.text = "%d km/h" % speed_kmh
	
	# Farbe basierend auf Geschwindigkeit
	if speed_kmh < 50:
		speed_label.add_theme_color_override("font_color", Color.WHITE)
	elif speed_kmh < 100:
		speed_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		speed_label.add_theme_color_override("font_color", Color.RED)
	

	throttle_bar.value = Input.get_action_strength("accelerate") * 100.0
	brake_bar.value = Input.get_action_strength("brake") * 100.0
	
	# Lenkung (-100 bis +100, zeigen wir als 0-100 mit Mitte bei 50)
	if vehicle.steering:
		var steering_percent = (vehicle.steering / vehicle.max_steering_angle) * 50.0 + 50.0
		steering_bar.value = steering_percent
