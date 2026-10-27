extends CharacterBody3D

# Player.gd - Low-poly third-person controller with camera orbit, enemy click-selection,
# and management of up to 3 active low-poly fighters.

const WALK_SPEED = 12.0
const SPRINT_SPEED = 24.0
const JUMP_VELOCITY = 8.5
const TARGET_MAX_DISTANCE = 40.0

@export var mouse_sensitivity: float = 0.005
@export var fighter_scene: PackedScene = preload("res://scenes/entities/Fighter.tscn")

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var fighter_container: Node3D = $FighterContainer
@onready var mesh_root: Node3D = $MeshRoot
@onready var sprint_particles: CPUParticles3D = $SprintParticles
@onready var left_arm: Node3D = $MeshRoot.get_node_or_null("LeftArm")
@onready var right_arm: Node3D = $MeshRoot.get_node_or_null("RightArm")
@onready var left_leg: Node3D = $MeshRoot.get_node_or_null("LeftLeg")
@onready var right_leg: Node3D = $MeshRoot.get_node_or_null("RightLeg")
@onready var scarf_mesh: Node3D = $MeshRoot.get_node_or_null("ScarfMesh")

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var is_right_mouse_down: bool = false
var is_sprinting: bool = false
var active_fighters: Array = []

func _ready() -> void:
	GameManager.player_ref = self
	GameManager.equipped_changed.connect(_update_active_fighters)
	_update_active_fighters()

func _exit_tree() -> void:
	if GameManager.player_ref == self:
		GameManager.player_ref = null

func _unhandled_input(event: InputEvent) -> void:
	# Right-click drag rotates camera (Roblox / MMO style)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_right_mouse_down = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_raycast_select_target(event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - 0.7, 3.0, 16.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + 0.7, 3.0, 16.0)

	if event is InputEventMouseMotion and is_right_mouse_down:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-70), deg_to_rad(30))
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_Q:
			GameManager.clear_target()
		elif event.keycode == KEY_C:
			GameManager.request_open_achievements_ui()

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Check Sprint input (Shift)
	is_sprinting = Input.is_key_pressed(KEY_SHIFT)
	var current_speed = SPRINT_SPEED if is_sprinting else WALK_SPEED

	# Movement direction relative to camera
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		input_dir.x += 1.0
		
	input_dir = input_dir.normalized()

	var cam_basis = camera_pivot.global_transform.basis
	var forward = -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right = cam_basis.x
	right.y = 0.0
	right = right.normalized()

	var direction = (forward * (-input_dir.y) + right * input_dir.x).normalized()

	if direction.length_squared() > 0.001:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		# Rotate mesh towards movement direction
		var target_rot = atan2(-direction.x, -direction.z)
		mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rot, delta * 14.0)
		
		# Procedural running bob and limb swing effect
		var bob_speed = 22.0 if is_sprinting else 14.0
		var bob_height = 0.12 if is_sprinting else 0.06
		var t = Time.get_ticks_msec() * 0.001 * bob_speed
		mesh_root.position.y = abs(sin(t)) * bob_height
		
		var swing_amp = 0.85 if is_sprinting else 0.5
		if left_arm and right_arm:
			left_arm.rotation.x = sin(t) * swing_amp
			right_arm.rotation.x = -sin(t) * swing_amp
		if left_leg and right_leg:
			left_leg.rotation.x = -sin(t) * swing_amp
			right_leg.rotation.x = sin(t) * swing_amp
		if scarf_mesh:
			scarf_mesh.rotation.x = deg_to_rad(35.0 if is_sprinting else 20.0) + sin(t * 1.5) * 0.12
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * delta * 8.0)
		velocity.z = move_toward(velocity.z, 0, current_speed * delta * 8.0)
		mesh_root.position.y = move_toward(mesh_root.position.y, 0, delta * 2.0)
		if left_arm and right_arm:
			left_arm.rotation.x = lerp(left_arm.rotation.x, 0.0, delta * 10.0)
			right_arm.rotation.x = lerp(right_arm.rotation.x, 0.0, delta * 10.0)
		if left_leg and right_leg:
			left_leg.rotation.x = lerp(left_leg.rotation.x, 0.0, delta * 10.0)
			right_leg.rotation.x = lerp(right_leg.rotation.x, 0.0, delta * 10.0)
		if scarf_mesh:
			scarf_mesh.rotation.x = lerp(scarf_mesh.rotation.x, deg_to_rad(15.0), delta * 6.0)

	# Dynamic Camera FOV during sprint (70 to 84 degrees)
	if camera:
		var target_fov = 84.0 if (is_sprinting and direction.length_squared() > 0.1) else 70.0
		camera.fov = lerp(camera.fov, target_fov, delta * 6.0)

	# Foot dust particles while sprinting on ground
	if sprint_particles:
		sprint_particles.emitting = (is_sprinting and is_on_floor() and direction.length_squared() > 0.1)

	move_and_slide()
	
	# Target distance check
	_check_current_target_validity()

func _raycast_select_target(screen_pos: Vector2) -> void:
	if not camera:
		return
	var ray_origin = camera.project_ray_origin(screen_pos)
	var ray_end = ray_origin + camera.project_ray_normal(screen_pos) * 100.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 0xFFFFFFFF & ~4 # ignore scenery collision layer
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		# Check if it's an enemy or child of enemy
		var hit_node = collider
		while hit_node and not hit_node.is_in_group("enemy") and hit_node != get_tree().root:
			hit_node = hit_node.get_parent()
			
		if hit_node and hit_node.is_in_group("enemy") and hit_node.has_method("take_damage"):
			if GameManager.current_target == hit_node:
				GameManager.clear_target()
			else:
				GameManager.set_target(hit_node)
			return

func _check_current_target_validity() -> void:
	var target = GameManager.current_target
	if target == null:
		return
		
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		GameManager.clear_target()
		return
		
	if target.has_method("is_dead") and target.is_dead():
		GameManager.clear_target()
		return
		
	var dist = global_position.distance_to(target.global_position)
	if dist > TARGET_MAX_DISTANCE:
		GameManager.clear_target()

# --- FIGHTER MANAGEMENT ---
func _update_active_fighters() -> void:
	# Clear old fighters
	for child in fighter_container.get_children():
		child.queue_free()
	active_fighters.clear()
	
	var equipped_list = GameManager.get_equipped_fighters()
	var count = equipped_list.size()
	
	for i in range(count):
		var f_data = equipped_list[i]
		var f_instance = fighter_scene.instantiate()
		fighter_container.add_child(f_instance)
		f_instance.setup(f_data, self, i, count)
		active_fighters.append(f_instance)
