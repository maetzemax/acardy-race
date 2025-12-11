extends Node
@export var vehicle: VehicleBody3D

var current_sector_times: Array[float]
var current_lap_time: float = 0.0
var lap_started: bool = false
var is_invalid_time: bool = false
var all_sectors_passed: bool = false

var checkpoints

func _ready():
	checkpoints = get_tree().get_nodes_in_group("lap_checkpoints")
	
	for checkpoint in checkpoints:
		if checkpoint.has_signal("lap_completed"):
			checkpoint.lap_completed.connect(_on_lap_completed)
		
		if checkpoint.has_signal("checkpoint_crossed"):
			checkpoint.checkpoint_crossed.connect(_on_checkpoint_crossed)


func _process(delta: float) -> void:
	if lap_started and not is_invalid_time:
		if vehicle.is_off_track():
			is_invalid_time = true
			return
		
		current_lap_time += delta
	
	if current_sector_times.size() == checkpoints.size() - 1 and not all_sectors_passed:
		all_sectors_passed = true
		

func _on_checkpoint_crossed(crossing_vehicle: Node3D, index: int):
	if crossing_vehicle != vehicle and not is_invalid_time:
		return
		
	current_sector_times.append(current_lap_time)
	
	if LeaderboardService.best_sector_times:
		var delta = current_lap_time - LeaderboardService.best_sector_times[index]
		LeaderboardService.current_delta = delta


func _on_lap_completed(crossing_vehicle: Node3D):
	if crossing_vehicle != vehicle:
		return
	
	if not lap_started:
		lap_started = true
	else:
		LeaderboardService.current_delta = current_lap_time - LeaderboardService.local_best_lap_time
		
		if not is_invalid_time and all_sectors_passed:
			if current_lap_time < LeaderboardService.local_best_lap_time or not LeaderboardService.local_best_lap_time:
				LeaderboardService.local_best_lap_time = current_lap_time
				LeaderboardService.best_sector_times = current_sector_times
				
				if current_lap_time < LeaderboardService.best_lap_time or not LeaderboardService.best_lap_time:
					LeaderboardService.best_lap_time = current_lap_time
				
				LeaderboardService.set_leaderboard_laptime(current_lap_time, current_sector_times)
			
			LeaderboardService.last_lap_time = current_lap_time
		
		current_lap_time = 0
		current_sector_times = []
		all_sectors_passed = false
		is_invalid_time = false
		
		await get_tree().create_timer(1.0).timeout
		LeaderboardService.load_best_time()
