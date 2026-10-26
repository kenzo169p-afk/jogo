extends CharacterBody3D

# Enemy.gd - Low-poly mob with health bar, floating damage numbers, and island coin drops.
# Notifies Spawner on defeat.

signal died(enemy_instance)

@export var island_id: int = 1
@export var patrol_radius: float = 2.0

var mob_name: String = "Inimigo"
var max_hp: float = 100.0
var current_hp: float = 100.0
var coin_drop: float = 20.0
var xp_reward: float = 15.0
var currency_id: String = IslandData.CURRENCY_ID
var currency_name: String = IslandData.CURRENCY_NAME

var spawn_origin: Vector3 = Vector3.ZERO
var patrol_target: Vector3 = Vector3.ZERO
var patrol_timer: float = 0.0
var _is_dead: bool = false

@onready var mesh_root: Node3D = $MeshRoot
@onready var health_bar_3d: Sprite3D = $HealthBar3D
@onready var viewport: SubViewport = $SubViewport
@onready var progress_bar: ProgressBar = $SubViewport/Panel/ProgressBar
@onready var name_label: Label = $SubViewport/Panel/NameLabel
@onready var hp_label: Label = $SubViewport/Panel/HpLabel
@onready var target_indicator: MeshInstance3D = $TargetIndicator
@onready var death_particles: CPUParticles3D = $DeathParticles

func setup(p_island_id: int, p_spawn_pos: Vector3) -> void:
	island_id = p_island_id
	spawn_origin = p_spawn_pos
	global_position = p_spawn_pos
	
	var data = IslandData.get_island(island_id)
	mob_name = data.get("mob_name", "Inimigo")
	max_hp = float(data.get("mob_hp", 100.0))
	current_hp = max_hp
	coin_drop = float(data.get("mob_drop", 10.0))
	xp_reward = float(data.get("mob_xp", 15.0))
	currency_id = data.get("currency_id", IslandData.CURRENCY_ID)
	currency_name = data.get("currency_name", IslandData.CURRENCY_NAME)
	
	_update_ui()
	_pick_new_patrol_point()

func _ready() -> void:
	add_to_group("enemy")
	if health_bar_3d and viewport:
		health_bar_3d.texture = viewport.get_texture()
	GameManager.target_changed.connect(_on_target_changed)
	if spawn_origin == Vector3.ZERO:
		spawn_origin = global_position
	_pick_new_patrol_point()
	_update_ui()

func _process(delta: float) -> void:
	if _is_dead:
		return
		
	# Minimal low-cost patrol in small radius
	if patrol_radius > 0.5:
		patrol_timer += delta
		if patrol_timer > 3.5:
			patrol_timer = 0.0
			_pick_new_patrol_point()
			
		var dir = (patrol_target - global_position)
		dir.y = 0.0
		if dir.length() > 0.2:
			global_position = global_position.move_toward(patrol_target, 1.2 * delta)
			var target_rot = atan2(dir.x, dir.z)
			mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rot, delta * 4.0)

func _pick_new_patrol_point() -> void:
	var angle = randf() * TAU
	var dist = randf_range(0.3, patrol_radius)
	patrol_target = spawn_origin + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func is_dead() -> bool:
	return _is_dead

func take_damage(amount: float, source: Node = null) -> void:
	if _is_dead:
		return
		
	current_hp = max(0.0, current_hp - amount)
	_spawn_damage_number(amount)
	_update_ui()
	
	# Visual hit flash / squash
	var tween = create_tween()
	tween.tween_property(mesh_root, "scale", Vector3(1.2, 0.8, 1.2), 0.05)
	tween.tween_property(mesh_root, "scale", Vector3(1.0, 1.0, 1.0), 0.1)
	
	if current_hp <= 0.0:
		_die()

func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	
	# Grant rewards (XP + coins + passives)
	GameManager.grant_kill_rewards(currency_id, coin_drop, xp_reward, false)
	
	if GameManager.current_target == self:
		GameManager.clear_target()
		
	# Death particles
	if death_particles:
		death_particles.restart()
		
	# Emit signal to spawner
	died.emit(self)
	
	# Fade and delete
	var tween = create_tween()
	tween.tween_property(mesh_root, "scale", Vector3.ZERO, 0.25)
	tween.tween_callback(queue_free)

func _spawn_damage_number(amount: float) -> void:
	var label = Label3D.new()
	label.text = "-%s" % IslandData.format_number(amount)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 28
	label.modulate = Color(1.0, 0.25, 0.25)
	label.outline_size = 6
	label.outline_modulate = Color.BLACK
	label.top_level = true
	
	var offset = Vector3(randf_range(-0.4, 0.4), randf_range(1.6, 2.2), randf_range(-0.4, 0.4))
	label.global_position = global_position + offset
	get_parent().add_child(label)
	
	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 1.4, 0.65)
	tween.tween_property(label, "modulate:a", 0.0, 0.65)
	tween.chain().tween_callback(label.queue_free)

func _update_ui() -> void:
	if progress_bar:
		progress_bar.max_value = max_hp
		progress_bar.value = current_hp
	if name_label:
		name_label.text = mob_name
	if hp_label:
		hp_label.text = "%s / %s" % [IslandData.format_number(current_hp), IslandData.format_number(max_hp)]

func _on_target_changed(new_target: Node) -> void:
	if target_indicator:
		target_indicator.visible = (new_target == self)
