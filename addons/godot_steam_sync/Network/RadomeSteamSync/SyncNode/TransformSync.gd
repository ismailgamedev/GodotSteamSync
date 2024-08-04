@icon("res://addons/godot_steam_sync/Network/RadomeSteamSync/SyncNode/transformSyncIcon.png")
class_name TransformSync extends Synchronizer

@export_group("SETTINGS","is")
@export var is_only_lobby_owner : bool = false ## Sadece Lobby Owner Gonderecek
## TODO: Bunun mekaniğini yaz.
@export var is_not_player_object : bool = false ## Playerin icinde olan bir nesneden yollayacaksak paketi

@export_group("NODES","object")
@export var object_player : Node ## Karakteri sec eger lobby owner yollayacaksa gerek yok
#@export var non_player : bool = false
#@export var player : Node ## If it is a synchronization for a character, select your character from here. ( Like Camera and Camera Position ). If non-player is true you dont need to select any node.

@export_group("")
@export var Position : bool = true
@export var Rotation : bool = false
@export var Scale : bool = false


var packet_index_pos : int = 0
var packet_index_rot : int = 0
var packet_index_scale : int = 0



var last_pos : Vector3 = Vector3.ZERO
var last_rot : Vector3 = Vector3.ZERO
var last_scale : Vector3 = Vector3.ZERO

var transform_buffer : Array = [null,null,null]
var last_index_buffer : PackedInt32Array = [0,0,0]

var posTimer : Timer
var rotTimer : Timer
var sclTimer : Timer


func init_pos_timer():
	posTimer = Timer.new()
	posTimer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	posTimer.wait_time = 0.1
	add_child(posTimer)
	posTimer.autostart = true
	posTimer.start()
	posTimer.connect("timeout",_on_pos_timer_timeout)
func init_rot_timer():
	rotTimer = Timer.new()
	rotTimer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	rotTimer.wait_time = 0.1
	add_child(rotTimer)
	rotTimer.autostart = true
	rotTimer.start()
	rotTimer.connect("timeout",_on_rot_timer_timeout)
func init_scl_timer():
	sclTimer = Timer.new()
	sclTimer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	sclTimer.wait_time = 0.1
	add_child(sclTimer)
	sclTimer.autostart = true
	sclTimer.start()
	sclTimer.connect("timeout",_on_scale_timer_timeout)

func _ready():
	init_pos_timer()
	init_rot_timer()
	init_scl_timer()
	if is_not_player_object and object_player.name != str(NetworkManager.STEAM_ID):
		posTimer.stop()
		rotTimer.stop()
		sclTimer.stop()
	if is_only_lobby_owner == false and object_player.name != str(NetworkManager.STEAM_ID):
		posTimer.stop()
		rotTimer.stop()
		sclTimer.stop()
	elif is_only_lobby_owner:
		if Steam.getLobbyOwner(NetworkManager.LOBBY_ID) != NetworkManager.STEAM_ID: 
			posTimer.stop()
			rotTimer.stop()
			sclTimer.stop()
	
			
	if !Position:
		posTimer.stop()
	if !Rotation:
		rotTimer.stop()
	if !Scale:
		sclTimer.stop()
		
func _on_pos_timer_timeout():
	if get_parent().global_position != last_pos and NetworkManager.GAME_STARTED:
		var DATA : Dictionary = {"Idx":packet_index_pos + 1,"player_id":NetworkManager.STEAM_ID,"TYPE":NetworkManager.TYPES.TRANFORM_SYNC,"value":get_parent().global_position,"node_path":get_path(),"property":"global_position"}	
		P2P._send_P2P_Packet(0,0, DATA,Steam.P2P_SEND_UNRELIABLE)
		packet_index_pos = packet_index_pos + 1
		last_pos = get_parent().global_position

func _on_rot_timer_timeout():
	if get_parent().rotation != last_rot and NetworkManager.GAME_STARTED:
		var DATA : Dictionary = {"Idx":packet_index_rot + 1,"player_id":NetworkManager.STEAM_ID,"TYPE":NetworkManager.TYPES.TRANFORM_SYNC,"value":get_parent().rotation,"node_path":get_path(),"property":"rotation"}	
		P2P._send_P2P_Packet(0,0, DATA,Steam.P2P_SEND_UNRELIABLE)
		packet_index_rot = packet_index_rot + 1
		last_rot = get_parent().rotation

func _on_scale_timer_timeout():
	if get_parent().scale != last_scale and NetworkManager.GAME_STARTED:
		var DATA : Dictionary = {"Idx":packet_index_scale + 1,"player_id":NetworkManager.STEAM_ID,"TYPE":NetworkManager.TYPES.TRANFORM_SYNC,"value":get_parent().scale,"node_path":get_path(),"property":"scale"}	
		P2P._send_P2P_Packet(0,0, DATA,Steam.P2P_SEND_UNRELIABLE)
		packet_index_scale = packet_index_scale + 1
		last_scale = get_parent().scale

func _process(delta):
	if transform_buffer[0] != null and NetworkManager.GAME_STARTED:
		if transform_buffer[0]["Idx"] >= last_index_buffer[0] :
			var lerped_value = lerp(get_parent().get(transform_buffer[0]["property"]),transform_buffer[0]["value"],0.1)
			get_parent().set(transform_buffer[0]["property"],lerped_value)
			last_index_buffer[0] = transform_buffer[0]["Idx"]
	# Rotation
	if transform_buffer[1] != null and NetworkManager.GAME_STARTED:
		if transform_buffer[1]["Idx"] >= last_index_buffer[1]:
			var lerped_value = lerp(get_parent().get(transform_buffer[1]["property"]),transform_buffer[1]["value"],0.1)
			get_parent().set(transform_buffer[1]["property"],lerped_value)
			last_index_buffer[1] = transform_buffer[1]["Idx"]
	# Scale
	if transform_buffer[2] != null and NetworkManager.GAME_STARTED:
		if transform_buffer[2]["Idx"] >= last_index_buffer[2]:
			var lerped_value = lerp(get_parent().get(transform_buffer[2]["property"]),transform_buffer[2]["value"],0.1)
			get_parent().set(transform_buffer[2]["property"],lerped_value)
			last_index_buffer[2] = transform_buffer[2]["Idx"]
func abort():
	posTimer.stop()
	rotTimer.stop()
	sclTimer.stop()
	set_process(false)
