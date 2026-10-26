extends Area3D

# IslandPortal.gd - Interactive portal that allows unlocking and teleporting to the next island.

@export var target_island_id: int = 2

var is_player_inside: bool = false
@onready var prompt_label: Label3D = $PromptLabel
@onready var portal_ring: MeshInstance3D = $PortalRing

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameManager.island_unlocked.connect(_on_island_unlocked)
	_update_prompt()

func _process(delta: float) -> void:
	# Subtle low-cost spin of portal ring
	if portal_ring:
		portal_ring.rotate_z(delta * 1.5)

func _update_prompt() -> void:
	if not prompt_label:
		return
		
	var target_data = IslandData.get_island(target_island_id)
	var is_unlocked = GameManager.is_island_unlocked(target_island_id)
	
	if is_unlocked:
		prompt_label.text = "Portal para: %s\n[E] Entrar" % target_data.get("name", "")
		prompt_label.modulate = Color(0.3, 1.0, 0.4)
	else:
		var cost = target_data.get("unlock_cost", 0)
		var curr_name = target_data.get("unlock_currency_name", "")
		prompt_label.text = "Desbloquear: %s\n[E] Custo: %s %s" % [
			target_data.get("name", ""),
			IslandData.format_number(cost),
			curr_name
		]
		prompt_label.modulate = Color(1.0, 0.8, 0.2)

func _unhandled_input(event: InputEvent) -> void:
	if is_player_inside and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_interact()

func _interact() -> void:
	var is_unlocked = GameManager.is_island_unlocked(target_island_id)
	if is_unlocked:
		GameManager.teleport_to_island(target_island_id)
	else:
		if GameManager.unlock_island(target_island_id):
			GameManager.teleport_to_island(target_island_id)
			_update_prompt()

func _on_body_entered(body: Node3D) -> void:
	if body == GameManager.player_ref or body.is_in_group("player"):
		is_player_inside = true
		_update_prompt()
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body == GameManager.player_ref or body.is_in_group("player"):
		is_player_inside = false
		if prompt_label:
			prompt_label.visible = false

func _on_island_unlocked(island_id: int) -> void:
	if island_id == target_island_id:
		_update_prompt()
