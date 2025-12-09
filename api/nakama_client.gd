extends Node

var client : NakamaClient
var session : NakamaSession

@onready var socket : NakamaSocket

func _ready():
	var device_id = OS.get_unique_id()
	
	client = Nakama.create_client("defaultkey", "92.205.25.104", 7350, "http")
	session = await client.authenticate_device_async(device_id)
	
	socket = Nakama.create_socket_from(client)
	var connected : NakamaAsyncResult = await socket.connect_async(session)
	
	if connected.is_exception():
		print("An error occurred: %s" % connected)
		return

	print("Socket connected.")
