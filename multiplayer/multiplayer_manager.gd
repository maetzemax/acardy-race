extends Node

@export var player_vehicle_scene: PackedScene
@export var local_player: VehicleBody3D
@export var spawn_offset: Vector3 = Vector3(5, 0, 0)

var remote_players: Dictionary = {}  # session_id -> vehicle_node
var multiplayer_service: Node = null


func _ready():
	# Find multiplayer service
	multiplayer_service = get_node("/root/MultiplayerService")
	
	# Connect signals
	multiplayer_service.player_joined.connect(_on_player_joined)
	multiplayer_service.player_left.connect(_on_player_left)
	multiplayer_service.remote_player_state_updated.connect(_on_remote_player_state_updated)


func _on_player_joined(session_id: String, username: String):
	print("Spawning remote player: %s" % username)
	
	# Spawn remote player vehicle
	if player_vehicle_scene:
		var remote_vehicle = player_vehicle_scene.instantiate()
		remote_vehicle.is_remote_player = true
		remote_vehicle.name = "RemotePlayer_%s" % session_id
		
		# Position next to local player
		if local_player:
			remote_vehicle.global_position = local_player.global_position + spawn_offset
			remote_vehicle.global_rotation = local_player.global_rotation
		
		get_parent().add_child(remote_vehicle)
		remote_players[session_id] = remote_vehicle
		
		print("Remote player spawned at: %s" % remote_vehicle.global_position)


func _on_player_left(session_id: String):
	if session_id in remote_players:
		var remote_vehicle = remote_players[session_id]
		remote_vehicle.queue_free()
		remote_players.erase(session_id)
		print("Remote player removed: %s" % session_id)


func _on_remote_player_state_updated(session_id: String, position: Vector3, rotation: Vector3):
	if session_id in remote_players:
		var remote_vehicle = remote_players[session_id]
		remote_vehicle.update_remote_state(position, rotation)
