extends Node

signal game_paused
signal game_resumed
signal game_restarted
signal score_changed(new_score: int)
signal time_changed(new_time: float)
signal fruit_collected(fruit_type: int, total_count: int)
signal gem_collected(gem_type: int, total_count: int)

var is_paused: bool = false
var current_level: String = ""
var current_section: String = ""
var score: int = 0
var trial_time: float = 0.0
var is_trial_mode: bool = false

# Collectible tracking
var fruit_counts: Dictionary = {}
var gem_counts: Dictionary = {}
var total_fruits: int = 0
var total_gems: int = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_collectibles()

func _input(event):
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
	elif Input.is_action_just_pressed("restart"):
		restart_game()
	elif OS.is_debug_build() and Input.is_action_just_pressed("debug_toggle"):
		DebugSettings.toggle_debug_borders()

func _process(delta):
	if is_trial_mode and trial_time > 0:
		trial_time -= delta
		time_changed.emit(trial_time)
		
		if trial_time <= 0:
			trial_time = 0
			_handle_trial_timeout()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	
	if is_paused:
		game_paused.emit()
	else:
		game_resumed.emit()

func restart_game():
	# Unpause and reset game state
	get_tree().paused = false
	is_paused = false
	score = 0
	trial_time = 0.0
	reset_collectibles()
	
	# Track level attempt for analytics
	if current_level != "" and Persistence:
		Persistence.increment_level_attempts(current_level)
	
	# Emit signals for UI updates
	score_changed.emit(score)
	game_restarted.emit()
	
	# Reset core systems
	_reset_game_systems()
	
	# Reload the scene to reset level state
	_restart_current_scene()

func _restart_current_scene():
	"""Reload the current scene to reset level state"""
	var current_scene = get_tree().current_scene
	if not current_scene:
		if ErrorHandler:
			ErrorHandler.error("No current scene to reload", "Game.restart")
		return
	
	var scene_path = current_scene.scene_file_path
	if scene_path == "":
		if ErrorHandler:
			ErrorHandler.error("Current scene has no file path", "Game.restart")
		return
	
	# Use SceneManager if available, otherwise fallback
	if SceneManager:
		SceneManager.change_scene(scene_path, false)
	else:
		var result = get_tree().change_scene_to_file(scene_path)
		if result != OK and ErrorHandler:
			ErrorHandler.report_scene_load_error(scene_path, result)

func _reset_game_systems():
	"""Reset all game systems to initial state"""
	if HealthSystem and HealthSystem.has_method("reset_health"):
		HealthSystem.reset_health()
	
	if GameTimer and GameTimer.has_method("reset_timer"):
		GameTimer.reset_timer()

func _handle_trial_timeout():
	"""Handle when trial mode time runs out"""
	# Could show game over screen or restart level
	# For now, just emit a signal that UI can listen to
	if current_level != "":
		show_level_results(current_level, 0.0, score, total_gems, 0)

func reset_collectibles():
	fruit_counts.clear()
	gem_counts.clear()
	total_fruits = 0
	total_gems = 0
	
	# Initialize fruit counts
	for i in range(5): # 5 fruit types
		fruit_counts[i] = 0
	
	# Initialize gem counts
	for i in range(5): # 5 gem types
		gem_counts[i] = 0

func add_score(points: int):
	score += points
	score_changed.emit(score)
	
	# Update persistence with new score if it's better
	if current_level != "":
		Persistence.set_best_score(current_level, score)

func get_score() -> int:
	return score

func collect_fruit(fruit_type: int):
	if fruit_type in fruit_counts:
		fruit_counts[fruit_type] += 1
		total_fruits += 1
		fruit_collected.emit(fruit_type, fruit_counts[fruit_type])
		
		# Update persistence statistics
		if Persistence:
			Persistence.update_statistics("total_collectibles", 1)

func collect_gem(gem_type: int):
	if gem_type in gem_counts:
		gem_counts[gem_type] += 1
		total_gems += 1
		gem_collected.emit(gem_type, gem_counts[gem_type])
		
		# Update persistence statistics
		if Persistence:
			Persistence.update_statistics("total_collectibles", 1)

func get_fruit_count(fruit_type: int) -> int:
	return fruit_counts.get(fruit_type, 0)

func get_gem_count(gem_type: int) -> int:
	return gem_counts.get(gem_type, 0)

func get_total_fruits() -> int:
	return total_fruits

func get_total_gems() -> int:
	return total_gems

func get_completion_rank() -> String:
	var completion_percentage = 0.0
	var max_possible_score = 1000 # Adjust based on level design
	
	if max_possible_score > 0:
		completion_percentage = (float(score) / max_possible_score) * 100.0
	
	# Factor in collectibles
	var collectible_bonus = (total_fruits * 2) + (total_gems * 5)
	completion_percentage += collectible_bonus
	
	# Determine rank based on performance
	if completion_percentage >= 95:
		return "S+"
	elif completion_percentage >= 90:
		return "S"
	elif completion_percentage >= 80:
		return "A"
	elif completion_percentage >= 70:
		return "B"
	elif completion_percentage >= 60:
		return "C"
	elif completion_percentage >= 50:
		return "D"
	else:
		return "F"

func start_trial_mode(time_limit: float):
	is_trial_mode = true
	trial_time = time_limit
	time_changed.emit(trial_time)

func subtract_time(amount: float):
	if is_trial_mode:
		trial_time = max(0, trial_time - amount)
		time_changed.emit(trial_time)

func get_trial_time() -> float:
	return trial_time

func show_level_results(level_name: String, time: float, final_score: int, gems: int, total_gems: int):
	"""Display level completion results"""
	# Save completion data
	if Persistence:
		var completion_data = {
			"level_name": level_name,
			"completion_time": time,
			"score": final_score,
			"gems_found": gems,
			"total_gems": total_gems,
			"hearts_remaining": HealthSystem.get_current_health() if HealthSystem else 5
		}
		Persistence.save_level_completion(level_name, completion_data)
	
	# Load results screen
	var results_scene = preload("res://ui/LevelResults.tscn")
	if results_scene:
		var results = results_scene.instantiate()
		if results and results.has_method("setup_results"):
			var results_data = {
				"level_name": level_name,
				"completion_time": time,
				"score": final_score,
				"gems_found": gems,
				"total_gems": total_gems,
				"hearts_remaining": HealthSystem.get_current_health() if HealthSystem else 5
			}
			results.setup_results(results_data)
			get_tree().current_scene.add_child(results)
