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

func _ready():
	if NetworkManager.GAME_STARTED:
		interval_pos = 1 / call_per_seccond_position
		interval_rot = 1 / call_per_seccond_rotation
		interval_scale = 1 / call_per_seccond_scale
		if not is_only_lobby_owner and object_player.name != str(NetworkManager.STEAM_ID):
			IS_OWNER = false
		elif is_only_lobby_owner and Steam.getLobbyOwner(NetworkManager.LOBBY_ID) != NetworkManager.STEAM_ID:
			IS_OWNER = false

func get_current_unix_time_ms() -> int:
	return Time.get_unix_time_from_system() * 1000

func sync_transform(last_property, packet_index_property: int, property_name: String):
	if get_parent().get(property_name) != last_property:
		var DATA: Dictionary = {
			"I": packet_index_property + 1,
			"PI": NetworkManager.STEAM_ID,
			"TS": get_current_unix_time_ms(),
			"T": NetworkManager.SEND_TYPE.TRANFORM_SYNC,
			"V": get_parent().get(property_name),
			"NP": get_path(),
			"P": property_name
		}
		P2P.send_P2P_Packet(0, 0, DATA, Steam.P2PSend.P2P_SEND_UNRELIABLE)
		packet_index_property += 1
		last_property = get_parent().get(property_name)
	return last_property

func recalculate_interpolation_offset_ms(interpolation_factor: float):
	if interpolation_factor > 1 and interpolation_offset_ms < 500:
		interpolation_offset_ms += 1
	elif interpolation_factor < 0 and interpolation_offset_ms > 1:
		interpolation_offset_ms -= 1

func read_transform(transform_buffer_index: int):
	var render_time := get_current_unix_time_ms() - interpolation_offset_ms

	if transform_buffer[transform_buffer_index] != null and NetworkManager.GAME_STARTED:
		if transform_buffer[transform_buffer_index]["I"] >= last_index_buffer[transform_buffer_index]:
			pos_buffer.append(transform_buffer[transform_buffer_index])
			
			
			
			if pos_buffer.size() > 2:
				while pos_buffer.size() > 2 and render_time > pos_buffer[1]["TS"]:
					pos_buffer.remove_at(0)

				if pos_buffer.size() < 2:
					return

				var start_pos = pos_buffer[0]["V"]
				var end_pos = pos_buffer[1]["V"]
				var start_time = pos_buffer[0]["TS"]
				var end_time = pos_buffer[1]["TS"]

				var time_diff := float(end_time - start_time)
				#if time_diff < 50:
					#return

				var interpolation_factor: float = float(render_time - start_time) / time_diff
				interpolation_factor = clamp(interpolation_factor, 0.0, 0.95)
				print("interpolation_factor: ", interpolation_factor)
				print("time_diff: ", interpolation_factor)
				var lerped_value = lerp(start_pos, end_pos, interpolation_factor)
				get_parent().set(transform_buffer[transform_buffer_index]["P"], lerped_value)
				last_index_buffer[transform_buffer_index] = transform_buffer[transform_buffer_index]["I"]



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
