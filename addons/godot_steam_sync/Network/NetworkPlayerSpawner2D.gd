extends Node
class_name NetworkPlayerSpawner2D

var players_parent_node : Node2D = Node2D.new()
@export var spawn_positions : Array[Marker2D]

func _ready() -> void:
	players_parent_node.name = "Players"
	players_parent_node.position = Vector2(0,0)
	# Add Players Node to the scene. Players will be inside of this Node.
	get_tree().current_scene.call_deferred("add_child",players_parent_node)
	for player in NetworkManager.LOBBY_MEMBERS.size():
		var instance_player : Node = NetworkManager.player.instantiate()
		instance_player.name = str(NetworkManager.LOBBY_MEMBERS[player]["steam_id"])
		
		var position_index = player % spawn_positions.size()
		var spawn_position = spawn_positions[position_index].position
		
		players_parent_node.call_deferred("add_child",instance_player)
		instance_player.position = spawn_position
		
		if instance_player.name == str(NetworkManager.STEAM_ID):
			instance_player.make_owner()
	NetworkManager.GAME_STARTED = true
