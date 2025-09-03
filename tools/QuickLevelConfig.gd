@tool
extends EditorScript

# Quick Level Configuration Helper
# Simple interface for common level map modifications

func _run():
	print("⚡ Quick Level Configuration Helper")
	print("========================================")
	
	# Quick configuration options - modify these and run the script
	var quick_config = {
		# Enable/disable dev mode (unlocks all levels)
		"enable_dev_mode": true,
		
		# Show debug information
		"show_debug_info": true,
		
		# Adjust level positions (useful for balancing the map layout)
		"reposition_levels": false,
		
		# Validate current configuration
		"validate_only": true
	}
	
	var config = _load_config()
	if config.is_empty():
		return
	
	if quick_config.enable_dev_mode:
		_enable_dev_mode(config, quick_config.show_debug_info)
	
	if quick_config.reposition_levels:
		_auto_reposition_levels(config)
	
	if quick_config.validate_only:
		_quick_validate(config)
	else:
		_save_config(config)
	
	print("✅ Quick configuration completed!")

func _load_config() -> Dictionary:
	var file = FileAccess.open("res://data/level_map_config.json", FileAccess.READ)
	if not file:
		print("❌ Could not load config file")
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		print("❌ Invalid JSON format")
		return {}
	
	return json.data

func _save_config(config: Dictionary):
	var file = FileAccess.open("res://data/level_map_config.json", FileAccess.WRITE)
	if not file:
		print("❌ Could not save config file")
		return
	
	file.store_string(JSON.stringify(config, "\t"))
	file.close()
	print("💾 Configuration saved successfully")

func _enable_dev_mode(config: Dictionary, show_debug: bool):
	if not config.has("map_config"):
		config["map_config"] = {}
	if not config.map_config.has("dev_mode"):
		config.map_config["dev_mode"] = {}
	
	config.map_config.dev_mode["unlock_all"] = true
	config.map_config.dev_mode["show_debug_info"] = show_debug
	
	print("🔧 Dev mode enabled:")
	print("  - Unlock all levels: true")
	print("  - Show debug info: ", show_debug)

func _auto_reposition_levels(config: Dictionary):
	var level_nodes = config.get("level_nodes", [])
	var spacing_x = 200
	var base_y = 300
	var current_x = 100
	
	print("📍 Auto-repositioning ", level_nodes.size(), " levels...")
	
	for i in range(level_nodes.size()):
		var node = level_nodes[i]
		node["position"] = {
			"x": current_x,
			"y": base_y + (i % 3 - 1) * 100  # Slight vertical variation
		}
		current_x += spacing_x
		print("  - ", node.get("display_name", "Unknown"), ": (", node.position.x, ", ", node.position.y, ")")

func _quick_validate(config: Dictionary):
	print("🔍 Quick validation check...")
	
	var level_nodes = config.get("level_nodes", [])
	var issues = 0
	
	# Check basic structure
	if not config.has("map_config"):
		print("⚠️ Missing map_config section")
		issues += 1
	
	if level_nodes.is_empty():
		print("⚠️ No level nodes defined")
		issues += 1
	
	# Check level nodes
	var level_ids = []
	for node in level_nodes:
		var id = node.get("id", "")
		if id == "":
			print("⚠️ Level node missing ID")
			issues += 1
		elif id in level_ids:
			print("⚠️ Duplicate level ID: ", id)
			issues += 1
		else:
			level_ids.append(id)
		
		# Check required fields
		var required = ["display_name", "description", "position"]
		for field in required:
			if not node.has(field):
				print("⚠️ Level ", id, " missing field: ", field)
				issues += 1
	
	# Summary
	if issues == 0:
		print("✅ Configuration looks good!")
		print("📊 Found ", level_nodes.size(), " levels")
		print("🎮 Dev mode: ", config.get("map_config", {}).get("dev_mode", {}).get("unlock_all", false))
	else:
		print("❌ Found ", issues, " issues that need attention")
	
	return issues == 0