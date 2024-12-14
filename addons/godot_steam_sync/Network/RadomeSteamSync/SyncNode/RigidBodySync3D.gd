class_name RigidBodySync3D extends Synchronizer

var packet_index: int = 0


var transform_buffer  = null
var last_index_buffer : int = 0

var last_pos : Vector3 = Vector3.ZERO 

var pTimer : Timer

func init_timer():
	pTimer = Timer.new()
	pTimer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	pTimer.wait_time = 1.0 /60.0
	add_child(pTimer)
	pTimer.autostart = true
	pTimer.start()
	pTimer.connect("timeout",_on_timer_timeout)

func _ready():
	init_timer()
	if Steam.getLobbyOwner(NetworkManager.LOBBY_ID) != NetworkManager.STEAM_ID: 
		pTimer.stop()
	
func _on_timer_timeout():
	if get_parent().position != last_pos and NetworkManager.GAME_STARTED:
		var DATA : Dictionary = {"Idx":packet_index,"player_id":NetworkManager.STEAM_ID,"TYPE":NetworkManager.TYPES.RIGIDBODY_SYNC,"value":[get_parent().linear_velocity,get_parent().angular_velocity,get_parent().position,get_parent().rotation],"node_path":get_path()}
		P2P._send_P2P_Packet(0,0, DATA,Steam.P2P_SEND_UNRELIABLE)
		packet_index = packet_index + 1
		last_pos = get_parent().position

var lerp_speed = 0.1 

func update_physics_values():
	var target_linear_velocity = transform_buffer["value"][0]
	var target_angular_velocity = transform_buffer["value"][1]
	var target_position = transform_buffer["value"][2]
	var target_rotation = transform_buffer["value"][3]
	# Linear velocity için Lerp
	get_parent().linear_velocity = lerp(get_parent().linear_velocity, target_linear_velocity, lerp_speed)
	# Angular velocity için Lerp
	get_parent().angular_velocity = lerp(get_parent().angular_velocity, target_angular_velocity, lerp_speed)
	# Position için Lerp
	get_parent().position = lerp(get_parent().position, target_position, lerp_speed)
	# Rotation için Lerp (Quaternion için)
	get_parent().rotation = lerp(get_parent().rotation , target_rotation, lerp_speed)

func _physics_process(delta: float) -> void:
	await get_tree().create_timer(0.1).timeout
	if transform_buffer != null and NetworkManager.GAME_STARTED:
		if transform_buffer["Idx"] >= last_index_buffer :
			update_physics_values()
			
			last_index_buffer = transform_buffer["Idx"]
