extends Control

# AchievementsUI.gd - Modal interface to view and claim achievements across 4 categories:
# 1. Horas Jogadas (+25% Dano cada)
# 2. Inimigos Derrotados (+25% XP cada)
# 3. Moedas Coletadas (+25% Moedas cada)
# 4. Chefes Derrotados (+25% Sorte nos Giros cada)

@onready var btn_close: Button = $Panel/Header/BtnClose
@onready var achievements_container: VBoxContainer = $Panel/ScrollContainer/AchievementsList

# Bonus summary labels
@onready var damage_bonus_label: Label = $Panel/SummaryPanel/HBox/DamageBonusLabel
@onready var xp_bonus_label: Label = $Panel/SummaryPanel/HBox/XpBonusLabel
@onready var coin_bonus_label: Label = $Panel/SummaryPanel/HBox/CoinBonusLabel
@onready var luck_bonus_label: Label = $Panel/SummaryPanel/HBox/LuckBonusLabel

# Category tabs
@onready var tab_all: Button = $Panel/CategoryTabs/TabAll
@onready var tab_time: Button = $Panel/CategoryTabs/TabTime
@onready var tab_coins: Button = $Panel/CategoryTabs/TabCoins
@onready var tab_enemies: Button = $Panel/CategoryTabs/TabEnemies
@onready var tab_spins: Button = $Panel/CategoryTabs/TabSpins

var current_filter: String = "all"

func _ready() -> void:
	visible = false
	btn_close.pressed.connect(close)
	GameManager.open_achievements_ui_requested.connect(open)
	GameManager.achievements_changed.connect(refresh_ui)
	
	if tab_all: tab_all.pressed.connect(func(): _set_filter("all"))
	if tab_time: tab_time.pressed.connect(func(): _set_filter("time"))
	if tab_coins: tab_coins.pressed.connect(func(): _set_filter("coins"))
	if tab_enemies: tab_enemies.pressed.connect(func(): _set_filter("enemies"))
	if tab_spins: tab_spins.pressed.connect(func(): _set_filter("spins"))
	
	refresh_ui()

func open() -> void:
	refresh_ui()
	visible = true

func close() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_C:
			close()

func _set_filter(cat: String) -> void:
	current_filter = cat
	_update_tab_styles()
	refresh_ui()

func _update_tab_styles() -> void:
	var tabs = {
		"all": tab_all,
		"time": tab_time,
		"coins": tab_coins,
		"enemies": tab_enemies,
		"spins": tab_spins
	}
	for k in tabs:
		var btn = tabs[k]
		if btn:
			if k == current_filter:
				btn.modulate = Color(1.0, 0.85, 0.3)
			else:
				btn.modulate = Color(0.75, 0.75, 0.75)

func refresh_ui() -> void:
	_update_summary()
	_populate_list()

func _update_summary() -> void:
	var dmg_b = GameManager.get_achievement_bonus("damage") * 100.0
	var xp_b = GameManager.get_achievement_bonus("xp") * 100.0
	var coin_b = GameManager.get_achievement_bonus("coins") * 100.0
	var luck_b = GameManager.get_achievement_bonus("luck") * 100.0
	
	if damage_bonus_label:
		damage_bonus_label.text = "⚔️ Dano: +%.2f%%" % dmg_b
	if xp_bonus_label:
		xp_bonus_label.visible = false # Foco nas 4 categorias requisitadas
	if coin_bonus_label:
		coin_bonus_label.text = "🪙 Moedas: +%.2f%%" % coin_b
	if luck_bonus_label:
		luck_bonus_label.text = "🍀 Sorte da Ilha: +%.2f%%" % luck_b

func _populate_list() -> void:
	if not achievements_container:
		return
		
	for child in achievements_container.get_children():
		child.queue_free()
		
	for ach in IslandData.ACHIEVEMENTS:
		var cat = ach.get("category", "")
		if current_filter != "all" and current_filter != cat:
			continue
			
		var aid = ach["id"]
		var is_claimed = GameManager.is_achievement_claimed(aid)
		var stat_val = GameManager.get_stat_for_category(cat)
		var target_val = float(ach["target"])
		var is_ready = (stat_val >= target_val and not is_claimed)
		
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 68)
		var style = StyleBoxFlat.new()
		if is_ready:
			style.bg_color = Color(0.18, 0.22, 0.15, 0.95)
			style.border_color = Color(0.3, 0.95, 0.4)
			style.set_border_width_all(2)
		elif is_claimed:
			style.bg_color = Color(0.1, 0.12, 0.16, 0.7)
			style.border_color = Color(0.2, 0.25, 0.35)
			style.set_border_width_all(1)
		else:
			style.bg_color = Color(0.12, 0.14, 0.19, 0.9)
			style.border_color = Color(0.25, 0.3, 0.42)
			style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		card.add_theme_stylebox_override("panel", style)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		card.add_child(hbox)
		
		# Icon & Title & Description
		var icon_lbl = Label.new()
		icon_lbl.text = ach.get("icon", "🏆")
		icon_lbl.add_theme_font_size_override("font_size", 26)
		icon_lbl.custom_minimum_size = Vector2(40, 0)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(icon_lbl)
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var title_hbox = HBoxContainer.new()
		var title_lbl = Label.new()
		title_lbl.text = ach.get("title", "")
		title_lbl.add_theme_font_size_override("font_size", 15)
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35) if is_ready else Color(0.9, 0.92, 0.96))
		title_hbox.add_child(title_lbl)
		
		var reward_badge = Label.new()
		reward_badge.text = "[ %s ]" % ach.get("reward_text", "")
		reward_badge.add_theme_font_size_override("font_size", 13)
		var b_color = Color(0.4, 0.9, 1.0)
		if ach["reward_type"] == "damage": b_color = Color(1.0, 0.4, 0.4)
		elif ach["reward_type"] == "xp": b_color = Color(0.6, 0.4, 1.0)
		elif ach["reward_type"] == "coins": b_color = Color(1.0, 0.85, 0.2)
		elif ach["reward_type"] == "luck": b_color = Color(0.3, 1.0, 0.6)
		reward_badge.add_theme_color_override("font_color", b_color)
		title_hbox.add_child(reward_badge)
		info_vbox.add_child(title_hbox)
		
		# Progress Bar & Formatted Stats
		var cur_str = ""
		var tgt_str = ""
		if cat == "time":
			cur_str = IslandData.format_time(stat_val)
			tgt_str = IslandData.format_time(target_val)
		else:
			cur_str = IslandData.format_number(stat_val)
			tgt_str = IslandData.format_number(target_val)
			
		var desc_lbl = Label.new()
		desc_lbl.text = "%s  •  Progresso: %s / %s" % [ach.get("description", ""), cur_str, tgt_str]
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.modulate = Color(0.72, 0.75, 0.82)
		info_vbox.add_child(desc_lbl)
		
		var pbar = ProgressBar.new()
		pbar.custom_minimum_size = Vector2(0, 8)
		pbar.max_value = target_val
		pbar.value = min(stat_val, target_val)
		pbar.show_percentage = false
		info_vbox.add_child(pbar)
		
		hbox.add_child(info_vbox)
		
		# Action Button
		var btn_claim = Button.new()
		btn_claim.custom_minimum_size = Vector2(130, 38)
		
		if is_claimed:
			btn_claim.text = "✓ Resgatado"
			btn_claim.disabled = true
			btn_claim.modulate = Color(0.55, 0.6, 0.7)
		elif is_ready:
			btn_claim.text = "⭐ Resgatar"
			btn_claim.modulate = Color(0.3, 1.0, 0.4)
			btn_claim.pressed.connect(func():
				GameManager.claim_achievement(aid)
				refresh_ui()
			)
		else:
			btn_claim.text = "Bloqueado"
			btn_claim.disabled = true
			btn_claim.modulate = Color(0.5, 0.5, 0.5)
			
		hbox.add_child(btn_claim)
		
		achievements_container.add_child(card)
