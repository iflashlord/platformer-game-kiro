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
	
	# Create multiple rapid flashes with different colors to simulate glitch
	var glitch_colors = [
		Color(0.8, 0.2, 1.0, 0.6),  # Purple
		Color(0.0, 1.0, 1.0, 0.4),  # Cyan  
		Color(1.0, 0.2, 0.5, 0.5),  # Magenta
		Color(0.2, 1.0, 0.2, 0.3),  # Green
	]
	
	# Create rapid succession of colored flashes
	for i in range(glitch_colors.size()):
		var delay = i * 0.05  # 0.05s between flashes
		get_tree().create_timer(delay).timeout.connect(
			func(): _create_glitch_flash(glitch_colors[i % glitch_colors.size()])
		)
	
	# Add scanline effect
	get_tree().create_timer(0.1).timeout.connect(_create_scanline_effect)
	
	# Add static noise overlay
	get_tree().create_timer(0.05).timeout.connect(_create_static_noise_effect)

func _create_glitch_flash(color: Color):
	"""Create a single glitch flash with the given color"""
	if FX:
		FX.flash_screen(color, 0.08, color.a)

func _create_scanline_effect():
	"""Create horizontal scanline effect across the screen"""
	var scanlines = ColorRect.new()
	scanlines.color = Color(0.0, 1.0, 1.0, 0.15)  # Cyan scanlines
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(scanlines)
		scanlines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		# Create moving scanline pattern
		var tween = create_tween()
		for i in range(3):
			var alpha = 0.3 if i % 2 == 0 else 0.05
			tween.tween_property(scanlines, "modulate:a", alpha, 0.03)
		
		tween.tween_property(scanlines, "modulate:a", 0.0, 0.06)
		tween.tween_callback(scanlines.queue_free)

func _create_static_noise_effect():
	"""Create static noise overlay effect"""
	var noise_overlay = ColorRect.new()
	noise_overlay.color = Color(1.0, 1.0, 1.0, 0.1)
	noise_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(noise_overlay)
		noise_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		# Create rapid flickering noise effect
		var tween = create_tween()
		for i in range(8):
			var noise_alpha = randf_range(0.05, 0.25)
			var noise_color = Color(randf(), randf(), randf(), noise_alpha)
			tween.tween_property(noise_overlay, "color", noise_color, 0.02)
		
		tween.tween_property(noise_overlay, "modulate:a", 0.0, 0.05)
		tween.tween_callback(noise_overlay.queue_free)
