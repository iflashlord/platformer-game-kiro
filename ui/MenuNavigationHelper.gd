extends Node
class_name MenuNavigationHelper

# Helper class for improved menu navigation and accessibility

static func setup_button_navigation(buttons: Array[Button]):
	"""Setup keyboard navigation between buttons"""
	if buttons.is_empty():
		return
	
	for i in range(buttons.size()):
		var current_button = buttons[i]
		var next_button = buttons[(i + 1) % buttons.size()]
		var prev_button = buttons[(i - 1 + buttons.size()) % buttons.size()]
		
		# Set up focus neighbors
		current_button.focus_neighbor_bottom = next_button.get_path()
		current_button.focus_neighbor_top = prev_button.get_path()
		current_button.focus_next = next_button.get_path()
		current_button.focus_previous = prev_button.get_path()

static func add_button_effects(button: Button, audio_manager = null):
	"""Add hover and click effects to a button"""
	if not button:
		return
	
	# Add hover effect
	button.mouse_entered.connect(func():
		if audio_manager and audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("ui_hover")
		_animate_button_scale(button, 1.05)
	)
	
	button.mouse_exited.connect(func():
		_animate_button_scale(button, 1.0)
	)
	
	# Add focus effects
	button.focus_entered.connect(func():
		if audio_manager and audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("ui_focus")
		_animate_button_scale(button, 1.05)
	)
	
	button.focus_exited.connect(func():
		_animate_button_scale(button, 1.0)
	)
	
	# Add press effect
	button.button_down.connect(func():
		_animate_button_scale(button, 0.95)
	)
	
	button.button_up.connect(func():
		_animate_button_scale(button, 1.05)
	)

static func _animate_button_scale(button: Button, target_scale: float):
	"""Animate button scale smoothly"""
	if not button:
		return
	
	var tween = button.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2(target_scale, target_scale), 0.1)

static func setup_responsive_layout(container: Control, min_width: int = 800):
	"""Setup responsive layout for different screen sizes"""
	if not container:
		return
	
	var viewport = container.get_viewport()
	if not viewport:
		return
	
	var screen_size = viewport.get_visible_rect().size
	
	# Adjust layout based on screen width
	if screen_size.x < min_width:
		# Mobile/narrow layout
		if container.has_method("set_columns") and container.columns > 1:
			container.columns = 1
	else:
		# Desktop layout
		if container.has_method("set_columns") and container.columns == 1:
			container.columns = 2