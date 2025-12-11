@tool
class_name NavigationButton
extends Button

enum NAVIGATION_DESTINATION {
	MAIN,
	MENU,
	QUIT,
}

const MAIN = preload("uid://un1xgkhi1vmp")
const MENU = preload("uid://cuxsom1083lt7")

@export var destination: NAVIGATION_DESTINATION

var font_size: int = 48

func _ready() -> void:
	pressed.connect(_on_pressed)
	add_theme_font_size_override("font_size", font_size)
	

func _on_pressed():
	match destination:
		NAVIGATION_DESTINATION.MAIN:
			get_tree().change_scene_to_packed(MAIN)
		NAVIGATION_DESTINATION.MENU:
			get_tree().change_scene_to_packed(MENU)
		NAVIGATION_DESTINATION.QUIT:
			get_tree().quit()
