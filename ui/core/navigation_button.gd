@tool
class_name NavigationButton
extends Button

enum NAVIGATION_DESTINATION {
	MAIN,
	MENU,
	QUIT,
}

@export var destination: NAVIGATION_DESTINATION

var font_size: int = 48

func _ready() -> void:
	pressed.connect(_on_pressed)
	add_theme_font_size_override("font_size", font_size)
	

func _on_pressed():
	match destination:
		NAVIGATION_DESTINATION.MAIN:
			get_tree().change_scene_to_packed(load("uid://un1xgkhi1vmp"))
		NAVIGATION_DESTINATION.MENU:
			get_tree().change_scene_to_packed(load("uid://cuxsom1083lt7"))
		NAVIGATION_DESTINATION.QUIT:
			get_tree().quit()
