extends Node

const PACKET_READ_LIMIT: int = 32

func _process(_delta: float) -> void:
	# Get packets only if lobby is joined
	if NetworkManager.LOBBY_ID > 0:
		_read_All_P2P_Packets()

			
func _read_P2P_Packet() -> void:
	var packet_size0 : int = Steam.getAvailableP2PPacketSize(0)

	
	#region Channel0
	if packet_size0 > 0:
		var this_packet0 : Dictionary = Steam.readP2PPacket(packet_size0, 0)
		
		if this_packet0.is_empty() or this_packet0 == null:
			print("WARNING: read an empty packet with non-zero size!")

		# Get the remote user's ID
		var packet_sender: int = this_packet0['remote_steam_id']

		# Make the packet data readablev
		var packet_code: PackedByteArray = this_packet0['data']

		# Decompress the array before turning it into a useable dictionary
		var READABLE: Dictionary = bytes_to_var(packet_code.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
		
			# Append logic here to deal with packet data
		if READABLE.has("T"):
			handle_packets(READABLE)

	#endregion
	

func _read_All_P2P_Packets(read_count: int = 0) -> void:
	if read_count >= PACKET_READ_LIMIT:
		return
	if Steam.getAvailableP2PPacketSize(0) > 0:
		_read_P2P_Packet()
		_read_All_P2P_Packets(read_count + 1)
var packet_size : float
func send_P2P_Packet(channel: int,target: int, packet_data: Dictionary,send_type: int) -> bool:
	# Create a data array to send the data through
	var this_data: PackedByteArray

	# Compress the PackedByteArray we create from our dictionary  using the GZIP compression method
	var compressed_data: PackedByteArray = var_to_bytes(packet_data).compress(FileAccess.COMPRESSION_GZIP)
	this_data.append_array(compressed_data)
	packet_size = this_data.size()
	# If sending a packet to everyone
	if target == 0:
		# If there is more than one user, send packets
		if NetworkManager.LOBBY_MEMBERS.size() > 1:
			# Loop through all members that aren't you
			for this_member in NetworkManager.LOBBY_MEMBERS:
				if this_member['steam_id'] != NetworkManager.STEAM_ID:
					return Steam.sendP2PPacket(this_member['steam_id'], this_data, send_type, channel)
	else:
		return Steam.sendP2PPacket(target, this_data, send_type, channel)
	return false
func handle_start_packet(READABLE):
	# This packet reading when someone ready
	if READABLE["T"] == NetworkManager.SEND_TYPE.READY:
		for member in NetworkManager.MEMBERS_DATA:
			if member["steam_id"] == READABLE["PI"]:
				member["ready"] = READABLE["ready"]

		
func handle_event_packets(READABLE):
	if READABLE["T"] == NetworkManager.SEND_TYPE.COMMAND:
		print("COMMAND:" + READABLE["method"] + str(READABLE["args"]))
		if READABLE["args"] != null:
			Command.callv(READABLE["method"],READABLE["args"])
		else:
			Command.call(READABLE["method"])
			
	if READABLE['T'] == NetworkManager.SEND_TYPE.EVENT:
		if READABLE["args"] != null:
			get_tree().root.get_node(READABLE["NP"]).callv(READABLE["method"],READABLE["args"]) 
		else:
			get_tree().root.get_node(READABLE["NP"]).call(READABLE["method"])
	
			
func handle_property_packets(READABLE):	
	
	if READABLE['T'] == NetworkManager.SEND_TYPE.TRANFORM_SYNC and NetworkManager.GAME_STARTED:
		if READABLE["P"] == "global_position":
			get_node(READABLE["NP"]).transform_buffer[0] = READABLE
		if READABLE["P"] == "rotation":
			get_node(READABLE["NP"]).transform_buffer[1] = READABLE
		if READABLE["P"] == "scale":
			get_node(READABLE["NP"]).transform_buffer[2] = READABLE

	if READABLE["T"] == NetworkManager.SEND_TYPE.RAGDOLL and NetworkManager.GAME_STARTED:
		get_tree().root.get_node(READABLE["NP"]).transform_buffer = READABLE
				
	if READABLE["T"] == NetworkManager.SEND_TYPE.RIGIDBODY_SYNC and NetworkManager.GAME_STARTED:
		get_tree().root.get_node(READABLE["NP"]).transform_buffer = READABLE
	
	if READABLE["T"] == NetworkManager.SEND_TYPE.PROPERTY and NetworkManager.GAME_STARTED:
		if !READABLE["ITP"]:
			get_tree().root.get_node(READABLE["NP"]).set(READABLE["P"],READABLE["V"])
		else:
			var DATA :Array = [READABLE["P"],READABLE["V"]]
			get_tree().root.get_node(READABLE["NP"]).DATA = DATA
	## 
	
	
func handle_voice(READABLE):
	if READABLE["T"] == NetworkManager.SEND_TYPE.VOICE and NetworkManager.GAME_STARTED:
		get_tree().root.get_node(READABLE["NP"]).process_voice_data(READABLE["voice_data"])
		#await get_tree().create_timer(0.1).timeout

func handle_packets(READABLE):
	handle_start_packet(READABLE)
	handle_event_packets(READABLE)
	handle_property_packets(READABLE)
	handle_voice(READABLE)
