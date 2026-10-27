extends Control

# IslandMenuUI.gd - Modal interface to view and teleport between all 10 islands.

@onready var island_list_container: VBoxContainer = $Panel/ScrollContainer/IslandListContainer
@onready var btn_close: Button = $Panel/Header/BtnClose

func _ready() -> void:
	GameManager.island_unlocked.connect(refresh_islands)
	GameManager.island_changed.connect(refresh_islands)
	btn_close.pressed.connect(func(): visible = false)
	visible = false
	refresh_islands()

func refresh_islands() -> void:
	if not island_list_container:
		return
		
	for child in island_list_container.get_children():
		child.queue_free()
		
	for id_val in range(1, 11):
		var island_data = IslandData.get_island(id_val)
		var is_unlocked = GameManager.is_island_unlocked(id_val)
		var is_current = (GameManager.current_island == id_val)
		
		var row = PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 50)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.14, 0.16, 0.2, 0.9)
		style.set_border_width_all(1)
		style.border_color = Color(0.3, 0.35, 0.45)
		style.set_corner_radius_all(4)
		row.add_theme_stylebox_override("panel", style)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		row.add_child(hbox)
		
		# Name & Currency Info
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var title_lbl = Label.new()
		title_lbl.text = "Ilha %d: %s" % [id_val, island_data["name"]]
		title_lbl.add_theme_font_size_override("font_size", 15)
		info_vbox.add_child(title_lbl)
		
		var sub_lbl = Label.new()
		sub_lbl.text = "Moeda: %s | Mob HP: %s" % [island_data["currency_name"], IslandData.format_number(island_data["mob_hp"])]
		sub_lbl.modulate = Color(0.7, 0.7, 0.7)
		sub_lbl.add_theme_font_size_override("font_size", 12)
		info_vbox.add_child(sub_lbl)
		
		hbox.add_child(info_vbox)
		
		# Status / Teleport Button
		if is_current:
			var cur_lbl = Label.new()
			cur_lbl.text = "[Aqui]"
			cur_lbl.modulate = Color(0.3, 1.0, 0.5)
			cur_lbl.add_theme_font_size_override("font_size", 14)
			hbox.add_child(cur_lbl)
			var btn_tp_cur = Button.new()
			btn_tp_cur.text = "Teleportar"
			btn_tp_cur.custom_minimum_size = Vector2(100, 36)
			btn_tp_cur.pressed.connect(func():
				GameManager.teleport_to_island(id_val)
				visible = false
			)
			hbox.add_child(btn_tp_cur)
		elif is_unlocked:
			var btn_tp = Button.new()
			btn_tp.text = "Teleportar"
			btn_tp.custom_minimum_size = Vector2(110, 36)
			btn_tp.pressed.connect(func():
				GameManager.teleport_to_island(id_val)
				visible = false
			)
			hbox.add_child(btn_tp)
		else:
			var cost = island_data.get("unlock_cost", 0)
			var req_curr = island_data.get("unlock_currency_name", "")
			var btn_unlock = Button.new()
			btn_unlock.text = "Desbloquear (%s %s)" % [IslandData.format_number(cost), req_curr]
			btn_unlock.custom_minimum_size = Vector2(170, 36)
			btn_unlock.modulate = Color(1.0, 0.8, 0.3)
			btn_unlock.pressed.connect(func():
				if GameManager.unlock_island(id_val):
					GameManager.teleport_to_island(id_val)
					visible = false
			)
			hbox.add_child(btn_unlock)
			
		island_list_container.add_child(row)
