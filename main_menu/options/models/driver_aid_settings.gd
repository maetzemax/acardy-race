class_name DriverAidSettings
extends Node

var shift_assistant: bool
var stability_assistant: bool


func _init(_shift_assistant: bool, _stability_assistant: bool) -> void:
	shift_assistant = _shift_assistant
	stability_assistant = _stability_assistant
