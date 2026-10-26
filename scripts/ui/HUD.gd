extends CanvasLayer

# HUD.gd - Main heads-up display showing island name, local currency, target mob info,
# system notifications, and quick action buttons.

@onready var island_name_label: Label = $TopBar/IslandContainer/IslandNameLabel
@onready var currency_label: Label = $TopBar/IslandContainer/CurrencyLabel
@onready var total_dps_label: Label = $TopBar/IslandContainer/TotalDpsLabel

@onready var target_panel: PanelContainer = $TargetPanel
@onready var target_name_label: Label = $TargetPanel/VBox/TargetNameLabel
@onready var target_hp_bar: ProgressBar = $TargetPanel/VBox/TargetHpBar
@onready var target_hp_text: Label = $TargetPanel/VBox/TargetHpText

@onready var notify_label: Label = $NotifyLabel
@onready var btn_inventory: Button = $ActionButtons/BtnInventory
@onready var btn_islands: Button = $ActionButtons/BtnIslands
@onready var btn_passives: Button = $ActionButtons.get_node_or_null("BtnPassives")
@onready var btn_equip_best: Button = $ActionButtons/BtnEquipBest
@onready var btn_save: Button = $ActionButtons/BtnSave

@export var inventory_ui: Control
@export var island_menu_ui: Control

var current_target_node: Node = null
var notify_tween: Tween

func _ready() -> void:
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.island_changed.connect(_on_island_changed)
	GameManager.target_changed.connect(_on_target_changed)
	GameManager.equipped_changed.connect(_update_total_dps)
	GameManager.system_message.connect(show_notification)
	SaveManager.game_saved.connect(_on_game_saved)
	
	btn_inventory.pressed.connect(_on_inventory_pressed)
	btn_islands.pressed.connect(_on_islands_pressed)
	if btn_passives:
		btn_passives.pressed.connect(_on_passives_pressed)
	btn_equip_best.pressed.connect(_on_equip_best_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	
	target_panel.visible = false
	_update_island_info()
	_update_total_dps()

func _process(_delta: float) -> void:
	# Continuously update targeted enemy HP bar if active
	if current_target_node and is_instance_valid(current_target_node):
		if current_target_node.has_method("is_dead") and current_target_node.is_dead():
			target_panel.visible = false
			current_target_node = null
		else:
			var cur_hp = current_target_node.get("current_hp")
			var max_hp = current_target_node.get("max_hp")
			if cur_hp != null and max_hp != null:
				target_hp_bar.max_value = max_hp
				target_hp_bar.value = cur_hp
				target_hp_text.text = "%s / %s" % [IslandData.format_number(cur_hp), IslandData.format_number(max_hp)]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			_on_inventory_pressed()
		elif event.keycode == KEY_M:
			_on_islands_pressed()
		elif event.keycode == KEY_P:
			_on_passives_pressed()

func _update_island_info() -> void:
	var island = IslandData.get_island(GameManager.current_island)
	island_name_label.text = "Ilha %d: %s" % [island["id"], island["name"]]
	var amt = GameManager.get_currency(IslandData.CURRENCY_ID)
	currency_label.text = "%s: %s" % [IslandData.CURRENCY_NAME, IslandData.format_number(amt)]

func _on_currency_changed(currency_id: String, _new_amt: float) -> void:
	if currency_id == IslandData.CURRENCY_ID:
		var amt = GameManager.get_currency(IslandData.CURRENCY_ID)
		currency_label.text = "%s: %s" % [IslandData.CURRENCY_NAME, IslandData.format_number(amt)]

func _on_island_changed(_island_id: int) -> void:
	_update_island_info()

func _update_total_dps() -> void:
	var equipped = GameManager.get_equipped_fighters()
	var total: float = 0.0
	for f in equipped:
		total += float(f.get("dps", 0.0))
	total_dps_label.text = "DPS da Equipe: %s (%d/3)" % [IslandData.format_number(total), equipped.size()]

func _on_target_changed(new_target: Node) -> void:
	current_target_node = new_target
	if current_target_node and is_instance_valid(current_target_node):
		target_panel.visible = true
		target_name_label.text = current_target_node.get("mob_name")
	else:
		target_panel.visible = false

func show_notification(text: String, color: Color = Color.WHITE) -> void:
	if not notify_label:
		return
	if notify_tween and notify_tween.is_valid():
		notify_tween.kill()
		
	notify_label.text = text
	notify_label.modulate = color
	notify_label.modulate.a = 1.0
	notify_label.visible = true
	
	notify_tween = create_tween()
	notify_tween.tween_interval(2.0)
	notify_tween.tween_property(notify_label, "modulate:a", 0.0, 0.8)
	notify_tween.tween_callback(func(): notify_label.visible = false)

func _on_game_saved() -> void:
	show_notification("Progresso salvo com sucesso!", Color(0.3, 1.0, 0.4))

func _on_inventory_pressed() -> void:
	if inventory_ui:
		inventory_ui.visible = not inventory_ui.visible

func _on_islands_pressed() -> void:
	if island_menu_ui:
		island_menu_ui.visible = not island_menu_ui.visible

func _on_passives_pressed() -> void:
	GameManager.request_open_passive_ui(GameManager.current_island)

func _on_equip_best_pressed() -> void:
	GameManager.equip_best_fighters()

func _on_save_pressed() -> void:
	SaveManager.save_game()
