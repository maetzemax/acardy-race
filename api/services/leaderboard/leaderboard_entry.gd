class_name LeaderboardEntry
extends Node

var laptime: float
var username: String
var sector_times


func _init(_laptime: float, _username: String, _sector_times):
	laptime = _laptime
	username = _username
	sector_times = _sector_times
