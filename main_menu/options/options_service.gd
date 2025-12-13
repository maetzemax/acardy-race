class_name OptionsService
extends Node


static func set_deadzone_settings(deadzone: DeadzoneSettings):
	var config = ConfigFile.new()
	config.set_value("input", "throttle_deadzone", deadzone.throttle)
	config.set_value("input", "brake_deadzone", deadzone.brake)
	config.set_value("input", "steering_deadzone", deadzone.steer)
	config.save("user://input_settings.cfg")


static func get_deadzone_settings() -> DeadzoneSettings:
	var config = ConfigFile.new()
	var err = config.load("user://input_settings.cfg")
	
	if err == OK:
		var throttle_deadzone = config.get_value("input", "throttle_deadzone", 0.05)
		var brake_deadzone = config.get_value("input", "brake_deadzone", 0.05)
		var steering_deadzone = config.get_value("input", "steering_deadzone", 0.0)
			
		return DeadzoneSettings.new(throttle_deadzone, brake_deadzone, steering_deadzone)
	else:
		return null


static func set_graphic_settings(graphic_settings: GraphicSettings):
	var config = ConfigFile.new()
	config.set_value("graphic", "resolution", graphic_settings.resolution)
	config.set_value("graphic", "is_fullscreen", graphic_settings.is_fullscreen)
	config.set_value("graphic", "antialiasing_method", graphic_settings.antialiasing_method)
	config.set_value("graphic", "antialiasing_quality", graphic_settings.antialiasing_quality)
	config.set_value("graphic", "shadow_quality", graphic_settings.shadow_quality)
	config.save("user://graphic_settings.cfg")


static func get_graphic_settings() -> GraphicSettings:
	var config = ConfigFile.new()
	var err = config.load("user://graphic_settings.cfg")
	
	if err == OK:
		var resolution = config.get_value("graphic", "resolution", 1)
		var is_fullscreen = config.get_value("graphic", "is_fullscreen", true)
		var antialiasing_method = config.get_value("graphic", "antialiasing_method", 1)
		var antialiasing_quality = config.get_value("graphic", "antialiasing_quality", 1)
		var shadow_quality = config.get_value("graphic", "shadow_quality", 1)
			
		return GraphicSettings.new(
			resolution,
			is_fullscreen,
			antialiasing_method,
			antialiasing_quality,
			shadow_quality
		)
	else:
		return null
