extends CharacterBody3D

signal hit

@export var speed = 14
@export var fall_acceleration = 75
# Vertical impulse applied to the character upon jumping in meters per second.
@export var jump_impulse = 20
# Vertical impulse applied to the character upon bouncing over a mob in
# meters per second.
@export var bounce_impulse = 16

@export_group("Trail")
@export var trail_color: Color = Color(1, 0.4, 0.2, 1)
@export var trail_width: float = 0.5
@export var sprint_multiplier: float = 2.0
@export var energy_start: int = 10000
@export var energy_deplete_per_sec: float = 1.0

var target_velocity = Vector3.ZERO
var trail: RibbonTrailMesh
var trail_instance: MeshInstance3D
var _trail_timer: float = 0.0
@export var trail_spawn_interval: float = 0.05
@export var trail_particle_scene: PackedScene
var is_sprinting: bool = false
var _prev_shift_down: bool = false
var _prev_l3_down: bool = false
var energy: float = 0.0
var _energy_label: Label

func _ready():
	trail = RibbonTrailMesh.new()
	trail.size = trail_width
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = trail_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# material is applied on the MeshInstance3D, not the mesh resource
	
	var curve = Curve.new()
	curve.min_value = 0.0
	curve.max_value = 1.0
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	trail.curve = curve

	trail_instance = MeshInstance3D.new()
	trail_instance.mesh = trail
	trail_instance.material_override = mat
	$Pivot.add_child(trail_instance)

	energy = float(energy_start)
	# Try to locate the EnergyLabel in the current scene UI
	var ui := get_tree().current_scene.get_node_or_null("UserInterface/EnergyLabel")
	if ui is Label:
		_energy_label = ui

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Energy drains at a fixed rate per second
	if energy > 0.0:
		energy = max(0.0, energy - energy_deplete_per_sec * delta)

	# Sprint toggle: Shift key or controller L3 (button index 9)
	var shift_down: bool = Input.is_key_pressed(KEY_SHIFT)
	var l3_down: bool = Input.is_joy_button_pressed(0, 9)
	if (shift_down and not _prev_shift_down) or (l3_down and not _prev_l3_down):
		is_sprinting = not is_sprinting
	_prev_shift_down = shift_down
	_prev_l3_down = l3_down

	if direction != Vector3.ZERO:
		$Pivot.look_at(position + direction)
		$AnimationPlayer.speed_scale = 4
	else:
		$AnimationPlayer.speed_scale = 1

	# Ground Velocity (apply sprint multiplier when toggled)
	var current_speed: float = speed * (sprint_multiplier if is_sprinting else 1.0)
	target_velocity.x = direction.x * current_speed
	target_velocity.z = direction.z * current_speed

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# Jumping.
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse

# Iterate through all collisions that occurred this frame
	for index in range(get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)

		# If there are duplicate collisions with a mob in a single frame
		# the mob will be deleted after the first collision, and a second call to
		# get_collider will return null, leading to a null pointer when calling
		# collision.get_collider().is_in_group("mob").
		# This block of code prevents processing duplicate collisions.
		if collision.get_collider() == null:
			continue

		# If the collider is with a mob
		if collision.get_collider().is_in_group("mob"):
			var mob = collision.get_collider()
			# we check that we are hitting it from above.
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				# If so, we squash it and bounce.
				mob.squash()
				target_velocity.y = bounce_impulse
				# Prevent further duplicate calls.
				break
				
	$Pivot.rotation.x = PI / 6 * velocity.y / jump_impulse

	# Spawn trail particles while moving
	if direction != Vector3.ZERO and is_instance_valid(trail_particle_scene):
		_trail_timer += delta
		if _trail_timer >= trail_spawn_interval:
			_trail_timer = 0.0
			var p = trail_particle_scene.instantiate()
			if p is Node3D:
				p.global_transform = $Pivot.global_transform
				get_tree().current_scene.add_child(p)

	# Moving the Character
	velocity = target_velocity
	move_and_slide()

	# Update energy label text if available
	if _energy_label:
		_energy_label.text = "Energy: %d" % int(energy)

# And this function at the bottom.
func die():
	hit.emit()
	queue_free()

func _on_mob_detector_body_entered(body: Node3D) -> void:
	#pass # Replace with function body.
	die()
	
