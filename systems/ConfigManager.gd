extends Node

## Production-ready configuration management system

# Configuration file paths
const GAME_CONFIG_PATH = "res://data/game_config.json"
const USER_CONFIG_PATH = "user://user_config.cfg"
const LEVEL_CONFIG_PATH = "res://data/level_map_config.json"

# Configuration data
var game_config: Dictionary = {}
var user_config: ConfigFile
var level_config: Dictionary = {}
var runtime_config: Dictionary = {}

# Default configurations
const DEFAULT_GAME_CONFIG = {
	"gameplay": {
		"default_lives": 5,
		"coyote_time": 0.1,
		"jump_buffer_time": 0.15,
		"respawn_delay": 1.0,
		"invincibility_time": 2.0
	},
	"scoring": {
		"fruit_points": 100,
		"gem_points": 500,
		"time_bonus_multiplier": 1.5,
		"perfect_bonus": 1000,
		"death_penalty": -50
	},
	"physics": {
		"gravity": 980.0,
		"jump_velocity": -400.0,
		"max_fall_speed": 1000.0,
		"acceleration": 2000.0,
		"friction": 1800.0
	},
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0
	},
	"graphics": {
		"target_fps": 60,
		"vsync_enabled": true,
		"particle_density": 1.0,
		"screen_shake_intensity": 1.0
	}
}

const DEFAULT_USER_CONFIG = {
	"controls": {
		"move_left": ["a", "left"],
		"move_right": ["d", "right"],
		"jump": ["space", "w", "up"],
		"dimension_flip": ["f"],
		"pause": ["escape", "p"],
		"restart": ["r"]
	},
	"accessibility": {
		"colorblind_mode": "none",
		"high_contrast": false,
		"large_ui": false,
		"reduced_motion": false,
		"screen_reader": false
	},
	"preferences": {
		"auto_save": true,
		"show_tutorials": true,
		"skip_cutscenes": false,
		"language": "en"
	}
}

signal config_loaded(config_type: String)
signal config_saved(config_type: String)
signal config_changed(config_type: String, key: String, value)
signal config_error(error_message: String)

func _ready():
	user_config = ConfigFile.new()
	_load_all_configurations()
	
	if ErrorHandler:
		ErrorHandler.info("Configuration manager initialized")

func _load_all_configurations():
	"""Load all configuration files"""
	_load_game_config()
	_load_user_config()
	_load_level_config()
	_initialize_runtime_config()

func _load_game_config():
	"""Load game configuration from JSON"""
	if FileAccess.file_exists(GAME_CONFIG_PATH):
		var file = FileAccess.open(GAME_CONFIG_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			if json.parse(json_string) == OK:
				game_config = json.data
				_merge_with_defaults(game_config, DEFAULT_GAME_CONFIG)
				config_loaded.emit("game")
				return
	
	# Use defaults if file doesn't exist or failed to load
	game_config = DEFAULT_GAME_CONFIG.duplicate(true)
	_save_game_config()
	
	if ErrorHandler:
		ErrorHandler.info("Game config loaded with defaults")

func _load_user_config():
	"""Load user configuration from CFG file"""
	var err = user_config.load(USER_CONFIG_PATH)
	
	if err == OK:
		config_loaded.emit("user")
		if ErrorHandler:
			ErrorHandler.info("User config loaded successfully")
	else:
		# Create default user config
		_create_default_user_config()
		_save_user_config()
		if ErrorHandler:
			ErrorHandler.info("User config created with defaults")

func _load_level_config():
	"""Load level configuration"""
	if FileAccess.file_exists(LEVEL_CONFIG_PATH):
		var file = FileAccess.open(LEVEL_CONFIG_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			if json.parse(json_string) == OK:
				level_config = json.data
				config_loaded.emit("level")
				return
	
	level_config = {}
	if ErrorHandler:
		ErrorHandler.warning("Level config not found", "ConfigManager")

func _initialize_runtime_config():
	"""Initialize runtime configuration"""
	runtime_config = {
		"current_level": "",
		"debug_mode": OS.is_debug_build(),
		"platform": OS.get_name(),
		"version": ProjectSettings.get_setting("application/config/version", "1.0.0"),
		"session_start": Time.get_datetime_string_from_system()
	}

func _create_default_user_config():
	"""Create default user configuration"""
	for section in DEFAULT_USER_CONFIG:
		for key in DEFAULT_USER_CONFIG[section]:
			user_config.set_value(section, key, DEFAULT_USER_CONFIG[section][key])

func _merge_with_defaults(config: Dictionary, defaults: Dictionary):
	"""Merge configuration with defaults to ensure all keys exist"""
	for key in defaults:
		if not config.has(key):
			config[key] = defaults[key]
		elif typeof(defaults[key]) == TYPE_DICTIONARY and typeof(config[key]) == TYPE_DICTIONARY:
			_merge_with_defaults(config[key], defaults[key])

# Public API - Game Config
func get_game_config(section: String, key: String, default_value = null):
	"""Get a game configuration value"""
	if section in game_config and key in game_config[section]:
		return game_config[section][key]
	return default_value

func set_game_config(section: String, key: String, value):
	"""Set a game configuration value"""
	if not section in game_config:
		game_config[section] = {}
	
	var old_value = game_config[section].get(key)
	game_config[section][key] = value
	
	config_changed.emit("game", section + "." + key, value)
	
	# Auto-save game config
	_save_game_config()

# Public API - User Config
func get_user_config(section: String, key: String, default_value = null):
	"""Get a user configuration value"""
	return user_config.get_value(section, key, default_value)

func set_user_config(section: String, key: String, value):
	"""Set a user configuration value"""
	var old_value = user_config.get_value(section, key)
	user_config.set_value(section, key, value)
	
	config_changed.emit("user", section + "." + key, value)
	
	# Auto-save user config
	_save_user_config()

# Public API - Level Config
func get_level_config(level_id: String) -> Dictionary:
	"""Get configuration for a specific level"""
	var levels = level_config.get("levels", {})
	return levels.get(level_id, {})

func get_level_nodes() -> Array:
	"""Get level node configuration"""
	return level_config.get("level_nodes", [])

# Public API - Runtime Config
func get_runtime_config(key: String, default_value = null):
	"""Get a runtime configuration value"""
	return runtime_config.get(key, default_value)

func set_runtime_config(key: String, value):
	"""Set a runtime configuration value"""
	runtime_config[key] = value
	config_changed.emit("runtime", key, value)

# Convenience methods for common settings
func get_master_volume() -> float:
	return get_game_config("audio", "master_volume", 1.0)

func set_master_volume(volume: float):
	set_game_config("audio", "master_volume", clamp(volume, 0.0, 1.0))

func get_target_fps() -> int:
	return get_game_config("graphics", "target_fps", 60)

func set_target_fps(fps: int):
	set_game_config("graphics", "target_fps", clamp(fps, 30, 144))

func is_vsync_enabled() -> bool:
	return get_game_config("graphics", "vsync_enabled", true)

func set_vsync_enabled(enabled: bool):
	set_game_config("graphics", "vsync_enabled", enabled)

func get_jump_velocity() -> float:
	return get_game_config("physics", "jump_velocity", -400.0)

func get_gravity() -> float:
	return get_game_config("physics", "gravity", 980.0)

func get_coyote_time() -> float:
	return get_game_config("gameplay", "coyote_time", 0.1)

func get_jump_buffer_time() -> float:
	return get_game_config("gameplay", "jump_buffer_time", 0.15)

# Control mapping
func get_control_mapping(action: String) -> Array:
	"""Get control mapping for an action"""
	return get_user_config("controls", action, [])

func set_control_mapping(action: String, keys: Array):
	"""Set control mapping for an action"""
	set_user_config("controls", action, keys)

# Accessibility
func is_colorblind_mode_enabled() -> bool:
	return get_user_config("accessibility", "colorblind_mode", "none") != "none"

func get_colorblind_mode() -> String:
	return get_user_config("accessibility", "colorblind_mode", "none")

func set_colorblind_mode(mode: String):
	set_user_config("accessibility", "colorblind_mode", mode)

func is_high_contrast_enabled() -> bool:
	return get_user_config("accessibility", "high_contrast", false)

func set_high_contrast_enabled(enabled: bool):
	set_user_config("accessibility", "high_contrast", enabled)

# Save functions
func _save_game_config():
	"""Save game configuration to file"""

	# do not save if on development mode
	if OS.is_debug_build():
		return


	var file = FileAccess.open(GAME_CONFIG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(game_config, "\t"))
		file.close()
		config_saved.emit("game")
	else:
		config_error.emit("Failed to save game config")

func _save_user_config():
	"""Save user configuration to file"""
	var err = user_config.save(USER_CONFIG_PATH)
	if err == OK:
		config_saved.emit("user")
	else:
		config_error.emit("Failed to save user config: " + str(err))

func save_all_configs():
	"""Save all configurations"""
	_save_game_config()
	_save_user_config()

# Validation and integrity
func validate_config() -> Dictionary:
	"""Validate all configurations and return issues"""
	var issues = []
	
	# Validate game config
	for section in DEFAULT_GAME_CONFIG:
		if not section in game_config:
			issues.append("Missing game config section: " + section)
		else:
			for key in DEFAULT_GAME_CONFIG[section]:
				if not key in game_config[section]:
					issues.append("Missing game config key: " + section + "." + key)
	
	# Validate user config
	for section in DEFAULT_USER_CONFIG:
		for key in DEFAULT_USER_CONFIG[section]:
			if not user_config.has_section_key(section, key):
				issues.append("Missing user config key: " + section + "." + key)
	
	return {
		"valid": issues.is_empty(),
		"issues": issues
	}

func repair_config():
	"""Repair configuration by merging with defaults"""
	_merge_with_defaults(game_config, DEFAULT_GAME_CONFIG)
	
	for section in DEFAULT_USER_CONFIG:
		for key in DEFAULT_USER_CONFIG[section]:
			if not user_config.has_section_key(section, key):
				user_config.set_value(section, key, DEFAULT_USER_CONFIG[section][key])
	
	save_all_configs()
	
	if ErrorHandler:
		ErrorHandler.info("Configuration repaired")

# Export/Import
func export_user_config() -> String:
	"""Export user configuration as JSON string"""
	var export_data = {}
	
	for section in user_config.get_sections():
		export_data[section] = {}
		for key in user_config.get_section_keys(section):
			export_data[section][key] = user_config.get_value(section, key)
	
	return JSON.stringify(export_data, "\t")

func import_user_config(json_string: String) -> bool:
	"""Import user configuration from JSON string"""
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return false
	
	var import_data = json.data
	if typeof(import_data) != TYPE_DICTIONARY:
		return false
	
	# Clear existing config
	for section in user_config.get_sections():
		user_config.erase_section(section)
	
	# Import new config
	for section in import_data:
		for key in import_data[section]:
			user_config.set_value(section, key, import_data[section][key])
	
	_save_user_config()
	return true

# Debug and diagnostics
func get_config_summary() -> Dictionary:
	"""Get a summary of all configurations"""
	return {
		"game_config_sections": game_config.keys(),
		"user_config_sections": user_config.get_sections(),
		"level_config_loaded": not level_config.is_empty(),
		"runtime_config": runtime_config
	}

func _exit_tree():
	save_all_configs()
