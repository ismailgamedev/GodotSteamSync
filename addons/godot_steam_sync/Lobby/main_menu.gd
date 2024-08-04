extends Control

@onready var online_text = $OnlineLbl





func _ready():

	if NetworkManager.IS_ONLINE:
		online_text.text = "online"
	else:
		online_text.text = "offline"
		

func _on_play_btn_pressed():
	get_tree().change_scene_to_file("res://addons/godot_steam_sync/Lobby/lobby_menu.tscn")

func _on_exit_btn_pressed():
	get_tree().quit()



