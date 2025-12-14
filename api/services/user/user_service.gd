extends Node


func get_username() -> String:
	return RacingNakamaClient.user.username


func set_username(username):
	var response = await RacingNakamaClient.client.update_account_async(
		RacingNakamaClient.session,
		username
	)
	
	if response.is_exception():
		print("An error occurred: %s" % response)
		return null
	
	return response
