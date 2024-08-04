@icon("res://addons/godot_steam_sync/Network/RadomeSteamSync/SyncNode/funcSyncIcon.png")
class_name FuncSync extends Synchronizer
 
signal FuncCalled(method : String,args)

func _ready() -> void:
	connect("FuncCalled",_on_func_called)

func call_f(method : String,args = null):
	emit_signal("FuncCalled",method,args)
	
func _on_func_called(method, args):
	if  NetworkManager.GAME_STARTED:
		var DATA : Dictionary = {"player_id":NetworkManager.STEAM_ID,"TYPE":NetworkManager.TYPES.EVENT,"args":args,"node_path":get_parent().get_path(),"method":method}
		P2P._send_P2P_Packet(0,0, DATA,Steam.P2P_SEND_RELIABLE)
