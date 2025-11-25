extends Node

var client : NakamaClient
var session : NakamaSession

func _ready():
	var device_id = OS.get_unique_id()
	
	client = Nakama.create_client("defaultkey", "92.205.25.104", 7350, "http")
	session = await client.authenticate_device_async(device_id)
