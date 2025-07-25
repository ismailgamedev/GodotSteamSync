extends Node
class_name PlayerSpawner 

var players_parent_node : Node3D = Node3D.new()
@export var spawn_positions : Array[Marker3D]


var object_spawn_finished : bool = false 



func _ready() -> void:
	if multiplayer.get_unique_id() != 1:
		SceneLoader.scene_loaded.rpc_id(1)
	else:
		SceneLoader.scene_loaded_server()
	


	players_parent_node.name = "Players"
	players_parent_node.position = Vector3(0,0,0)
	# Add Players Node to the scene. Players will be inside of this Node.
	get_tree().current_scene.call_deferred("add_child",players_parent_node)
	if NetworkManager.is_lobby_owner():
		for i in NetworkManager.network_data.MULTIPLAYER_MEMBERS.size():
			var id : int =NetworkManager.network_data.MULTIPLAYER_MEMBERS[i]
			print(id)
			var instance_player = NetworkManager.player.instantiate()
			instance_player.name = str(id)
			
			await get_tree().process_frame 
			
			var position_index = i % spawn_positions.size()
			var spawn_position = spawn_positions[position_index].global_position
			var spawn_rotation = spawn_positions[position_index].rotation
			
			instance_player.global_position = spawn_position
			instance_player.rotation = spawn_rotation
			
			players_parent_node.call_deferred("add_child",instance_player)
	else:
		for i in NetworkManager.network_data.MULTIPLAYER_MEMBERS.size():
			var id : int =NetworkManager.network_data.MULTIPLAYER_MEMBERS[i]
			var instance_player = NetworkManager.player.instantiate()
			instance_player.name = str(id)
			
			
			
			
			players_parent_node.call_deferred("add_child",instance_player)
		
