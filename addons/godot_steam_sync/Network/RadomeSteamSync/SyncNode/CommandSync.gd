extends Node

@onready var loadingScreen = preload("res://addons/godot_steam_sync/SceneChanger/LoadingScreen.tscn")
func send(method : String,args = null):
	var DATA : Dictionary = {"player_id":NetworkManager.STEAM_ID,"TYPE":NetworkManager.TYPES.COMMAND,"args":args,"method":method}
	P2P._send_P2P_Packet(0,0, DATA,Steam.P2P_SEND_RELIABLE)
	
	
func start_scene(scene : String):
	NetworkManager.GAME_STARTED = false
	var instance = loadingScreen.instantiate()
	get_parent().add_child(instance)
	instance.change(scene)
	
func set_dungeon_seed(seed) -> void:
	NetworkManager.DUNGEON_SEED = seed
