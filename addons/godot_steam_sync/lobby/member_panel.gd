extends Panel


var AVATAR: Image
var STEAM_ID :int
func _ready():
	# connect some signals
	var SIGNAL_CONNECT: int = Steam.connect("avatar_loaded", Callable(self, "_loaded_Avatar"))

func _loaded_Avatar(id: int, this_size: int, buffer: PackedByteArray) -> void:
	# Check we're only triggering a load for the right player, and check the data has actually changed
	if id == STEAM_ID and (not AVATAR or not buffer == AVATAR.get_data()):
		# Create the image and texture for loading
		AVATAR = Image.create_from_data(this_size, this_size, false, Image.FORMAT_RGBA8, buffer)
		# Apply it to the texture
		var AVATAR_TEXTURE: ImageTexture = ImageTexture.create_from_image(AVATAR)
		# Set it
		$MarginContainer/HBoxContainer/MemberTexture.set_texture(AVATAR_TEXTURE)

func set_member_panel(steam_id:int,steam_name:String) -> void:
	STEAM_ID = steam_id
	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, steam_id)
	$MarginContainer/HBoxContainer/MemberLbl.text =str(steam_name)
