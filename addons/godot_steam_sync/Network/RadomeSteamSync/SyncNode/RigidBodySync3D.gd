class_name RigidBodySync3D extends Synchronizer

var packet_index_velo : int = 0
var packet_index_ang_velo : int = 0

@export_category("Velocities") 
@export var Liner_Velocity : bool = true
@export var Angular_Velocity : bool = false

var transform_buffer : Array = [null,null]
var last_index_buffer : PackedInt32Array = [0,0]

var last_velocity : Vector3 = Vector3.ZERO
var last_angular_velocity : Vector3 = Vector3.ZERO

var velTimer : Timer
var angularTimer : Timer


func init_vel_timer():
	velTimer = Timer.new()
	velTimer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	velTimer.wait_time = 0.1
	add_child(velTimer)
	velTimer.autostart = true
	velTimer.start()
	velTimer.connect("timeout",_on_vel_timer_timeout)
func init_ang_timer():
	angularTimer = Timer.new()
	angularTimer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	angularTimer.wait_time = 0.1
	add_child(angularTimer)
	angularTimer.autostart = true
	angularTimer.start()
	angularTimer.connect("timeout",_on_angular_timer_timeout)

func _ready():
	init_vel_timer()
	init_ang_timer()
	if Steam.getLobbyOwner(NetworkManager.LOBBY_ID) != NetworkManager.STEAM_ID: 
		velTimer.stop()
		angularTimer.stop()
	
	
	
func _on_vel_timer_timeout():
	if get_parent().linear_velocity != last_velocity and NetworkManager.GAME_STARTED:
		var DATA : Dictionary = {"Idx":packet_index_velo,"player_id":NetworkManager.STEAM_ID,"TYPE":NetworkManager.TYPES.RIGIDBODY_SYNC,"value":get_parent().linear_velocity,"node_path":get_path(),"property":"linear_velocity"}
		P2P._send_P2P_Packet(0,0, DATA,Steam.P2P_SEND_UNRELIABLE)
		packet_index_velo = packet_index_velo + 1
		last_velocity = get_parent().linear_velocity
		
func _process(delta):
	if transform_buffer[0] != null and NetworkManager.GAME_STARTED:
		if transform_buffer[0]["Idx"] >= last_index_buffer[0] :
			get_parent().set(transform_buffer[0]["property"],transform_buffer[0]["value"])
			last_index_buffer[0] = transform_buffer[0]["Idx"]
	if transform_buffer[1] != null and NetworkManager.GAME_STARTED:
		if transform_buffer[1]["Idx"] >= last_index_buffer[1] :
			get_parent().set(transform_buffer[1]["property"],transform_buffer[1]["value"])
			last_index_buffer[1] = transform_buffer[1]["Idx"]


func _on_angular_timer_timeout():
	if get_parent().angular_velocity != last_angular_velocity and NetworkManager.GAME_STARTED:
		var DATA : Dictionary = {"Idx":packet_index_ang_velo,"player_id":NetworkManager.STEAM_ID,"TYPE":NetworkManager.TYPES.RIGIDBODY_SYNC,"value":get_parent().angular_velocity,"node_path":get_path(),"property":"angular_velocity"}
		P2P._send_P2P_Packet(0,0, DATA,Steam.P2P_SEND_UNRELIABLE)
		packet_index_ang_velo = packet_index_ang_velo + 1
		last_angular_velocity = get_parent().angular_velocity
