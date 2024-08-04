extends Panel

var STEAM_ID: int = 0

# Stored at the class level to enable comparisons when helper functions are called
var AVATAR: Image

# Is it ready? Do stuff!
func _ready():
	# connect some signals
	var SIGNAL_CONNECT: int = Steam.connect("avatar_loaded", Callable(self, "_loaded_Avatar"))

# Set this player up
func _set_Member(steam_id: int, steam_name: String) -> void:
	# Set the ID and username
	STEAM_ID = steam_id
	$MarginContainer/HBoxContainer/ScrollContainer/UsernameLbl.set_text(steam_name)
	# Get the avatar and show it
	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, STEAM_ID)
	
# Load an avatar
func _loaded_Avatar(id: int, this_size: int, buffer: PackedByteArray) -> void:
	# Check we're only triggering a load for the right player, and check the data has actually changed
	if id == STEAM_ID and (not AVATAR or not buffer == AVATAR.get_data()):
		# Create the image and texture for loading
		AVATAR = Image.create_from_data(this_size, this_size, false, Image.FORMAT_RGBA8, buffer)
		# Apply it to the texture
		var AVATAR_TEXTURE: ImageTexture = ImageTexture.create_from_image(AVATAR)
		# Set it
		$MarginContainer/HBoxContainer/Avatar.set_texture(AVATAR_TEXTURE)


func _on_view_btn_pressed():
	Steam.activateGameOverlayToUser("steamid", STEAM_ID)
