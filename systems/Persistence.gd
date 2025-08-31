extends Node

signal profile_loaded(profile_name: String)
signal profile_saved(profile_name: String)
signal save_failed(error_message: String)

const SAVE_FILE = "user://profile.save"
const HTML5_STORAGE_KEY = "dimension_runner_profile"

var current_profile: Dictionary = {}
var is_html5: bool = false

func _ready():
	# Detect if running on HTML5
	is_html5 = OS.get_name() == "Web"
	
	# Load default profile
	load_profile()

func get_default_profile() -> Dictionary:
	return {
		"profile_name": "Player",
		"created_at": Time.get_unix_time_from_system(),
		"last_played": Time.get_unix_time_from_system(),
		"total_playtime": 0.0,
		"levels": {},
		"level_completions": {},  # New: track level completion data
		"settings": {
			"master_volume": 1.0,
			"music_volume": 0.7,
			"sfx_volume": 1.0,
			"fullscreen": false,
			"vsync": true
		},
		"statistics": {
			"total_score": 0,
			"total_deaths": 0,
			"total_jumps": 0,
			"total_collectibles": 0,
			"levels_completed": 0,
			"time_trials_completed": 0
		},
		"achievements": [],
		"version": "1.0.0"
	}

func save_profile(profile: Dictionary = current_profile) -> bool:
	if profile.is_empty():
		profile = current_profile
	
	# Update last played time
	profile.last_played = Time.get_unix_time_from_system()
	
	var success = false
	
	if is_html5:
		success = save_to_localstorage(profile)
	else:
		success = save_to_file(profile)
	
	if success:
		current_profile = profile
		profile_saved.emit(profile.get("profile_name", "Unknown"))
		print("Profile saved successfully")
	else:
		save_failed.emit("Failed to save profile")
		print("Failed to save profile")
	
	return success

func load_profile(profile_name: String = "") -> Dictionary:
	var loaded_profile = {}
	
	if is_html5:
		loaded_profile = load_from_localstorage()
	else:
		loaded_profile = load_from_file()
	
	if loaded_profile.is_empty():
		print("No saved profile found, creating default")
		loaded_profile = get_default_profile()
		if profile_name != "":
			loaded_profile.profile_name = profile_name
		save_profile(loaded_profile)
	
	current_profile = loaded_profile
	apply_settings()
	profile_loaded.emit(current_profile.get("profile_name", "Unknown"))
	
	return current_profile

func save_to_file(profile: Dictionary) -> bool:
	var save_file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if save_file == null:
		print("Failed to open save file for writing: ", FileAccess.get_open_error())
		return false
	
	var json_string = JSON.stringify(profile, "\t")
	save_file.store_string(json_string)
	save_file.close()
	return true

func load_from_file() -> Dictionary:
	if not FileAccess.file_exists(SAVE_FILE):
		return {}
	
	var save_file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if save_file == null:
		print("Failed to open save file for reading: ", FileAccess.get_open_error())
		return {}
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Failed to parse save file: ", json.error_string)
		return {}
	
	return json.data

func save_to_localstorage(profile: Dictionary) -> bool:
	if not is_html5:
		return false
	
	var json_string = JSON.stringify(profile)
	
	# Use JavaScript to save to localStorage
	var js_code = """
		try {
			localStorage.setItem('%s', '%s');
			return true;
		} catch (e) {
			console.error('Failed to save to localStorage:', e);
			return false;
		}
	""" % [HTML5_STORAGE_KEY, json_string.replace("'", "\\'")]
	
	var result = JavaScriptBridge.eval(js_code)
	return result == true

func load_from_localstorage() -> Dictionary:
	if not is_html5:
		return {}
	
	# Use JavaScript to load from localStorage
	var js_code = """
		try {
			var data = localStorage.getItem('%s');
			return data || '';
		} catch (e) {
			console.error('Failed to load from localStorage:', e);
			return '';
		}
	""" % HTML5_STORAGE_KEY
	
	var json_string = JavaScriptBridge.eval(js_code)
	
	if json_string == "" or json_string == null:
		return {}
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Failed to parse localStorage data: ", json.error_string)
		return {}
	
	return json.data

func set_best_time(level_name: String, time_ms: int):
	if not level_name in current_profile.levels:
		current_profile.levels[level_name] = {
			"best_time_ms": time_ms,
			"best_score": 0,
			"completed": false,
			"time_trial_completed": false,
			"attempts": 0,
			"deaths": 0
		}
	else:
		var level_data = current_profile.levels[level_name]
		var current_best = level_data.get("best_time_ms", 999999999)
		
		if time_ms < current_best:
			level_data.best_time_ms = time_ms
			print("New best time for ", level_name, ": ", time_ms, "ms")
	
	# Update LevelLoader with the new time if available
	if has_node("/root/LevelLoader") and get_node("/root/LevelLoader").has_method("update_best_time"):
		var time_seconds = time_ms / 1000.0
		get_node("/root/LevelLoader").update_best_time(level_name, time_seconds)
	
	save_profile()

func set_best_score(level_name: String, score: int):
	if not level_name in current_profile.levels:
		current_profile.levels[level_name] = {
			"best_time_ms": 999999999,
			"best_score": score,
			"completed": false,
			"time_trial_completed": false,
			"attempts": 0,
			"deaths": 0
		}
	else:
		var level_data = current_profile.levels[level_name]
		var current_best = level_data.get("best_score", 0)
		
		if score > current_best:
			level_data.best_score = score
			print("New best score for ", level_name, ": ", score)
	
	# Update LevelLoader with the new score if available
	if has_node("/root/LevelLoader") and get_node("/root/LevelLoader").has_method("update_best_score"):
		get_node("/root/LevelLoader").update_best_score(level_name, score)
	
	save_profile()

func mark_level_completed(level_name: String, is_time_trial: bool = false):
	if not level_name in current_profile.levels:
		current_profile.levels[level_name] = {
			"best_time_ms": 999999999,
			"best_score": 0,
			"completed": false,
			"time_trial_completed": false,
			"attempts": 0,
			"deaths": 0
		}
	
	var level_data = current_profile.levels[level_name]
	
	if is_time_trial:
		level_data.time_trial_completed = true
		current_profile.statistics.time_trials_completed += 1
	else:
		if not level_data.completed:
			level_data.completed = true
			current_profile.statistics.levels_completed += 1
	
	save_profile()

func increment_level_attempts(level_name: String):
	if not level_name in current_profile.levels:
		current_profile.levels[level_name] = {
			"best_time_ms": 999999999,
			"best_score": 0,
			"completed": false,
			"time_trial_completed": false,
			"attempts": 0,
			"deaths": 0
		}
	
	current_profile.levels[level_name].attempts += 1
	save_profile()

func increment_level_deaths(level_name: String):
	if not level_name in current_profile.levels:
		current_profile.levels[level_name] = {
			"best_time_ms": 999999999,
			"best_score": 0,
			"completed": false,
			"time_trial_completed": false,
			"attempts": 0,
			"deaths": 0
		}
	
	current_profile.levels[level_name].deaths += 1
	current_profile.statistics.total_deaths += 1
	save_profile()

func add_playtime(seconds: float):
	current_profile.total_playtime += seconds
	save_profile()

func update_statistics(stat_name: String, value: int):
	if stat_name in current_profile.statistics:
		current_profile.statistics[stat_name] += value
		save_profile()

func get_level_data(level_name: String) -> Dictionary:
	return current_profile.levels.get(level_name, {})

func get_best_time_ms(level_name: String) -> int:
	var level_data = get_level_data(level_name)
	return level_data.get("best_time_ms", 999999999)

func get_best_score(level_name: String) -> int:
	var level_data = get_level_data(level_name)
	return level_data.get("best_score", 0)

func is_level_completed(level_name: String) -> bool:
	var level_data = get_level_data(level_name)
	return level_data.get("completed", false)

func is_time_trial_completed(level_name: String) -> bool:
	var level_data = get_level_data(level_name)
	return level_data.get("time_trial_completed", false)

func get_total_score() -> int:
	var total = 0
	for level_name in current_profile.levels:
		var level_data = current_profile.levels[level_name]
		total += level_data.get("best_score", 0)
	return total

func get_completion_percentage() -> float:
	var total_levels = 4  # Level00, Level01, Level02, Level03
	if has_node("/root/LevelLoader") and get_node("/root/LevelLoader").has_method("get_all_levels"):
		total_levels = get_node("/root/LevelLoader").get_all_levels().size()
	
	if total_levels == 0:
		return 0.0
	
	var completed_levels = current_profile.statistics.get("levels_completed", 0)
	return (float(completed_levels) / float(total_levels)) * 100.0

func apply_settings():
	var settings = current_profile.get("settings", {})
	
	# Apply audio settings
	if Audio:
		Audio.set_master_volume(settings.get("master_volume", 1.0))
		Audio.set_music_volume(settings.get("music_volume", 0.7))
		Audio.set_sfx_volume(settings.get("sfx_volume", 1.0))
	
	# Apply display settings
	if settings.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if settings.get("vsync", true) else DisplayServer.VSYNC_DISABLED
	)

func update_setting(key: String, value):
	current_profile.settings[key] = value
	apply_settings()
	save_profile()

func reset_profile():
	current_profile = get_default_profile()
	save_profile()
	print("Profile reset to defaults")

func export_profile() -> String:
	return JSON.stringify(current_profile, "\t")

func import_profile(json_string: String) -> bool:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		save_failed.emit("Invalid profile data")
		return false
	
	current_profile = json.data
	return save_profile()

func get_profile_summary() -> Dictionary:
	return {
		"name": current_profile.get("profile_name", "Unknown"),
		"total_playtime": current_profile.get("total_playtime", 0.0),
		"levels_completed": current_profile.statistics.get("levels_completed", 0),
		"total_score": get_total_score(),
		"completion_percentage": get_completion_percentage(),
		"last_played": current_profile.get("last_played", 0)
	}

func complete_level(level_name: String, time: float, score: int):
	# Mark level as completed
	mark_level_completed(level_name, false)
	
	# Update best time (convert to milliseconds)
	var time_ms = int(time * 1000)
	set_best_time(level_name, time_ms)
	
	# Update best score
	set_best_score(level_name, score)
	
	print("Level completed: ", level_name, " Time: ", time, "s Score: ", score)

func get_current_profile() -> Dictionary:
	return current_profile

# New level completion tracking functions
func save_level_completion(level_name: String, completion_data: Dictionary):
	if not "level_completions" in current_profile:
		current_profile["level_completions"] = {}
	
	# Add timestamp to completion data
	completion_data["timestamp"] = Time.get_unix_time_from_system()
	completion_data["completed"] = true  # Mark as completed
	
	# Store or update completion data
	var existing_data = current_profile.level_completions.get(level_name, {})
	var is_first_completion = existing_data.is_empty()
	
	# Keep best performance
	if is_first_completion or _is_better_completion(completion_data, existing_data):
		current_profile.level_completions[level_name] = completion_data
		print("💾 New best completion saved for ", level_name)
	else:
		print("💾 Completion recorded but not a new best for ", level_name)
	
	# Update statistics (only if first completion)
	if is_first_completion:
		current_profile.statistics.levels_completed += 1
	current_profile.statistics.total_score += completion_data.get("score", 0)
	
	# Check and unlock next levels based on level progression
	_check_and_unlock_next_levels(level_name, completion_data)
	
	save_profile()

func get_level_completion(level_name: String) -> Dictionary:
	if not "level_completions" in current_profile:
		current_profile["level_completions"] = {}
	
	return current_profile.level_completions.get(level_name, {})

func _is_better_completion(new_data: Dictionary, old_data: Dictionary) -> bool:
	# Better if more hearts remaining
	var new_hearts = new_data.get("hearts_remaining", 0)
	var old_hearts = old_data.get("hearts_remaining", 0)
	
	if new_hearts > old_hearts:
		return true
	elif new_hearts < old_hearts:
		return false
	
	# Same hearts, better if more gems
	var new_gems = new_data.get("gems_found", 0)
	var old_gems = old_data.get("gems_found", 0)
	
	if new_gems > old_gems:
		return true
	elif new_gems < old_gems:
		return false
	
	# Same hearts and gems, better if faster time
	var new_time = new_data.get("completion_time", 999999.0)
	var old_time = old_data.get("completion_time", 999999.0)
	
	return new_time < old_time

func reset_level_progress():
	current_profile.level_completions = {}
	current_profile.levels = {}
	current_profile.statistics.levels_completed = 0
	save_profile()
	print("🔄 All level progress has been reset")

func is_level_unlocked(level_name: String) -> bool:
	# Load level map config to check unlock requirements
	var level_config = _load_level_map_config()
	if level_config.is_empty():
		# Fallback to simple progression if config not available
		match level_name:
			"Level00", "Tutorial":
				return true
			"Level01":
				return get_level_completion("Level00").get("completed", false)
			"Level02":
				return get_level_completion("Level01").get("completed", false)
			"Level03":
				return get_level_completion("Level02").get("completed", false)
			_:
				return false
	
	# Check dev mode first - if unlock_all is true, unlock everything
	var map_config = level_config.get("map_config", {})
	var dev_mode = map_config.get("dev_mode", {})
	if dev_mode.get("unlock_all", false):
		return true
	
	# Check if level is in the unlocked_levels array (manually unlocked)
	var unlocked_levels = current_profile.get("unlocked_levels", [])
	if level_name in unlocked_levels:
		return true
	
	# Find level in config
	var level_nodes = level_config.get("level_nodes", [])
	var level_data = null
	for node in level_nodes:
		if node.get("id", "") == level_name:
			level_data = node
			break
	
	if not level_data:
		return false
	
	# Check unlock requirements
	var requirements = level_data.get("unlock_requirements", {})
	
	# No requirements means always unlocked (like tutorial)
	if requirements.is_empty():
		return true
	
	# Check previous level requirement
	if "previous_level" in requirements:
		var prev_level = requirements["previous_level"]
		var prev_completion = get_level_completion(prev_level)
		if not prev_completion.get("completed", false):
			return false
	
	# Check minimum score requirement
	if "min_score" in requirements:
		var required_score = requirements["min_score"]
		var prev_level = requirements.get("previous_level", "")
		if prev_level != "":
			var prev_completion = get_level_completion(prev_level)
			var prev_score = prev_completion.get("score", 0)
			if prev_score < required_score:
				return false
	
	# Check maximum deaths requirement
	if "deaths_max" in requirements:
		var max_deaths = requirements["deaths_max"]
		var prev_level = requirements.get("previous_level", "")
		if prev_level != "":
			var prev_completion = get_level_completion(prev_level)
			var deaths = prev_completion.get("deaths", 999)
			if deaths > max_deaths:
				return false
	
	# Check relic count requirement
	if "relic_count" in requirements:
		var required_relics = requirements["relic_count"]
		var total_relics = _count_total_relics()
		if total_relics < required_relics:
			return false
	
	return true

func has_save_data() -> bool:
	"""Check if player has any meaningful progress saved"""
	# Check if any levels have been completed
	if current_profile.statistics.get("levels_completed", 0) > 0:
		return true
	
	# Check if any level has been attempted (has completion data)
	if not current_profile.level_completions.is_empty():
		return true
	
	# Check if any level has recorded data (old format)
	for level_name in current_profile.levels:
		var level_data = current_profile.levels[level_name]
		if level_data.get("attempts", 0) > 0 or level_data.get("completed", false):
			return true
	
	# Check if total playtime is significant (more than 30 seconds)
	if current_profile.get("total_playtime", 0.0) > 30.0:
		return true
	
	return false

func get_last_level() -> String:
	"""Get the path to the last level the player was working on"""
	var last_level_name = ""
	var latest_timestamp = 0
	
	# Check level data for the most recent last_played timestamp
	for level_name in current_profile.levels:
		var level_data = current_profile.levels[level_name]
		var timestamp = level_data.get("last_played", 0)
		if timestamp > latest_timestamp:
			latest_timestamp = timestamp
			last_level_name = level_name
	
	# Also check level completions for recent activity
	for level_name in current_profile.level_completions:
		var completion_data = current_profile.level_completions[level_name]
		var timestamp = completion_data.get("timestamp", 0)
		if timestamp > latest_timestamp:
			latest_timestamp = timestamp
			last_level_name = level_name
	
	# Convert level name to scene path
	if last_level_name != "":
		return _get_level_scene_path(last_level_name)
	
	# Default to first level if no progress found
	return "res://levels/Level00.tscn"

func _get_level_scene_path(level_name: String) -> String:
	"""Convert level name to scene file path"""
	match level_name:
		"Level00", "Tutorial":
			return "res://levels/Level00.tscn"
		"Level01":
			return "res://levels/Level01.tscn"
		"Level02":
			return "res://levels/Level02.tscn"
		"Level03":
			return "res://levels/Level03.tscn"
		_:
			# Try to construct path from name
			var scene_path = "res://levels/" + level_name + ".tscn"
			if FileAccess.file_exists(scene_path):
				return scene_path
			return "res://levels/Level00.tscn"

func get_next_recommended_level() -> String:
	"""Get the next level the player should play based on their progress"""
	# If no progress, start with tutorial
	if not has_save_data():
		return "res://levels/Level00.tscn"
	
	# Check what levels are unlocked and not completed
	var level_order = ["Level00", "Level01", "Level02", "Level03"]
	
	for level_name in level_order:
		if is_level_unlocked(level_name):
			var completion_data = get_level_completion(level_name)
			if not completion_data.get("completed", false):
				return _get_level_scene_path(level_name)
	
	# All levels completed, return the last level
	return _get_level_scene_path(level_order[-1])

func track_level_start(level_name: String):
	"""Track when a player starts a level (for last level tracking)"""
	if not level_name in current_profile.levels:
		current_profile.levels[level_name] = {
			"best_time_ms": 999999999,
			"best_score": 0,
			"completed": false,
			"time_trial_completed": false,
			"attempts": 0,
			"deaths": 0
		}
	
	# Update last played timestamp
	current_profile.levels[level_name]["last_played"] = Time.get_unix_time_from_system()
	
	# Increment attempts
	current_profile.levels[level_name].attempts += 1
	
	save_profile()
	print("📍 Level started: ", level_name)

func _check_and_unlock_next_levels(completed_level: String, completion_data: Dictionary):
	"""Check if completing this level unlocks any new levels"""
	var level_config = _load_level_map_config()
	if level_config.is_empty():
		return
	
	var level_nodes = level_config.get("level_nodes", [])
	var newly_unlocked = []
	
	# Always unlock the immediate next level when completing any level
	var next_level = get_next_level_in_progression(completed_level)
	if next_level != "" and not is_level_unlocked(next_level):
		# Mark as unlocked in profile
		if not "unlocked_levels" in current_profile:
			current_profile["unlocked_levels"] = []
		if not next_level in current_profile.unlocked_levels:
			current_profile.unlocked_levels.append(next_level)
		newly_unlocked.append(next_level)
	
	# Also check other levels that might be unlocked by meeting requirements
	for node in level_nodes:
		var level_id = node.get("id", "")
		var requirements = node.get("unlock_requirements", {})
		
		# Skip if no requirements, already unlocked, or already in newly_unlocked
		if requirements.is_empty() or is_level_unlocked(level_id) or level_id in newly_unlocked:
			continue
		
		# Check if this level's requirements are now met
		var should_unlock = true
		
		# Check previous level requirement
		if "previous_level" in requirements:
			var prev_level = requirements["previous_level"]
			var prev_completion = get_level_completion(prev_level)
			if not prev_completion.get("completed", false):
				should_unlock = false
		
		# Check minimum score requirement
		if should_unlock and "min_score" in requirements:
			var required_score = requirements["min_score"]
			var prev_level = requirements.get("previous_level", "")
			if prev_level != "":
				var prev_completion = get_level_completion(prev_level)
				var prev_score = prev_completion.get("score", 0)
				if prev_score < required_score:
					should_unlock = false
		
		# Check maximum deaths requirement
		if should_unlock and "deaths_max" in requirements:
			var max_deaths = requirements["deaths_max"]
			var prev_level = requirements.get("previous_level", "")
			if prev_level != "":
				var prev_completion = get_level_completion(prev_level)
				var deaths = prev_completion.get("deaths", 0)
				if deaths > max_deaths:
					should_unlock = false
		
		if should_unlock:
			# Mark as unlocked in profile
			if not "unlocked_levels" in current_profile:
				current_profile["unlocked_levels"] = []
			if not level_id in current_profile.unlocked_levels:
				current_profile.unlocked_levels.append(level_id)
			newly_unlocked.append(level_id)
	
	# Notify about newly unlocked levels
	for level_id in newly_unlocked:
		print("🔓 Level unlocked: ", level_id)
		# Emit signal if EventBus is available
		if EventBus and EventBus.has_signal("level_unlocked"):
			EventBus.level_unlocked.emit(level_id)

func _load_level_map_config() -> Dictionary:
	"""Load the level map configuration"""
	var config_path = "res://data/level_map_config.json"
	
	if not FileAccess.file_exists(config_path):
		print("Warning: level_map_config.json not found")
		return {}
	
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		print("Error: Could not open level_map_config.json")
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing level_map_config.json: ", json.error_string)
		return {}
	
	return json.data

func _count_total_relics() -> int:
	"""Count total relics/gems collected across all levels"""
	var total = 0
	for level_name in current_profile.level_completions:
		var completion_data = current_profile.level_completions[level_name]
		total += completion_data.get("gems_found", 0)
	return total

func get_next_level_in_progression(current_level: String) -> String:
	"""Get the next level in the progression sequence"""
	var level_config = _load_level_map_config()
	if level_config.is_empty():
		return ""
	
	var level_nodes = level_config.get("level_nodes", [])
	
	# Sort by order
	level_nodes.sort_custom(func(a, b): return a.get("order", 0) < b.get("order", 0))
	
	# Find current level and return next
	for i in range(level_nodes.size()):
		if level_nodes[i].get("id", "") == current_level:
			if i + 1 < level_nodes.size():
				return level_nodes[i + 1].get("id", "")
			break
	
	return ""  # No next level or current level not found

func get_unlocked_levels() -> Array:
	"""Get list of all unlocked level IDs"""
	var level_config = _load_level_map_config()
	if level_config.is_empty():
		return ["Level00"]  # Fallback
	
	var unlocked = []
	var level_nodes = level_config.get("level_nodes", [])
	
	for node in level_nodes:
		var level_id = node.get("id", "")
		if level_id != "" and is_level_unlocked(level_id):
			unlocked.append(level_id)
	
	return unlocked
