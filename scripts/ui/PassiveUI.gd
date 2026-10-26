extends Control

# PassiveUI.gd - Modal UI for selecting a fighter and rolling passives using island currency.

@onready var panel: Panel = $Panel
@onready var btn_close: Button = $Panel/Header/BtnClose
@onready var title_label: Label = $Panel/Header/TitleLabel

# Left column: Fighter selector
@onready var fighter_list_container: VBoxContainer = $Panel/HBox/LeftCol/ScrollContainer/FighterList

# Right column: Details & Action
@onready var selected_name_label: Label = $Panel/HBox/RightCol/FighterDetails/NameLabel
@onready var selected_level_label: Label = $Panel/HBox/RightCol/FighterDetails/LevelLabel
@onready var selected_dps_label: Label = $Panel/HBox/RightCol/FighterDetails/DpsLabel
@onready var current_passive_label: Label = $Panel/HBox/RightCol/FighterDetails/CurrentPassiveLabel
@onready var passive_desc_label: Label = $Panel/HBox/RightCol/FighterDetails/PassiveDescLabel

@onready var odds_label: Label = $Panel/HBox/RightCol/OddsPanel/OddsLabel
@onready var cost_label: Label = $Panel/HBox/RightCol/ActionArea/CostLabel
@onready var btn_reroll: Button = $Panel/HBox/RightCol/ActionArea/BtnReroll
@onready var result_label: Label = $Panel/HBox/RightCol/ActionArea/ResultLabel

var current_island_id: int = 1
var selected_fighter_id: String = ""

func _ready() -> void:
	visible = false
	btn_close.pressed.connect(close)
	btn_reroll.pressed.connect(_on_reroll_pressed)
	GameManager.open_passive_ui_requested.connect(open_for_island)
	GameManager.inventory_changed.connect(_on_inventory_changed)
	_setup_odds_display()

func open_for_island(p_island_id: int) -> void:
	current_island_id = p_island_id
	var data = IslandData.get_island(current_island_id)
	title_label.text = "MÁQUINA DE PASSIVAS - %s" % data.get("name", "").to_upper()
	
	_update_cost_display()
	_refresh_fighter_list()
	
	# Auto-select first fighter if none selected or invalid
	if selected_fighter_id == "" or GameManager.get_fighter_by_id(selected_fighter_id).is_empty():
		if GameManager.inventory.size() > 0:
			select_fighter(GameManager.inventory[0].get("id", ""))
		else:
			_clear_fighter_details()
	else:
		_update_fighter_details()
		
	visible = true

func close() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close()

func _setup_odds_display() -> void:
	if odds_label:
		odds_label.text = "CHANCES DE ROLAGEM:\n• [Comum] 50%  • [Raro] 30%  • [Épico] 13%  • [Lendário] 6%  • [Mítico] 1%"

func _update_cost_display() -> void:
	var data = IslandData.get_island(current_island_id)
	var cost = data.get("reroll_cost", 50)
	var curr_name = data.get("currency_name", IslandData.CURRENCY_NAME)
	var curr_id = data.get("currency_id", IslandData.CURRENCY_ID)
	var player_curr = GameManager.get_currency(curr_id)
	
	cost_label.text = "Custo: %s %s (Você tem: %s)" % [
		IslandData.format_number(cost),
		curr_name,
		IslandData.format_number(player_curr)
	]
	
	if player_curr < cost:
		cost_label.modulate = Color(1.0, 0.4, 0.4)
		btn_reroll.disabled = true
	else:
		cost_label.modulate = Color(1.0, 1.0, 1.0)
		btn_reroll.disabled = (selected_fighter_id == "")

func _refresh_fighter_list() -> void:
	for c in fighter_list_container.get_children():
		c.queue_free()
		
	for f in GameManager.inventory:
		var fid = f.get("id", "")
		var fname = f.get("name", "Lutador")
		var rarity = f.get("rarity", IslandData.RARITY_COMMON)
		var lvl = f.get("level", 1)
		var p_id = f.get("passive_id", "none")
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 38)
		var p_name = ""
		if p_id != "none" and IslandData.PASSIVES.has(p_id):
			p_name = " | " + IslandData.PASSIVES[p_id]["name"]
		btn.text = "%s [Nv.%d]%s" % [fname, lvl, p_name]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var r_color = IslandData.RARITY_COLORS.get(rarity, Color.WHITE)
		btn.modulate = r_color if fid == selected_fighter_id else r_color.lerp(Color.WHITE, 0.4)
		
		btn.pressed.connect(func(): select_fighter(fid))
		fighter_list_container.add_child(btn)

func select_fighter(f_id: String) -> void:
	selected_fighter_id = f_id
	_refresh_fighter_list()
	_update_fighter_details()
	_update_cost_display()

func _update_fighter_details() -> void:
	var f = GameManager.get_fighter_by_id(selected_fighter_id)
	if f.is_empty():
		_clear_fighter_details()
		return
		
	var fname = f.get("name", "Lutador")
	var rarity = f.get("rarity", IslandData.RARITY_COMMON)
	var lvl = f.get("level", 1)
	var dps = float(f.get("dps", 0.0))
	var p_id = f.get("passive_id", "none")
	var r_color = IslandData.RARITY_COLORS.get(rarity, Color.WHITE)
	
	selected_name_label.text = "%s [%s]" % [fname, rarity]
	selected_name_label.modulate = r_color
	selected_level_label.text = "Nível: %d / %d" % [lvl, IslandData.MAX_LEVEL]
	selected_dps_label.text = "DPS Atual: %s" % IslandData.format_number(dps)
	
	var p_info = IslandData.get_passive_info(p_id)
	if p_id != "none":
		var p_rarity = p_info.get("rarity", IslandData.RARITY_COMMON)
		var p_color = IslandData.RARITY_COLORS.get(p_rarity, Color.WHITE)
		current_passive_label.text = "Passiva Atual: [%s] %s" % [p_rarity, p_info.get("name", "")]
		current_passive_label.modulate = p_color
		passive_desc_label.text = "Efeito: %s" % p_info.get("description", "")
	else:
		current_passive_label.text = "Passiva Atual: Nenhuma"
		current_passive_label.modulate = Color(0.6, 0.6, 0.6)
		passive_desc_label.text = "Role uma nova passiva abaixo!"

func _clear_fighter_details() -> void:
	selected_name_label.text = "Nenhum lutador selecionado"
	selected_name_label.modulate = Color.WHITE
	selected_level_label.text = ""
	selected_dps_label.text = ""
	current_passive_label.text = "Passiva Atual: -"
	passive_desc_label.text = ""
	btn_reroll.disabled = true

func _on_reroll_pressed() -> void:
	if selected_fighter_id == "":
		return
		
	var result = GameManager.reroll_passive(selected_fighter_id, current_island_id)
	if not result.is_empty():
		var tier_color = IslandData.RARITY_COLORS.get(result.get("rarity", IslandData.RARITY_COMMON), Color.WHITE)
		result_label.text = "ROLADO: [%s] %s!\n(%s)" % [result.get("rarity", ""), result.get("name", ""), result.get("description", "")]
		result_label.modulate = tier_color
		
		# Animate result label
		var tween = create_tween()
		tween.tween_property(result_label, "scale", Vector2(1.15, 1.15), 0.08)
		tween.tween_property(result_label, "scale", Vector2(1.0, 1.0), 0.12)
		
		_update_fighter_details()
		_update_cost_display()
		_refresh_fighter_list()

func _on_inventory_changed() -> void:
	if visible:
		_refresh_fighter_list()
		_update_fighter_details()
		_update_cost_display()
