extends Control

## Input Settings UI für Deadzone-Einstellungen

@export var vehicle: VehicleBody3D

# UI Elemente
var steering_deadzone_slider: HSlider
var accelerate_deadzone_slider: HSlider
var brake_deadzone_slider: HSlider

var steering_value_label: Label
var accelerate_value_label: Label
var brake_value_label: Label

# Einstellungen
var steering_deadzone: float = 0.0
var accelerate_deadzone: float = 0.05
var brake_deadzone: float = 0.05


func _ready():
	_create_ui()
	_load_settings()


func _create_ui():
	# Hauptcontainer (unten links)
	var main_panel = PanelContainer.new()
	main_panel.position = Vector2(20, get_viewport().size.y - 320)
	add_child(main_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	main_panel.add_child(vbox)
	
	# Titel
	var title = Label.new()
	title.text = "Input Deadzones"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	# Steering Deadzone
	vbox.add_child(_create_deadzone_control("Lenkung", "steering"))
	
	# Accelerate Deadzone
	vbox.add_child(_create_deadzone_control("Gas", "accelerate"))
	
	# Brake Deadzone
	vbox.add_child(_create_deadzone_control("Bremse", "brake"))
	
	# Reset Button
	var reset_button = Button.new()
	reset_button.text = "Reset auf Standard"
	reset_button.focus_mode = Control.FOCUS_NONE  # Kein Focus
	reset_button.pressed.connect(_reset_to_defaults)
	vbox.add_child(reset_button)


func _create_deadzone_control(label_text: String, input_type: String) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	
	# Label mit Wert
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(label)
	
	var value_label = Label.new()
	value_label.text = "0.00"
	value_label.add_theme_color_override("font_color", Color.CYAN)
	hbox.add_child(value_label)
	
	container.add_child(hbox)
	
	# Slider
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 0.3
	slider.step = 0.01
	slider.value = 0.0
	slider.custom_minimum_size = Vector2(300, 30)
	slider.focus_mode = Control.FOCUS_NONE  # Kein Focus
	slider.value_changed.connect(_on_deadzone_changed.bind(input_type, value_label))
	container.add_child(slider)
	
	# Speichere Referenzen
	match input_type:
		"steering":
			steering_deadzone_slider = slider
			steering_value_label = value_label
		"accelerate":
			accelerate_deadzone_slider = slider
			accelerate_value_label = value_label
		"brake":
			brake_deadzone_slider = slider
			brake_value_label = value_label
	
	return container


func _on_deadzone_changed(value: float, input_type: String, value_label: Label):
	value_label.text = "%.2f" % value
	
	match input_type:
		"steering":
			steering_deadzone = value
		"accelerate":
			accelerate_deadzone = value
		"brake":
			brake_deadzone = value
	
	_save_settings()
	
	# Wende auf Vehicle an
	if vehicle and vehicle.has_method("set_input_deadzones"):
		vehicle.set_input_deadzones(steering_deadzone, accelerate_deadzone, brake_deadzone)


func _reset_to_defaults():
	steering_deadzone_slider.value = 0.0
	accelerate_deadzone_slider.value = 0.05
	brake_deadzone_slider.value = 0.05


func _save_settings():
	"""Speichert Deadzone-Einstellungen"""
	var config = ConfigFile.new()
	config.set_value("input", "steering_deadzone", steering_deadzone)
	config.set_value("input", "accelerate_deadzone", accelerate_deadzone)
	config.set_value("input", "brake_deadzone", brake_deadzone)
	config.save("user://input_settings.cfg")


func _load_settings():
	"""Lädt Deadzone-Einstellungen"""
	var config = ConfigFile.new()
	var err = config.load("user://input_settings.cfg")
	
	if err == OK:
		steering_deadzone = config.get_value("input", "steering_deadzone", 0.0)
		accelerate_deadzone = config.get_value("input", "accelerate_deadzone", 0.05)
		brake_deadzone = config.get_value("input", "brake_deadzone", 0.05)
		
		# Setze Slider-Werte
		if steering_deadzone_slider:
			steering_deadzone_slider.value = steering_deadzone
		if accelerate_deadzone_slider:
			accelerate_deadzone_slider.value = accelerate_deadzone
		if brake_deadzone_slider:
			brake_deadzone_slider.value = brake_deadzone
		
		# Wende auf Vehicle an
		if vehicle and vehicle.has_method("set_input_deadzones"):
			vehicle.set_input_deadzones(steering_deadzone, accelerate_deadzone, brake_deadzone)
		
		print("Input-Einstellungen geladen")
