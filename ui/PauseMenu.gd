extends CanvasLayer
class_name PauseMenu

# Button references
@onready var resume_button: Button = $UI/MenuContainer/ButtonContainer/ResumeButton
@onready var restart_button: Button = $UI/MenuContainer/ButtonContainer/RestartButton
@onready var settings_button: Button = $UI/MenuContainer/ButtonContainer/SettingsButton
@onready var level_select_button: Button = $UI/MenuContainer/ButtonContainer/LevelSelectButton
@onready var main_menu_button: Button = $UI/MenuContainer/ButtonContainer/MainMenuButton
@onready var quit_button: Button = $UI/MenuContainer/ButtonContainer/QuitButton

# UI elements
@onready var level_info_label: Label = $UI/MenuContainer/Header/LevelInfo
@onready var time_label: Label = $UI/MenuContainer/Header/GameStats/TimeLabel
@onready var score_label: Label = $UI/MenuContainer/Header/GameStats/ScoreLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Signals
signal resume_requested
signal restart_requested
signal settings_requested
signal level_select_requested
signal main_menu_requested
signal quit_requested

# State
var is_menu_active: bool = false
var selected_button_index: int = 0
var menu_buttons: Array[Button] = []

func _ready():
	print("🎮 PauseMenu _ready() called")
	_setup_ui()
	_connect_signals()
	_setup_platform_specific()
	
	# Start hidden
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("✅ PauseMenu initialized")

func _setup_ui():
	"""Setup UI elements and button array"""
	# Setup button array for navigation
	menu_buttons = [
		resume_button,
		restart_button,
		settings_button,
		level_select_button,
		main_menu_button,
		quit_button
	]
	
	# Filter out null buttons
	menu_buttons = menu_buttons.filter(func(btn): return btn != null)
	
	# Setup proper keyboard navigation
	MenuNavigationHelper.setup_button_navigation(menu_buttons)
	
	# Setup button effects
	_setup_button_effects()

func _connect_signals():
	"""Connect all button signals and game events"""
	# Connect button signals safely
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if level_select_button:
		level_select_button.pressed.connect(_on_level_select_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect to game events
	if Game:
		if Game.has_signal("game_paused"):
			Game.game_paused.connect(_on_game_paused)
		if Game.has_signal("game_resumed"):
			Game.game_resumed.connect(_on_game_resumed)

func _setup_platform_specific():
	"""Setup platform-specific features"""
	# Hide quit button on web platforms
	if OS.get_name() == "Web" and quit_button:
		quit_button.visible = false
		# Remove from menu buttons array
		menu_buttons = menu_buttons.filter(func(btn): return btn != quit_button)
		# Re-setup navigation after removing button
		MenuNavigationHelper.setup_button_navigation(menu_buttons)

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
	elif Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_resume_pressed()

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
		if button and button.visible:
			button.grab_focus()

func _activate_selected_button():
	"""Activate the currently selected button"""
	if selected_button_index < menu_buttons.size():
		var button = menu_buttons[selected_button_index]
		if button:
			button.pressed.emit()

func show_pause_menu():
	"""Show the pause menu with animation"""
	print("🎮 Showing pause menu")
	
	visible = true
	is_menu_active = true
	selected_button_index = 0
	
	# Update game info
	_update_game_info()
	
	# Focus first button
	_update_button_focus()
	
	# Play entrance animation
	if animation_player and animation_player.has_animation("slide_in"):
		animation_player.play("slide_in")
	
	# Play sound
	_play_ui_sound("ui_pause")

func hide_pause_menu():
	"""Hide the pause menu"""
	print("🎮 Hiding pause menu")
	
	visible = false
	is_menu_active = false

func _update_game_info():
	"""Update displayed game information"""
	# Update level info
	if level_info_label and Game:
		var level_name = Game.current_level
		if level_name != "":
			if LevelLoader and LevelLoader.has_method("get_level_display_name"):
				level_name = LevelLoader.get_level_display_name(level_name)
			level_info_label.text = "Level: " + level_name
		else:
			level_info_label.text = "Level: Unknown"
	
	# Update time
	if time_label and GameTimer:
		if GameTimer.has_method("get_formatted_time"):
			time_label.text = "Time: " + GameTimer.get_formatted_time()
		else:
			time_label.text = "Time: --:--"
	
	# Update score
	if score_label and Game:
		score_label.text = "Score: " + str(Game.get_score())

# Button callbacks
func _on_resume_pressed():
	"""Resume the game"""
	_play_ui_sound("ui_select")
	hide_pause_menu()
	resume_requested.emit()

func _on_restart_pressed():
	"""Restart the current level"""
	_play_ui_sound("ui_select")
	
	# Show confirmation dialog for restart
	_show_restart_confirmation()

func _on_settings_pressed():
	"""Open settings menu"""
	_play_ui_sound("ui_select")
	settings_requested.emit()
	
	# For now, just show a message
	print("ℹ️ Settings menu not implemented yet")

func _on_level_select_pressed():
	"""Go to level select"""
	_play_ui_sound("ui_select")
	hide_pause_menu()
	level_select_requested.emit()

func _on_main_menu_pressed():
	"""Go to main menu"""
	_play_ui_sound("ui_select")
	hide_pause_menu()
	main_menu_requested.emit()

func _on_quit_pressed():
	"""Quit the game"""
	_play_ui_sound("ui_select")
	quit_requested.emit()

func _show_restart_confirmation():
	"""Show confirmation dialog for restart"""
	# For now, just restart immediately
	# TODO: Add proper confirmation dialog
	print("🔄 Restarting level...")
	hide_pause_menu()
	restart_requested.emit()

# Game event handlers
func _on_game_paused():
	"""Handle game pause event"""
	show_pause_menu()

func _on_game_resumed():
	"""Handle game resume event"""
	hide_pause_menu()

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
	if Audio and Audio.has_method("play_sfx"):
		Audio.play_sfx(sound_name)

func get_menu_buttons() -> Array[Button]:
	"""Get array of menu buttons"""
	return menu_buttons

func is_active() -> bool:
	"""Check if pause menu is currently active"""
	return is_menu_active

# Legacy compatibility
func _on_resume_button_pressed():
	_on_resume_pressed()

func _on_restart_button_pressed():
	_on_restart_pressed()

func _on_level_select_button_pressed():
	_on_level_select_pressed()

func _on_main_menu_button_pressed():
	_on_main_menu_pressed()
