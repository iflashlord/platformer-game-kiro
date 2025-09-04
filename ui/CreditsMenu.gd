extends CanvasLayer
class_name CreditsMenu

@onready var back_button: Button = $UI/MainContainer/BackButton

func _ready():
	_setup_ui()
	_connect_signals()

func _setup_ui():
	back_button.grab_focus()
	_setup_button_effects()

func _connect_signals():
	back_button.pressed.connect(_on_back_pressed)

func _setup_button_effects():
	"""Setup enhanced button hover and focus effects"""
	if back_button:
		# Add hover effects
		back_button.mouse_entered.connect(_on_button_hover.bind(back_button))
		back_button.mouse_exited.connect(_on_button_exit.bind(back_button))
		
		# Add focus effects  
		back_button.focus_entered.connect(_on_button_focus.bind(back_button))
		back_button.focus_exited.connect(_on_button_unfocus.bind(back_button))

func _on_button_hover(button: Button):
	if not button.has_focus():  # Only apply hover if not focused
		if Audio: Audio.play_sfx("ui_hover")
		_animate_button_selection(button, true)

func _on_button_exit(button: Button):
	if not button.has_focus():  # Only reset if not focused
		_animate_button_selection(button, false)

func _on_button_focus(button: Button):
	if Audio: Audio.play_sfx("ui_focus")
	_animate_button_selection(button, true)

func _on_button_unfocus(button: Button):
	_animate_button_selection(button, false)

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
			tween.parallel().tween_property(button, "scale", Vector2(1.15, 1.15), 0.2)
			tween.parallel().tween_property(button, "modulate", Color(1.4, 1.2, 0.8), 0.2)  # Golden glow
			
			# Add glow border effect
			var style_box = StyleBoxFlat.new()
			style_box.bg_color = Color(0.3, 0.6, 1.0, 0.2)  # Blue glow background
			style_box.border_width_left = 4
			style_box.border_width_right = 4
			style_box.border_width_top = 4
			style_box.border_width_bottom = 4
			style_box.border_color = Color(0.5, 1.0, 1.0, 0.9)  # Bright cyan border
			style_box.corner_radius_top_left = 12
			style_box.corner_radius_top_right = 12
			style_box.corner_radius_bottom_left = 12
			style_box.corner_radius_bottom_right = 12
			button.add_theme_stylebox_override("focus", style_box)
		else:
			# Reset to normal appearance
			tween.parallel().tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)
			tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.15)
			
			# Remove custom focus style
			button.remove_theme_stylebox_override("focus")

func _on_back_pressed():
	"""Return to main menu with glitch effect"""
	if Audio:
		Audio.play_sfx("ui_select")
	_trigger_glitch_transition()
	await get_tree().create_timer(0.3).timeout
	_safe_scene_change("res://ui/MainMenu.tscn")

func _trigger_glitch_transition():
	"""Trigger dimension glitch effect for menu transitions"""
	if DimensionManager and DimensionManager.has_method("trigger_menu_glitch_effect"):
		DimensionManager.trigger_menu_glitch_effect()
		print("🌀 Triggered glitch transition effect")
	else:
		print("⚠️ DimensionManager not available for glitch effect")

func _safe_scene_change(scene_path: String):
	"""Standard scene loading - same as MainMenu approach"""
	print("🎬 Standard scene change to: ", scene_path)
	
	var result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		print("❌ Scene change failed, error code: ", result)
	else:
		print("✅ Scene change successful")

func _input(event):
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_down"):
		# Focus the back button when down arrow is pressed
		if back_button:
			back_button.grab_focus()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_up"):
		# Remove focus from button (go back to content scrolling)
		if back_button and back_button.has_focus():
			back_button.release_focus()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_accept"):
		# If back button has focus, activate it; otherwise focus it
		if back_button and back_button.has_focus():
			_on_back_pressed()
		elif back_button:
			back_button.grab_focus()
		get_viewport().set_input_as_handled()
