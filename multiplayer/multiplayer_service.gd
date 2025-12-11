extends Node

# Op codes for different message types
const OP_CODE_POSITION = 1

var match_id: String = ""
var is_host: bool = false
var remote_players: Dictionary = {}  # session_id -> player_node
var self_session_id: String = ""

signal player_joined(session_id: String, username: String)
signal player_left(session_id: String)
signal remote_player_state_updated(session_id: String, position: Vector3, rotation: Vector3)

func join_match():
	print("Join Match")
	
	var min_players = 0
	var max_players = 2
	var limit = 1
	var authoritative = false
	var label: String
	var query: String
	
	var matches:  NakamaAPI.ApiMatchList = await RacingNakamaClient.client.list_matches_async(RacingNakamaClient.session, min_players, max_players, limit, authoritative, label, query)

	if matches.is_exception():
		print("An error occurred: %s" % matches)
		return
	
	for m in matches.matches:
		var joined_match = await RacingNakamaClient.socket.join_match_async(m.match_id)
	
		if joined_match.is_exception():
			print("An error occurred: %s" % joined_match)
			return
		
		match_id = joined_match.match_id
		self_session_id = joined_match.self_user.session_id
		is_host = false
		
		for presence in joined_match.presences:
			print("User id %s name %s'." % [presence.user_id, presence.username])
			# Emit signal for each existing player
			if presence.session_id != self_session_id:
				player_joined.emit(presence.session_id, presence.username)
	
		# Setup event listeners
		RacingNakamaClient.socket.received_match_state.connect(self._on_match_state)
		RacingNakamaClient.socket.received_match_presence.connect(self._on_match_presence)
		print("Successfully joined match: %s" % match_id)
	
func create_match():
	print("Create Match")
	
	var match_name = "Test"
	var created_match: NakamaRTAPI.Match = await RacingNakamaClient.socket.create_match_async(match_name)

	if created_match.is_exception():
		print("An error occurred: %s" % created_match)
		return

	match_id = created_match.match_id
	self_session_id = created_match.self_user.session_id
	is_host = true
	print("New match with id %s" % created_match.match_id)
	
	# Setup event listeners
	RacingNakamaClient.socket.received_match_state.connect(self._on_match_state)
	RacingNakamaClient.socket.received_match_presence.connect(self._on_match_presence)

func _on_match_state(p_state : NakamaRTAPI.MatchData):
	# Ignore own messages
	if self_session_id != "" and p_state.presence.session_id == self_session_id:
		return
	
	var data = JSON.parse_string(p_state.data)
	
	match p_state.op_code:
		OP_CODE_POSITION:
			var position = Vector3(data.x, data.y, data.z)
			var rotation = Vector3(data.rx, data.ry, data.rz)
			remote_player_state_updated.emit(p_state.presence.session_id, position, rotation)
		_:
			print("Unknown op code: %s" % p_state.op_code)

func _on_match_presence(p_presence : NakamaRTAPI.MatchPresenceEvent):
	# Handle players joining
	for p in p_presence.joins:
		if self_session_id == "" or p.session_id != self_session_id:
			print("Player joined: %s" % p.username)
			player_joined.emit(p.session_id, p.username)
	
	# Handle players leaving
	for p in p_presence.leaves:
		if self_session_id == "" or p.session_id != self_session_id:
			print("Player left: %s" % p.username)
			player_left.emit(p.session_id)
			if p.session_id in remote_players:
				remote_players.erase(p.session_id)

func send_player_position(position: Vector3, rotation: Vector3):
	if match_id.is_empty():
		return
	
	var state = {
		"x": position.x,
		"y": position.y,
		"z": position.z,
		"rx": rotation.x,
		"ry": rotation.y,
		"rz": rotation.z
	}
	
	await RacingNakamaClient.socket.send_match_state_async(match_id, OP_CODE_POSITION, JSON.stringify(state))

func leave_match():
	if not match_id.is_empty():
		await RacingNakamaClient.socket.leave_match_async(match_id)
		match_id = ""
		self_session_id = ""
		remote_players.clear()
		print("Left match")
