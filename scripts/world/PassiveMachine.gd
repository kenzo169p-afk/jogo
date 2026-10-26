extends Area3D

# PassiveMachine.gd - Low-poly 3D reroll station.
# Interacts when the player presses 'E' while inside or clicks on the machine.

@export var island_id: int = 1

var is_player_inside: bool = false
var reroll_cost: int = 50
var currency_id: String = IslandData.CURRENCY_ID
var currency_name: String = IslandData.CURRENCY_NAME

@onready var crystal_mesh: MeshInstance3D = $CrystalMesh
@onready var prompt_label: Label3D = $PromptLabel
@onready var sparkle_particles: CPUParticles3D = $SparkleParticles

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)
	_update_info()

func _process(delta: float) -> void:
	if crystal_mesh:
		crystal_mesh.rotate_y(delta * 1.8)
		crystal_mesh.position.y = 2.2 + sin(Time.get_ticks_msec() * 0.003) * 0.12

func _update_info() -> void:
	var data = IslandData.get_island(island_id)
	reroll_cost = data.get("reroll_cost", 50)
	currency_id = data.get("currency_id", IslandData.CURRENCY_ID)
	currency_name = data.get("currency_name", IslandData.CURRENCY_NAME)
	
	if prompt_label:
		prompt_label.text = "Máquina de Passivas (%s)\n[E] Rolar (%s %s)" % [
			data.get("name", ""),
			IslandData.format_number(reroll_cost),
			currency_name
		]
		prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if is_player_inside and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			interact()

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
		interact()

func interact() -> void:
	if crystal_mesh:
		var tween = create_tween()
		tween.tween_property(crystal_mesh, "scale", Vector3(1.3, 1.3, 1.3), 0.1)
		tween.tween_property(crystal_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.15)
	if sparkle_particles:
		sparkle_particles.restart()
	GameManager.request_open_passive_ui(island_id)
