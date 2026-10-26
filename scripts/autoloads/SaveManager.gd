extends Node

# SaveManager.gd - Handles robust persistence to user://savegame.json
# Compliant with Godot 4.x FileAccess and JSON APIs.

const SAVE_PATH = "user://savegame.json"

signal game_saved()
signal game_loaded()

var _auto_save_timer: Timer

func _ready() -> void:
	# Configure periodic auto-save every 30 seconds
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = 30.0
	_auto_save_timer.one_shot = false
	_auto_save_timer.autostart = true
	_auto_save_timer.timeout.connect(_on_auto_save_timeout)
	add_child(_auto_save_timer)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()

func _on_auto_save_timeout() -> void:
	save_game()

func save_game() -> bool:
	if GameManager == null:
		return false
		
	var data: Dictionary = {
		"version": 1,
		"currencies": GameManager.currencies,
		"unlocked_islands": GameManager.unlocked_islands,
		"current_island": GameManager.current_island,
		"inventory": GameManager.inventory,
		"equipped_fighters": GameManager.equipped_fighter_ids,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var json_str = JSON.stringify(data, "\t")
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to open save file for writing at %s. Error: %d" % [SAVE_PATH, FileAccess.get_open_error()])
		return false
		
	file.store_string(json_str)
	file.close()
	game_saved.emit()
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Failed to open save file for reading.")
		return false
		
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error("SaveManager: Error parsing savegame.json: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return false
		
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return false
		
	# Populate GameManager
	if data.has("currencies") and typeof(data["currencies"]) == TYPE_DICTIONARY:
		for k in data["currencies"]:
			GameManager.currencies[k] = float(data["currencies"][k])
		GameManager.migrate_legacy_currencies()
			
	if data.has("unlocked_islands") and typeof(data["unlocked_islands"]) == TYPE_ARRAY:
		GameManager.unlocked_islands.clear()
		for id_val in data["unlocked_islands"]:
			GameManager.unlocked_islands.append(int(id_val))
		if not GameManager.unlocked_islands.has(1):
			GameManager.unlocked_islands.append(1)
			
	if data.has("current_island"):
		GameManager.current_island = int(data["current_island"])
		
	if data.has("inventory") and typeof(data["inventory"]) == TYPE_ARRAY:
		GameManager.inventory.clear()
		for item in data["inventory"]:
			if typeof(item) == TYPE_DICTIONARY:
				GameManager.inventory.append(item)
				
	if data.has("equipped_fighters") and typeof(data["equipped_fighters"]) == TYPE_ARRAY:
		GameManager.equipped_fighter_ids.clear()
		for fid in data["equipped_fighters"]:
			GameManager.equipped_fighter_ids.append(str(fid))
			
	game_loaded.emit()
	return true
