class_name GraphicSettings
extends Node

var resolution: int
var is_fullscreen: bool
var antialiasing_method: int
var antialiasing_quality: int
var shadow_quality: int


func _init(
	_resolution: int,
	_is_fullscreen: bool,
	_antialiasing_method: int,
	_antialiasing_quality: int,
	_shadow_quality: int
):
	resolution = _resolution
	is_fullscreen = _is_fullscreen
	antialiasing_method =_antialiasing_method
	antialiasing_quality = _antialiasing_quality
	shadow_quality = _shadow_quality
