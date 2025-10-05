extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var sensitivity = 0.003

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	var move_forward = InputEventKey.new()
	move_forward.keycode = KEY_W
	InputMap.action_add_event("ui_up", move_forward)
	
	var move_backward = InputEventKey.new()
	move_backward.keycode = KEY_S
	InputMap.action_add_event("ui_down", move_backward)
	
	var move_left = InputEventKey.new()
	move_left.keycode = KEY_A
	InputMap.action_add_event("ui_left", move_left)
	
	var move_right = InputEventKey.new()
	move_right.keycode = KEY_D
	InputMap.action_add_event("ui_right", move_right)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		$Camera3D.rotate_x(-event.relative.y * sensitivity)
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -PI/2, PI/2)
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()

var arm_raise_speed = 2.0
var left_arm_rotation = 0.0
var right_arm_rotation = 0.0

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		left_arm_rotation = lerp(left_arm_rotation, deg_to_rad(90), delta * arm_raise_speed)
	else:
		left_arm_rotation = lerp(left_arm_rotation, 0.0, delta * arm_raise_speed)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		right_arm_rotation = lerp(right_arm_rotation, deg_to_rad(90), delta * arm_raise_speed)
	else:
		right_arm_rotation = lerp(right_arm_rotation, 0.0, delta * arm_raise_speed)
	
	$LeftArmPivot.rotation.x = left_arm_rotation
	$RightArmPivot.rotation.x = right_arm_rotation

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
