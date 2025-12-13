extends Control

@onready var lap_time_list: VBoxContainer = $LapTimeList

var entries: Array[LeaderboardEntry] = []


func _ready():
	await get_tree().create_timer(0.2).timeout
	entries = await LeaderboardService.get_global_best_times(5)
	
	if entries.size() < 1:
		var label = Label.new()
		label.text = "NO TIMES FOUND"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 48)
		lap_time_list.add_child(label)
		return
	
	for entry in entries:
		var lap_entry_box = VBoxContainer.new()
		
		var label = Label.new()
		label.text = entry.username + " - " + _format_time(entry.laptime)
		label.add_theme_font_size_override("font_size", 32)
		
		if entry.username == RacingNakamaClient.user.username:
			label.add_theme_color_override("font_color", Color.GREEN)
		
		lap_entry_box.add_child(label)
		
		var footnote_label = Label.new()
		footnote_label.text = _format_sectors(entry.sector_times)
		footnote_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		lap_entry_box.add_child(footnote_label)
		
		lap_time_list.add_child(lap_entry_box)


func _format_time(time_seconds: float) -> String:
	var minutes = int(time_seconds / 60)
	var seconds = int(time_seconds) % 60
	var milliseconds = int((time_seconds - int(time_seconds)) * 1000)
	return "%d:%02d.%03d" % [minutes, seconds, milliseconds]

	
func _format_sectors(sectors) -> String:
	var base = ""
	
	for sector in sectors:
		base += _format_time(sector)
		
		if sector != sectors[sectors.size() - 1]:
			base += ", "
	
	return base
