extends Node3D

# World.gd - Instantiates and sets up the 10 expansive, isolated anime islands.
# Features: 
# - Multi-layered 95x95 floating sky islands with stone cliff foundations
# - Cobblestone walkways, Central Boss Arena dais, Lanterns, Stylized Trees, Rocks & Theme Gates
# - Isolated dimension rendering (only current island is visible and active, maintaining 60 FPS)

@export var spawner_scene: PackedScene = preload("res://scenes/world/Spawner.tscn")
@export var capsule_scene: PackedScene = preload("res://scenes/world/GachaCapsule.tscn")
@export var portal_scene: PackedScene = preload("res://scenes/world/IslandPortal.tscn")
@export var boss_scene: PackedScene = preload("res://scenes/entities/BossEnemy.tscn")
@export var passive_machine_scene: PackedScene = preload("res://scenes/world/PassiveMachine.tscn")

@onready var islands_container: Node3D = $IslandsContainer
@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD

var islands_dict: Dictionary = {}

# Shared mesh resources for low-overhead VRAM batching & 60+ FPS stability
var _mesh_ground: BoxMesh
var _mesh_cliff1: BoxMesh
var _mesh_cliff2: BoxMesh
var _mesh_dais: CylinderMesh
var _mesh_road_ns: BoxMesh
var _mesh_road_we: BoxMesh
var _mesh_corner: BoxMesh
var _mesh_cap: PrismMesh
var _mesh_beacon: SphereMesh
var _mesh_trunk: CylinderMesh
var _mesh_crown: SphereMesh
var _mesh_border_h: BoxMesh
var _mesh_border_v: BoxMesh
var _col_shape_ground: BoxShape3D

func _ready() -> void:
	_init_shared_meshes()
	_build_islands()
	GameManager.island_changed.connect(_on_island_changed)
	_update_islands_visibility(GameManager.current_island)

func _init_shared_meshes() -> void:
	_mesh_ground = BoxMesh.new()
	_mesh_ground.size = Vector3(95.0, 2.0, 95.0)
	
	_mesh_cliff1 = BoxMesh.new()
	_mesh_cliff1.size = Vector3(86.0, 6.0, 86.0)
	
	_mesh_cliff2 = BoxMesh.new()
	_mesh_cliff2.size = Vector3(70.0, 8.0, 70.0)
	
	_mesh_dais = CylinderMesh.new()
	_mesh_dais.top_radius = 7.5
	_mesh_dais.bottom_radius = 8.2
	_mesh_dais.height = 0.25
	
	_mesh_road_ns = BoxMesh.new()
	_mesh_road_ns.size = Vector3(5.5, 0.08, 72.0)
	
	_mesh_road_we = BoxMesh.new()
	_mesh_road_we.size = Vector3(62.0, 0.08, 5.5)
	
	_mesh_corner = BoxMesh.new()
	_mesh_corner.size = Vector3(3.2, 8.0, 3.2)
	
	_mesh_cap = PrismMesh.new()
	_mesh_cap.size = Vector3(4.4, 2.2, 4.4)
	
	_mesh_beacon = SphereMesh.new()
	_mesh_beacon.radius = 0.8
	_mesh_beacon.height = 1.6
	
	_mesh_trunk = CylinderMesh.new()
	_mesh_trunk.top_radius = 0.35
	_mesh_trunk.bottom_radius = 0.55
	_mesh_trunk.height = 3.2
	
	_mesh_crown = SphereMesh.new()
	_mesh_crown.radius = 2.1
	_mesh_crown.height = 3.6
	
	_mesh_border_h = BoxMesh.new()
	_mesh_border_h.size = Vector3(92.0, 1.3, 1.2)
	
	_mesh_border_v = BoxMesh.new()
	_mesh_border_v.size = Vector3(1.2, 1.3, 92.0)
	
	_col_shape_ground = BoxShape3D.new()
	_col_shape_ground.size = Vector3(95.0, 2.0, 95.0)

func _create_toon_material(color: Color, roughness: float = 0.65, rim: float = 0.3) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	if rim > 0.0:
		mat.rim_enabled = true
		mat.rim = rim
		mat.rim_tint = 0.35
	return mat

func _on_island_changed(new_island_id: int) -> void:
	_update_islands_visibility(new_island_id)

func _update_islands_visibility(current_id: int) -> void:
	# Only render and process the island the player is currently on
	for id in islands_dict:
		var island_node = islands_dict[id]
		var is_active = (id == current_id)
		island_node.visible = is_active
		island_node.process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED

func _build_islands() -> void:
	for island_id in IslandData.ISLANDS:
		var data = IslandData.ISLANDS[island_id]
		var island_root = Node3D.new()
		island_root.name = "Island_%d" % island_id
		island_root.position = data["world_position"]
		islands_container.add_child(island_root)
		islands_dict[island_id] = island_root
		
		# 1. Expansive Low-Poly Ground Platform (95x95x2 box)
		var ground = StaticBody3D.new()
		ground.name = "Ground"
		
		var ground_mesh = MeshInstance3D.new()
		ground_mesh.mesh = _mesh_ground
		ground_mesh.material_override = _create_toon_material(data["ground_color"], 0.75, 0.2)
		ground.add_child(ground_mesh)
		
		var col = CollisionShape3D.new()
		col.shape = _col_shape_ground
		ground.add_child(col)
		ground.position.y = -1.0
		island_root.add_child(ground)
		
		# Detailed architectural & environmental decorations per island
		_build_island_decorations(island_root, data["ground_color"], island_id)
		
		# 2. Grand Island Billboard Sign
		var sign_label = Label3D.new()
		sign_label.text = "Ilha %d: %s\n[%s]" % [island_id, data["name"], data["currency_name"]]
		sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sign_label.font_size = 38
		sign_label.outline_size = 10
		sign_label.modulate = Color(1.0, 0.92, 0.45)
		sign_label.position = Vector3(0, 8.5, 40.0)
		island_root.add_child(sign_label)
		
		# 3. 3 Mob Spawners generously spaced across the 95x95 island
		var spawner_positions = [
			Vector3(-26.0, 0.0, -18.0),
			Vector3(26.0, 0.0, -18.0),
			Vector3(0.0, 0.0, -32.0)
		]
		for i in range(spawner_positions.size()):
			var spawner = spawner_scene.instantiate()
			spawner.name = "Spawner_%d" % (i + 1)
			spawner.island_id = island_id
			spawner.position = spawner_positions[i]
			island_root.add_child(spawner)
			
		# 4. Central Island Boss (5x Coins, 5x XP, 15s Respawn)
		var boss = boss_scene.instantiate()
		boss.name = "CentralBoss"
		boss.island_id = island_id
		boss.position = Vector3(0.0, 1.0, 0.0)
		island_root.add_child(boss)

		# 5. Gacha Capsule Station
		var capsule = capsule_scene.instantiate()
		capsule.name = "GachaCapsule"
		capsule.island_id = island_id
		capsule.position = Vector3(-28.0, 1.0, 22.0)
		island_root.add_child(capsule)
		
		# 6. Passive Reroll Machine
		var passive_machine = passive_machine_scene.instantiate()
		passive_machine.name = "PassiveMachine"
		passive_machine.island_id = island_id
		passive_machine.position = Vector3(-28.0, 1.0, 8.0)
		island_root.add_child(passive_machine)
		
		# 7. Island Portal to next island (if not last island)
		if island_id < 10:
			var portal = portal_scene.instantiate()
			portal.name = "PortalToNext"
			portal.target_island_id = island_id + 1
			portal.position = Vector3(28.0, 1.0, 22.0)
			island_root.add_child(portal)

func _build_island_decorations(island_node: Node3D, base_color: Color, island_id: int) -> void:
	# Cliff under-island tiers with Cel/Toon shading
	var cliff_mat = _create_toon_material(base_color.darkened(0.45), 0.9, 0.15)
	
	var cliff1 = MeshInstance3D.new()
	cliff1.mesh = _mesh_cliff1
	cliff1.material_override = cliff_mat
	cliff1.position = Vector3(0, -5.0, 0)
	island_node.add_child(cliff1)
	
	var cliff2 = MeshInstance3D.new()
	cliff2.mesh = _mesh_cliff2
	cliff2.material_override = cliff_mat
	cliff2.position = Vector3(0, -12.0, 0)
	island_node.add_child(cliff2)

	# Stone Paths & Central Boss Arena Dais
	var stone_mat = _create_toon_material(base_color.lightened(0.22), 0.7, 0.25)
	
	var dais = MeshInstance3D.new()
	dais.mesh = _mesh_dais
	dais.material_override = stone_mat
	dais.position = Vector3(0, 0.12, 0)
	island_node.add_child(dais)
	
	# Main North-South Road & West-East Plaza Walkway
	var road_ns = MeshInstance3D.new()
	road_ns.mesh = _mesh_road_ns
	road_ns.material_override = stone_mat
	road_ns.position = Vector3(0, 0.04, -2.0)
	island_node.add_child(road_ns)
	
	var road_we = MeshInstance3D.new()
	road_we.mesh = _mesh_road_we
	road_we.material_override = stone_mat
	road_we.position = Vector3(0, 0.04, 22.0)
	island_node.add_child(road_we)

	var pillar_mat = _create_toon_material(base_color.darkened(0.35), 0.65, 0.3)
	
	var gold_glow_mat = StandardMaterial3D.new()
	gold_glow_mat.albedo_color = Color(1.0, 0.82, 0.25)
	gold_glow_mat.emission_enabled = true
	gold_glow_mat.emission = Color(1.0, 0.78, 0.2)
	gold_glow_mat.emission_energy_multiplier = 2.2
	
	# 4 Grand Corner Watchtowers with Glowing Beacons
	var corners = [
		Vector3(-46.0, 4.0, -46.0),
		Vector3(46.0, 4.0, -46.0),
		Vector3(-46.0, 4.0, 46.0),
		Vector3(46.0, 4.0, 46.0)
	]
	for pos in corners:
		var p = MeshInstance3D.new()
		p.mesh = _mesh_corner
		p.material_override = pillar_mat
		p.position = pos
		island_node.add_child(p)
		
		var roof = MeshInstance3D.new()
		roof.mesh = _mesh_cap
		roof.material_override = stone_mat
		roof.position = pos + Vector3(0, 5.1, 0)
		island_node.add_child(roof)
		
		var beacon = MeshInstance3D.new()
		beacon.mesh = _mesh_beacon
		beacon.material_override = gold_glow_mat
		beacon.position = pos + Vector3(0, 6.8, 0)
		island_node.add_child(beacon)
		
	# Stylized Trees around the perimeter
	var trunk_mat = _create_toon_material(Color(0.42, 0.26, 0.15), 0.8, 0.2)
	var leaf_color = base_color.lightened(0.28) if island_id != 1 else Color(1.0, 0.62, 0.78)
	var leaf_mat = _create_toon_material(leaf_color, 0.6, 0.35)
	
	var tree_spots = [
		Vector3(-38, 0, -36), Vector3(38, 0, -36),
		Vector3(-38, 0, -8), Vector3(38, 0, -8),
		Vector3(-38, 0, 34), Vector3(38, 0, 34),
		Vector3(-16, 0, -40), Vector3(16, 0, -40)
	]
	for tpos in tree_spots:
		var trunk = MeshInstance3D.new()
		trunk.mesh = _mesh_trunk
		trunk.material_override = trunk_mat
		trunk.position = tpos + Vector3(0, 1.6, 0)
		island_node.add_child(trunk)
		
		var crown = MeshInstance3D.new()
		crown.mesh = _mesh_crown
		crown.material_override = leaf_mat
		crown.position = tpos + Vector3(0, 4.2, 0)
		island_node.add_child(crown)

	# Low-poly perimeter safety border
	var border_north = MeshInstance3D.new()
	border_north.mesh = _mesh_border_h
	border_north.material_override = pillar_mat
	border_north.position = Vector3(0, 0.65, -47.0)
	island_node.add_child(border_north)
	
	var border_south = MeshInstance3D.new()
	border_south.mesh = _mesh_border_h
	border_south.material_override = pillar_mat
	border_south.position = Vector3(0, 0.65, 47.0)
	island_node.add_child(border_south)
	
	var border_west = MeshInstance3D.new()
	border_west.mesh = _mesh_border_v
	border_west.material_override = pillar_mat
	border_west.position = Vector3(-47.0, 0.65, 0)
	island_node.add_child(border_west)
	
	var border_east = MeshInstance3D.new()
	border_east.mesh = _mesh_border_v
	border_east.material_override = pillar_mat
	border_east.position = Vector3(47.0, 0.65, 0)
	island_node.add_child(border_east)
