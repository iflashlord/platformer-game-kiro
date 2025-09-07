extends Node2D
class_name BaseLevel

# Base level script that all levels inherit from
signal level_completed(score: int, time: float, deaths: int)
signal level_failed()

@export var level_id: String = ""
@export var level_name: String = ""
@export var target_score: int = 100
@export var time_limit: float = 0.0  # 0 = no time limit

var start_time: float
var current_score: int = 0
var death_count: int = 0
var is_completed: bool = false
 
@onready var ui: Node = get_node_or_null("UI")
@onready var player: Player = get_node_or_null("Player")
@onready var hud = get_node_or_null("UI/GameHUD")
@onready var levelManager = get_tree().current_scene.get_node_or_null("LevelManager")

var hidden_gems_collected_count: int = 0

func _ready():
	start_time = Time.get_unix_time_from_system()

	#level manager 
	print("BaseLevel ready, looking for LevelManager..."+ str(levelManager))
	levelManager.initialize_level(level_id if level_id != "" else level_name)

	# Reset hidden gems counter
	hidden_gems_collected_count = 0

	# Track level start for save data
	if level_id != "" and Persistence and Persistence.has_method("track_level_start"):
		Persistence.track_level_start(level_id)
	elif level_name != "" and Persistence and Persistence.has_method("track_level_start"):
		Persistence.track_level_start(level_name)

	# Initialize systems
	if HealthSystem:
		HealthSystem.reset_health()
	
	if Respawn:
		Respawn.reset_checkpoints()

	# Start game timer
	if GameTimer:
		GameTimer.start_timer()
	
	# Reset score
	if Game:
		Game.score = 0

	# Reset dimension to layer A
	if DimensionManager:
		DimensionManager.reset_to_layer_a()

	# Audio feedback
	if Audio:
		Audio.play_music(level_id, 0.4)
	
	# Connect health system to HUD
	if HealthSystem and hud and hud.has_method("update_health"):
		# Disconnect any existing connections to avoid duplicates
		if HealthSystem.health_changed.is_connected(hud.update_health):
			HealthSystem.health_changed.disconnect(hud.update_health)
		
		HealthSystem.health_changed.connect(hud.update_health)
		HealthSystem.player_died.connect(_on_game_over)
		hud.update_health(HealthSystem.get_current_health(), HealthSystem.get_max_health())
	
	setup_level()
	connect_signals()
	# Defer gem counting to ensure all nodes are ready
	call_deferred("_update_total_gems")
func _update_total_gems():
	var total_gems = _count_total_gems_in_level()
	print("Total gems in level (including hidden): ", total_gems)
	var total_hidden_gems = _count_total_hidden_gems_in_level()
	print("Total hidden gems in level: ", total_hidden_gems)
	var total_hidden_gems_collected = _count_total_hidden_gems_collected_in_level()
	print("Total hidden gems collected in level: ", total_hidden_gems_collected)

func setup_level():
	# Override in child classes for level-specific setup
	pass
 
func connect_signals():
	if player and player.has_signal("player_died"):
		# Disconnect if already connected to avoid duplicates
		if player.player_died.is_connected(_on_player_died):
			player.player_died.disconnect(_on_player_died)
		player.player_died.connect(_on_player_died)

	# Set initial spawn position
	if player and Respawn:
		Respawn.default_spawn_position = player.global_position

	# Reset hidden gems counter
	hidden_gems_collected_count = 0

	# Connect to hidden gems
	var hidden_gems = get_tree().get_nodes_in_group("hidden_gems")
	for gem in hidden_gems:
		if gem.has_signal("hidden_gem_found") and not gem.hidden_gem_found.is_connected(_on_hidden_gem_found):
			gem.hidden_gem_found.connect(_on_hidden_gem_found)
	
	# Connect to EventBus for global events (disconnect first to avoid duplicates)
	if EventBus:
		if EventBus.fruit_collected.is_connected(_on_fruit_collected):
			EventBus.fruit_collected.disconnect(_on_fruit_collected)
		if EventBus.gem_collected.is_connected(_on_gem_collected):
			EventBus.gem_collected.disconnect(_on_gem_collected)
		if EventBus.level_portal_entered.is_connected(_on_level_completed):
			EventBus.level_portal_entered.disconnect(_on_level_completed)
		
		EventBus.fruit_collected.connect(_on_fruit_collected)
		EventBus.gem_collected.connect(_on_gem_collected)
		EventBus.level_portal_entered.connect(_on_level_completed)

func _on_player_died():
	death_count += 1
	# Respawn logic handled by Game system

func _on_game_over():
	print("💀 Game Over")
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func _on_fruit_collected(points: int):
	current_score += points
	update_ui()

func _on_gem_collected(points: int):
	current_score += points
	update_ui()

func _on_hidden_gem_found():
	hidden_gems_collected_count += 1
	print("Hidden gem found! Total collected: ", hidden_gems_collected_count)

func _on_level_completed():
	if is_completed:
		return
		
	is_completed = true
	var end_time = Time.get_unix_time_from_system()
	var completion_time = end_time - start_time
	
	_update_total_gems()
	call_deferred("_update_total_gems")


	# Hide and cleanup pause menu if it's showing
	if PauseManager:
		if PauseManager.has_method("hide_pause_menu"):
			PauseManager.hide_pause_menu()
		if PauseManager.has_method("cleanup"):
			PauseManager.cleanup()
	
	# Pause the game immediately when level is completed
	if Game:
		Game.is_paused = true
		get_tree().paused = true
		Game.game_paused.emit()
	
	# Prepare completion data
	var completion_data = {
		"level_name": level_id if level_id != "" else level_name,
		"score": current_score,
		"completion_time": completion_time,
		"deaths": death_count,
		"hearts_remaining": HealthSystem.get_current_health() if HealthSystem else 5,
		"gems_found": Game.get_total_gems() if Game else 0,
		"total_gems": _count_total_gems_in_level(),
		"hidden_gems_collected": hidden_gems_collected_count,
		"total_hidden_gems": _count_total_hidden_gems_in_level(),
		"completed": true
	}
	
	# Save completion to persistence system
	if Persistence and Persistence.has_method("save_level_completion"):
		var level_name_to_save = level_id if level_id != "" else level_name
		print("BaseLevel save level complete " + level_name_to_save)
		Persistence.save_level_completion(level_name_to_save, completion_data)
	
	# Show level results
	_show_level_results(completion_data)
	
	level_completed.emit(current_score, completion_time, death_count)

func update_ui():
	if ui and ui.has_method("update_score"):
		ui.update_score(current_score)

func get_completion_stats() -> Dictionary:
	return {
		"score": current_score,
		"deaths": death_count,
		"time": Time.get_time_dict_from_system()["unix"] - start_time
	}

func _count_total_gems_in_level() -> int:
	"""Count total gems available in this level"""
	var gem_count = 0
	var gems = get_tree().get_nodes_in_group("gems")
	if gems:
		gem_count = gems.size()
	
	# Also check for HiddenGem nodes
	var hidden_gems = get_tree().get_nodes_in_group("hidden_gems")
	if hidden_gems:
		gem_count += hidden_gems.size()
	
	return gem_count

func _count_total_hidden_gems_in_level() -> int:
	"""Count total gems available in this level"""
	var gem_count = 0
	# Also check for HiddenGem nodes
	var hidden_gems = get_tree().get_nodes_in_group("hidden_gems")
	if hidden_gems:
		gem_count += hidden_gems.size()
	
	return gem_count

func _count_total_hidden_gems_collected_in_level() -> int:
	"""Count total gems collected in this level"""
	print("Total hidden_gems_collected:", hidden_gems_collected_count)
	return hidden_gems_collected_count

func _show_level_results(completion_data: Dictionary):
	"""Show the level results screen"""
	# Load and show the level results scene

	_count_total_hidden_gems_collected_in_level()

	var results_scene = preload("res://ui/LevelResults.tscn")
	if results_scene:
		var results_instance = results_scene.instantiate()
		get_tree().current_scene.add_child(results_instance)
		
		# Setup the results with completion data
		if results_instance.has_method("setup_results"):
			results_instance.setup_results(completion_data)
		
		print("🎉 Level results shown for: ", completion_data.get("level_name", "Unknown"))
