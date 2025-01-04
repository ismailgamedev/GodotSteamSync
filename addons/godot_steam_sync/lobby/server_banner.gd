extends Panel



var lobby_id : int = 0
func set_server_banner(name : String,max_players : int,current_players : int,_lobby_id :int) -> void:
	
	$HBoxContainer/LobbyNameLbl.text = name
	# CurrentPlayers/MaxPlayers
	$HBoxContainer/MarginContainer2/PlayersLbl.text = "%s/%s" % [current_players,max_players]
	lobby_id = _lobby_id

func _on_join_to_lobby_pressed() -> void:
	get_tree().current_scene.call("join_lobby",lobby_id)
