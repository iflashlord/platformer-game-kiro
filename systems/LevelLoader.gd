extends Node

signal level_loaded(level_name: String)
signal level_load_failed(level_name: String)
signal loading_started(level_name: String)
signal loading_progress(progress: float)

var current_level_scene: Node = null
var levels_data: Dictionary = {}
var loading_overlay: Control = null
var is_loading: bool = false

func _ready():
	# Load levels configuration
	load_levels_config()
	
	# Create loading overlay
	create_loading_overlay()

func load_levels_config():
	var config_path = "res://data/load_levels_config.json"
	
	if not FileAccess.file_exists(config_path):
		print("Warning: levels.json not found, using default configuration")
		create_default_levels_config()
		return
	
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		print("Error: Could not open levels.json")
		create_default_levels_config()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing levels.json: ", json.error_string)
		create_default_levels_config()
		return
	
	levels_data = json.data
	print("Loaded levels configuration with ", levels_data.levels.size(), " levels")

func create_default_levels_config():
	levels_data = {
		"levels": {
			"Level00": {
				"name": "Tutorial",
				"scene_path": "res://levels/Level00.tscn",
				"unlocked": true,
				"time_trial_unlocked": false,
				"best_time": 0.0,
				"best_score": 0,
				"unlock_requirements": {},
				"time_trial_requirements": {
					"best_time": 60.0
				}
			},
			"CrateTest": {
				"name": "Crate Test",
				"scene_path": "res://levels/CrateTest.tscn",
				"unlocked": true,
				"time_trial_unlocked": false,
				"best_time": 0.0,
				"best_score": 0,
				"unlock_requirements": {},
				"time_trial_requirements": {
					"best_time": 45.0
				}
			},
			"CollectibleTest": {
				"name": "Collectible Test",
				"scene_path": "res://levels/CollectibleTest.tscn",
				"unlocked": true,
				"time_trial_unlocked": false,
				"best_time": 0.0,
				"best_score": 0,
				"unlock_requirements": {},
				"time_trial_requirements": {
					"best_time": 30.0
				}
			}
		}
	}

func create_loading_overlay():
	loading_overlay = Control.new()
	loading_overlay.name = "LoadingOverlay"
	loading_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	loading_overlay.visible = false
	
	# Background
	var background = ColorRect.new()
	background.color = Color.BLACK
	background.color.a = 0.8
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_overlay.add_child(background)
	
	# Loading container
	var container = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	container.offset_left = -150
	container.offset_top = -50
	container.offset_right = 150
	container.offset_bottom = 50
	loading_overlay.add_child(container)
	
	# Loading label
	var loading_label = Label.new()
	loading_label.text = "LOADING..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 24)
	container.add_child(loading_label)
	
	# Progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.name = "ProgressBar"
	container.add_child(progress_bar)
	
	# Level name label
	var level_label = Label.new()
	level_label.text = ""
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.name = "LevelLabel"
	container.add_child(level_label)

func show_loading_overlay(level_name: String):
	if not loading_overlay:
		create_loading_overlay()
	
	# Add to current scene
	get_tree().current_scene.add_child(loading_overlay)
	loading_overlay.visible = true
	
	# Update labels
	var level_label = loading_overlay.get_node("VBoxContainer/LevelLabel")
	if level_label:
		var display_name = get_level_display_name(level_name)
		level_label.text = "Loading: " + display_name
	
	# Reset progress
	var progress_bar = loading_overlay.get_node("VBoxContainer/ProgressBar")
	if progress_bar:
		progress_bar.value = 0.0

func hide_loading_overlay():
	if loading_overlay and loading_overlay.get_parent():
		loading_overlay.get_parent().remove_child(loading_overlay)

func update_loading_progress(progress: float):
	if not loading_overlay:
		return
	
	var progress_bar = loading_overlay.get_node("VBoxContainer/ProgressBar")
	if progress_bar:
		progress_bar.value = progress * 100.0
	
	loading_progress.emit(progress)

func goto(level_name: String) -> bool:
	if is_loading:
		print("Already loading a level")
		return false
	
	if not is_level_unlocked(level_name):
		print("Level ", level_name, " is not unlocked")
		return false
	
	load_level_async(level_name, false)
	return true

func restart() -> bool:
	if Game.current_level == "":
		print("No current level to restart")
		return false
	
	load_level_async(Game.current_level, false)
	return true

func load_time_trial(level_name: String) -> bool:
	if is_loading:
		print("Already loading a level")
		return false
	
	if not is_time_trial_unlocked(level_name):
		print("Time trial for ", level_name, " is not unlocked")
		return false
	
	load_level_async(level_name, true)
	return true

func load_level_async(level_name: String, is_time_trial: bool = false) -> bool:
	var level_info = get_level_info(level_name)
	if level_info.is_empty():
		level_load_failed.emit(level_name)
		return false
	
	var scene_path = level_info.scene_path
	if not ResourceLoader.exists(scene_path):
		print("Level scene not found: ", scene_path)
		level_load_failed.emit(level_name)
		return false
	
	is_loading = true
	loading_started.emit(level_name)
	show_loading_overlay(level_name)
	
	# Start async loading
	var loader = ResourceLoader.load_threaded_request(scene_path)
	if loader == null:
		print("Failed to start loading: ", scene_path)
		is_loading = false
		hide_loading_overlay()
		level_load_failed.emit(level_name)
		return false
	
	# Monitor loading progress
	await monitor_loading_progress(scene_path, level_name, is_time_trial)
	return true

func monitor_loading_progress(scene_path: String, level_name: String, is_time_trial: bool):
	var progress = []
	
	while true:
		var status = ResourceLoader.load_threaded_get_status(scene_path, progress)
		
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				update_loading_progress(progress[0])
				await get_tree().process_frame
			ResourceLoader.THREAD_LOAD_LOADED:
				update_loading_progress(1.0)
				await complete_level_load(scene_path, level_name, is_time_trial)
				return
			ResourceLoader.THREAD_LOAD_FAILED:
				print("Failed to load level: ", scene_path)
				is_loading = false
				hide_loading_overlay()
				level_load_failed.emit(level_name)
				return
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				print("Invalid resource: ", scene_path)
				is_loading = false
				hide_loading_overlay()
				level_load_failed.emit(level_name)
				return

func complete_level_load(scene_path: String, level_name: String, is_time_trial: bool):
	# Get the loaded resource
	var level_resource = ResourceLoader.load_threaded_get(scene_path)
	if level_resource == null:
		print("Failed to get loaded resource")
		is_loading = false
		hide_loading_overlay()
		level_load_failed.emit(level_name)
		return
	
	# Small delay for visual feedback
	await get_tree().create_timer(0.5).timeout
	
	# Clean up current level
	if current_level_scene:
		current_level_scene.queue_free()
	
	# Change scene
	get_tree().change_scene_to_packed(level_resource)
	
	# Update game state
	Game.current_level = level_name
	if is_time_trial:
		var level_info = get_level_info(level_name)
		var time_limit = level_info.get("time_trial_limit", 60.0)
		Game.start_trial_mode(time_limit)
	
	# Cleanup
	is_loading = false
	hide_loading_overlay()
	level_loaded.emit(level_name)
	
	print("Successfully loaded level: ", level_name, " (Time Trial: ", is_time_trial, ")")

func get_level_info(level_name: String) -> Dictionary:
	if level_name in levels_data.levels:
		return levels_data.levels[level_name]
	return {}

func get_level_display_name(level_name: String) -> String:
	var level_info = get_level_info(level_name)
	return level_info.get("name", level_name)

func is_level_unlocked(level_name: String) -> bool:
	var level_info = get_level_info(level_name)
	return level_info.get("unlocked", false)

func is_time_trial_unlocked(level_name: String) -> bool:
	var level_info = get_level_info(level_name)
	return level_info.get("time_trial_unlocked", false)

func unlock_level(level_name: String):
	if level_name in levels_data.levels:
		levels_data.levels[level_name].unlocked = true
		save_levels_config()

func unlock_time_trial(level_name: String):
	if level_name in levels_data.levels:
		levels_data.levels[level_name].time_trial_unlocked = true
		save_levels_config()

func update_best_time(level_name: String, time: float):
	if level_name in levels_data.levels:
		var current_best = levels_data.levels[level_name].get("best_time", 0.0)
		if time < current_best or current_best == 0.0:
			levels_data.levels[level_name].best_time = time
			save_levels_config()
			
			# Check if time trial should be unlocked
			check_time_trial_unlock(level_name)

func update_best_score(level_name: String, score: int):
	if level_name in levels_data.levels:
		var current_best = levels_data.levels[level_name].get("best_score", 0)
		if score > current_best:
			levels_data.levels[level_name].best_score = score
			save_levels_config()

func check_time_trial_unlock(level_name: String):
	var level_info = get_level_info(level_name)
	if level_info.is_empty():
		return
	
	var requirements = level_info.get("time_trial_requirements", {})
	var required_time = requirements.get("best_time", 0.0)
	var current_best = level_info.get("best_time", 0.0)
	
	if required_time > 0.0 and current_best > 0.0 and current_best <= required_time:
		unlock_time_trial(level_name)
		print("Time trial unlocked for ", level_name, "!")

func save_levels_config():
	var config_path = "res://data/levels.json"
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	if file == null:
		print("Error: Could not save levels.json")
		return
	
	file.store_string(JSON.stringify(levels_data, "\t"))
	file.close()

func get_all_levels() -> Dictionary:
	return levels_data.get("levels", {})

func has_next_level() -> bool:
	# Get current level and find next in progression
	var current = Game.current_level
	if current == "":
		return false
	
	var level_order = ["Level00", "CrateTest", "CollectibleTest", "DimensionTest", "EnemyGauntlet", "Level01", "Level02", "Level03", "Chase01"]
	var current_index = level_order.find(current)
	
	if current_index >= 0 and current_index < level_order.size() - 1:
		var next_level = level_order[current_index + 1]
		return is_level_unlocked(next_level)
	
	return false

func load_next_level() -> bool:
	var current = Game.current_level
	if current == "":
		return false
	
	var level_order = ["Level00", "CrateTest", "CollectibleTest", "DimensionTest", "EnemyGauntlet", "Level01", "Level02", "Level03", "Chase01"]
	var current_index = level_order.find(current)
	
	if current_index >= 0 and current_index < level_order.size() - 1:
		var next_level = level_order[current_index + 1]
		if is_level_unlocked(next_level):
			return goto(next_level)
	
	return false

func check_level_completion(score: int, time: float, collectibles_percentage: float = 100.0):
	var current = Game.current_level
	if current == "":
		return
	
	# Update best records
	update_best_score(current, score)
	update_best_time(current, time)
	
	# Check unlock requirements for next levels
	check_unlock_requirements()
	
	print("Level completion checked for ", current, " - Score: ", score, ", Time: ", time)

func check_unlock_requirements():
	var levels = get_all_levels()
	
	for level_id in levels.keys():
		var level_info = levels[level_id]
		
		# Skip if already unlocked
		if level_info.get("unlocked", false):
			continue
		
		var requirements = level_info.get("unlock_requirements", {})
		if requirements.is_empty():
			continue
		
		var should_unlock = true
		
		# Check previous level requirement
		if "previous_level" in requirements:
			var prev_level = requirements.previous_level
			var prev_info = get_level_info(prev_level)
			if prev_info.is_empty() or prev_info.get("best_score", 0) == 0:
				should_unlock = false
		
		# Check minimum score requirement
		if "min_score" in requirements:
			var required_score = requirements.min_score
			var prev_level = requirements.get("previous_level", "")
			if prev_level != "":
				var prev_info = get_level_info(prev_level)
				if prev_info.get("best_score", 0) < required_score:
					should_unlock = false
		
		# Check maximum deaths requirement
		if "deaths_max" in requirements:
			# This would need to be tracked in Game system
			pass
		
		if should_unlock:
			unlock_level(level_id)
			print("Level unlocked: ", level_id)

func get_loading_status() -> String:
	if is_loading:
		return "Loading..."
	return "Ready"

func is_loading_active() -> bool:
	return is_loading

# Legacy methods for compatibility
func load_level(level_name: String) -> bool:
	return goto(level_name)

func reload_current_level() -> bool:
	return restart()
