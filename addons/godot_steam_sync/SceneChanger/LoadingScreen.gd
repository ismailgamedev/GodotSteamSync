extends CanvasLayer


func change(scene_name: String):
	await get_tree().create_timer(0.1).timeout
	if get_tree().change_scene_to_file(scene_name) != 0:
		printerr("Wrong Scene Path " + str(scene_name))

func _process(delta):
	if NetworkManager.GAME_STARTED == true:
		queue_free()
