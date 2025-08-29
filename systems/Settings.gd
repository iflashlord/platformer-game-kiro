extends Node

## Simplified settings system

var current_settings: Dictionary = {}

signal setting_changed(category: String, key: String, value)

func _ready():
	_load_default_settings()

func _load_default_settings():
	current_settings = {
		"audio": {
			"master_volume": 1.0,
			"music_volume": 0.8,
			"sfx_volume": 1.0,
			"muted": false
		},
		"graphics": {
			"fullscreen": true,
			"vsync": true
		},
		"gameplay": {
			"show_fps": false,
			"screen_shake": true
		}
	}

func get_setting(category: String, key: String, default_value = null):
	if category in current_settings and key in current_settings[category]:
		return current_settings[category][key]
	return default_value

func set_setting(category: String, key: String, value):
	if not category in current_settings:
		current_settings[category] = {}
	
	current_settings[category][key] = value
	setting_changed.emit(category, key, value)

func get_master_volume() -> float:
	return get_setting("audio", "master_volume", 1.0)

func set_master_volume(volume: float):
	set_setting("audio", "master_volume", clamp(volume, 0.0, 1.0))

func is_fullscreen() -> bool:
	return get_setting("graphics", "fullscreen", true)

func set_fullscreen(enabled: bool):
	set_setting("graphics", "fullscreen", enabled)

func is_muted() -> bool:
	return get_setting("audio", "muted", false)

func set_muted(muted: bool):
	set_setting("audio", "muted", muted)