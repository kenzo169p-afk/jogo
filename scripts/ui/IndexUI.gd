extends Control

# IndexUI.gd - Modal interface showing the Character Index (collection progress)
# across all 10 islands together, including the percentage obtained and percentage missing.

var panel: Panel
var title_label: Label
var btn_close: Button
var summary_obtained_lbl: Label
var summary_missing_lbl: Label
var summary_islands_lbl: Label
var islands_list_vbox: VBoxContainer

func _ready() -> void:
	visible = false
	_build_ui()
	GameManager.open_index_ui_requested.connect(open)
	GameManager.inventory_changed.connect(refresh_ui)
	refresh_ui()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(860, 560)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -430
	panel.offset_top = -280
	panel.offset_right = 430
	panel.offset_bottom = 280
	
	var modal_style = StyleBoxFlat.new()
	modal_style.bg_color = Color(0.08, 0.09, 0.13, 0.97)
	modal_style.border_color = Color(0.0, 0.82, 0.83, 1.0)
	modal_style.set_border_width_all(2)
	modal_style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", modal_style)
	add_child(panel)
	
	# Header
	var header = HBoxContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 18
	header.offset_top = 14
	header.offset_right = -18
	header.offset_bottom = 52
	panel.add_child(header)
	
	title_label = Label.new()
	title_label.text = "📖 ÍNDICE DE PERSONAGENS (TODAS AS 10 ILHAS)"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.0, 0.85, 0.88))
	header.add_child(title_label)
	
	btn_close = Button.new()
	btn_close.text = "X"
	btn_close.custom_minimum_size = Vector2(36, 34)
	btn_close.pressed.connect(close)
	header.add_child(btn_close)
	
	# Summary Bar (All Islands Together)
	var summary_panel = PanelContainer.new()
	summary_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	summary_panel.offset_left = 18
	summary_panel.offset_top = 56
	summary_panel.offset_right = -18
	summary_panel.offset_bottom = 98
	var sum_style = StyleBoxFlat.new()
	sum_style.bg_color = Color(0.11, 0.14, 0.2, 0.9)
	sum_style.border_color = Color(0.0, 0.82, 0.83, 0.7)
	sum_style.set_border_width_all(1)
	sum_style.set_corner_radius_all(6)
	summary_panel.add_theme_stylebox_override("panel", sum_style)
	panel.add_child(summary_panel)
	
	var sum_hbox = HBoxContainer.new()
	sum_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sum_hbox.add_theme_constant_override("separation", 24)
	summary_panel.add_child(sum_hbox)
	
	summary_obtained_lbl = Label.new()
	summary_obtained_lbl.add_theme_font_size_override("font_size", 14)
	summary_obtained_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
	sum_hbox.add_child(summary_obtained_lbl)
	
	summary_missing_lbl = Label.new()
	summary_missing_lbl.add_theme_font_size_override("font_size", 14)
	summary_missing_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.5))
	sum_hbox.add_child(summary_missing_lbl)
	
	summary_islands_lbl = Label.new()
	summary_islands_lbl.add_theme_font_size_override("font_size", 14)
	summary_islands_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	sum_hbox.add_child(summary_islands_lbl)
	
	# Scrollable list of all 10 islands together
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 18
	scroll.offset_top = 108
	scroll.offset_right = -18
	scroll.offset_bottom = -16
	panel.add_child(scroll)
	
	islands_list_vbox = VBoxContainer.new()
	islands_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	islands_list_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(islands_list_vbox)

func open() -> void:
	refresh_ui()
	visible = true

func close() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_X:
			close()

func refresh_ui() -> void:
	if not islands_list_vbox:
		return
		
	var g_stats = GameManager.get_global_index_stats()
	if summary_obtained_lbl:
		summary_obtained_lbl.text = "📖 Obtidos (Todas as Ilhas): %d / %d (%d%%)" % [
			g_stats["total_owned"], g_stats["total_fighters"], g_stats["pct_owned"]
		]
	if summary_missing_lbl:
		if g_stats["pct_missing"] == 0:
			summary_missing_lbl.text = "✅ Falta: 0% (COLEÇÃO COMPLETA!)"
		else:
			summary_missing_lbl.text = "⏳ Porcentagem que Falta: %d%% (Faltam %d)" % [
				g_stats["pct_missing"], g_stats["total_missing"]
			]
	if summary_islands_lbl:
		summary_islands_lbl.text = "🏝️ Ilhas 100%% Completas: %d / 10" % g_stats["completed_islands"]
		
	for child in islands_list_vbox.get_children():
		child.queue_free()
		
	var rarities = [
		IslandData.RARITY_COMMON,
		IslandData.RARITY_RARE,
		IslandData.RARITY_EPIC,
		IslandData.RARITY_LEGENDARY,
		IslandData.RARITY_MYTHIC
	]
	
	for isl_id in range(1, 11):
		var isl_data = IslandData.get_island(isl_id)
		var st = GameManager.get_island_index_stats(isl_id)
		
		var card = PanelContainer.new()
		var c_style = StyleBoxFlat.new()
		c_style.bg_color = Color(0.11, 0.14, 0.2, 0.94)
		c_style.border_color = Color(0.25, 0.9, 0.45) if st["is_complete"] else Color(0.24, 0.3, 0.42)
		c_style.set_border_width_all(2 if st["is_complete"] else 1)
		c_style.set_corner_radius_all(6)
		card.add_theme_stylebox_override("panel", c_style)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		card.add_child(vbox)
		
		var top_row = HBoxContainer.new()
		vbox.add_child(top_row)
		
		var isl_title = Label.new()
		isl_title.text = "Ilha %d: %s" % [isl_id, isl_data.get("name", "")]
		isl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		isl_title.add_theme_font_size_override("font_size", 15)
		isl_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35))
		top_row.add_child(isl_title)
		
		var status_lbl = Label.new()
		status_lbl.add_theme_font_size_override("font_size", 13)
		if st["is_complete"]:
			status_lbl.text = "✅ COMPLETO (5/5 • Falta 0%)"
			status_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		else:
			status_lbl.text = "Obtidos: %d/%d (%d%%) | Falta: %d%% (%d)" % [
				st["owned"], st["total"], st["pct_owned"], st["pct_missing"], st["missing_count"]
			]
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
		top_row.add_child(status_lbl)
		
		var prog = ProgressBar.new()
		prog.custom_minimum_size = Vector2(0, 8)
		prog.max_value = 100
		prog.value = st["pct_owned"]
		prog.show_percentage = false
		vbox.add_child(prog)
		
		var fighters_hbox = HBoxContainer.new()
		fighters_hbox.add_theme_constant_override("separation", 8)
		vbox.add_child(fighters_hbox)
		
		var pool = isl_data.get("fighters", {})
		for rar in rarities:
			if not pool.has(rar):
				continue
			var f_info = pool[rar]
			var fname = f_info.get("name", "")
			var fdps = float(f_info.get("dps", 0.0))
			var has_it = GameManager.is_fighter_discovered(fname)
			var r_col = IslandData.RARITY_COLORS.get(rar, Color.WHITE)
			
			var f_box = PanelContainer.new()
			f_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var f_style = StyleBoxFlat.new()
			f_style.bg_color = Color(0.14, 0.19, 0.27, 0.95) if has_it else Color(0.08, 0.1, 0.14, 0.65)
			f_style.border_color = r_col if has_it else Color(0.2, 0.25, 0.32)
			f_style.set_border_width_all(1)
			f_style.set_corner_radius_all(5)
			f_box.add_theme_stylebox_override("panel", f_style)
			
			var f_vbox = VBoxContainer.new()
			f_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			f_box.add_child(f_vbox)
			
			var r_lbl = Label.new()
			r_lbl.text = rar.to_upper()
			r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			r_lbl.add_theme_font_size_override("font_size", 10)
			r_lbl.modulate = r_col
			f_vbox.add_child(r_lbl)
			
			var n_lbl = Label.new()
			n_lbl.text = fname
			n_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			n_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			n_lbl.add_theme_font_size_override("font_size", 11)
			n_lbl.modulate = Color.WHITE if has_it else Color(0.5, 0.55, 0.6)
			f_vbox.add_child(n_lbl)
			
			var st_lbl = Label.new()
			st_lbl.text = "✓ Obtido" if has_it else "✗ Falta"
			st_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			st_lbl.add_theme_font_size_override("font_size", 11)
			st_lbl.modulate = Color(0.3, 1.0, 0.5) if has_it else Color(1.0, 0.4, 0.4)
			f_vbox.add_child(st_lbl)
			
			fighters_hbox.add_child(f_box)
			
		islands_list_vbox.add_child(card)
