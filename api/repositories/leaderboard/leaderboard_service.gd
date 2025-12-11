extends Node3D

const LEADERBOARD_ID = "lap_times"

static var local_best_lap_time: float
static var best_lap_time: float
static var last_lap_time: float

static var current_delta: float
static var best_sector_times: Array[float]

func _ready():
	await get_tree().create_timer(1.0).timeout
	load_best_time()
	get_personal_best_time()


func set_leaderboard_laptime(lap_time: float, sector_times: Array[float]):
	var score = int(lap_time * 1000)
	
	var metadata = {
		"sector_times": sector_times
	}
	
	var record : NakamaAPI.ApiLeaderboardRecord = await RacingNakamaClient.client.write_leaderboard_record_async(
		RacingNakamaClient.session,
		LEADERBOARD_ID,
		score,
		0,
		JSON.stringify(metadata)
	)
	
	if record.is_exception():
		print("An error occurred: %s" % record)
		return


func get_personal_best_time():
	var account: NakamaAPI.ApiAccount = await RacingNakamaClient.client.get_account_async(RacingNakamaClient.session)

	if account.is_exception():
		print("An error occurred: %s" % account)
		return

	var user = account.user
	print("User id '%s' and username '%s'." % [user.id, user.username])
	
	var result: NakamaAPI.ApiLeaderboardRecordList = await  RacingNakamaClient.client.list_leaderboard_records_around_owner_async(
		RacingNakamaClient.session,
		LEADERBOARD_ID,
		user.id,
		null,
		1,
		null
	)
	
	if result.records.size() > 0:
		var record : NakamaAPI.ApiLeaderboardRecord = result.records[0]
		var lap_time = float(record.score) / 1000.0
		local_best_lap_time = lap_time

func load_best_time():
	var result : NakamaAPI.ApiLeaderboardRecordList = await RacingNakamaClient.client.list_leaderboard_records_async(
		RacingNakamaClient.session,
		LEADERBOARD_ID,
		null,
		null,
		1
	)
	
	if result.is_exception():
		print("An error occurred: %s" % result)
		return
	
	if result.records.size() > 0:
		var record : NakamaAPI.ApiLeaderboardRecord = result.records[0]
		var lap_time = float(record.score) / 1000.0
		best_lap_time = lap_time


func load_best_times(limit = 20) -> Array[LeaderboardEntry]:
	var result : NakamaAPI.ApiLeaderboardRecordList = await RacingNakamaClient.client.list_leaderboard_records_async(
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
		var _err = json.parse(record.metadata)
		var sector_times = json.data.get("sector_times", [])
		
		times.append(LeaderboardEntry.new(time, username, sector_times))
	
	return times
