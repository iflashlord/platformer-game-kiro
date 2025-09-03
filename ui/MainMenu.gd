extends CanvasLayer
class_name MainMenu

# Button references
@onready var play_button: Button = $UI/MainContainer/RightPanel/MenuContainer/ButtonContainer/PlayButton
@onready var continue_button: Button = $UI/MainContainer/RightPanel/MenuContainer/ButtonContainer/ContinueButton
@onready var level_select_button: Button = $UI/MainContainer/RightPanel/MenuContainer/ButtonContainer/LevelSelectButton
@onready var options_button: Button = $UI/MainContainer/RightPanel/MenuContainer/ButtonContainer/OptionsButton
@onready var credits_button: Button = $UI/MainContainer/RightPanel/MenuContainer/ButtonContainer/CreditsButton
@onready var quit_button: Button = $UI/MainContainer/RightPanel/MenuContainer/ButtonContainer/QuitButton

# UI elements
@onready var version_label: Label = $UI/BottomContainer/VersionLabel
@onready var web_info: Label = $UI/BottomContainer/WebInfo
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# State
var has_save_data: bool = false

func _ready():
	_setup_ui()
	_connect_signals()
	_setup_platform_specific()
	_check_save_data()
	_start_intro_animation()
	
	# Start menu music
	if Audio and Audio.has_method("play_music"):
		Audio.play_music("menu_theme")

func _setup_ui():
	# Set version from project settings
	if version_label:
		var version = ProjectSettings.get_setting("application/config/version", "1.0.0")
		version_label.text = "v" + version
	
	# Setup web-specific info
	if web_info:
		if OS.get_name() == "Web":
			web_info.text = "Web Build - Use WASD/Arrow Keys + Space to Jump, F to Flip Dimensions"
		else:
			web_info.text = "Desktop Build - Use WASD/Arrow Keys + Space to Jump, F to Flip Dimensions"

func _connect_signals():
	# Connect all button signals safely
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if level_select_button:
		level_select_button.pressed.connect(_on_level_select_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
	if credits_button:
		credits_button.pressed.connect(_on_credits_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Setup basic button effects (without MenuNavigationHelper for now)
	_setup_button_effects()

func _setup_platform_specific():
	# Hide quit button on web platforms
	if OS.get_name() == "Web":
		quit_button.visible = false
	
	# Setup touch controls hint for mobile
	if OS.has_feature("mobile"):
		web_info.text = "Touch controls available - Tap to jump, swipe to move"

func _check_save_data():
	# Check if player has save data to show continue button
	has_save_data = false
	
	# Safely check for save data
	if Persistence and Persistence.has_method("has_save_data"):
		has_save_data = Persistence.has_save_data()
	
	# Update button text and visibility based on save data
	if play_button:
		if has_save_data:
			play_button.text = "  Continue"
		else:
			play_button.text = "  Play"
	
	# Hide the separate continue button since we're using the play button for both
	if continue_button:
		continue_button.visible = false
		
	# Focus the play button
	if play_button:
		play_button.grab_focus()

func _start_intro_animation():
	if animation_player and animation_player.has_animation("fade_in"):
		animation_player.play("fade_in")

func _get_all_buttons() -> Array[Button]:
	return [
		play_button,
		continue_button,
		level_select_button,
		options_button,
		credits_button,
		quit_button
	]

func _get_visible_buttons() -> Array[Button]:
	var visible_buttons: Array[Button] = []
	for button in _get_all_buttons():
		if button and button.visible:
			visible_buttons.append(button)
	return visible_buttons

func _validate_button_references():
	"""Validate that all button references are properly set"""
	if ErrorHandler and OS.is_debug_build():
		ErrorHandler.debug("Validating MainMenu button references", "MainMenu")
		var validation_results = {
			"play_button": play_button != null,
			"continue_button": continue_button != null,
			"level_select_button": level_select_button != null,
			"options_button": options_button != null,
			"credits_button": credits_button != null,
			"quit_button": quit_button != null,
			"version_label": version_label != null,
			"web_info": web_info != null,
			"animation_player": animation_player != null
		}
		
		for key in validation_results:
			if not validation_results[key]:
				ErrorHandler.warning("Missing UI element: " + key, "MainMenu")

# Button callbacks
func _on_play_pressed():
	_play_button_sound()
	_trigger_glitch_transition()
	
	# If player has save data, continue from where they left off
	if has_save_data:
		var target_scene = "res://levels/Level00.tscn"
		
		if Persistence and Persistence.has_method("get_next_recommended_level"):
			target_scene = Persistence.get_next_recommended_level()
		
		await get_tree().create_timer(0.3).timeout  # Wait for glitch effect
		_transition_to_scene(target_scene, "Continuing your adventure...")
	else:
		# New player, start from tutorial
		await get_tree().create_timer(0.3).timeout  # Wait for glitch effect
		_transition_to_scene("res://levels/Level00.tscn", "Starting new game...")

func _on_continue_pressed():
	_play_button_sound()
	_trigger_glitch_transition()
	
	var target_scene = "res://levels/Level00.tscn"
	
	if Persistence and Persistence.has_method("get_last_level"):
		var last_level = Persistence.get_last_level()
		if last_level and FileAccess.file_exists(last_level):
			target_scene = last_level
	
	await get_tree().create_timer(0.3).timeout  # Wait for glitch effect
	_transition_to_scene(target_scene, "Continuing game...")

func _on_level_select_pressed():
	_play_button_sound()
	_trigger_glitch_transition()
	await get_tree().create_timer(0.3).timeout  # Wait for glitch effect
	_transition_to_scene("res://ui/LevelMapPro.tscn", "Opening level select...")

func _on_options_pressed():
	_play_button_sound()
	_trigger_glitch_transition()
	await get_tree().create_timer(0.3).timeout  # Wait for glitch effect
	_transition_to_scene("res://ui/SettingsMenuStandalone.tscn", "Opening settings...")

func _on_credits_pressed():
	_play_button_sound()
	_trigger_glitch_transition()
	
	# Check if credits screen exists
	if FileAccess.file_exists("res://ui/CreditsMenu.tscn"):
		await get_tree().create_timer(0.3).timeout  # Wait for glitch effect
		_transition_to_scene("res://ui/CreditsMenu.tscn", "Loading credits...")
	else:
		_show_coming_soon("Credits screen coming soon!")

func _on_quit_pressed():
	_play_button_sound()
	get_tree().quit()

# Helper functions
func _transition_to_scene(scene_path: String, message: String = ""):
	print("🎬 Attempting to load scene: ", scene_path)
	
	# Enhanced export-compatible scene loading
	var scene_resource = load(scene_path)
	if not scene_resource:
		print("❌ Failed to load scene resource: ", scene_path)
		_show_error("Scene not found: " + scene_path.get_file())
		return
	
	print("✅ Scene resource loaded successfully")
	
	var result = get_tree().change_scene_to_packed(scene_resource)
	if result != OK:
		print("❌ Failed to change scene, error code: ", result)
		# Try fallback method
		result = get_tree().change_scene_to_file(scene_path)
		if result != OK:
			print("❌ Fallback scene change also failed, error code: ", result)
			_show_error("Failed to load " + scene_path.get_file())
		else:
			print("✅ Fallback scene change succeeded")
	else:
		print("✅ Scene change succeeded")

func _play_button_sound():
	_play_ui_sound("ui_select")

func _trigger_glitch_transition():
	"""Trigger dimension glitch effect for menu transitions"""
	if DimensionManager and DimensionManager.has_method("trigger_menu_glitch_effect"):
		DimensionManager.trigger_menu_glitch_effect()
		print("🌀 Triggered glitch transition effect")
	else:
		print("⚠️ DimensionManager not available for glitch effect")

func _setup_button_effects():
	"""Setup basic button hover and focus effects"""
	var buttons = _get_all_buttons()
	
	for button in buttons:
		if not button:
			continue
			
		# Add hover effects
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_exit.bind(button))
		
		# Add focus effects  
		button.focus_entered.connect(_on_button_focus.bind(button))
		button.focus_exited.connect(_on_button_unfocus.bind(button))

func _on_button_hover(button: Button):
	if not button.has_focus():  # Only apply hover if not focused
		_play_ui_sound("ui_hover")
		_animate_button_selection(button, true)

func _on_button_exit(button: Button):
	if not button.has_focus():  # Only reset if not focused
		_animate_button_selection(button, false)

func _on_button_focus(button: Button):
	_play_ui_sound("ui_focus")
	_animate_button_selection(button, true)

func _on_button_unfocus(button: Button):
	_animate_button_selection(button, false)

func _play_ui_sound(sound_name: String):
	"""Play UI sound with fallback"""
	if not Audio or not Audio.has_method("play_sfx"):
		return
	
	# Try to play the specific sound, fallback to ui_select if not found
	if Audio.has_method("has_sfx") and not Audio.has_sfx(sound_name):
		Audio.play_sfx("ui_select")
	else:
		Audio.play_sfx(sound_name)

func _animate_button_selection(button: Button, selected: bool):
	"""Animate button selection with enhanced visual effects"""
	if not button:
		return
	
	var tween = create_tween()
	if tween:
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		
		if selected:
			# Make selected button much more obvious
			tween.parallel().tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)
			tween.parallel().tween_property(button, "modulate", Color(1.3, 1.3, 1.0), 0.2)  # Bright yellow tint
			
			# Add subtle glow effect with border
			var style_box = StyleBoxFlat.new()
			style_box.bg_color = Color(0.2, 0.4, 0.8, 0.3)  # Semi-transparent blue
			style_box.border_width_left = 3
			style_box.border_width_right = 3
			style_box.border_width_top = 3
			style_box.border_width_bottom = 3
			style_box.border_color = Color(0.4, 0.8, 1.0, 0.8)  # Bright cyan border
			style_box.corner_radius_top_left = 8
			style_box.corner_radius_top_right = 8
			style_box.corner_radius_bottom_left = 8
			style_box.corner_radius_bottom_right = 8
			button.add_theme_stylebox_override("focus", style_box)
		else:
			# Reset to normal appearance
			tween.parallel().tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)
			tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.15)
			
			# Remove custom focus style
			button.remove_theme_stylebox_override("focus")

func _show_error(message: String):
	# Could show an error popup here
	push_error("MainMenu: " + message)

func _show_coming_soon(message: String):
	# Could show a coming soon popup here
	pass

# Input handling
func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		if OS.get_name() != "Web":
			_on_quit_pressed()
	elif Input.is_action_just_pressed("ui_accept"):
		# Trigger focused button
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button:
			focused.pressed.emit()
	elif Input.is_action_just_pressed("pause"):
		_on_options_pressed()
