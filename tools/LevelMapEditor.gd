@tool
extends EditorScript

# Level Map Configuration Editor
# Run this script in the Godot editor to easily modify level map settings

func _run():
	print("🛠️ Level Map Editor - Configuration Helper")
	
	# Example usage - modify these values and run the script
	var config_updates = {
		"add_level": {
			"id": "NewLevel",
			"display_name": "New Adventure",
			"description": "A brand new level to explore",
			"position": {"x": 400, "y": 300},
			"difficulty": 3,
			"estimated_time": "5-6 min"
		},
		"update_positions": {
			"Level00": {"x": 100, "y": 400},
			"CrateTest": {"x": 300, "y": 350}
		},
		"dev_mode": {
			"unlock_all": true,
			"show_debug_info": true
		}
	}
	
	# Load current config
	var config = _load_map_config()
	if config.is_empty():
		print("❌ Failed to load map config")
		return
	
	print("📊 Current config loaded successfully")
	print("📝 Available operations:")
	print("  1. add_level - Add a new level to the map")
	print("  2. update_positions - Update level positions")
	print("  3. dev_mode - Toggle development features")
	print("  4. validate_config - Check configuration integrity")
	
	# Uncomment the operations you want to perform:
	
	# _add_level(config, config_updates.add_level)
	# _update_positions(config, config_updates.update_positions)
	# _set_dev_mode(config, config_updates.dev_mode)
	_validate_config(config)
	
	# Save updated config
	# _save_map_config(config)
	
	print("✅ Level Map Editor completed")

func _load_map_config() -> Dictionary:
	"""Load the current map configuration"""
	var config_path = "res://data/level_map_config.json"
	if not FileAccess.file_exists(config_path):
		print("❌ Map config file not found: ", config_path)
		return {}
	
	var file = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		print("❌ Failed to open config file")
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		print("❌ Failed to parse JSON: ", json.error_string)
		return {}
	
	return json.data

func _save_map_config(config: Dictionary):
	"""Save the updated map configuration"""
	var config_path = "res://data/level_map_config.json"
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	if not file:
		print("❌ Failed to open config file for writing")
		return
	
	file.store_string(JSON.stringify(config, "\t"))
	file.close()
	print("✅ Map configuration saved")

func _add_level(config: Dictionary, level_data: Dictionary):
	"""Add a new level to the map"""
	var level_nodes = config.get("level_nodes", [])
	
	# Check if level already exists
	for node in level_nodes:
		if node.get("id", "") == level_data.get("id", ""):
			print("⚠️ Level already exists: ", level_data.get("id", ""))
			return
	
	# Add default values
	var new_level = {
		"id": level_data.get("id", "NewLevel"),
		"display_name": level_data.get("display_name", "New Level"),
		"description": level_data.get("description", "A new level to explore"),
		"position": level_data.get("position", {"x": 0, "y": 0}),
		"thumbnail": "res://content/thumbnails/" + level_data.get("id", "new_level").to_lower() + ".png",
		"difficulty": level_data.get("difficulty", 1),
		"estimated_time": level_data.get("estimated_time", "5 min"),
		"rewards": level_data.get("rewards", ["New Achievement"]),
		"unlock_requirements": level_data.get("unlock_requirements", {}),
		"connections": level_data.get("connections", [])
	}
	
	level_nodes.append(new_level)
	config["level_nodes"] = level_nodes
	
	print("✅ Added new level: ", new_level.id)

func _update_positions(config: Dictionary, position_updates: Dictionary):
	"""Update positions of existing levels"""
	var level_nodes = config.get("level_nodes", [])
	var updated_count = 0
	
	for node in level_nodes:
		var level_id = node.get("id", "")
		if level_id in position_updates:
			node["position"] = position_updates[level_id]
			updated_count += 1
			print("📍 Updated position for: ", level_id)
	
	config["level_nodes"] = level_nodes
	print("✅ Updated positions for ", updated_count, " levels")

func _set_dev_mode(config: Dictionary, dev_settings: Dictionary):
	"""Update development mode settings"""
	if not config.has("map_config"):
		config["map_config"] = {}
	if not config.map_config.has("dev_mode"):
		config.map_config["dev_mode"] = {}
	
	for key in dev_settings.keys():
		config.map_config.dev_mode[key] = dev_settings[key]
		print("🔧 Set dev_mode.", key, " = ", dev_settings[key])
	
	print("✅ Development mode settings updated")

func _validate_config(config: Dictionary):
	"""Validate configuration integrity"""
	print("🔍 Validating configuration...")
	
	var issues = []
	var level_nodes = config.get("level_nodes", [])
	
	# Check for duplicate IDs
	var ids = []
	for node in level_nodes:
		var id = node.get("id", "")
		if id in ids:
			issues.append("Duplicate level ID: " + id)
		else:
			ids.append(id)
	
	# Check for missing required fields
	for node in level_nodes:
		var required_fields = ["id", "display_name", "description", "position"]
		for field in required_fields:
			if not node.has(field):
				issues.append("Missing field '" + field + "' in level: " + node.get("id", "unknown"))
	
	# Check connections
	for node in level_nodes:
		var connections = node.get("connections", [])
		for connection_id in connections:
			if not connection_id in ids:
				issues.append("Invalid connection '" + connection_id + "' in level: " + node.get("id", "unknown"))
	
	# Check thumbnail paths
	for node in level_nodes:
		var thumbnail = node.get("thumbnail", "")
		if thumbnail != "" and not FileAccess.file_exists(thumbnail):
			issues.append("Missing thumbnail: " + thumbnail + " for level: " + node.get("id", "unknown"))
	
	# Report results
	if issues.is_empty():
		print("✅ Configuration is valid!")
	else:
		print("⚠️ Found ", issues.size(), " issues:")
		for issue in issues:
			print("  - ", issue)
	
	print("📊 Configuration summary:")
	print("  - Total levels: ", level_nodes.size())
	print("  - Dev mode: ", config.get("map_config", {}).get("dev_mode", {}).get("unlock_all", false))
	print("  - Debug info: ", config.get("map_config", {}).get("dev_mode", {}).get("show_debug_info", false))