extends Node

@onready var loadingScreen = preload("res://addons/godot_steam_sync/SceneChanger/LoadingScreen.tscn")

func change_scene(scene : String):
	Command.send("start_scene",[scene])
	NetworkManager.GAME_STARTED = false
	var instance = loadingScreen.instantiate()
	get_parent().add_child(instance)
	instance.change(scene)
	#get_tree().change_scene_to_file(scene)
	
