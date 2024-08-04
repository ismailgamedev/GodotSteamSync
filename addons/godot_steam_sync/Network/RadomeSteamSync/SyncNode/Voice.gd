extends Synchronizer 
class_name VoiceSystem 

var current_sample_rate: int = 48000
var local_playback : AudioStreamGeneratorPlayback = null
var local_voice_buffer: PackedByteArray = PackedByteArray()
var use_optimal_sample_rate: bool = false
var DATA : Dictionary 
const REF_SAMPLE_RATE : int = 48000

@export var loopback_enabled : bool = false
@export var audio_node : AudioStreamPlayer 
@export var voice_key : String = "push_to_talk"

var streamplay : AudioStreamGenerator
var playback_stream : AudioStreamGeneratorPlayback  

func _ready():
	change_voice_settings(true)
	DATA = {
		"steam_id": NetworkManager.STEAM_ID,
		"TYPE": NetworkManager.TYPES.VOICE,
		"node_path": get_path(),
		"voice_data": {}
	}
	
	if NetworkManager.LOBBY_MEMBERS.size() > 1:
		loopback_enabled = false
	if audio_node != null:
		audio_node.stream.mix_rate = current_sample_rate
		audio_node.play()
		local_playback = audio_node.get_stream_playback()

	
func change_voice_settings(push_to_talk :bool):

	if push_to_talk:
		Steam.setInGameVoiceSpeaking(NetworkManager.STEAM_ID, false)
		Steam.stopVoiceRecording()
		set_process_input(true)
	else:
		Steam.setInGameVoiceSpeaking(NetworkManager.STEAM_ID, true)
		Steam.startVoiceRecording()
		set_process_input(false)
		
func record(voice : bool):
	Steam.setInGameVoiceSpeaking(NetworkManager.STEAM_ID, voice)
	
	if voice:
		Steam.startVoiceRecording()
	else:
		Steam.stopVoiceRecording()
		
func check_for_voice() -> void:
	var available_voice: Dictionary = Steam.getAvailableVoice()
	if available_voice['result'] == Steam.VOICE_RESULT_OK and available_voice['buffer'] > 0:
		
		var voice_data: Dictionary = Steam.getVoice()
		if voice_data['result'] == Steam.VOICE_RESULT_OK and voice_data['written']:
			
			DATA["voice_data"] = voice_data
			
			P2P._send_P2P_Packet(0,0, DATA,Steam.P2P_SEND_RELIABLE)
			if loopback_enabled:
				process_voice_data(voice_data)


func _process(_delta: float) -> void:
		

	if get_parent().name == str(NetworkManager.STEAM_ID):
		check_for_voice()
		if Input.is_action_pressed(voice_key):
			record(true)
		
		if Input.is_action_just_released(voice_key):
			record(false)

func get_sample_rate() -> void:
	var optimal_sample_rate: int = Steam.getVoiceOptimalSampleRate()
	# SpaceWar uses 11000 for sample rate?!
	# If are using Steam's "optimal" rate, set it; otherwise we default to 48000
	if use_optimal_sample_rate:
		current_sample_rate = optimal_sample_rate
	else:
		current_sample_rate = 48000

	
func process_voice_data(voice_data: Dictionary) -> void:
	get_sample_rate()
	var pitch : float = float(current_sample_rate)/REF_SAMPLE_RATE
	audio_node.set_pitch_scale(pitch)
	
	var decompressed_voice: Dictionary = Steam.decompressVoice(
			voice_data['buffer'], 
			voice_data['written'], 
			current_sample_rate)
			
	if (
			not decompressed_voice['result'] == Steam.VOICE_RESULT_OK
			or decompressed_voice['size'] == 0
	):
		return
	
	if local_playback != null:
		if local_playback.get_frames_available() <= 0:
			return
		
		local_voice_buffer = decompressed_voice['uncompressed']
		local_voice_buffer.resize(decompressed_voice['size'])
		
		for i: int in range(0, mini(local_playback.get_frames_available() * 2, local_voice_buffer.size()), 2):
			var raw_value = local_voice_buffer.decode_s16(i)
			# Convert the 16-bit integer to a float on from -1 to 1
			var amplitude: float = float(raw_value) / 32768.0
			local_playback.push_frame(Vector2(amplitude, amplitude))
			#local_voice_buffer.remove_at(0)
			#local_voice_buffer.remove_at(0)
	
