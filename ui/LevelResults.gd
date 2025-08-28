extends CanvasLayer
class_name LevelResults

# UI References
@onready var level_name_label: Label = $UI/MenuContainer/Header/LevelName
@onready var time_label: Label = $UI/MenuContainer/StatsContainer/TimeLabel
@onready var hearts_label: Label = $UI/MenuContainer/StatsContainer/HeartsLabel
@onready var gems_label: Label = $UI/MenuContainer/StatsContainer/GemsLabel
@onready var score_label: Label = $UI/MenuContainer/StatsContainer/ScoreLabel

@onready var next_level_button: Button = $UI/MenuContainer/ButtonContainer/NextLevelButton
@onready var retry_button: Button = $UI/MenuContainer/ButtonContainer/RetryButton
@onready var level_select_button: Button = $UI/MenuContainer/ButtonContainer/LevelSelectButton
@onready var main_menu_button: Button = $UI/MenuContainer/ButtonContainer/MainMenuButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# State
var current_level: String = ""
var next_level: String = ""
var completion_data: Dictionary = {}
var menu_buttons: Array[Button] = []
var selected_button_index: int = 0
var is_menu_active: bool = false

func _ready():
	print("🎉 LevelResults _ready() called")
	
	# Add to group to prevent duplicates
	add_to_group("level_results")
	
	# Setup UI and connect signals
	_setup_ui()
	_connect_signals()
	_setup_button_effects()
	
	# Start hidden, will be shown when setup_results is called
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("✅ LevelResults initialized")

func _setup_ui():
	"""Setup UI elements and button array"""
	# Setup button array for navigation
	menu_buttons = [
		next_level_button,
		retry_button,
		level_select_button,
		main_menu_button
	]
	
	# Filter out null buttons
	menu_buttons = menu_buttons.filter(func(btn): return btn != null)
	
	# Setup proper keyboard navigation
	if MenuNavigationHelper:
		MenuNavigationHelper.setup_button_navigation(menu_buttons)

func _connect_signals():
	"""Connect all button signals"""
	if next_level_button:
		next_level_button.pressed.connect(_on_next_level_pressed)
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if level_select_button:
		level_select_button.pressed.connect(_on_level_select_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)

func show_results():
	"""Show the results screen with animation"""
	print("🎉 Showing level results")
	
	visible = true
	is_menu_active = true
	selected_button_index = 0
	
	# Focus first button
	_update_button_focus()
	
	# Play entrance animation
	if animation_player and animation_player.has_animation("slide_in"):
		animation_player.play("slide_in")
	
	# Play completion sound
	_play_ui_sound("ui_level_complete")

func setup_results(data: Dictionary):
	"""Setup the results screen with completion data"""
	completion_data = data
	current_level = data.get("level_name", "")
	
	print("🎉 Setting up results for level: ", current_level)
	
	# IMPORTANT: Save completion data to persistence FIRST
	# This ensures the level is marked as completed before checking unlock status
	_save_completion_data()
	
	# Determine next level
	next_level = _get_next_level(current_level)
	
	# Update labels
	level_name_label.text = _get_level_display_name(current_level)
	
	# Format time
	var time = data.get("completion_time", 0.0)
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	time_label.text = "⏱️ Time: %02d:%02d.%02d" % [minutes, seconds, milliseconds]
	
	# Hearts remaining
	hearts_label.text = "❤️ Hearts Remaining: %d/5" % data.get("hearts_remaining", 5)
	
	# Gems found
	gems_label.text = "💎 Hidden Gems: %d/%d" % [data.get("gems_found", 0), data.get("total_gems", 0)]
	
	# Final score
	score_label.text = "🏆 Final Score: %04d" % data.get("score", 0)
	
	# Color code based on performance
	_apply_performance_colors(data)
	
	# Update next level button (now that completion is saved)
	_setup_next_level_button()
	
	# Show the results
	show_results()

func _get_level_display_name(level_name: String) -> String:
	"""Get display name for a level"""
	var display_names = {
		"Level00": "🎓 Tutorial",
		"Level01": "🌲 Forest Adventure",
		"Level02": "🏭 Industrial Zone", 
		"Level03": "☁️ Sky Realm",
		"CrateTest": "📦 Crate Chaos",
		"CollectibleTest": "💎 Treasure Hunt",
		"DimensionTest": "🌀 Dimension Shift",
		"EnemyGauntlet": "⚔️ Enemy Gauntlet",
		"Chase01": "🏃 The Great Escape"
	}
	return display_names.get(level_name, level_name)

func _get_next_level(current: String) -> String:
	"""Get the next level in progression"""
	if has_node("/root/Persistence") and get_node("/root/Persistence").has_method("get_next_level_in_progression"):
		return get_node("/root/Persistence").get_next_level_in_progression(current)
	
	# Fallback to hardcoded progression
	var level_progression = [
		"Level00",
		"CrateTest", 
		"CollectibleTest",
		"DimensionTest",
		"EnemyGauntlet",
		"Level01",
		"Level02",
		"Level03",
		"Chase01"
	]
	
	var current_index = level_progression.find(current)
	if current_index >= 0 and current_index < level_progression.size() - 1:
		return level_progression[current_index + 1]
	
	return ""  # No next level

func _setup_next_level_button():
	"""Setup the next level button based on availability"""
	print("🔍 Setting up next level button...")
	print("  Current level: ", current_level)
	print("  Next level: ", next_level)
	
	if next_level == "":
		# No next level - this was the final level
		next_level_button.text = "🏆 GAME COMPLETE!"
		next_level_button.disabled = true
		next_level_button.modulate = Color(0.7, 0.7, 0.7)
		print("  No next level - game complete")
	else:
		# Check if current level is marked as completed
		if has_node("/root/Persistence"):
			var current_completion = get_node("/root/Persistence").get_level_completion(current_level)
			print("  Current level completion data: ", current_completion)
		
		# Check if next level is unlocked using Persistence system
		var is_unlocked = false
		if has_node("/root/Persistence") and get_node("/root/Persistence").has_method("is_level_unlocked"):
			is_unlocked = get_node("/root/Persistence").is_level_unlocked(next_level)
			print("  Next level unlock check result: ", is_unlocked)
		elif has_node("/root/LevelLoader"):
			is_unlocked = get_node("/root/LevelLoader").is_level_unlocked(next_level)
			print("  Next level unlock check (LevelLoader): ", is_unlocked)
		
		var next_display_name = _get_level_display_name(next_level)
		var short_name = next_display_name.split(" ", false, 1)[1] if " " in next_display_name else next_display_name
		
		if is_unlocked:
			next_level_button.text = "▶ NEXT: " + short_name
			next_level_button.disabled = false
			next_level_button.modulate = Color.WHITE
			# Make it the primary action (focused by default)
			selected_button_index = 0
			print("✅ Next level available: ", next_level)
		else:
			next_level_button.text = "🔒 LOCKED: " + short_name
			next_level_button.disabled = true
			next_level_button.modulate = Color(0.7, 0.7, 0.7)
			# Focus level select instead
			selected_button_index = 2
			print("🔒 Next level locked: ", next_level)

func _save_completion_data():
	"""Save completion data to persistence system"""
	if has_node("/root/Persistence") and current_level != "":
		# The completion data should already be saved by BaseLevel
		# But let's ensure it's saved with the latest data from the results screen
		if has_node("/root/Persistence"):
			get_node("/root/Persistence").save_level_completion(current_level, completion_data)
			
			# Also save to legacy system for compatibility
			var time = completion_data.get("completion_time", 0.0)
			var score = completion_data.get("score", 0)
			get_node("/root/Persistence").complete_level(current_level, time, score)
		
		print("💾 Completion data confirmed saved for ", current_level)

func _apply_performance_colors(data: Dictionary):
	"""Apply color coding based on performance"""
	# Color hearts based on remaining
	var hearts_remaining = data.get("hearts_remaining", 5)
	var heart_color = Color.WHITE
	if hearts_remaining >= 4:
		heart_color = Color.GREEN
	elif hearts_remaining >= 2:
		heart_color = Color.YELLOW
	else:
		heart_color = Color.RED
	hearts_label.modulate = heart_color
	
	# Color gems based on collection
	var gems_found = data.get("gems_found", 0)
	var total_gems = data.get("total_gems", 0)
	var gem_color = Color.WHITE
	if total_gems > 0:
		if gems_found == total_gems:
			gem_color = Color.GOLD
		elif gems_found > 0:
			gem_color = Color.CYAN
		else:
			gem_color = Color.GRAY
	gems_label.modulate = gem_color
	
	# Color score based on performance
	var score = data.get("score", 0)
	var score_color = Color.WHITE
	if score >= 2500:
		score_color = Color.GOLD
	elif score >= 2000:
		score_color = Color.CYAN
	elif score >= 1500:
		score_color = Color.GREEN
	score_label.modulate = score_color

# Button callbacks
func _on_next_level_pressed():
	"""Go to next level"""
	_play_ui_sound("ui_select")
	
	if next_level == "":
		# No next level, go to level select to show completion
		_on_level_select_pressed()
		return
	
	print("▶ Loading next level: ", next_level)
	_load_level(next_level)

func _on_retry_pressed():
	"""Restart the current level"""
	_play_ui_sound("ui_select")
	print("🔄 Retrying level: ", current_level)
	get_tree().reload_current_scene()
	queue_free()

func _on_level_select_pressed():
	"""Go to level select"""
	_play_ui_sound("ui_select")
	print("🗺 Going to level select")
	get_tree().change_scene_to_file("res://ui/LevelMapPro.tscn")
	queue_free()

func _on_main_menu_pressed():
	"""Go to main menu"""
	_play_ui_sound("ui_select")
	print("🏠 Going to main menu")
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
	queue_free()

func _load_level(level_id: String):
	"""Load a specific level"""
	print("🔍 _load_level called with level_id: ", level_id)
	
	# Check if level is unlocked first using Persistence system
	var is_unlocked = false
	if has_node("/root/Persistence") and get_node("/root/Persistence").has_method("is_level_unlocked"):
		is_unlocked = get_node("/root/Persistence").is_level_unlocked(level_id)
		print("🔍 Persistence unlock check for ", level_id, ": ", is_unlocked)
	elif has_node("/root/LevelLoader"):
		is_unlocked = get_node("/root/LevelLoader").is_level_unlocked(level_id)
		print("🔍 LevelLoader unlock check for ", level_id, ": ", is_unlocked)
	
	if not is_unlocked:
		print("❌ Level ", level_id, " is not unlocked yet")
		# Show message and go to level select instead
		_show_level_locked_message(level_id)
		return
	
	# Skip LevelLoader for now and go directly to scene loading
	# This avoids potential issues with LevelLoader system
	print("🔍 Loading level directly via scene file...")
	
	# Try to find level scene directly
	var level_scenes = {
		"Level00": "res://levels/Level00.tscn",
		"Level01": "res://levels/Level01.tscn", 
		"Level02": "res://levels/Level02.tscn",
		"Level03": "res://levels/Level03.tscn",
		"CrateTest": "res://levels/CrateTest.tscn",
		"CollectibleTest": "res://levels/CollectibleTest.tscn",
		"DimensionTest": "res://levels/DimensionTest.tscn",
		"EnemyGauntlet": "res://levels/EnemyGauntlet.tscn",
		"Chase01": "res://levels/Chase01.tscn"
	}
	
	var scene_path = level_scenes.get(level_id, "")
	print("🔍 Looking for scene path: ", scene_path)
	print("🔍 File exists: ", FileAccess.file_exists(scene_path) if scene_path != "" else false)
	
	if scene_path != "" and FileAccess.file_exists(scene_path):
		print("✅ Loading level scene: ", scene_path)
		get_tree().change_scene_to_file(scene_path)
		queue_free()
	else:
		print("❌ Level scene not found for ", level_id, " at path: ", scene_path)
		_on_level_select_pressed()  # Fallback to level select

func _show_level_locked_message(level_id: String):
	"""Show a message that the level is locked and go to level select"""
	print("🔒 Next level is locked, going to level select")
	
	# Wait a moment then go to level select
	await get_tree().create_timer(1.0).timeout
	_on_level_select_pressed()

# Input handling
func _input(event):
	if not visible or not is_menu_active:
		return
	
	# Handle keyboard navigation
	if Input.is_action_just_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		_navigate_menu(-1)
	elif Input.is_action_just_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_navigate_menu(1)
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		get_viewport().set_input_as_handled()
		_activate_selected_button()
	elif Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		get_viewport().set_input_as_handled()
		_on_level_select_pressed()

func _navigate_menu(direction: int):
	"""Navigate through menu buttons"""
	if menu_buttons.is_empty():
		return
	
	# Find currently focused button
	var current_focused = -1
	for i in range(menu_buttons.size()):
		if menu_buttons[i].has_focus():
			current_focused = i
			break
	
	# If no button is focused, start from selected index
	if current_focused == -1:
		current_focused = selected_button_index
	
	# Calculate next button index
	var next_index = (current_focused + direction) % menu_buttons.size()
	if next_index < 0:
		next_index = menu_buttons.size() - 1
	
	selected_button_index = next_index
	_update_button_focus()
	_play_ui_sound("ui_focus")

func _update_button_focus():
	"""Update visual focus indicators"""
	if selected_button_index >= 0 and selected_button_index < menu_buttons.size():
		var button = menu_buttons[selected_button_index]
		if button and button.visible and not button.disabled:
			button.grab_focus()

func _activate_selected_button():
	"""Activate the currently selected button"""
	if selected_button_index < menu_buttons.size():
		var button = menu_buttons[selected_button_index]
		if button and not button.disabled:
			button.pressed.emit()

# Helper functions
func _setup_button_effects():
	"""Setup hover and focus effects for buttons"""
	for button in menu_buttons:
		if not button:
			continue
		
		# Add hover effects
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_exit.bind(button))
		
		# Add focus effects
		button.focus_entered.connect(_on_button_focus.bind(button))
		button.focus_exited.connect(_on_button_unfocus.bind(button))

func _on_button_hover(button: Button):
	_play_ui_sound("ui_hover")
	_animate_button_scale(button, 1.05)

func _on_button_exit(button: Button):
	_animate_button_scale(button, 1.0)

func _on_button_focus(button: Button):
	_play_ui_sound("ui_focus")
	_animate_button_scale(button, 1.05)

func _on_button_unfocus(button: Button):
	_animate_button_scale(button, 1.0)

func _animate_button_scale(button: Button, target_scale: float):
	"""Animate button scale smoothly"""
	if not button:
		return
	
	var tween = create_tween()
	if tween:
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(button, "scale", Vector2(target_scale, target_scale), 0.1)

func _play_ui_sound(sound_name: String):
	"""Play UI sound with fallback"""
	if has_node("/root/Audio") and get_node("/root/Audio").has_method("play_sfx"):
		get_node("/root/Audio").play_sfx(sound_name)

func get_menu_buttons() -> Array[Button]:
	"""Get array of menu buttons"""
	return menu_buttons

func is_active() -> bool:
	"""Check if results screen is currently active"""
	return is_menu_active
