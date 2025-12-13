extends Control

#region DeadzoneSettings
@export var accelerate_value_label: Label
@export var brake_value_label: Label
@export var steering_value_label: Label

@export var throttle_deadzone_slider: HSlider
@export var brake_deadzone_slider: HSlider
@export var steering_deadzone_slider: HSlider

var throttle_deadzone: float = 0.1
var brake_deadzone: float = 0.1
var steering_deadzone: float = 0.1
#endregion

@export var shift_assistant: CheckBox

@export var username_line_edit: LineEdit

#region Graphics
@export var resolution_selection: OptionButton
@export var fullscreen: CheckBox

@export var antialiasing_method: OptionButton
@export var antialiasing_quality: OptionButton
@export var shadow_quality: OptionButton
#endregion

@export var save_button: Button


func _ready():
	save_button.pressed.connect(_on_save)
	resolution_selection.item_selected.connect(_on_resoulution_change)
	fullscreen.toggled.connect(_on_fullscreen_toggled)
	
	antialiasing_method.item_selected.connect(_on_antialiasing_method_change)
	antialiasing_quality.item_selected.connect(_on_antialiasing_quality_change)
	shadow_quality.item_selected.connect(_on_shadow_quality_change)
	
	_load_deadzone()
	_load_graphics()
	_load_driver_aids()
	
	await get_tree().create_timer(0.5).timeout
	username_line_edit.text = UserService.get_username()


func _process(_delta):
	throttle_deadzone = throttle_deadzone_slider.value
	brake_deadzone = brake_deadzone_slider.value
	steering_deadzone = steering_deadzone_slider.value
	
	accelerate_value_label.text = "%1.2f" % throttle_deadzone
	brake_value_label.text = "%1.2f" % brake_deadzone
	steering_value_label.text = "%1.2f" % steering_deadzone
	
	resolution_selection.disabled = fullscreen.button_pressed


func _on_save():
	var deadzone = DeadzoneSettings.new(throttle_deadzone, brake_deadzone, steering_deadzone) 
	OptionsService.set_deadzone_settings(deadzone)
	
	if RacingNakamaClient.user.username != username_line_edit.text and username_line_edit.text.length() > 2:
		UserService.set_username(username_line_edit.text)
	
	var graphics = GraphicSettings.new(
		resolution_selection.get_selected_id(),
		fullscreen.button_pressed,
		antialiasing_method.get_selected_id(),
		antialiasing_quality.get_selected_id(),
		shadow_quality.get_selected_id()
	)
	OptionsService.set_graphic_settings(graphics)
	
	var driver_aids = DriverAidSettings.new(
		shift_assistant.button_pressed
	)
	OptionsService.set_driver_aid_settings(driver_aids)

	
func _on_fullscreen_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_antialiasing_method_change(index):
	RenderingServer.viewport_set_screen_space_aa(get_window().get_viewport_rid(), index)


func _on_antialiasing_quality_change(index):
	RenderingServer.viewport_set_msaa_3d(get_window().get_viewport_rid(), index)


func _on_shadow_quality_change(index):
	RenderingServer.directional_soft_shadow_filter_set_quality(index)


func _on_resoulution_change(index):
	if not fullscreen.button_pressed:
		match index:
			0:
				DisplayServer.window_set_size(Vector2i(2560, 1440))
			1:
				DisplayServer.window_set_size(Vector2i(1920, 1080))
			2:
				DisplayServer.window_set_size(Vector2i(1280, 720))
		
		get_window().move_to_center()


func _load_deadzone():
	var deadzone = OptionsService.get_deadzone_settings()
	
	if not deadzone:
		return
	
	throttle_deadzone = deadzone.throttle
	brake_deadzone = deadzone.brake
	steering_deadzone = deadzone.steer
	
	throttle_deadzone_slider.value = throttle_deadzone
	brake_deadzone_slider.value = brake_deadzone
	steering_deadzone_slider.value = steering_deadzone
	
	accelerate_value_label.text = "%1.2f" % throttle_deadzone
	brake_value_label.text = "%1.2f" % brake_deadzone
	steering_value_label.text = "%1.2f" % steering_deadzone


func _load_graphics():
	var graphics: GraphicSettings = OptionsService.get_graphic_settings()
	
	if not graphics:
		return
	
	fullscreen.button_pressed = graphics.is_fullscreen
	resolution_selection.select(graphics.resolution)
	_on_resoulution_change(graphics.resolution)
	antialiasing_method.select(graphics.antialiasing_method)
	antialiasing_quality.select(graphics.antialiasing_quality)
	shadow_quality.select(graphics.shadow_quality)
	

func _load_driver_aids():
	var driver_aids: DriverAidSettings = OptionsService.get_driver_aid_settings()
	
	if not driver_aids:
		return
	
	shift_assistant.button_pressed = driver_aids.shift_assistant
	
