extends Node3D

# Spawner.gd - Manages the lifecycle of an enemy on an island spawn point.
# Automatically respawns an enemy 4 seconds after its death.

@export var island_id: int = 1
@export var respawn_time: float = 4.0
@export var enemy_scene: PackedScene = preload("res://scenes/entities/Enemy.tscn")

var current_enemy: Node = null
var respawn_timer: Timer

func _ready() -> void:
	respawn_timer = Timer.new()
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_spawn_enemy)
	add_child(respawn_timer)
	
	# Initial spawn
	_spawn_enemy()

func _spawn_enemy() -> void:
	if not enemy_scene:
		return
		
	var enemy = enemy_scene.instantiate()
	enemy.island_id = island_id
	enemy.position = Vector3.ZERO
	add_child(enemy)
	enemy.setup(island_id, global_position)
	enemy.died.connect(_on_enemy_died)
	current_enemy = enemy

func _on_enemy_died(_enemy_node: Node) -> void:
	current_enemy = null
	respawn_timer.start(respawn_time)
