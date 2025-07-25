extends Node


var MEMBERS_LOADED : Dictionary = {}
var loading : PackedScene = preload("res://addons/godot_steam_sync/SceneLoader/loading.tscn")
var instance_loading
func load_scene(path : String):
	
	load_scene_RPC.rpc(path)
	

@rpc("authority","call_local")
func load_scene_RPC(path : String):
	MEMBERS_LOADED.clear()
	instance_loading = loading.instantiate()
	call_deferred("add_child",instance_loading)
	if multiplayer.get_unique_id() == 1:
		MEMBERS_LOADED[1] = false
		for id in multiplayer.get_peers():
			MEMBERS_LOADED[id] = false
	get_tree().change_scene_to_file(path)
	
@rpc("any_peer","call_remote")
func scene_loaded():
	MEMBERS_LOADED[multiplayer.get_remote_sender_id()] = true
	if all_loaded(MEMBERS_LOADED):
		instance_loading.loaded_delete_loading.rpc()
		
func scene_loaded_server():
	MEMBERS_LOADED[1] = true
	if all_loaded(MEMBERS_LOADED):
		instance_loading.loaded_delete_loading.rpc()

func all_loaded(my_array : Dictionary) -> bool:
	return my_array.values().all(func(value): return value)
