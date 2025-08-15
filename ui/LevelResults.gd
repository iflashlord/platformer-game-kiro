extends CanvasLayer

@onready var level_name_label: Label = $ResultsPanel/VBoxContainer/LevelName
@onready var time_label: Label = $ResultsPanel/VBoxContainer/StatsContainer/TimeLabel
@onready var hearts_label: Label = $ResultsPanel/VBoxContainer/StatsContainer/HeartsLabel
@onready var gems_label: Label = $ResultsPanel/VBoxContainer/StatsContainer/GemsLabel
@onready var score_label: Label = $ResultsPanel/VBoxContainer/StatsContainer/ScoreLabel

@onready var retry_button: Button = $ResultsPanel/VBoxContainer/ButtonContainer/RetryButton
@onready var map_button: Button = $ResultsPanel/VBoxContainer/ButtonContainer/MapButton
@onready var menu_button: Button = $ResultsPanel/VBoxContainer/ButtonContainer/MenuButton

var current_level: String = ""

func _ready():
	# Add to group to prevent duplicates
	add_to_group("level_results")
	
	# Connect buttons
	retry_button.pressed.connect(_on_retry_pressed)
	map_button.pressed.connect(_on_map_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Animate panel entrance
	var panel = $ResultsPanel
	panel.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.5)
	tween.tween_callback(func(): Audio.play_sfx("ui_appear"))

func setup_results(completion_data: Dictionary):
	current_level = completion_data.level_name
	
	# Update labels
	level_name_label.text = _get_level_display_name(completion_data.level_name)
	
	# Format time
	var time = completion_data.completion_time
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	time_label.text = "⏱️ Time: %02d:%02d.%02d" % [minutes, seconds, milliseconds]
	
	# Hearts remaining
	hearts_label.text = "❤️ Hearts Remaining: %d/5" % completion_data.hearts_remaining
	
	# Gems found
	gems_label.text = "💎 Hidden Gems: %d/%d" % [completion_data.gems_found, completion_data.total_gems]
	
	# Final score
	score_label.text = "🏆 Final Score: %04d" % completion_data.score
	
	# Color code based on performance
	_apply_performance_colors(completion_data)

func _get_level_display_name(level_name: String) -> String:
	var display_names = {
		"Level01": "🌲 Forest Adventure",
		"Level02": "🏭 Industrial Zone", 
		"Level03": "☁️ Sky Realm"
	}
	return display_names.get(level_name, level_name)

func _apply_performance_colors(completion_data: Dictionary):
	# Color hearts based on remaining
	var heart_color = Color.WHITE
	if completion_data.hearts_remaining >= 4:
		heart_color = Color.GREEN
	elif completion_data.hearts_remaining >= 2:
		heart_color = Color.YELLOW
	else:
		heart_color = Color.RED
	hearts_label.modulate = heart_color
	
	# Color gems based on collection
	var gem_color = Color.WHITE
	if completion_data.gems_found == completion_data.total_gems:
		gem_color = Color.GOLD
	elif completion_data.gems_found > 0:
		gem_color = Color.CYAN
	else:
		gem_color = Color.GRAY
	gems_label.modulate = gem_color
	
	# Color score based on performance
	var score_color = Color.WHITE
	if completion_data.score >= 2500:
		score_color = Color.GOLD
	elif completion_data.score >= 2000:
		score_color = Color.CYAN
	elif completion_data.score >= 1500:
		score_color = Color.GREEN
	score_label.modulate = score_color

func _on_retry_pressed():
	Audio.play_sfx("ui_click")
	# Restart the current level
	print("🔄 Retrying level: ", current_level)
	if LevelLoader and LevelLoader.has_method("load_level"):
		LevelLoader.load_level(current_level)
	else:
		# Fallback: reload current scene
		get_tree().reload_current_scene()
	queue_free()

func _on_map_pressed():
	Audio.play_sfx("ui_click")
	# Go to level map
	get_tree().change_scene_to_file("res://ui/LevelMap.tscn")
	queue_free()

func _on_menu_pressed():
	Audio.play_sfx("ui_click")
	# Go to main menu
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
	queue_free()