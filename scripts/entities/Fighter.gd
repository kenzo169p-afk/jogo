extends Node3D

# Fighter.gd - Low-poly pet/fighter logic.
# Smooth lerp orbit around player in idle state, dash & attack loop in combat state.

enum State { FOLLOW, ATTACK }

const ATTACK_INTERVAL = 0.5 # Attacks every 0.5 seconds
const ATTACK_RANGE = 2.4
const MOVE_SPEED = 18.0

var current_state: State = State.FOLLOW
var fighter_data: Dictionary = {}
var player_ref: Node3D = null
var slot_index: int = 0
var total_slots: int = 1

var dps: float = 25.0
var current_attack_interval: float = 0.5
var attack_timer: float = 0.0

@onready var mesh_body: MeshInstance3D = $MeshBody
@onready var aura_ring: MeshInstance3D = $AuraRing
@onready var attack_particles: CPUParticles3D = $AttackParticles
@onready var name_label: Label3D = $NameLabel

func setup(data: Dictionary, player: Node3D, index: int, total: int) -> void:
	fighter_data = data
	player_ref = player
	slot_index = index
	total_slots = total
	dps = float(data.get("dps", 25.0))
	
	var passive_id = data.get("passive_id", "none")
	var atk_speed = IslandData.calculate_fighter_atk_speed(passive_id)
	current_attack_interval = ATTACK_INTERVAL / max(0.1, atk_speed)
	
	# Apply visual styling
	var hex_col = data.get("mesh_color", "#ffffff")
	var color = Color(hex_col)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.45
	mesh_body.material_override = mat
	for child in mesh_body.get_children():
		if child is MeshInstance3D and child.name != "ChibiHead":
			child.material_override = mat
	
	var rarity = data.get("rarity", IslandData.RARITY_COMMON)
	var rarity_col = IslandData.RARITY_COLORS.get(rarity, Color.WHITE)
	if aura_ring:
		var aura_mat = StandardMaterial3D.new()
		aura_mat.albedo_color = rarity_col
		aura_mat.emission_enabled = true
		aura_mat.emission = rarity_col
		aura_mat.emission_energy_multiplier = 1.4
		aura_ring.material_override = aura_mat
	
	if name_label:
		var lvl = data.get("level", 1)
		var p_text = ""
		if passive_id != "none" and IslandData.PASSIVES.has(passive_id):
			p_text = "\n★ %s" % IslandData.PASSIVES[passive_id]["name"]
		name_label.text = "%s [Nv.%d]%s\n[%s]" % [data.get("name", "Lutador"), lvl, p_text, rarity]
		name_label.modulate = rarity_col

func _ready() -> void:
	top_level = true # Allows smooth global movement independent of player hierarchy
	if player_ref:
		global_position = player_ref.global_position + Vector3(0, 0.5, 2.0)

func _process(delta: float) -> void:
	var target = GameManager.current_target
	
	if target != null and is_instance_valid(target) and not target.is_queued_for_deletion():
		if target.has_method("is_dead") and target.is_dead():
			current_state = State.FOLLOW
		else:
			current_state = State.ATTACK
	else:
		current_state = State.FOLLOW
		
	match current_state:
		State.FOLLOW:
			_process_follow_state(delta)
		State.ATTACK:
			_process_attack_state(delta, target)

func _process_follow_state(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
		
	# Compute triangular formation offset relative to player facing direction
	var target_offset = _get_formation_offset()
	var player_basis = player_ref.global_transform.basis
	var desired_pos = player_ref.global_position + player_basis * target_offset
	
	# Gentle hovering bob effect
	var bob = sin(Time.get_ticks_msec() * 0.005 + slot_index * 1.5) * 0.15
	desired_pos.y += bob
	
	# Smooth lerp
	global_position = global_position.lerp(desired_pos, delta * 8.0)
	
	# Face forward relative to player
	var look_target = global_position - player_basis.z * 5.0
	look_target.y = global_position.y
	look_at(look_target, Vector3.UP)

func _process_attack_state(delta: float, target: Node) -> void:
	if not target or not is_instance_valid(target):
		current_state = State.FOLLOW
		return
		
	# Position fighters around the mob in a circle
	var angle = (float(slot_index) / float(maxi(1, total_slots))) * TAU
	var surround_offset = Vector3(cos(angle), 0, sin(angle)) * (ATTACK_RANGE * 0.8)
	var attack_spot = target.global_position + surround_offset
	attack_spot.y = target.global_position.y + 0.3
	
	var dist_to_spot = global_position.distance_to(attack_spot)
	
	if dist_to_spot > 0.4:
		# Dash to attack spot
		global_position = global_position.move_toward(attack_spot, MOVE_SPEED * delta)
	
	# Face enemy
	var enemy_pos = target.global_position
	enemy_pos.y = global_position.y
	if global_position.distance_squared_to(enemy_pos) > 0.01:
		look_at(enemy_pos, Vector3.UP)
		
	# Attack damage loop
	var dist_to_enemy = global_position.distance_to(target.global_position)
	if dist_to_enemy <= ATTACK_RANGE + 0.8:
		attack_timer += delta
		if attack_timer >= current_attack_interval:
			attack_timer = 0.0
			_strike(target)

func _strike(target: Node) -> void:
	if not target or not is_instance_valid(target):
		return
		
	var damage = dps * current_attack_interval
	if target.has_method("take_damage"):
		target.take_damage(damage, self)
		
	# Low-poly attack visual (hop forward and back)
	var tween = create_tween()
	var forward_dir = -global_transform.basis.z * 0.4
	tween.tween_property(self, "position", position + forward_dir, 0.08)
	tween.tween_property(self, "position", position, 0.12)
	
	if attack_particles:
		attack_particles.restart()

func _get_formation_offset() -> Vector3:
	match total_slots:
		1:
			return Vector3(0.0, 0.6, 2.4)
		2:
			if slot_index == 0:
				return Vector3(-1.8, 0.6, 2.0)
			else:
				return Vector3(1.8, 0.6, 2.0)
		3:
			if slot_index == 0:
				return Vector3(-1.8, 0.6, 1.8)
			elif slot_index == 1:
				return Vector3(1.8, 0.6, 1.8)
			else:
				return Vector3(0.0, 0.8, 3.0)
	return Vector3(0.0, 0.6, 2.0)
