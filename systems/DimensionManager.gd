extends Node

signal layer_changed(new_layer: String)

var current_layer: String = "A"
var layer_objects: Dictionary = {}

# Cooldown system for dimension switching
var switch_cooldown: float = 0.0
var switch_cooldown_time: float = 3.0  # 3 seconds cooldown
var is_switching: bool = false

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
	await get_tree().create_timer(0.5).timeout  # Brief delay for glitch effect
	
	
	
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

func _set_object_visibility(obj: Node, visible: bool):
	"""Set visibility for an object, handling different node types"""
	if obj is DimensionNode:
		# DimensionNode handles its own visibility logic
		obj.set_layer_active(visible)
	elif obj.has_property("visible"):
		# Standard CanvasItem nodes
		obj.visible = visible
	else:
		# For other node types, we can't control visibility directly
		print("⚠️ Warning: Cannot set visibility for node type: ", obj.get_class())

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
		Color(0.8, 0.2, 1.0, 0.9),  # Purple - increased alpha
		Color(0.0, 1.0, 1.0, 0.7),  # Cyan - increased alpha
		Color(1.0, 0.2, 0.5, 0.8),  # Magenta - increased alpha
		Color(0.2, 1.0, 0.2, 0.6),  # Green - increased alpha
	]
	
	# Create rapid succession of colored flashes
	for i in range(glitch_colors.size()):
		var delay = i * 0.03  # Faster flashes
		get_tree().create_timer(delay).timeout.connect(
			func(): _create_glitch_flash(glitch_colors[i % glitch_colors.size()], glitch_layer)
		)
	
	# Add scanline effect
	get_tree().create_timer(0.05).timeout.connect(func(): _create_scanline_effect(glitch_layer))
	
	# Add static noise overlay
	get_tree().create_timer(0.02).timeout.connect(func(): _create_static_noise_effect(glitch_layer))
	
	# Add chromatic aberration effect
	get_tree().create_timer(0.08).timeout.connect(func(): _create_chromatic_aberration_effect(glitch_layer))
	
	# Clean up the glitch layer after all effects are done
	get_tree().create_timer(0.6).timeout.connect(func(): 
		if is_instance_valid(glitch_layer):
			glitch_layer.queue_free()
	)

func _create_glitch_canvas_layer() -> CanvasLayer:
	"""Create a dedicated CanvasLayer for glitch effects that's guaranteed to be on top"""
	var glitch_layer = CanvasLayer.new()
	glitch_layer.layer = 1000  # Very high layer to ensure it's on top
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
	tween.tween_callback(flash_overlay.queue_free)

func _create_scanline_effect(glitch_layer: CanvasLayer):
	"""Create horizontal scanline effect across the screen"""
	var scanlines = ColorRect.new()
	scanlines.color = Color(0.0, 1.0, 1.0, 0.5)  # More visible cyan scanlines
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Get viewport size to cover entire screen
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	
	glitch_layer.add_child(scanlines)
	scanlines.size = screen_size
	scanlines.position = Vector2.ZERO
	
	# Create moving scanline pattern with more dramatic effect
	var tween = create_tween()
	for i in range(8):  # More flickers
		var alpha = 0.7 if i % 2 == 0 else 0.2
		var color_shift = Color(randf_range(0.0, 0.3), 1.0, randf_range(0.8, 1.0), alpha)
		tween.tween_property(scanlines, "color", color_shift, 0.02)
	
	tween.tween_property(scanlines, "modulate:a", 0.0, 0.08)
	tween.tween_callback(scanlines.queue_free)

func _create_static_noise_effect(glitch_layer: CanvasLayer):
	"""Create static noise overlay effect"""
	var noise_overlay = ColorRect.new()
	noise_overlay.color = Color(1.0, 1.0, 1.0, 0.4)  # More visible
	noise_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Get viewport size to cover entire screen
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	
	glitch_layer.add_child(noise_overlay)
	noise_overlay.size = screen_size
	noise_overlay.position = Vector2.ZERO
	
	# Create rapid flickering noise effect with more intensity
	var tween = create_tween()
	for i in range(15):  # More flickers
		var noise_alpha = randf_range(0.2, 0.6)
		var noise_color = Color(randf(), randf(), randf(), noise_alpha)
		tween.tween_property(noise_overlay, "color", noise_color, 0.015)
	
	tween.tween_property(noise_overlay, "modulate:a", 0.0, 0.06)
	tween.tween_callback(noise_overlay.queue_free)

func _create_main_glitch_overlay(glitch_layer: CanvasLayer):
	"""Create the main glitch overlay that encompasses the entire effect"""
	var main_overlay = ColorRect.new()
	main_overlay.color = Color(0.5, 0.0, 1.0, 0.3)  # Purple base
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
	tween.tween_callback(main_overlay.queue_free)

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
