extends Control

# InventoryUI.gd - Inventory panel displaying owned fighters with Equip/Unequip and Equip Best.

@onready var grid_container: GridContainer = $Panel/ScrollContainer/GridContainer
@onready var equipped_count_label: Label = $Panel/Header/EquippedCountLabel
@onready var btn_equip_best: Button = $Panel/Header/BtnEquipBest
@onready var btn_close: Button = $Panel/Header/BtnClose

func _ready() -> void:
	GameManager.inventory_changed.connect(refresh_inventory)
	GameManager.equipped_changed.connect(refresh_inventory)
	btn_equip_best.pressed.connect(_on_equip_best_pressed)
	btn_close.pressed.connect(func(): visible = false)
	visible = false
	refresh_inventory()

func refresh_inventory() -> void:
	if not grid_container:
		return
		
	# Clear previous cards
	for child in grid_container.get_children():
		child.queue_free()
		
	var inv = GameManager.inventory
	var equipped_ids = GameManager.equipped_fighter_ids
	
	if equipped_count_label:
		equipped_count_label.text = "Equipados: %d / %d" % [equipped_ids.size(), GameManager.MAX_EQUIPPED_FIGHTERS]
		
	for f_data in inv:
		var card = _create_fighter_card(f_data)
		grid_container.add_child(card)

func _create_fighter_card(data: Dictionary) -> Control:
	var fid = data.get("id", "")
	var fname = data.get("name", "Lutador")
	var rarity = data.get("rarity", IslandData.RARITY_COMMON)
	var dps = float(data.get("dps", 0.0))
	var level = int(data.get("level", 1))
	var xp = int(data.get("xp", 0))
	var passive_id = data.get("passive_id", "none")
	var is_equipped = GameManager.is_fighter_equipped(fid)
	var color = IslandData.RARITY_COLORS.get(rarity, Color.WHITE)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(175, 230)
	
	# Style the card with a neat border matching the rarity
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 0.95)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)
	
	# Top Rarity Tag
	var rarity_label = Label.new()
	rarity_label.text = rarity.to_upper()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.modulate = color
	rarity_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(rarity_label)
	
	# Fighter Name
	var name_lbl = Label.new()
	name_lbl.text = fname
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(name_lbl)
	
	# Level display
	var lvl_lbl = Label.new()
	lvl_lbl.text = "Nv. %d / %d" % [level, IslandData.MAX_LEVEL]
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_lbl.modulate = Color(0.4, 0.9, 1.0)
	lvl_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lvl_lbl)
	
	# XP Progress Bar
	var xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(0, 10)
	xp_bar.show_percentage = false
	if level >= IslandData.MAX_LEVEL:
		xp_bar.max_value = 1.0
		xp_bar.value = 1.0
		xp_bar.tooltip_text = "NÍVEL MÁXIMO"
	else:
		var req_xp = IslandData.get_xp_needed(level)
		xp_bar.max_value = max(1, req_xp)
		xp_bar.value = xp
		xp_bar.tooltip_text = "XP: %s / %s" % [IslandData.format_number(xp), IslandData.format_number(req_xp)]
	vbox.add_child(xp_bar)
	
	# Passive Badge
	var passive_lbl = Label.new()
	passive_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	passive_lbl.add_theme_font_size_override("font_size", 11)
	if passive_id != "none" and IslandData.PASSIVES.has(passive_id):
		var p_info = IslandData.PASSIVES[passive_id]
		var p_rarity = p_info.get("rarity", IslandData.RARITY_COMMON)
		var p_color = IslandData.RARITY_COLORS.get(p_rarity, Color(0.8, 0.8, 0.8))
		passive_lbl.text = "★ %s" % p_info.get("name", "")
		passive_lbl.modulate = p_color
		passive_lbl.tooltip_text = "%s: %s" % [p_info.get("name", ""), p_info.get("description", "")]
	else:
		passive_lbl.text = "Sem Passiva"
		passive_lbl.modulate = Color(0.5, 0.5, 0.5)
	vbox.add_child(passive_lbl)
	
	# DPS display
	var dps_lbl = Label.new()
	dps_lbl.text = "DPS: %s" % IslandData.format_number(dps)
	dps_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dps_lbl.modulate = Color(1.0, 0.85, 0.3)
	dps_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(dps_lbl)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Equip / Unequip button
	var btn_action = Button.new()
	btn_action.custom_minimum_size = Vector2(0, 30)
	if is_equipped:
		btn_action.text = "Desequipar"
		btn_action.modulate = Color(1.0, 0.5, 0.5)
		btn_action.pressed.connect(func(): GameManager.unequip_fighter(fid))
	else:
		btn_action.text = "Equipar"
		btn_action.modulate = Color(0.4, 1.0, 0.5)
		btn_action.pressed.connect(func(): GameManager.equip_fighter(fid))
		
	vbox.add_child(btn_action)
	return panel

func _on_equip_best_pressed() -> void:
	GameManager.equip_best_fighters()
