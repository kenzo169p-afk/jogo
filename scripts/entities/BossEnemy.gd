extends CharacterBody3D

# BossEnemy.gd - Grand central island boss with 5x coin drop, 5x XP reward, 
# prominent boss health bar, and 15-second respawn timer.

signal boss_died(boss_node)
signal boss_respawned(boss_node)

@export var island_id: int = 1

var boss_name: String = "Chefe"
var max_hp: float = 1000.0
var current_hp: float = 1000.0
var coin_drop: float = 100.0
var xp_reward: float = 75.0
var currency_id: String = IslandData.CURRENCY_ID
var currency_name: String = IslandData.CURRENCY_NAME

var spawn_origin: Vector3 = Vector3.ZERO
var _is_dead: bool = false
var respawn_timer: Timer

@onready var mesh_root: Node3D = $MeshRoot
@onready var health_bar_3d: Sprite3D = $HealthBar3D
@onready var viewport: SubViewport = $SubViewport
@onready var progress_bar: ProgressBar = $SubViewport/Panel/ProgressBar
@onready var name_label: Label = $SubViewport/Panel/NameLabel
@onready var hp_label: Label = $SubViewport/Panel/HpLabel
@onready var target_indicator: MeshInstance3D = $TargetIndicator
@onready var death_particles: CPUParticles3D = $DeathParticles
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func setup(p_island_id: int, p_spawn_pos: Vector3) -> void:
	island_id = p_island_id
	spawn_origin = p_spawn_pos
	global_position = p_spawn_pos
	
	var data = IslandData.get_island(island_id)
	boss_name = data.get("boss_name", "Grande Chefe")
	max_hp = float(data.get("boss_hp", 1000.0))
	current_hp = max_hp
	coin_drop = float(data.get("boss_drop", 20.0))
	xp_reward = float(data.get("boss_xp", 75.0))
	currency_id = data.get("currency_id", IslandData.CURRENCY_ID)
	currency_name = data.get("currency_name", IslandData.CURRENCY_NAME)
	
	_update_ui()

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	
	if health_bar_3d and viewport:
		health_bar_3d.texture = viewport.get_texture()
		
	GameManager.target_changed.connect(_on_target_changed)
	
	respawn_timer = Timer.new()
	respawn_timer.wait_time = 15.0 # Exactly 15 seconds as specified
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_respawn_boss)
	add_child(respawn_timer)
	
	if spawn_origin == Vector3.ZERO:
		spawn_origin = global_position
		setup(island_id, global_position)
	else:
		_update_ui()

func is_dead() -> bool:
	return _is_dead

func take_damage(amount: float, source: Node = null) -> void:
	if _is_dead:
		return
		
	current_hp = max(0.0, current_hp - amount)
	_spawn_damage_number(amount)
	_update_ui()
	
	# Boss hit punch animation
	var tween = create_tween()
	tween.tween_property(mesh_root, "scale", Vector3(2.1, 1.7, 2.1), 0.05)
	tween.tween_property(mesh_root, "scale", Vector3(1.9, 1.9, 1.9), 0.1)
	
	if current_hp <= 0.0:
		_die()

func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	
	# Grant double coin rewards and 5x XP rewards to player's equipped team
	GameManager.grant_kill_rewards(currency_id, coin_drop, xp_reward, true)
	
	if GameManager.current_target == self:
		GameManager.clear_target()
		
	if death_particles:
		death_particles.restart()
		
	boss_died.emit(self)
	
	# Hide and disable collision while waiting for 15s respawn
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	var tween = create_tween()
	tween.tween_property(mesh_root, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(func():
		mesh_root.visible = false
		if health_bar_3d:
			health_bar_3d.visible = false
	)
	
	# Start 15 second respawn timer
	respawn_timer.start(15.0)

func _respawn_boss() -> void:
	_is_dead = false
	current_hp = max_hp
	global_position = spawn_origin
	
	mesh_root.visible = true
	mesh_root.scale = Vector3.ZERO
	if health_bar_3d:
		health_bar_3d.visible = true
		
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
		
	_update_ui()
	
	# Reappear animation
	var tween = create_tween()
	tween.tween_property(mesh_root, "scale", Vector3(1.9, 1.9, 1.9), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	boss_respawned.emit(self)

func _spawn_damage_number(amount: float) -> void:
	var label = Label3D.new()
	label.text = "-%s" % IslandData.format_number(amount)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 34
	label.modulate = Color(1.0, 0.8, 0.1) # Golden/orange text for boss hits
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.top_level = true
	
	var offset = Vector3(randf_range(-0.6, 0.6), randf_range(2.8, 3.6), randf_range(-0.6, 0.6))
	label.global_position = global_position + offset
	get_parent().add_child(label)
	
	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 1.8, 0.75)
	tween.tween_property(label, "modulate:a", 0.0, 0.75)
	tween.chain().tween_callback(label.queue_free)

func _update_ui() -> void:
	if progress_bar:
		progress_bar.max_value = max_hp
		progress_bar.value = current_hp
	if name_label:
		name_label.text = "[CHEFE] %s" % boss_name
	if hp_label:
		hp_label.text = "%s / %s" % [IslandData.format_number(current_hp), IslandData.format_number(max_hp)]

func _on_target_changed(new_target: Node) -> void:
	if target_indicator:
		target_indicator.visible = (new_target == self)
