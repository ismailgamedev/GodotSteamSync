@icon("res://addons/godot_steam_sync/Network/RadomeSteamSync/SyncNode/propertySyncIcon.png")
class_name PropertySync extends Synchronizer


@export_group("SETTINGS","is")
## If true, onlu lobby owner will send the packet.
@export var is_only_lobby_owner : bool = false 


@export_group("NODES","object")
## Select player if its not player or not inside player you can make 'is_only_lobby_owner' true.
@export var object_player : Node 

@export_group("INTERPOLATION")
@export var is_interpolated :bool = false
@export var interpolation_value : float = 0.1

@export_group("")
@export var property_list : PackedStringArray## Hangi ozellikler yollayacaksak



var property_type : Array
var DATA : Array
var path : NodePath
var timer : Timer 

func init_timer():
	timer = Timer.new()
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	timer.wait_time = 0.1
	add_child(timer)
	timer.autostart = true
	timer.start()
	timer.connect("timeout",_on_timer_timeout)

func _ready():
	init_timer()
	
	if !is_interpolated:
		path = get_parent().get_path()
		set_process(false)
	else:
		path = get_path()
	if is_only_lobby_owner == false and object_player.name != str(NetworkManager.STEAM_ID):
		timer.stop()
	elif is_only_lobby_owner:
		if Steam.getLobbyOwner(NetworkManager.LOBBY_ID) != NetworkManager.STEAM_ID: 
			timer.stop()
		
	for property in property_list:
		var v = get_parent().get(property)
		property_type.append(v)

func _process(delta):
	# Data[0] property Data[1] value
	if (!DATA.is_empty()):
		get_parent().set(DATA[0],lerp(get_parent().get(DATA[0]),DATA[1],interpolation_value))
		
		

func _on_timer_timeout():
	for property in property_list.size():
		if property_type[property] != get_parent().get(property_list[property]) and NetworkManager.GAME_STARTED: 
			var DATA : Dictionary = {"player_id":NetworkManager.STEAM_ID,"TYPE":NetworkManager.TYPES.PROPERTY,"value":get_parent().get(property_list[property]),"node_path":path,"property":property_list[property],"interpolated":is_interpolated}
			P2P._send_P2P_Packet(0,0, DATA,Steam.P2P_SEND_RELIABLE)
			property_type[property] = get_parent().get(property_list[property])
			
func abort():
	timer.stop()
	set_process(false)
