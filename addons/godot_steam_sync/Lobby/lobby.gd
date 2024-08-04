extends Control

@onready var lobby_name_txt = $CreateLobbyCont/LobbyNameTxt
@onready var lobby_visibility = $CreateLobbyCont/LobbyVisibilityBtn
@onready var max_members = $CreateLobbyCont/MaxMembersBtn
@onready var lobby_member = preload("res://addons/godot_steam_sync/Lobby/lobby_member.tscn")
@onready var lobby_name_lbl = $LobbyPanel/MarginContainer/LobbyCont/Panel/LobbyNameLbl
@onready var start_btn = $LobbyPanel/MarginContainer/LobbyCont/StartBtn
var im_ready : bool = false
func _ready() -> void:
	Steam.join_requested.connect(_on_lobby_join_requested)
	#Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created)
	#Steam.lobby_data_update.connect(_on_lobby_data_update)
	#Steam.lobby_invite.connect(_on_lobby_invite)
	Steam.lobby_joined.connect(_on_lobby_joined)
	#Steam.lobby_match_list.connect(_on_lobby_match_list)
	#Steam.lobby_message.connect(_on_lobby_message)
	Steam.persona_state_change.connect(_on_persona_change)
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	Steam.p2p_session_connect_fail.connect(_on_p2p_session_connect_fail)


	# Check for command line arguments
	check_command_line()
	
func check_command_line() -> void:
	var these_arguments: Array = OS.get_cmdline_args()

	# There are arguments to process
	if these_arguments.size() > 0:

		# A Steam connection argument exists
		if these_arguments[0] == "+connect_lobby":

			# Lobby invite exists so try to connect to it
			if int(these_arguments[1]) > 0:

				# At this point, you'll probably want to change scenes
				# Something like a loading into lobby screen
				print("Command line lobby ID: %s" % these_arguments[1])
				join_lobby(int(these_arguments[1]))
				
#region JoinLobbyRegion
func join_lobby(this_lobby_id: int) -> void:
	print("Attempting to join lobby %s" % this_lobby_id)

	# Clear any previous lobby members lists, if you were in a previous lobby
	NetworkManager.LOBBY_MEMBERS.clear()

	# Make the lobby join request to Steam
	Steam.joinLobby(this_lobby_id)

func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int):
	# If joining succeed, this will be 1
	if response == 1:
		# Set this lobby ID as your lobby ID
		NetworkManager.LOBBY_ID = lobby_id
		# Print the lobby ID to a label
		lobby_name_lbl.set_text(Steam.getLobbyData(NetworkManager.LOBBY_ID,"name"))
		# Append to output
		print("[STEAM] Joined lobby "+str(NetworkManager.LOBBY_ID)+".\n")
		# Get the lobby members
		get_lobby_members()
		# Make the initial handshake
		make_p2p_handshake()
		change_lobby_ui(true)
		
	# Else it failed for some reason
	else:
		# Get the failure reason
		var FAIL_REASON: String
		match response:
			2:	FAIL_REASON = "This lobby no longer exists."
			3:	FAIL_REASON = "You don't have permission to join this lobby."
			4:	FAIL_REASON = "The lobby is now full."
			5:	FAIL_REASON = "Uh... something unexpected happened!"
			6:	FAIL_REASON = "You are banned from this lobby."
			7:	FAIL_REASON = "You cannot join due to having a limited account."
			8:	FAIL_REASON = "This lobby is locked or disabled."
			9:	FAIL_REASON = "This lobby is community locked."
			10:	FAIL_REASON = "A user in the lobby has blocked you from joining."
			11:	FAIL_REASON = "A user you have blocked is in the lobby."
		$Frame/Main/Displays/Outputs/Output.append_text("[STEAM] Failed joining lobby "+str(lobby_id)+": "+str(FAIL_REASON)+"\n")
		# Reopen the server list
		#_on_Open_Lobby_List_pressed()

func _on_lobby_join_requested(lobby_id: int, friend_id: int):
	# Get the lobby owner's name
	var OWNER_NAME = Steam.getFriendPersonaName(friend_id)
	print("[STEAM] Joining "+str(OWNER_NAME)+"'s lobby...\n")
	# Attempt to join the lobby
	join_lobby(lobby_id)
#endregion

func change_lobby_ui(current : bool):
	if current:
		$CreateLobbyCont.hide()
		$LobbyPanel.show()
		$MembersPnl.show()
	else:
		$CreateLobbyCont.show()
		$LobbyPanel.hide()
		$MembersPnl.hide()
	
#region CreateLobbyRegion
func _on_create_lobby_btn_pressed():
	if NetworkManager.LOBBY_ID == 0:
		Steam.createLobby(lobby_visibility.get_selected_id(), int(max_members.get_item_text(max_members.get_selected_id())))
		
func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
	if connect == 1:
		# Set the lobby ID
		NetworkManager.LOBBY_ID = this_lobby_id
		print("Created a lobby: %s" % NetworkManager.LOBBY_ID )
		# Set this lobby as joinable, just in case, though this should be done by default
		Steam.setLobbyJoinable(NetworkManager.LOBBY_ID, true)
		# Set some lobby data
		Steam.setLobbyData(NetworkManager.LOBBY_ID, "name", lobby_name_txt.text)
		Steam.setLobbyData(NetworkManager.LOBBY_ID, "mode", "Mechatronauts")

		# Allow P2P connections to fallback to being relayed through Steam if needed
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		
		get_lobby_members()
		change_lobby_ui(true)
#endregion
func get_lobby_members() -> void:
	# Clear your previous lobby list
	NetworkManager.LOBBY_MEMBERS.clear()
	for MEMBER in $MembersPnl/MarginContainer/ScrollContainer/VBoxContainer.get_children():
		MEMBER.hide()
		MEMBER.queue_free()
	# Get the number of members from this lobby from Steam
	var num_of_members: int = Steam.getNumLobbyMembers(NetworkManager.LOBBY_ID)

	# Get the data of these players from Steam
	for this_member in range(0, num_of_members):
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(NetworkManager.LOBBY_ID, this_member)
		
		# Get the member's Steam name
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)

		# Add them to the list
		add_member_to_list(member_steam_id,member_steam_name)
		if NetworkManager.STEAM_ID == Steam.getLobbyOwner(NetworkManager.LOBBY_ID):
			NetworkManager.IS_READY[member_steam_id] = false

		else:
			start_btn.hide()
			start_btn.disabled = true
			
# A user's information has changed
func _on_persona_change(this_steam_id: int, _flag: int) -> void:
	# Make sure you're in a lobby and this user is valid or Steam might spam your console log
	if NetworkManager.LOBBY_ID > 0:
		print("A user (%s) had information change, update the lobby list" % this_steam_id)
		# Update the player list
		get_lobby_members()
		
func add_member_to_list(steam_id: int, steam_name: String):
	print("Adding new player to the list: "+str(steam_id)+" / "+str(steam_name))
	# Add them to the list
	NetworkManager.LOBBY_MEMBERS.append({"steam_id":steam_id, "steam_name":steam_name })
	# Instance the lobby member object
	var THIS_MEMBER: Object = lobby_member.instantiate()
	# Add their Steam name and ID
	THIS_MEMBER.name = str(steam_id)
	THIS_MEMBER._set_Member(steam_id, steam_name)
	# Add the child node
	$MembersPnl/MarginContainer/ScrollContainer/VBoxContainer.add_child(THIS_MEMBER)
	

#region P2PHandshake
func make_p2p_handshake() -> void:
	print("Sending P2P handshake to the lobby")
	P2P._send_P2P_Packet(0,0, {"message": "handshake", "from": NetworkManager.STEAM_ID},Steam.P2P_SEND_RELIABLE)
	
func _on_p2p_session_request(remote_id: int) -> void:
	# Get the requester's name
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	print("%s is requesting a P2P session" % this_requester)
	# Accept the P2P session; can apply logic to deny this request if needed
	Steam.acceptP2PSessionWithUser(remote_id)
	# Make the initial handshake
	make_p2p_handshake()
#endregion
	
#region LobbyEvents
func _on_p2p_session_connect_fail(lobby_id: int, session_error: int) -> void:
	# Note the session errors are: 0 - none, 1 - target user not running the same game, 2 - local user doesn't own app, 3 - target user isn't connected to Steam, 4 - connection timed out, 5 - unused
	# If no error was given
	if session_error == 0:
		print("[WARNING] Session failure with "+str(lobby_id)+" [no error given].")
	# Else if target user was not running the same game
	elif session_error == 1:
		print("[WARNING] Session failure with "+str(lobby_id)+" [target user not running the same game].")
	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("[WARNING] Session failure with "+str(lobby_id)+" [local user doesn't own app / game].")
	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("[WARNING] Session failure with "+str(lobby_id)+" [target user isn't connected to Steam].")
	# Else if connection timed out
	elif session_error == 4:
		print("[WARNING] Session failure with "+str(lobby_id)+" [connection timed out].")
	# Else if unused
	elif session_error == 5:
		print("[WARNING] Session failure with "+str(lobby_id)+" [unused].")
	# Else no known error
	else:
		print("[WARNING] Session failure with "+str(lobby_id)+" [unknown error "+str(session_error)+"].")
		
func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	# Get the user who has made the lobby change
	var changer_name: String = Steam.getFriendPersonaName(change_id)

	# If a player has joined the lobby
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s has joined the lobby." % changer_name)

	# Else if a player has left the lobby
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		print("%s has left the lobby." % changer_name)

	# Else if a player has been kicked
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		print("%s has been kicked from the lobby." % changer_name)

	# Else if a player has been banned
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		print("%s has been banned from the lobby." % changer_name)

	# Else there was some unknown change
	else:
		print("%s did... something." % changer_name)

	# Update the lobby now that a change has occurred
	get_lobby_members()
#endregion
		
func _on_ready_btn_pressed():
	
	if NetworkManager.STEAM_ID == Steam.getLobbyOwner(NetworkManager.LOBBY_ID):
		im_ready = !im_ready
		#for ready in NetworkManager.IS_READY.keys():
			#if ready == NetworkManager.STEAM_ID:
		NetworkManager.IS_READY[NetworkManager.STEAM_ID] = im_ready
	else:
		im_ready = !im_ready
		P2P._send_P2P_Packet(0,Steam.getLobbyOwner(NetworkManager.LOBBY_ID),{"TYPE":NetworkManager.TYPES.READY,"steam_id":NetworkManager.STEAM_ID,"ready":im_ready},Steam.P2P_SEND_RELIABLE)

func _on_start_btn_pressed():
	if NetworkManager.STEAM_ID == Steam.getLobbyOwner(NetworkManager.LOBBY_ID):
		var result = NetworkManager.IS_READY.values().all(func(number): return number == true)
		if result:
			SceneManager.change_scene("res://godotsteam_sync_example/Test.tscn")
			
