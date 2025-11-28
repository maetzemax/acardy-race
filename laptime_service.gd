class_name LaptimeService
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
	load_personal_best_time()

func set_leaderboard_laptime(time):
	var score = int(time * 1000)
	
	var record : NakamaAPI.ApiLeaderboardRecord = await RacingNakamaClient.client.write_leaderboard_record_async(
		RacingNakamaClient.session,
		LEADERBOARD_ID,
		score
	)
	
	if record.is_exception():
		print("An error occurred: %s" % record)
		return

func load_personal_best_time():
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
