@icon("res://Network/RadomeSteamSync/SyncNode/transformSyncIcon.png")
class_name RagDollSync extends Synchronizer

@export_group("SETTINGS","is")
@export var is_only_lobby_owner : bool = false ## Sadece Lobby Owner Gonderecek

@export_group("NODES","object")
@export var object_player : Node ## Karakteri sec eger lobby owner yollayacaksa gerek yok

@export var interpolation : float = 0.35

signal simulating(status : bool)

var bones : Array[PhysicalBone3D]
var packet_index_pos : int = 0
var last_pos : Array[Vector3]
var transform_buffer : Dictionary = {}
var last_index_buffer : int 
var timer : Timer 

func init_timer():
	timer = Timer.new()
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	timer.wait_time = 0.1
	add_child(timer)
	timer.connect("timeout",_on_pos_timer_timeout)

func _ready():
	init_timer()
	get_all_bones()
	
func get_pos_bone() -> Array[Vector3]:
	var pos : Array[Vector3]
	for bone in bones:
		pos.append(bone.global_transform.origin)
 
	return pos
	
func get_all_bones():
	for i in get_parent().get_children():
		if is_instance_of(i,PhysicalBone3D):
			bones.append(i)
			
func _on_pos_timer_timeout():

	if get_pos_bone() != last_pos and NetworkManager.GAME_STARTED:
		var pos = get_pos_bone()
		var DATA : Dictionary = {"Idx":packet_index_pos + 1,"TYPE":NetworkManager.TYPES.RAGDOLL,"value":pos,"node_path":get_path()}	
		P2P._send_P2P_Packet(0,0, DATA,Steam.P2P_SEND_UNRELIABLE)
		packet_index_pos = packet_index_pos + 1
		last_pos = pos
func _physics_process(delta):
	if transform_buffer.has("Idx") and NetworkManager.GAME_STARTED:
		if transform_buffer["Idx"] >= last_index_buffer :
			set_pos_bone(transform_buffer["value"]) 

func set_pos_bone(DATA):
	for i in range(bones.size()):
		var lerped_value = lerp(bones[i].global_transform.origin,DATA[i],interpolation)
		bones[i].global_transform.origin = lerped_value
		last_index_buffer = transform_buffer["Idx"]

func abort():
	set_process(false)
	timer.stop()

func _on_simulating(status : bool):
	if status== true:
		if is_only_lobby_owner and Steam.getLobbyOwner(NetworkManager.LOBBY_ID) == NetworkManager.STEAM_ID:
			timer.start()
		elif !is_only_lobby_owner and str(NetworkManager.STEAM_ID) == object_player.name:
			timer.start()
	else:
		timer.stop()
