@icon("res://addons/godot_steam_sync/Network/RadomeSteamSync/SyncNode/transformSyncIcon.png")
class_name TransformSync2D extends Synchronizer

@export_group("SETTINGS")
@export var is_only_lobby_owner: bool = false
@export var call_per_seccond_position: float = 20
@export var call_per_seccond_rotation: float = 20
@export var call_per_seccond_scale: float = 20

@export_group("NODES", "object")
@export var object_player: Node

@export_group("")
@export var Position: bool = true
@export var Rotation: bool = false
@export var Scale: bool = false

var packet_index_pos: int = 0
var packet_index_rot: int = 0
var packet_index_scale: int = 0

var last_pos: Vector2 = Vector2.ZERO
var last_rot: float = 0
var last_scale: Vector2 = Vector2.ZERO

var transform_buffer: Array = [null, null, null]
var last_index_buffer: PackedInt32Array = [0, 0, 0]

var IS_OWNER: bool = true

var elapsed_time_pos: float = 0
var elapsed_time_rot: float = 0
var elapsed_time_scale: float = 0

var interval_pos: float = 1
var interval_rot: float = 1
var interval_scale: float = 1

var interpolation_offset_ms: int = 100
var pos_buffer: Array[Dictionary] = []

#var Cposition : Vector2 = Vector2.ZERO
#var Crotation : float = 0
#var Cscale :Vector2 = Vector2.ZERO

var parent : Node2D

func _ready():
	if NetworkManager.GAME_STARTED:
		interval_pos = 1 / call_per_seccond_position
		interval_rot = 1 / call_per_seccond_rotation
		interval_scale = 1 / call_per_seccond_scale
		
		if not is_only_lobby_owner and object_player.name != str(NetworkManager.STEAM_ID):
			IS_OWNER = false
		elif is_only_lobby_owner and Steam.getLobbyOwner(NetworkManager.LOBBY_ID) != NetworkManager.STEAM_ID:
			IS_OWNER = false
		parent = get_parent()
		
		#Cposition = parent.global_position
		#Crotation = parent.rotation
		#Cscale = parent.scale

func sync_transform(last_property, packet_index_property: int, property_name: String):
	if parent.get(property_name) != last_property:
		var DATA: Dictionary = {
			"I": packet_index_property + 1,
			"PI": NetworkManager.STEAM_ID,
			"T": NetworkManager.SEND_TYPE.TRANFORM_SYNC,
			"V": parent.get(property_name),
			"NP": get_path(),
			"P": property_name
		}
		P2P.send_P2P_Packet(0, 0, DATA, Steam.P2PSend.P2P_SEND_UNRELIABLE)
		packet_index_property += 1
		last_property = parent.get(property_name)
	return last_property


func read_transform(transform_buffer_index: int):
	var data : Dictionary = transform_buffer[transform_buffer_index]
	if data != null and NetworkManager.GAME_STARTED:
		if data["I"] >= last_index_buffer[transform_buffer_index]:
			var lerped_value = lerp(parent.get(data["P"]),data["V"],0.45)
			parent.set(data["P"],lerped_value)
			last_index_buffer[transform_buffer_index] = data["I"]
			
		
func _process(delta: float) -> void:
	if not IS_OWNER:
		if Position:
			read_transform(0)
		if Rotation:
			read_transform(1)
		if Scale:
			read_transform(2)
	else:
		if Position:
			elapsed_time_pos += delta
			while elapsed_time_pos >= interval_pos:
				elapsed_time_pos -= interval_pos
				last_pos = sync_transform(last_pos, packet_index_pos, "global_position")
		if Rotation:
			elapsed_time_rot += delta
			while elapsed_time_rot >= interval_rot:
				elapsed_time_rot -= interval_rot
				last_rot = sync_transform(last_rot, packet_index_rot, "rotation")
		if Scale:
			elapsed_time_scale += delta
			while elapsed_time_scale >= interval_scale:
				elapsed_time_scale -= interval_scale
				last_scale = sync_transform(last_scale, packet_index_scale, "scale")
