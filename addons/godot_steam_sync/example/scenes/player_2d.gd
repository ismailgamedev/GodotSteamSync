extends CharacterBody2D



const SPEED = 90.0
const JUMP_VELOCITY = -180.0
var IS_OWNER : bool = false


var test_property : int = 0

var push_force = 10.0



func make_owner():
	IS_OWNER = true
	$Camera2D.enabled = true
	
func _physics_process(delta: float) -> void:
	$Label.text = str(test_property)
	if IS_OWNER:
		# This represents the player's inertia.
		


		# after calling move_and_slide()

		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction := Input.get_axis("ui_left", "ui_right")
		
		if direction > 0:
			$PlayerSprite.flip_h = false
		elif direction < 0:
			$PlayerSprite.flip_h = true

		
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * push_force)
			
func printergo(isim : String):
	print(isim)
	if IS_OWNER:
		$AFuncSync.call_f("printergo",0,[isim])
	
func _input(event: InputEvent) -> void:
	if IS_OWNER:
		if event is InputEventKey:
			if event.keycode == KEY_F1 and event.pressed:
				test_property += 1
			
