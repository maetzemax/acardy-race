extends Control

enum VIEWS {
	MENU,
	LEADERBOARD,
	OPTIONS,
}

@onready var menu: CenterContainer = $Menu

@onready var options: CenterContainer = $Options
@onready var options_button: Button = $Menu/VBoxContainer/OptionsButton
@onready var options_back_button: Button = $Options/VBoxContainer/Back

@onready var leaderboard: CenterContainer = $Leaderboard
@onready var leaderboard_button: Button = $Menu/VBoxContainer/LeaderboardButton
@onready var leaderboard_back_button: Button = $Leaderboard/VBoxContainer/Back

@export var camera: Camera3D

const CAMERA_SPEED = 5.0

var _current_view: VIEWS = VIEWS.MENU


func _ready():
	options_button.pressed.connect(_on_option_navigation)
	options_back_button.pressed.connect(_on_option_navigation)
	
	leaderboard_button.pressed.connect(_on_leadboard_navigation)
	leaderboard_back_button.pressed.connect(_on_leadboard_navigation)


func _process(_delta):
	match _current_view:
		VIEWS.MENU:
			menu.visible = true
			leaderboard.visible = false
			options.visible = false
			camera.rotation_degrees = lerp(camera.rotation_degrees, Vector3(0, -170, -0), _delta * CAMERA_SPEED)
		VIEWS.LEADERBOARD:
			menu.visible = false
			leaderboard.visible = true
			options.visible = false
			camera.rotation_degrees = lerp(camera.rotation_degrees, Vector3(0, -230, -0), _delta * CAMERA_SPEED)
		VIEWS.OPTIONS:
			menu.visible = false
			leaderboard.visible = false
			options.visible = true
			camera.rotation_degrees = lerp(camera.rotation_degrees, Vector3(0, -110, -0), _delta * CAMERA_SPEED)


func _on_option_navigation():
	if _current_view == VIEWS.OPTIONS:
		_current_view = VIEWS.MENU
	else:
		_current_view = VIEWS.OPTIONS
	
func _on_leadboard_navigation():
	if _current_view == VIEWS.LEADERBOARD:
		_current_view = VIEWS.MENU
	else:
		_current_view = VIEWS.LEADERBOARD
