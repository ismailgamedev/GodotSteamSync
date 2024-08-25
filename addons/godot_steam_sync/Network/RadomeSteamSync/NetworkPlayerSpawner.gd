class_name NetworkPlayerSpawner extends Node

## Where the players will be spawned.
@export var spawn_pos : Node  
## The node the players will be in after they are spawned. It has to be at the center of the scene. It has to be named 'Players'.
@export var players_parent_node : Node
## Here you can choose which way each spawned player will move. If you choose an axis, the player born will automatically move one unit away. If the game is 2D, choosing the Z axis means the center.
@export_flags("X" ,"Y" ,"Z") var spawn_distance_axis = 1 

@export var increase_spawn_distance : Vector3 

func _ready(): 
	players_parent_node.name = "Players"
	if spawn_pos is Node3D:
		for player in NetworkManager.LOBBY_MEMBERS.size():
			var instance_player : Node = NetworkManager.player.instantiate()
			instance_player.name = str(NetworkManager.LOBBY_MEMBERS[player]["steam_id"])
			var direction = spawn_check() 
			match direction:
				"CENTER":
					instance_player.transform.origin = spawn_pos.transform.origin + Vector3(0, 0, 0)
				"X":
					instance_player.transform.origin = spawn_pos.transform.origin + Vector3(player + increase_spawn_distance.x, 0, 0)
				"Y":
					instance_player.transform.origin = spawn_pos.transform.origin + Vector3(0, player + increase_spawn_distance.y, 0)
				"Z":
					instance_player.transform.origin = spawn_pos.transform.origin + Vector3(0, 0, player + increase_spawn_distance.z)
				"XY":
					instance_player.transform.origin = spawn_pos.transform.origin + Vector3(player + increase_spawn_distance.x, player + increase_spawn_distance.y, 0)
				"XZ":
					instance_player.transform.origin = spawn_pos.transform.origin + Vector3(player + increase_spawn_distance.x, 0, player + increase_spawn_distance.z)
				"YZ":
					instance_player.transform.origin = spawn_pos.transform.origin + Vector3(0, player + increase_spawn_distance.y, player + increase_spawn_distance.z)
				"XYZ":
					instance_player.transform.origin = spawn_pos.transform.origin + Vector3(player + increase_spawn_distance.x, player + increase_spawn_distance.y, player + increase_spawn_distance.z)
				_:
					instance_player.transform.origin = spawn_pos.transform.origin + Vector3(0, 0, 0)  
			players_parent_node.add_child(instance_player)
			
			if instance_player.name == str(NetworkManager.STEAM_ID):
				instance_player.make_owner()
			NetworkManager.GAME_STARTED = true
	if spawn_pos is Node2D:
		for player in NetworkManager.LOBBY_MEMBERS.size():
			var instance_player : Node = NetworkManager.player.instantiate()
			instance_player.name = str(NetworkManager.LOBBY_MEMBERS[player]["steam_id"])
			var direction = spawn_check() 

			match direction:
				"CENTER":
					instance_player.position = spawn_pos.position + Vector2(0, 0)
				"X":
					instance_player.position = spawn_pos.position + Vector2(player + increase_spawn_distance.x, 0)
				"Y":
					instance_player.position = spawn_pos.position + Vector2(0, player + increase_spawn_distance.y)
				"XY":
					instance_player.position = spawn_pos.position + Vector2(player + increase_spawn_distance.x, player + increase_spawn_distance.y)
				_:
					instance_player.position = spawn_pos.position + Vector2(0, 0)  
			players_parent_node.add_child(instance_player)
			if instance_player.name == str(NetworkManager.STEAM_ID):
				instance_player.make_owner()
			NetworkManager.GAME_STARTED = true

func spawn_check() -> String:
	match spawn_distance_axis:
		0:
			return "CENTER"
		1:
			return "X"
		2:
			return "Y"
		3:
			return "XY"
		4:
			return "Z"
		5:
			return "XZ"
		6:
			return "YZ"
		7:
			return "XYZ"   
		_:
			return "CENTER"  
	return "CENTER"
