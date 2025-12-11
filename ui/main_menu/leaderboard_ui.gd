extends Control

@onready var lap_time_list: VBoxContainer = $VBoxContainer/LapTimeList

var _lap_times: Dictionary = {}


func _ready():
	await get_tree().create_timer(1.0).timeout
	_lap_times = await LeaderboardService.load_best_times(5)
	
	if _lap_times.size() < 1:
		var label = Label.new()
		label.text = "NO TIMES FOUND"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 48)
		lap_time_list.add_child(label)
		return
	
	for username in _lap_times:
		var label = Label.new()
		label.text = username + " - " + _format_time(_lap_times[username])
		
		if username == RacingNakamaClient.user.username:
			label.add_theme_color_override("font_color", Color.GREEN)
		
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 48)
		lap_time_list.add_child(label)


func _format_time(time_seconds: float) -> String:
	var minutes = int(time_seconds / 60)
	var seconds = int(time_seconds) % 60
	var milliseconds = int((time_seconds - int(time_seconds)) * 1000)
	return "%d:%02d.%03d" % [minutes, seconds, milliseconds]
