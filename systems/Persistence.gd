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
	
	# Update LevelLoader with the new time
	var time_seconds = time_ms / 1000.0
	LevelLoader.update_best_time(level_name, time_seconds)
	
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
	
	# Update LevelLoader with the new score
	LevelLoader.update_best_score(level_name, score)
	
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
	var total_levels = LevelLoader.get_all_levels().size()
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
	
	# Store or update completion data
	var existing_data = current_profile.level_completions.get(level_name, {})
	
	# Keep best performance
	if existing_data.is_empty() or _is_better_completion(completion_data, existing_data):
		current_profile.level_completions[level_name] = completion_data
		print("💾 New best completion saved for ", level_name)
	else:
		print("💾 Completion recorded but not a new best for ", level_name)
	
	# Update statistics
	current_profile.statistics.levels_completed += 1
	current_profile.statistics.total_score += completion_data.get("score", 0)
	
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
	match level_name:
		"Tutorial":
			return true
		"Level01":
			return get_level_completion("Tutorial").get("completed", false)
		"Level02":
			return get_level_completion("Level01").get("completed", false)
		"Level03":
			return get_level_completion("Level02").get("completed", false)
		_:
			return false