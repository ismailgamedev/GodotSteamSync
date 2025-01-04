extends HBoxContainer

@onready var profile_image : TextureRect = $AvatarTexture
@onready var profile_name : Label = $SteamUserNameLbl
var AVATAR: Image
# Is it ready? Do stuff!
func _ready():
	Steam.avatar_loaded.connect(_loaded_Avatar)
	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, NetworkManager.STEAM_ID)

	profile_name.text = NetworkManager.STEAM_USERNAME
func _loaded_Avatar(id: int, this_size: int, buffer: PackedByteArray) -> void:
	# Check we're only triggering a load for the right player, and check the data has actually changed
	if id == NetworkManager.STEAM_ID and (not AVATAR or not buffer == AVATAR.get_data()):
		# Create the image and texture for loading
		AVATAR = Image.create_from_data(this_size, this_size, false, Image.FORMAT_RGBA8, buffer)
		# Apply it to the texture
		var AVATAR_TEXTURE: ImageTexture = ImageTexture.create_from_image(AVATAR)
		# Set it
		profile_image.set_texture(AVATAR_TEXTURE)
