extends CanvasLayer

func loaded_delete_loading():
	queue_free()
	NetworkManager.GAME_STARTED = true
