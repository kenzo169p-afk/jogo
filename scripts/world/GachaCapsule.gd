extends Area3D

# GachaCapsule.gd - Low-poly gacha capsule station on each island.
# Interacts when the player presses 'E' while inside the area or clicks on the capsule.

@export var island_id: int = 1

var is_player_inside: bool = false
var capsule_cost: int = 100
var currency_id: String = IslandData.CURRENCY_ID
var currency_name: String = IslandData.CURRENCY_NAME

@onready var mesh_capsule: MeshInstance3D = $MeshCapsule
@onready var prompt_label: Label3D = $PromptLabel
@onready var open_particles: CPUParticles3D = $OpenParticles

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)
	
	_update_info()

func _update_info() -> void:
	var data = IslandData.get_island(island_id)
	capsule_cost = data.get("capsule_cost", 100)
	currency_id = data.get("currency_id", IslandData.CURRENCY_ID)
	currency_name = data.get("currency_name", IslandData.CURRENCY_NAME)
	
	if prompt_label:
		prompt_label.text = "Cápsula %s\n[E] Abrir (%s %s)" % [
			data.get("name", ""),
			IslandData.format_number(capsule_cost),
			currency_name
		]
		prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if is_player_inside and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			try_open_capsule()

func _on_body_entered(body: Node3D) -> void:
	if body == GameManager.player_ref or body.is_in_group("player"):
		is_player_inside = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body == GameManager.player_ref or body.is_in_group("player"):
		is_player_inside = false
		if prompt_label:
			prompt_label.visible = false

func _on_input_event(_camera: Camera3D, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		try_open_capsule()

func try_open_capsule() -> void:
	var result = GameManager.gacha_pull(island_id)
	if not result.is_empty():
		# Quick visual punch
		if mesh_capsule:
			var tween = create_tween()
			tween.tween_property(mesh_capsule, "scale", Vector3(1.3, 0.7, 1.3), 0.08)
			tween.tween_property(mesh_capsule, "scale", Vector3(1.0, 1.0, 1.0), 0.12)
			
		if open_particles:
			var rarity_color = IslandData.RARITY_COLORS.get(result.get("rarity", IslandData.RARITY_COMMON), Color.WHITE)
			open_particles.color = rarity_color
			open_particles.restart()
