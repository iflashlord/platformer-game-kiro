extends Node

signal layer_changed(new_layer: String)

var current_layer: String = "A"
var layer_objects: Dictionary = {}

# Cooldown system for dimension switching
var switch_cooldown: float = 0.0
var switch_cooldown_time: float = 3.0 # 3 seconds cooldown
var is_switching: bool = false

# Glitch effect state
var _glitch_active: bool = false

func _ready():
	# Make this a singleton-like autoload
	add_to_group("dimension_managers")
	print("🌀 DimensionManager initialized - Current layer: ", current_layer)

func _process(delta):
	# Update cooldown timer
	if switch_cooldown > 0:
		switch_cooldown -= delta

func set_layer(new_layer: String):
	if new_layer == current_layer:
		return
	
	# Check cooldown - prevent switching if still in cooldown
	if switch_cooldown > 0:
		print("🌀 Dimension switch blocked - cooldown active: ", switch_cooldown, "s remaining")
		return
	
	# Check if already switching (prevent rapid switching during effect)
	if is_switching:
		print("🌀 Dimension switch blocked - already switching")
		return
	
	var old_layer = current_layer
	current_layer = new_layer
	is_switching = true
	
	print("🌀 Switching from layer ", old_layer, " to ", new_layer)
	
	# Start glitch effect BEFORE switching
	_trigger_dimension_glitch_effect()
	
	# Audio feedback
	if Audio:
		Audio.play_sfx("dimension")

	# Wait for glitch effect, then complete the switch
	await get_tree().create_timer(0.5).timeout # Brief delay for glitch effect
	
	
	# Update all registered layer objects
	_update_layer_objects()
	
	# Emit signal for other systems
	layer_changed.emit(new_layer)
	
	# Set cooldown and reset switching flag
	switch_cooldown = switch_cooldown_time
	is_switching = false
	
	print("🌀 Dimension switch completed - cooldown active for ", switch_cooldown_time, " seconds")

func get_current_layer() -> String:
	return current_layer

func register_layer_object(obj: Node, layer: String):
	"""Register an object to be shown/hidden based on layer"""
	if not layer_objects.has(layer):
		layer_objects[layer] = []
	
	layer_objects[layer].append(obj)
	
	# Set initial visibility
	var should_be_visible = (layer == current_layer)
	_set_object_visibility(obj, should_be_visible)
	
	print("🌀 Registered object ", obj.name, " to layer ", layer, " (visible: ", should_be_visible, ")")

func unregister_layer_object(obj: Node, layer: String):
	"""Remove an object from layer management"""
	if layer_objects.has(layer):
		layer_objects[layer].erase(obj)

func _update_layer_objects():
	"""Update visibility of all layer objects"""
	print("🌀 Updating layer objects for layer: ", current_layer)
	
	for layer in layer_objects.keys():
		var objects = layer_objects[layer]
		var should_be_visible = (layer == current_layer)
		
		print("🌀 Layer ", layer, " objects: ", objects.size(), " (should be visible: ", should_be_visible, ")")
		
		for obj in objects:
			if is_instance_valid(obj):
				_set_object_visibility(obj, should_be_visible)
				print("  - ", obj.name, " visibility set to: ", should_be_visible)
			else:
				# Clean up invalid objects
				objects.erase(obj)
				print("  - Removed invalid object from layer ", layer)

# Utility functions
func is_layer_active(layer: String) -> bool:
	return current_layer == layer

func toggle_layer():
	var new_layer = "B" if current_layer == "A" else "A"
	set_layer(new_layer)

func can_switch_dimension() -> bool:
	"""Check if dimension switching is currently allowed"""
	return switch_cooldown <= 0 and not is_switching

func get_switch_cooldown() -> float:
	"""Get remaining cooldown time"""
	return switch_cooldown

func get_inactive_layer() -> String:
	return "B" if current_layer == "A" else "A"

func reset_to_layer_a():
	"""Reset dimension to layer A - called when level starts/restarts"""
	print("🌀 Resetting dimension to layer A")
	current_layer = "A"
	switch_cooldown = 0.0
	is_switching = false
	_glitch_active = false
	
	# Update all objects to show layer A
	_update_all_objects()
	
	# Emit signal to notify other systems
	layer_changed.emit("A")

func _update_all_objects():
	"""Update visibility of all registered objects based on current layer"""
	for layer in layer_objects:
		for obj in layer_objects[layer]:
			if obj and is_instance_valid(obj):
				var should_be_visible = (layer == current_layer)
				_set_object_visibility(obj, should_be_visible)

func _set_object_visibility(obj: Node, visible: bool):
	"""Set visibility for an object, handling different node types"""
	if obj is DimensionNode:
		# DimensionNode handles its own visibility logic
		obj.set_layer_active(visible)
	elif obj.has_method("set") and "visible" in obj:
		# Standard CanvasItem nodes
		obj.visible = visible
	elif obj is CanvasItem:
		# Direct CanvasItem check
		obj.visible = visible
	elif obj is Node2D:
		# Node2D nodes also have visibility
		obj.visible = visible
	else:
		# For other node types, we can't control visibility directly
		print("⚠️ Warning: Cannot set visibility for node type: ", obj.get_class())

func trigger_menu_glitch_effect():
	"""Public function to trigger glitch effect for menu transitions"""
	# Prevent multiple rapid triggers
	if _glitch_active:
		print("🌀 Glitch effect already active, skipping")
		return
	
	_glitch_active = true
	_trigger_dimension_glitch_effect()
	
	# Reset flag after effect duration
	get_tree().create_timer(0.5).timeout.connect(func(): _glitch_active = false)

func _trigger_dimension_glitch_effect():
	"""Create a glitch effect when switching dimensions"""
	print("✨ Triggering dimension glitch effect")
	
	# Screen shake for disorientation
	if FX:
		FX.screen_shake(0.4, 15.0)
	
	# Create a dedicated CanvasLayer for glitch effects
	var glitch_layer = _create_glitch_canvas_layer()
	
	# Create the main glitch overlay immediately
	_create_main_glitch_overlay(glitch_layer)
	
	# Create multiple rapid flashes with different colors to simulate glitch
	var glitch_colors = [
		Color(0.8, 0.2, 1.0, 0.9), # Purple - increased alpha
		Color(0.0, 1.0, 1.0, 0.7), # Cyan - increased alpha
		Color(1.0, 0.2, 0.5, 0.8), # Magenta - increased alpha
		Color(0.2, 1.0, 0.2, 0.6), # Green - increased alpha
	]
	
	# Create rapid succession of colored flashes
	for i in range(glitch_colors.size()):
		var delay = i * 0.03 # Faster flashes
		get_tree().create_timer(delay).timeout.connect(
			func(): _create_glitch_flash(glitch_colors[i % glitch_colors.size()], glitch_layer)
		)
	
	# Add scanline effect
	get_tree().create_timer(0.05).timeout.connect(func(): _create_scanline_effect(glitch_layer))
	
	# Add static noise overlay
	get_tree().create_timer(0.02).timeout.connect(func(): _create_static_noise_effect(glitch_layer))
	
	# Add chromatic aberration effect
	get_tree().create_timer(0.08).timeout.connect(func(): _create_chromatic_aberration_effect(glitch_layer))
	
	# TIME TRAVEL EFFECTS - Add these new temporal effects
	# Temporal spiral vortex effect
	get_tree().create_timer(0.01).timeout.connect(func(): _create_temporal_spiral_effect(glitch_layer))
	
	# Clock/time ripple effect
	get_tree().create_timer(0.04).timeout.connect(func(): _create_noise_rect_effect(glitch_layer))
	
	# Reality distortion waves
	get_tree().create_timer(0.06).timeout.connect(func(): _create_reality_distortion_effect(glitch_layer))
	
	# Temporal echo/afterimage effect
	get_tree().create_timer(0.03).timeout.connect(func(): _create_temporal_echo_effect(glitch_layer))
	
	# Time fracture lines
	get_tree().create_timer(0.07).timeout.connect(func(): _create_time_fracture_effect(glitch_layer))
	
	# Clean up the glitch layer after all effects are done (extended time for new effects)
	get_tree().create_timer(0.8).timeout.connect(func():
		if is_instance_valid(glitch_layer):
			glitch_layer.queue_free()
	)

func _create_glitch_canvas_layer() -> CanvasLayer:
	"""Create a dedicated CanvasLayer for glitch effects that's guaranteed to be on top"""
	var glitch_layer = CanvasLayer.new()
	glitch_layer.layer = 1000 # Very high layer to ensure it's on top
	glitch_layer.name = "GlitchEffectLayer"
	
	# Add to the scene tree root to ensure it covers everything
	get_tree().root.add_child(glitch_layer)
	
	return glitch_layer

func _create_glitch_flash(color: Color, glitch_layer: CanvasLayer):
	"""Create a single glitch flash with the given color"""
	# Try FX system first, but also create our own overlay as backup
	if FX:
		FX.flash_screen(color, 0.08, color.a)
	
	# Create our own flash overlay for guaranteed visibility
	var flash_overlay = ColorRect.new()
	flash_overlay.color = color
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Get viewport size to cover entire screen
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	
	glitch_layer.add_child(flash_overlay)
	flash_overlay.size = screen_size
	flash_overlay.position = Vector2.ZERO
	
	# Quick flash animation
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.08)
	tween.tween_callback(func():
		if is_instance_valid(flash_overlay):
			flash_overlay.queue_free()
	)

func _create_scanline_effect(glitch_layer: CanvasLayer):
	"""Create horizontal scanline effect across the screen"""
	var scanlines = ColorRect.new()
	scanlines.color = Color(0.0, 1.0, 1.0, 0.5) # More visible cyan scanlines
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Get viewport size to cover entire screen
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	
	glitch_layer.add_child(scanlines)
	scanlines.size = screen_size
	scanlines.position = Vector2.ZERO
	
	# Create moving scanline pattern with more dramatic effect
	var tween = create_tween()
	for i in range(8): # More flickers
		var alpha = 0.7 if i % 2 == 0 else 0.2
		var color_shift = Color(randf_range(0.0, 0.3), 1.0, randf_range(0.8, 1.0), alpha)
		tween.tween_property(scanlines, "color", color_shift, 0.02)
	
	tween.tween_property(scanlines, "modulate:a", 0.0, 0.08)
	tween.tween_callback(scanlines.queue_free)

func _create_static_noise_effect(glitch_layer: CanvasLayer):
	"""Create static noise overlay effect"""
	var noise_overlay = ColorRect.new()
	noise_overlay.color = Color(1.0, 1.0, 1.0, 0.4) # More visible
	noise_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Get viewport size to cover entire screen
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	
	glitch_layer.add_child(noise_overlay)
	noise_overlay.size = screen_size
	noise_overlay.position = Vector2.ZERO
	
	# Create rapid flickering noise effect with more intensity
	var tween = create_tween()
	for i in range(15): # More flickers
		var noise_alpha = randf_range(0.2, 0.6)
		var noise_color = Color(randf(), randf(), randf(), noise_alpha)
		tween.tween_property(noise_overlay, "color", noise_color, 0.015)
	
	tween.tween_property(noise_overlay, "modulate:a", 0.0, 0.06)
	tween.tween_callback(noise_overlay.queue_free)

func _create_main_glitch_overlay(glitch_layer: CanvasLayer):
	"""Create the main glitch overlay that encompasses the entire effect"""
	var main_overlay = ColorRect.new()
	main_overlay.color = Color(0.5, 0.0, 1.0, 0.3) # Purple base
	main_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Get viewport size to cover entire screen
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	
	glitch_layer.add_child(main_overlay)
	main_overlay.size = screen_size
	main_overlay.position = Vector2.ZERO
	
	# Create pulsing effect
	var tween = create_tween()
	tween.set_loops(4)
	tween.tween_property(main_overlay, "modulate:a", 0.8, 0.06)
	tween.tween_property(main_overlay, "modulate:a", 0.2, 0.06)
	tween.tween_callback(func():
		if is_instance_valid(main_overlay):
			main_overlay.queue_free()
	)

func _create_chromatic_aberration_effect(glitch_layer: CanvasLayer):
	"""Create chromatic aberration effect by offsetting RGB channels"""
	var red_overlay = ColorRect.new()
	var blue_overlay = ColorRect.new()
	
	red_overlay.color = Color(1.0, 0.0, 0.0, 0.4)
	blue_overlay.color = Color(0.0, 0.0, 1.0, 0.4)
	
	red_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blue_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Get viewport size to cover entire screen
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	
	glitch_layer.add_child(red_overlay)
	glitch_layer.add_child(blue_overlay)
	
	red_overlay.size = screen_size
	blue_overlay.size = screen_size
	
	# Offset the channels slightly for chromatic aberration
	red_overlay.position = Vector2(5, 0)
	blue_overlay.position = Vector2(-5, 0)
	
	# Animate the aberration
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Red channel animation
	tween.tween_property(red_overlay, "position:x", 8, 0.1)
	tween.tween_property(red_overlay, "modulate:a", 0.0, 0.15)
	
	# Blue channel animation  
	tween.tween_property(blue_overlay, "position:x", -8, 0.1)
	tween.tween_property(blue_overlay, "modulate:a", 0.0, 0.15)
	
	tween.tween_callback(func():
		red_overlay.queue_free()
		blue_overlay.queue_free()
	)

# ===== TIME TRAVEL EFFECTS =====

func _create_temporal_spiral_effect(glitch_layer: CanvasLayer):
	"""Create a spiral vortex effect like traveling through a time tunnel"""
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	var center = screen_size / 2
	
	# Create multiple spiral rings
	for ring in range(5):
		var spiral_overlay = ColorRect.new()
		var ring_color = Color(0.4 + ring * 0.1, 0.8 - ring * 0.1, 1.0, 0.3)
		spiral_overlay.color = ring_color
		spiral_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		glitch_layer.add_child(spiral_overlay)
		
		# Start as a small circle in center, expand outward
		var ring_size = 50 + ring * 30
		spiral_overlay.size = Vector2(ring_size, ring_size)
		spiral_overlay.position = center - spiral_overlay.size / 2
		
		# Make it circular by using a custom draw (approximated with rotation)
		spiral_overlay.rotation = ring * PI / 3
		
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Expand the ring outward and center it properly
		var final_size_val = screen_size.length() + ring * 100
		var final_size = Vector2(final_size_val, final_size_val)
		
		# Use a custom positioning function that captures the overlay reference properly
		_animate_spiral_expansion(spiral_overlay, center, final_size, tween)
		
		# Rotate the spiral
		tween.tween_property(spiral_overlay, "rotation", spiral_overlay.rotation + PI * 2, 0.4)
		
		# Fade out
		tween.tween_property(spiral_overlay, "modulate:a", 0.0, 0.4)
		tween.tween_callback(spiral_overlay.queue_free)

func _animate_spiral_expansion(overlay: ColorRect, center: Vector2, final_size: Vector2, tween: Tween):
	"""Helper function to animate spiral expansion with proper positioning"""
	# Animate size
	tween.tween_property(overlay, "size", final_size, 0.4)
	
	# Animate position to keep centered - use a more reliable approach
	var initial_pos = overlay.position
	var final_pos = center - final_size / 2
	tween.tween_property(overlay, "position", final_pos, 0.4)

func _create_noise_rect_effect(glitch_layer: CanvasLayer):
	"""Create concentric ripples like time waves emanating from center"""
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	var center = screen_size / 2
	  
	# Add small random glitch rects around the screen
	for i in range(12):
		var glitch_rect = ColorRect.new()
		var glitch_color = Color(randf_range(0.7, 1.0), randf_range(0.7, 1.0), 1.0, randf_range(0.3, 0.7))
		glitch_rect.color = glitch_color
		glitch_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rect_size = Vector2(randf_range(3, 10), randf_range(2, 8))
		glitch_rect.size = rect_size
		var rand_x = randf_range(0, screen_size.x - rect_size.x)
		var rand_y = randf_range(0, screen_size.y - rect_size.y)
		glitch_rect.position = Vector2(rand_x, rand_y)
		glitch_layer.add_child(glitch_rect)
		var glitch_tween = create_tween()
		glitch_tween.tween_property(glitch_rect, "modulate:a", 0.0, randf_range(0.15, 0.28))
		glitch_tween.tween_callback(glitch_rect.queue_free)

func _create_reality_distortion_effect(glitch_layer: CanvasLayer):
	"""Create reality-bending wave distortions across the screen"""
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	
	# Create horizontal distortion waves
	for wave in range(3):
		var distortion_overlay = ColorRect.new()
		var wave_color = Color(1.0, 0.3, 0.8, 0.4) # Magenta reality distortion
		distortion_overlay.color = wave_color
		distortion_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		glitch_layer.add_child(distortion_overlay)
		
		# Start as a thin horizontal line
		distortion_overlay.size = Vector2(screen_size.x, 10)
		distortion_overlay.position = Vector2(0, screen_size.y * (0.2 + wave * 0.3))
		
		# Safety check before animating
		if not is_instance_valid(distortion_overlay):
			continue
		
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Expand vertically while moving
		tween.tween_property(distortion_overlay, "size:y", 80, 0.2)
		tween.tween_property(distortion_overlay, "position:y", distortion_overlay.position.y - 40, 0.2)
		
		# Wave motion - move across screen
		tween.tween_property(distortion_overlay, "position:x", -screen_size.x * 0.2, 0.25)
		
		# Fade and distort (using scale instead of skew for compatibility)
		tween.tween_property(distortion_overlay, "modulate:a", 0.0, 0.25)
		tween.tween_property(distortion_overlay, "scale", Vector2(1.2, 0.8), 0.15)
		
		# Safe cleanup with validity check
		tween.tween_callback(func():
			if is_instance_valid(distortion_overlay):
				distortion_overlay.queue_free()
		)

func _create_temporal_echo_effect(glitch_layer: CanvasLayer):
	"""Create afterimage/echo effects like time is stuttering"""
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	
	# Create multiple echo layers with different colors and positions
	var echo_colors = [
		Color(1.0, 1.0, 0.0, 0.3), # Yellow past
		Color(0.0, 1.0, 0.5, 0.3), # Green present
		Color(0.5, 0.0, 1.0, 0.3), # Purple future
	]
	
	for i in range(echo_colors.size()):
		var echo_overlay = ColorRect.new()
		echo_overlay.color = echo_colors[i]
		echo_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		glitch_layer.add_child(echo_overlay)
		echo_overlay.size = screen_size
		
		# Offset each echo slightly
		var offset = Vector2(i * 8 - 8, i * 4 - 4)
		echo_overlay.position = offset
		
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Create stuttering motion
		for stutter in range(4):
			var stutter_delay = stutter * 0.03
			var stutter_offset = Vector2(randf_range(-5, 5), randf_range(-3, 3))
			tween.tween_property(echo_overlay, "position", offset + stutter_offset, 0.02)
			tween.tween_property(echo_overlay, "position", offset, 0.02)
		
		# Fade out
		tween.tween_property(echo_overlay, "modulate:a", 0.0, 0.2)
		tween.tween_callback(echo_overlay.queue_free)

func _create_time_fracture_effect(glitch_layer: CanvasLayer):
	"""Create fracture lines across reality like time is cracking"""
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	
	# Create multiple fracture lines
	for fracture in range(6):
		var fracture_line = ColorRect.new()
		var fracture_color = Color(1.0, 1.0, 1.0, 0.8) # Bright white cracks
		fracture_line.color = fracture_color
		fracture_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		glitch_layer.add_child(fracture_line)
		
		# Random fracture line properties
		var is_vertical = fracture % 2 == 0
		var thickness = randf_range(2, 6)
		
		if is_vertical:
			fracture_line.size = Vector2(thickness, screen_size.y)
			fracture_line.position = Vector2(randf_range(0, screen_size.x), 0)
			fracture_line.rotation = randf_range(-0.2, 0.2) # Slight angle
		else:
			fracture_line.size = Vector2(screen_size.x, thickness)
			fracture_line.position = Vector2(0, randf_range(0, screen_size.y))
			fracture_line.rotation = randf_range(-0.1, 0.1)
		
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Fracture appears suddenly then fades
		tween.tween_property(fracture_line, "modulate:a", 0.0, 0.15)
		
		# Add crackling motion using tween chains
		var crack_tween = create_tween()
		for crack in range(3):
			var crack_delay = crack * 0.02
			var crack_intensity = randf_range(0.5, 1.0)
			crack_tween.tween_interval(crack_delay)
			crack_tween.tween_property(fracture_line, "modulate:a", crack_intensity, 0.01)
			crack_tween.tween_property(fracture_line, "modulate:a", 0.2, 0.01)
		
		# Clean up after all animations
		crack_tween.tween_callback(fracture_line.queue_free)
