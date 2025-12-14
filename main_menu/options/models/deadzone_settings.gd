class_name DeadzoneSettings
extends Node

var throttle: float
var brake: float
var steer: float


func _init(_throttle: float, _brake: float, _steer: float):
	throttle = _throttle
	brake = _brake
	steer = _steer
