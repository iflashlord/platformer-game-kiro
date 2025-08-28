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
	elif Input.is_action_just_pressed("debug_toggle"):
		DebugSettings.toggle_debug_borders()
		print("Debug borders toggled: ", DebugSettings.show_debug_borders)
	elif Input.is_action_just_pressed("restart"):
		restart_game()

func _process(delta):
	if is_trial_mode and trial_time > 0:
		trial_time -= delta
		time_changed.emit(trial_time)
		
		if trial_time <= 0:
			trial_time = 0
			# Time's up!
			print("Time's up! Trial failed!")

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	
	if is_paused:
		game_paused.emit()
	else:
		game_resumed.emit()

func restart_game():
	print("🔄 Restarting game...")
	
	get_tree().paused = false
	is_paused = false
	score = 0
	trial_time = 0.0
	reset_collectibles()
	
	# Track level attempt
	if current_level != "":
		Persistence.increment_level_attempts(current_level)
	
	game_restarted.emit()
	
	# Use LevelLoader if available for better restart handling
	if LevelLoader and LevelLoader.has_method("restart") and current_level != "":
		print("🔄 Using LevelLoader to restart: ", current_level)
		LevelLoader.restart()
	else:
		# Fallback to scene reload
		_restart_current_scene()

func _restart_current_scene():
	"""Restart current scene as fallback"""
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_path = current_scene.scene_file_path
		if scene_path != "":
			print("🔄 Reloading scene: ", scene_path)
			get_tree().change_scene_to_file(scene_path)
		else:
			print("❌ Current scene path is empty, cannot reload.")
	else:
		print("❌ No current scene to reload.")

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
		Persistence.update_statistics("total_collectibles", 1)
		
		print("Fruit collected! Type: ", fruit_type, " Total: ", total_fruits)

func collect_gem(gem_type: int):
	if gem_type in gem_counts:
		gem_counts[gem_type] += 1
		total_gems += 1
		gem_collected.emit(gem_type, gem_counts[gem_type])
		
		# Update persistence statistics
		Persistence.update_statistics("total_collectibles", 1)
		
		print("Gem collected! Type: ", gem_type, " Total: ", total_gems)

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
		print("Time reduced by ", amount, "s! Remaining: ", trial_time, "s")

func get_trial_time() -> float:
	return trial_time

func show_level_results(level_name: String, time: float, final_score: int, gems: int, total_gems: int):
	print("Level Results: ", level_name)
	print("Time: ", time, "s")
	print("Score: ", final_score)
	print("Gems: ", gems, "/", total_gems)
	
	# This would typically show a results screen
	# For now, just print the results
