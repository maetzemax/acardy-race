extends Node3D

const LEADERBOARD_ID = "lap_times"

static var local_best_lap_time: float
static var best_lap_time: float
static var last_lap_time: float

static var current_delta: float
static var best_sector_times


func _ready():
	await get_tree().create_timer(1.0).timeout
	get_global_best_time()
	get_personal_best_time()


func set_leaderboard_laptime(lap_time: float, sector_times: Array[float]):
	var score = int(lap_time * 1000)
	
	var metadata = {
		"sector_times": sector_times
	}
	
	var record: NakamaAPI.ApiLeaderboardRecord = await RacingNakamaClient.client.write_leaderboard_record_async(
		RacingNakamaClient.session,
		LEADERBOARD_ID,
		score,
		0,
		JSON.stringify(metadata)
	)
	
	if record.is_exception():
		print("An error occurred: %s" % record)
		return


func get_personal_best_time() -> LeaderboardEntry:
	var result: NakamaAPI.ApiLeaderboardRecordList = await RacingNakamaClient.client.list_leaderboard_records_around_owner_async(
		RacingNakamaClient.session,
		LEADERBOARD_ID,
		RacingNakamaClient.user.id,
		null,
		1,
		null
	)

	if result.records.size() == 0:
		return null
	
	var record : NakamaAPI.ApiLeaderboardRecord = result.records[0]
	
	var lap_time = float(record.score) / 1000.0
	local_best_lap_time = lap_time
	var username = record.username

	var json = JSON.new()
	json.parse(record.metadata)
	var sector_times = json.data.get("sector_times", [])
	best_sector_times = sector_times
	
	return LeaderboardEntry.new(lap_time, username, sector_times)


func get_global_best_time() -> LeaderboardEntry:
	var result: NakamaAPI.ApiLeaderboardRecordList = await RacingNakamaClient.client.list_leaderboard_records_async(
		RacingNakamaClient.session,
		LEADERBOARD_ID,
		null,
		null,
		1
	)
	
	if result.is_exception():
		print("An error occurred: %s" % result)
		return null
	
	if result.records.size() == 0:
		return null
	
	var record: NakamaAPI.ApiLeaderboardRecord = result.records[0]
	var lap_time = float(record.score) / 1000.0
	best_lap_time = lap_time
	var username = record.username

	var json = JSON.new()
	json.parse(record.metadata)
	var sector_times = json.data.get("sector_times", [])
	
	return LeaderboardEntry.new(lap_time, username, sector_times)


func get_global_best_times(limit = 5) -> Array[LeaderboardEntry]:
	var result: NakamaAPI.ApiLeaderboardRecordList = await RacingNakamaClient.client.list_leaderboard_records_async(
		RacingNakamaClient.session,
		LEADERBOARD_ID,
		null,
		null,
		limit
	)
	
	if result.is_exception():
		print("An error occurred: %s" % result)
		return []
	
	var times: Array[LeaderboardEntry] = []
	
	for record in result.records:
		var time = float(record.score) / 1000
		var username = record.username
		
		var json = JSON.new()
		json.parse(record.metadata)
		var sector_times = json.data.get("sector_times", [])
		
		times.append(LeaderboardEntry.new(time, username, sector_times))
	
	return times
