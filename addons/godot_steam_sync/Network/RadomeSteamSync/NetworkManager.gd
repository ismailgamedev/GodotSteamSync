extends Node

var IS_ON_STEAM: bool = false
var IS_ON_STEAM_DECK: bool = false
var IS_ONLINE: bool = false
var IS_OWNED: bool = false
var STEAM_ID: int = 0
var STEAM_USERNAME: String = "No one"
var LOBBY_ID: int = 0
var LOBBY_MEMBERS: Array = []
var DATA : Dictionary
var LOBBY_MAX_MEMBERS: int = 4
var GAME_STARTED : bool = false
var IS_READY : Dictionary = {}

enum TYPES {START,READY,START_SCENE,TRANFORM_SYNC,PROPERTY,EVENT,RIGIDBODY_SYNC,SCENE_LOADED,COMMAND,VOICE,RAGDOLL}

@onready var player = preload("res://godotsteam_sync_example/Camera.tscn")


#region Initilazation
func _ready() -> void:
	_initialize_Steam()

	if IS_ON_STEAM_DECK:
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
func _initialize_Steam() -> void:
	if Engine.has_singleton("Steam"):
		var INIT: Dictionary = Steam.steamInitEx(true,480)

		# If the status isn't one, print out the possible error and quit the program
		if INIT['status'] != 0:
			print("[STEAM] Failed to initialize: "+str(INIT)+" Shutting down...")
			get_tree().quit()

		# Is the user actually using Steam; if false, the app assumes this is a non-Steam version
		IS_ON_STEAM = true
		# Checking if the app is on Steam Deck to modify certain behaviors
		IS_ON_STEAM_DECK = Steam.isSteamRunningOnSteamDeck()
		# Acquire information about the user
		IS_ONLINE = Steam.loggedOn()
		IS_OWNED = Steam.isSubscribed()
		STEAM_ID = Steam.getSteamID()
		STEAM_USERNAME = Steam.getPersonaName()
		
		# Check if account owns the game
		if IS_OWNED == false:
			print("[STEAM] User does not own this game")
			# Uncomment this line to close the game if the user does not own the game
			get_tree().quit()
func _process(_delta: float) -> void:
	if IS_ON_STEAM:
		Steam.run_callbacks()

#endregion
