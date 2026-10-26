extends Node

# GameManager.gd - Central manager for game state, economy, inventory, combat, XP/leveling, and passives.
# Autoloaded as 'GameManager'

signal currency_changed(currency_id: String, new_amount: float)
signal inventory_changed()
signal equipped_changed()
signal target_changed(new_target: Node)
signal island_changed(new_island_id: int)
signal island_unlocked(island_id: int)
signal system_message(text: String, color: Color)
signal fighter_leveled_up(fighter_id: String, new_level: int)
signal fighter_passive_changed(fighter_id: String, new_passive_id: String)
signal open_passive_ui_requested(island_id: int)

const MAX_EQUIPPED_FIGHTERS = 3

var currencies: Dictionary = {}
var unlocked_islands: Array = [1]
var current_island: int = 1
var inventory: Array = []
var equipped_fighter_ids: Array = []

var current_target: Node = null
var player_ref: Node = null

func _ready() -> void:
	_init_currencies()
	if not SaveManager.load_game():
		_init_starter_pack()
	migrate_legacy_currencies()
	_recalc_all_fighters_stats()

func _init_currencies() -> void:
	if not currencies.has(IslandData.CURRENCY_ID):
		currencies[IslandData.CURRENCY_ID] = 0.0

func migrate_legacy_currencies() -> void:
	if not currencies.has(IslandData.CURRENCY_ID):
		currencies[IslandData.CURRENCY_ID] = 0.0
	var legacy_keys: Array = []
	for k in currencies.keys():
		if k != IslandData.CURRENCY_ID:
			currencies[IslandData.CURRENCY_ID] += float(currencies[k])
			legacy_keys.append(k)
	for k in legacy_keys:
		currencies.erase(k)

func _init_starter_pack() -> void:
	add_currency(IslandData.CURRENCY_ID, 50.0)
	var starter_id = generate_uuid()
	var starter_fighter = {
		"id": starter_id,
		"uid": starter_id,
		"name": "Clone de Naruto",
		"rarity": IslandData.RARITY_COMMON,
		"base_dps": 25.0,
		"dps": 25.0,
		"level": 1,
		"xp": 0,
		"passive_id": "none",
		"island_id": 1,
		"mesh_color": Color(0.95, 0.45, 0.05).to_html()
	}
	inventory.append(starter_fighter)
	equipped_fighter_ids.append(starter_id)
	inventory_changed.emit()
	equipped_changed.emit()
	SaveManager.save_game()

func generate_uuid() -> String:
	return "f_%x_%x" % [Time.get_ticks_usec(), randi()]

func _recalc_all_fighters_stats() -> void:
	for f in inventory:
		var base = float(f.get("base_dps", f.get("dps", 25.0)))
		f["base_dps"] = base
		if not f.has("level"):
			f["level"] = 1
		if not f.has("xp"):
			f["xp"] = 0
		if not f.has("passive_id"):
			f["passive_id"] = "none"
		if not f.has("uid"):
			f["uid"] = f.get("id", generate_uuid())
		f["dps"] = IslandData.calculate_fighter_dps(base, f["level"], f["passive_id"])

# --- CURRENCY API ---
func get_currency(currency_id: String) -> float:
	return currencies.get(currency_id, 0.0)

func add_currency(currency_id: String, amount: float) -> void:
	if not currencies.has(currency_id):
		currencies[currency_id] = 0.0
	currencies[currency_id] += amount
	currency_changed.emit(currency_id, currencies[currency_id])

func spend_currency(currency_id: String, amount: float) -> bool:
	var current = get_currency(currency_id)
	if current >= amount:
		currencies[currency_id] = current - amount
		currency_changed.emit(currency_id, currencies[currency_id])
		SaveManager.save_game()
		return true
	return false

# --- KILL REWARDS & XP DISTRIBUTION ---
func grant_kill_rewards(currency_id: String, base_coins: float, base_xp: float, is_boss: bool = false) -> void:
	# Calculate passive coin bonuses from equipped team
	var coin_mult: float = 1.0
	for fid in equipped_fighter_ids:
		var f = get_fighter_by_id(fid)
		if not f.is_empty():
			var p_info = IslandData.get_passive_info(f.get("passive_id", "none"))
			coin_mult += float(p_info.get("coin_bonus", 0.0))
			
	var final_coins = base_coins * coin_mult
	add_currency(currency_id, final_coins)
	
	var data = IslandData.get_island(current_island)
	var curr_name = data.get("currency_name", "Moedas")
	if is_boss:
		system_message.emit("CHEFE DERROTADO! +%s %s | +%s XP!" % [IslandData.format_number(final_coins), curr_name, IslandData.format_number(base_xp)], Color(1.0, 0.85, 0.2))
	else:
		system_message.emit("+%s %s (+%s XP)" % [IslandData.format_number(final_coins), curr_name, IslandData.format_number(base_xp)], Color(0.9, 0.9, 0.3))
		
	# Distribute XP to equipped fighters
	add_xp_to_equipped_fighters(base_xp)

func add_xp_to_equipped_fighters(base_xp_amount: float) -> void:
	if equipped_fighter_ids.is_empty():
		return
		
	var any_leveled_up: bool = false
	
	for fid in equipped_fighter_ids:
		var f = get_fighter_by_id(fid)
		if f.is_empty():
			continue
			
		var cur_lvl: int = int(f.get("level", 1))
		if cur_lvl >= IslandData.MAX_LEVEL:
			continue
			
		var p_info = IslandData.get_passive_info(f.get("passive_id", "none"))
		var xp_bonus: float = float(p_info.get("xp_bonus", 0.0))
		var gained_xp: int = int(base_xp_amount * (1.0 + xp_bonus))
		
		f["xp"] = int(f.get("xp", 0)) + gained_xp
		
		# Check level up progression
		while cur_lvl < IslandData.MAX_LEVEL:
			var needed = IslandData.get_xp_needed(cur_lvl)
			if f["xp"] >= needed:
				f["xp"] -= needed
				cur_lvl += 1
				f["level"] = cur_lvl
				f["dps"] = IslandData.calculate_fighter_dps(f.get("base_dps", 25.0), cur_lvl, f.get("passive_id", "none"))
				fighter_leveled_up.emit(f["id"], cur_lvl)
				any_leveled_up = true
			else:
				break
				
	inventory_changed.emit()
	equipped_changed.emit()
	
	if any_leveled_up:
		SaveManager.save_game()

# --- PASSIVES REROLL MACHINE ---
func reroll_passive(fighter_id: String, island_id: int) -> Dictionary:
	var f = get_fighter_by_id(fighter_id)
	if f.is_empty():
		return {}
		
	var island_info = IslandData.get_island(island_id)
	var cost = island_info.get("reroll_cost", 50)
	var curr_id = island_info.get("currency_id", IslandData.CURRENCY_ID)
	
	if not spend_currency(curr_id, cost):
		system_message.emit("Moedas insuficientes para rolar passiva! Custo: %s %s" % [IslandData.format_number(cost), island_info.get("currency_name", "")], Color(1.0, 0.3, 0.3))
		return {}
		
	var new_passive_id = IslandData.roll_random_passive()
	f["passive_id"] = new_passive_id
	f["dps"] = IslandData.calculate_fighter_dps(f.get("base_dps", 25.0), f.get("level", 1), new_passive_id)
	
	fighter_passive_changed.emit(fighter_id, new_passive_id)
	inventory_changed.emit()
	equipped_changed.emit()
	SaveManager.save_game()
	
	var p_info = IslandData.get_passive_info(new_passive_id)
	var tier_color = IslandData.RARITY_COLORS.get(p_info["rarity"], Color.WHITE)
	system_message.emit("Nova Passiva Rolada: [%s] %s! (%s)" % [p_info["rarity"], p_info["name"], p_info["description"]], tier_color)
	
	return p_info

func request_open_passive_ui(island_id: int) -> void:
	open_passive_ui_requested.emit(island_id)

# --- ISLAND UNLOCKS & TELEPORT ---
func is_island_unlocked(island_id: int) -> bool:
	return unlocked_islands.has(island_id)

func unlock_island(island_id: int) -> bool:
	if is_island_unlocked(island_id):
		return true
	var island_info = IslandData.get_island(island_id)
	var cost = island_info["unlock_cost"]
	var req_curr = island_info["unlock_currency_id"]
	
	if cost == 0 or spend_currency(req_curr, cost):
		unlocked_islands.append(island_id)
		island_unlocked.emit(island_id)
		SaveManager.save_game()
		system_message.emit("Nova Ilha Desbloqueada: %s!" % island_info["name"], Color(0.2, 1.0, 0.3))
		return true
	else:
		system_message.emit("Moedas insuficientes para desbloquear esta ilha!", Color(1.0, 0.3, 0.3))
		return false

func teleport_to_island(island_id: int) -> void:
	if not is_island_unlocked(island_id):
		system_message.emit("Esta ilha ainda está bloqueada!", Color(1.0, 0.3, 0.3))
		return
		
	current_island = island_id
	var island_info = IslandData.get_island(island_id)
	var target_pos = island_info["world_position"] + Vector3(0, 1.5, 25)
	
	if player_ref and is_instance_valid(player_ref):
		player_ref.global_position = target_pos
		clear_target()
		
	island_changed.emit(island_id)
	SaveManager.save_game()
	system_message.emit("Viajou para: %s" % island_info["name"], Color(0.4, 0.8, 1.0))

# --- INVENTORY & FIGHTERS ---
func add_fighter_to_inventory(fighter_data: Dictionary) -> String:
	if not fighter_data.has("id"):
		fighter_data["id"] = generate_uuid()
	if not fighter_data.has("uid"):
		fighter_data["uid"] = fighter_data["id"]
	if not fighter_data.has("level"):
		fighter_data["level"] = 1
	if not fighter_data.has("xp"):
		fighter_data["xp"] = 0
	if not fighter_data.has("passive_id"):
		fighter_data["passive_id"] = "none"
	if not fighter_data.has("base_dps"):
		fighter_data["base_dps"] = float(fighter_data.get("dps", 25.0))
		
	fighter_data["dps"] = IslandData.calculate_fighter_dps(fighter_data["base_dps"], fighter_data["level"], fighter_data["passive_id"])
	
	inventory.append(fighter_data)
	inventory_changed.emit()
	
	if equipped_fighter_ids.size() < MAX_EQUIPPED_FIGHTERS:
		equip_fighter(fighter_data["id"])
	else:
		SaveManager.save_game()
		
	return fighter_data["id"]

func is_fighter_equipped(fighter_id: String) -> bool:
	return equipped_fighter_ids.has(fighter_id)

func equip_fighter(fighter_id: String) -> bool:
	if is_fighter_equipped(fighter_id):
		return true
	if equipped_fighter_ids.size() >= MAX_EQUIPPED_FIGHTERS:
		system_message.emit("Limite de %d lutadores equipados atingido!" % MAX_EQUIPPED_FIGHTERS, Color(1.0, 0.6, 0.2))
		return false
		
	equipped_fighter_ids.append(fighter_id)
	equipped_changed.emit()
	SaveManager.save_game()
	return true

func unequip_fighter(fighter_id: String) -> void:
	if is_fighter_equipped(fighter_id):
		equipped_fighter_ids.erase(fighter_id)
		equipped_changed.emit()
		SaveManager.save_game()

func equip_best_fighters() -> void:
	if inventory.is_empty():
		return
	
	var sorted = inventory.duplicate()
	sorted.sort_custom(func(a, b): return a.get("dps", 0.0) > b.get("dps", 0.0))
	
	equipped_fighter_ids.clear()
	for i in range(mini(MAX_EQUIPPED_FIGHTERS, sorted.size())):
		equipped_fighter_ids.append(sorted[i]["id"])
		
	equipped_changed.emit()
	SaveManager.save_game()
	system_message.emit("Melhores lutadores equipados com sucesso!", Color(0.3, 1.0, 0.5))

func get_fighter_by_id(fighter_id: String) -> Dictionary:
	for f in inventory:
		if f.get("id") == fighter_id or f.get("uid") == fighter_id:
			return f
	return {}

func get_equipped_fighters() -> Array:
	var result = []
	for fid in equipped_fighter_ids:
		var f = get_fighter_by_id(fid)
		if not f.is_empty():
			result.append(f)
	return result

# --- GACHA ROLLING ---
func gacha_pull(island_id: int) -> Dictionary:
	var island_info = IslandData.get_island(island_id)
	var cost = island_info["capsule_cost"]
	var curr_id = island_info["currency_id"]
	
	if not spend_currency(curr_id, cost):
		system_message.emit("Moedas insuficientes para abrir a cápsula!", Color(1.0, 0.3, 0.3))
		return {}
		
	var roll = randf()
	var selected_rarity = IslandData.RARITY_COMMON
	
	if roll < IslandData.RARITY_CHANCES[IslandData.RARITY_MYTHIC]:
		selected_rarity = IslandData.RARITY_MYTHIC
	elif roll < IslandData.RARITY_CHANCES[IslandData.RARITY_MYTHIC] + IslandData.RARITY_CHANCES[IslandData.RARITY_LEGENDARY]:
		selected_rarity = IslandData.RARITY_LEGENDARY
	elif roll < IslandData.RARITY_CHANCES[IslandData.RARITY_MYTHIC] + IslandData.RARITY_CHANCES[IslandData.RARITY_LEGENDARY] + IslandData.RARITY_CHANCES[IslandData.RARITY_EPIC]:
		selected_rarity = IslandData.RARITY_EPIC
	elif roll < IslandData.RARITY_CHANCES[IslandData.RARITY_MYTHIC] + IslandData.RARITY_CHANCES[IslandData.RARITY_LEGENDARY] + IslandData.RARITY_CHANCES[IslandData.RARITY_EPIC] + IslandData.RARITY_CHANCES[IslandData.RARITY_RARE]:
		selected_rarity = IslandData.RARITY_RARE
	else:
		selected_rarity = IslandData.RARITY_COMMON
		
	var pool_info = island_info["fighters"].get(selected_rarity, island_info["fighters"][IslandData.RARITY_COMMON])
	var mesh_col = pool_info.get("mesh_color", Color(1, 1, 1))
	var base_dps = float(pool_info["dps"])
	
	var new_uuid = generate_uuid()
	var new_fighter = {
		"id": new_uuid,
		"uid": new_uuid,
		"name": pool_info["name"],
		"rarity": selected_rarity,
		"base_dps": base_dps,
		"dps": base_dps,
		"level": 1,
		"xp": 0,
		"passive_id": "none",
		"island_id": island_id,
		"mesh_color": mesh_col.to_html()
	}
	
	add_fighter_to_inventory(new_fighter)
	system_message.emit("Obteve: [%s] %s (DPS: %s)!" % [selected_rarity, new_fighter["name"], IslandData.format_number(new_fighter["dps"])], IslandData.RARITY_COLORS[selected_rarity])
	return new_fighter

# --- COMBAT TARGETING ---
func set_target(target: Node) -> void:
	if current_target != target:
		current_target = target
		target_changed.emit(target)

func clear_target() -> void:
	if current_target != null:
		current_target = null
		target_changed.emit(null)
