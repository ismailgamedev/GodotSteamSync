class_name RigidBodySync3D extends Synchronizer

@export var interpolation_value = 0.3

var packet_index: int = 0
var state_data  = null
var last_index : int = 0
var last_pos : Vector3 = Vector3.ZERO 
var pTimer : Timer

func init_timer():
	pTimer = Timer.new()
	pTimer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	pTimer.wait_time = 1.0 /30.0
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
		var DATA : Dictionary = {
			"I":packet_index,
			"PI":NetworkManager.STEAM_ID,
			"T":NetworkManager.TYPES.RIGIDBODY_SYNC,
			"V":[get_parent().linear_velocity,get_parent().angular_velocity,get_parent().position,get_parent().rotation],
			"NP":get_path()}
		P2P._send_P2P_Packet(0,0, DATA,Steam.P2P_SEND_UNRELIABLE)
		packet_index = packet_index + 1
		last_pos = get_parent().position



func update_physics_values():
	var target_linear_velocity = state_data["V"][0]
	var target_angular_velocity = state_data["V"][1]
	var target_position = state_data["V"][2]
	var target_rotation = state_data["V"][3]
	# Linear velocity için Lerp
	get_parent().linear_velocity = lerp(get_parent().linear_velocity, target_linear_velocity, interpolation_value)
	# Angular velocity için Lerp
	get_parent().angular_velocity = lerp(get_parent().angular_velocity, target_angular_velocity, interpolation_value)
	# Position için Lerp
	get_parent().position = lerp(get_parent().position, target_position, interpolation_value)
	# Rotation için Lerp (Quaternion için)
	get_parent().rotation = lerp(get_parent().rotation , target_rotation, interpolation_value)

func _physics_process(delta: float) -> void:
	await get_tree().create_timer(0.1).timeout
	if state_data != null and NetworkManager.GAME_STARTED:
		if state_data["I"] >= last_index :
			update_physics_values()
			
			last_index = state_data["I"]
