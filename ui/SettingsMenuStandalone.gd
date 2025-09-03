extends CanvasLayer

@onready var master_slider: HSlider = $UI/MainContainer/SettingsContainer/MasterVolume/Slider
@onready var music_slider: HSlider = $UI/MainContainer/SettingsContainer/MusicVolume/Slider
@onready var sfx_slider: HSlider = $UI/MainContainer/SettingsContainer/SFXVolume/Slider
@onready var master_label: Label = $UI/MainContainer/SettingsContainer/MasterVolume/ValueLabel
@onready var music_label: Label = $UI/MainContainer/SettingsContainer/MusicVolume/ValueLabel
@onready var sfx_label: Label = $UI/MainContainer/SettingsContainer/SFXVolume/ValueLabel
@onready var test_sfx_button: Button = $UI/MainContainer/SettingsContainer/ButtonContainer/TestSFX
@onready var reset_progress_button: Button = $UI/MainContainer/SettingsContainer/ButtonContainer/ResetProgress
@onready var back_button: Button = $UI/MainContainer/BackButton

func _ready():
	# Connect slider signals
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Connect button signals
	test_sfx_button.pressed.connect(_on_test_sfx_pressed)
	reset_progress_button.pressed.connect(_on_reset_everything_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Setup keyboard navigation
	_setup_keyboard_navigation()
	
	# Setup enhanced button effects
	_setup_button_effects()
	
	# Load current settings
	_load_settings()
	
	# Focus first interactive element
	master_slider.grab_focus()

func _load_settings():
	"""Load current settings and update UI"""
	if Audio:
		# Safely get volume values with fallbacks
		master_slider.value = Audio.get_master_volume() if Audio.has_method("get_master_volume") else Audio.master_volume if "master_volume" in Audio else 1.0
		music_slider.value = Audio.get_music_volume() if Audio.has_method("get_music_volume") else Audio.music_volume if "music_volume" in Audio else 0.8
		sfx_slider.value = Audio.get_sfx_volume() if Audio.has_method("get_sfx_volume") else Audio.sfx_volume if "sfx_volume" in Audio else 1.0
		_update_labels()
	else:
		# Set defaults if no Audio system
		master_slider.value = 1.0
		music_slider.value = 0.8
		sfx_slider.value = 1.0
		_update_labels()

func _update_labels():
	"""Update volume percentage labels"""
	master_label.text = str(int(master_slider.value * 100)) + "%"
	music_label.text = str(int(music_slider.value * 100)) + "%"
	sfx_label.text = str(int(sfx_slider.value * 100)) + "%"

func _on_master_volume_changed(value: float):
	"""Handle master volume change"""
	if Audio and Audio.has_method("set_master_volume"):
		Audio.set_master_volume(value)
	_update_labels()

func _on_music_volume_changed(value: float):
	"""Handle music volume change"""
	if Audio and Audio.has_method("set_music_volume"):
		Audio.set_music_volume(value)
	_update_labels()

func _on_sfx_volume_changed(value: float):
	"""Handle SFX volume change"""
	if Audio and Audio.has_method("set_sfx_volume"):
		Audio.set_sfx_volume(value)
	_update_labels()

func _on_test_sfx_pressed():
	"""Test SFX volume with sample sound"""
	if Audio and Audio.has_method("play_sfx"):
		Audio.play_sfx("ui_select")
	else:
		print("🔊 Audio system not available for testing")

func _on_reset_everything_pressed():
	"""Show simple reset confirmation"""
	var dialog = ConfirmationDialog.new()
	dialog.title = "Reset Everything"
	dialog.dialog_text = "Reset ALL data to defaults?\n\n• Audio volumes → Default\n• Level progress → Cleared\n• All unlocks → Cleared\n\nThis cannot be undone!"
	
	# Connect confirmation
	dialog.confirmed.connect(_reset_everything)
	
	# Style the dialog
	add_child(dialog)
	dialog.popup_centered()
	
	# Cleanup when done
	dialog.tree_exiting.connect(func(): dialog.queue_free())

func _reset_everything():
	"""Reset all game data and settings"""
	print("🔄 Resetting everything...")
	
	# Reset audio settings to defaults
	_reset_audio_settings()
	
	# Reset game progress
	_reset_game_progress()
	
	# Show success message
	_show_simple_success()

func _reset_audio_settings():
	"""Reset all audio settings to default"""
	if Audio and Audio.has_method("reset_to_defaults"):
		Audio.reset_to_defaults()
		print("🔊 Audio settings reset to defaults")
	elif Audio:
		# Manual reset if no reset method
		Audio.set_master_volume(1.0)
		Audio.set_music_volume(0.8)
		Audio.set_sfx_volume(1.0)
		print("🔊 Audio settings manually reset")
	
	# Update UI sliders
	_load_settings()

func _reset_game_progress():
	"""Reset all game progress data"""
	if Persistence:
		Persistence.reset_level_progress()
		Persistence.reset_profile()
		print("💾 Game progress reset")
	else:
		print("❌ Persistence system not available")

func _show_simple_success():
	"""Show simple success message"""
	var dialog = AcceptDialog.new()
	dialog.title = "Reset Complete"
	dialog.dialog_text = "Everything has been reset!\nRestart the game to see all changes."
	
	add_child(dialog)
	dialog.popup_centered()
	dialog.tree_exiting.connect(func(): dialog.queue_free())

func _on_back_pressed():
	"""Return to main menu with glitch effect"""
	_trigger_glitch_transition()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")

func _setup_keyboard_navigation():
	"""Setup proper keyboard navigation between UI elements"""
	# Create navigation chain: Master → Music → SFX → Test → Reset → Back → (wrap to Master)
	var ui_elements = [master_slider, music_slider, sfx_slider, test_sfx_button, reset_progress_button, back_button]
	
	# Set up navigation chain
	for i in range(ui_elements.size()):
		var current = ui_elements[i]
		var next = ui_elements[(i + 1) % ui_elements.size()]
		var prev = ui_elements[(i - 1 + ui_elements.size()) % ui_elements.size()]
		
		if current and next:
			current.focus_neighbor_bottom = current.get_path_to(next)
			current.focus_neighbor_right = current.get_path_to(next)
		if current and prev:
			current.focus_neighbor_top = current.get_path_to(prev)
			current.focus_neighbor_left = current.get_path_to(prev)
	
	print("⌨️ Keyboard navigation setup complete")

func _setup_button_effects():
	"""Setup enhanced visual effects for buttons only"""
	# Connect buttons only - no effects for sliders
	_connect_button_effects(test_sfx_button)
	_connect_button_effects(reset_progress_button) 
	_connect_button_effects(back_button)
	
	print("✨ Enhanced button effects setup complete")

func _connect_button_effects(button: Button):
	"""Connect hover and focus events to a button"""
	if not button:
		return
		
	button.mouse_entered.connect(_on_button_hover.bind(button))
	button.mouse_exited.connect(_on_button_exit.bind(button))
	button.focus_entered.connect(_on_button_focus.bind(button))
	button.focus_exited.connect(_on_button_unfocus.bind(button))



func _on_button_hover(button: Button):
	"""Handle button hover"""
	if not button.has_focus():
		_animate_button_selection(button, true, 1.15)

func _on_button_exit(button: Button):
	"""Handle button exit"""
	if not button.has_focus():
		_animate_button_selection(button, false, 1.15)

func _on_button_focus(button: Button):
	"""Handle button focus"""
	_animate_button_selection(button, true, 1.15)

func _on_button_unfocus(button: Button):
	"""Handle button unfocus"""
	_animate_button_selection(button, false, 1.15)



func _animate_button_selection(element: Control, selected: bool, scale_factor: float):
	"""Enhanced button/slider selection animation with glow and border effects"""
	if not element:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if selected:
		# Scale up with enhanced visuals
		tween.tween_property(element, "scale", Vector2.ONE * scale_factor, 0.15)
		tween.tween_property(element, "modulate", Color(1.2, 1.1, 0.8), 0.15)
		
		# Add golden glow effect by adjusting self_modulate
		element.self_modulate = Color(1.3, 1.2, 0.9, 1.0)
		
		# Create subtle border effect by adjusting the element's theme
		if element is Button:
			var style_box = element.get_theme_stylebox("normal").duplicate()
			if style_box is StyleBoxFlat:
				style_box.border_color = Color.CYAN
				style_box.border_width_left = 2
				style_box.border_width_top = 2
				style_box.border_width_right = 2
				style_box.border_width_bottom = 2
				element.add_theme_stylebox_override("normal", style_box)
	else:
		# Scale down and remove effects
		tween.tween_property(element, "scale", Vector2.ONE, 0.15)
		tween.tween_property(element, "modulate", Color.WHITE, 0.15)
		
		# Remove glow
		element.self_modulate = Color.WHITE
		
		# Remove border
		if element is Button:
			element.remove_theme_stylebox_override("normal")

func _trigger_glitch_transition():
	"""Trigger dimension glitch effect for menu transitions"""
	if DimensionManager and DimensionManager.has_method("trigger_menu_glitch_effect"):
		DimensionManager.trigger_menu_glitch_effect()
		print("🌀 Triggered glitch transition effect")
	else:
		print("⚠️ DimensionManager not available for glitch effect")

func _input(event):
	"""Handle input events for settings menu"""
	if not visible:
		return
		
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_accept"):
		# Activate focused element
		var focused = get_viewport().gui_get_focus_owner()
		if focused and focused is Button:
			focused.pressed.emit()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		# Let the focus system handle this naturally
		pass
