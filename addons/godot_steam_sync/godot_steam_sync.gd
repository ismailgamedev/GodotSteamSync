@tool
extends EditorPlugin


func _enter_tree() -> void:

	add_autoload_singleton("NetworkManager","res://addons/godot_steam_sync/Network/RadomeSteamSync/NetworkManager.gd")
	add_autoload_singleton("P2P","res://addons/godot_steam_sync/Network/RadomeSteamSync/P2P.gd")
	add_autoload_singleton("Command","res://addons/godot_steam_sync/Network/RadomeSteamSync/SyncNode/CommandSync.gd")
	add_autoload_singleton("SceneManager","res://addons/godot_steam_sync/SceneChanger/SceneManager.gd")

	
	
func _exit_tree() -> void:
	remove_autoload_singleton("NetworkManager")
	remove_autoload_singleton("P2P")
	remove_autoload_singleton("Command")
	remove_autoload_singleton("SceneManager")

	
