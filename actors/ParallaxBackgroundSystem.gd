extends Node2D
class_name ParallaxBackgroundSystem

## Advanced parallax background system with multiple layers
## Supports different textures per dimension layer and configurable parallax speeds

signal all_backgrounds_ready

@export_group("System Settings")
@export var auto_find_camera: bool = true
@export var follow_camera: bool = true

@export_group("Background Color")
# Main scene background color (used as fallback)
@export var main_bg_color: Color = Color(0, 0, 0, 0)
# Optional per-dimension overrides; if alpha == 0, falls back to main_bg_color
@export var layer_a_bg_color: Color = Color(0, 0, 0, 0)
@export var layer_b_bg_color: Color = Color(0, 0, 0, 0)

# Background layer configuration
@export_group("Background Layers")
@export var background_layers: Array[BackgroundLayerConfig] = []

# Internal variables
var _camera: Camera2D
var _background_instances: Array[LoopingBackground] = []
var _is_ready: bool = false
var _bg_enabled: bool = false
var _bg_color_current: Color = Color(0, 0, 0, 0)
var _bg_poly: Polygon2D

@onready var _dimension_manager: Node = get_node("/root/DimensionManager")

func _ready():
	if auto_find_camera:
		_find_camera()
	
	_setup_background_layers()
	_setup_background_fill()
	_is_ready = true
	all_backgrounds_ready.emit()
	
	print("🌄 ParallaxBackgroundSystem initialized with ", background_layers.size(), " layers")

func _find_camera():
	"""Find the main camera in the scene"""
	var cameras = get_tree().get_nodes_in_group("cameras")
	if cameras.size() > 0:
		_camera = cameras[0]
		return
	
	_camera = get_viewport().get_camera_2d()
	
	if not _camera:
		print("⚠️ ParallaxBackgroundSystem: No camera found")

func _setup_background_layers():
	"""Create LoopingBackground instances for each configured layer"""
	# Clear existing instances
	for bg in _background_instances:
		if is_instance_valid(bg):
			bg.queue_free()
	_background_instances.clear()
	
	# Create background instances
	for i in range(background_layers.size()):
		var config = background_layers[i]
		if not config:
			continue
		
		var bg = LoopingBackground.new()
		bg.name = "BackgroundLayer_" + str(i)
		
		# Apply configuration
		bg.texture = config.texture
		bg.scroll_speed = config.scroll_speed
		bg.parallax_factor = config.parallax_factor
		bg.auto_scroll = config.auto_scroll
		bg.loop_seamlessly = config.loop_seamlessly
		bg.modulate_color = config.modulate_color
		bg.z_index = config.z_index
		bg.scale_factor = config.scale_factor
		bg.horizontal_gap =  config.horizontal_gap
		bg.vertical_gap = config.vertical_gap

		# Layer-specific textures
		bg.layer_a_texture = config.layer_a_texture
		bg.layer_b_texture = config.layer_b_texture
		bg.use_different_textures_per_layer = config.use_different_textures_per_layer
		
		# Dimension settings
		bg.target_layer = config.target_layer
		bg.visible_in_both_dimensions = config.visible_in_both_dimensions
		
		# Loop control settings
		bg.loop_start_point = config.loop_start_point
		bg.loop_end_point = config.loop_end_point
		bg.reset_position = config.reset_position
		bg.loop_left = config.loop_left
		bg.loop_right = config.loop_right
		bg.loop_up = config.loop_up
		bg.loop_down = config.loop_down
		
		add_child(bg)
		_background_instances.append(bg)
		
		print("🌄 Created background layer: ", bg.name, " (z: ", config.z_index, ")")

func _setup_background_fill():
	"""Initialize background color drawing and connect signals."""
	_bg_enabled = (main_bg_color.a > 0.0) or (layer_a_bg_color.a > 0.0) or (layer_b_bg_color.a > 0.0)
	if not _bg_enabled:
		return

	# Initialize current color based on current dimension
	var current_layer := "A"
	if _dimension_manager and _dimension_manager.has_method("get_current_layer"):
		current_layer = _dimension_manager.get_current_layer()
	_bg_color_current = _get_bg_color_for_layer(current_layer)
	# Prepare poly drawer
	if not is_instance_valid(_bg_poly):
		_bg_poly = Polygon2D.new()
		_bg_poly.name = "BackgroundFill2D"
		_bg_poly.z_as_relative = false
		_bg_poly.z_index = -4096  # draw behind all world items
		_bg_poly.color = _bg_color_current
		add_child(_bg_poly)

	_update_bg_polygon()
	_update_bg_position()

	# Update on dimension change
	if _dimension_manager and not _dimension_manager.layer_changed.is_connected(_on_dim_layer_changed):
		_dimension_manager.layer_changed.connect(_on_dim_layer_changed)

	# Redraw on viewport resize
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)

func _get_bg_color_for_layer(layer: String) -> Color:
	"""Return the active background color for the given dimension, falling back to main."""
	if layer == "A" and layer_a_bg_color.a > 0.0:
		return layer_a_bg_color
	if layer == "B" and layer_b_bg_color.a > 0.0:
		return layer_b_bg_color
	return main_bg_color

func _on_dim_layer_changed(new_layer: String):
	if not _bg_enabled:
		return
	_bg_color_current = _get_bg_color_for_layer(new_layer)
	if is_instance_valid(_bg_poly):
		_bg_poly.color = _bg_color_current

func _on_viewport_resized():
	if _bg_enabled:
		_update_bg_polygon()
		_update_bg_position()
func _update_bg_polygon():
	if not (_bg_enabled and is_instance_valid(_bg_poly)):
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	_bg_poly.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(vp_size.x, 0),
		Vector2(vp_size.x, vp_size.y),
		Vector2(0, vp_size.y)
	])

func _update_bg_position():
	if not (_bg_enabled and is_instance_valid(_bg_poly)):
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half: Vector2 = vp_size * 0.5
	var cam_pos: Vector2 = _camera.global_position if _camera else Vector2.ZERO
	_bg_poly.global_position = cam_pos - half

func _process(delta):
	if _bg_enabled:
		_update_bg_position()

# Public API
func add_background_layer(config: BackgroundLayerConfig):
	"""Add a new background layer at runtime"""
	background_layers.append(config)
	
	if _is_ready:
		_setup_background_layers()

func remove_background_layer(index: int):
	"""Remove a background layer by index"""
	if index >= 0 and index < background_layers.size():
		background_layers.remove_at(index)
		
		if _is_ready:
			_setup_background_layers()

func set_camera(camera: Camera2D):
	"""Set the camera to follow"""
	_camera = camera

func pause_all_scrolling():
	"""Pause scrolling for all background layers"""
	for bg in _background_instances:
		if is_instance_valid(bg):
			bg.pause_scrolling()

func resume_all_scrolling():
	"""Resume scrolling for all background layers"""
	for bg in _background_instances:
		if is_instance_valid(bg):
			bg.resume_scrolling()

func set_global_scroll_speed_multiplier(multiplier: float):
	"""Apply a speed multiplier to all background layers"""
	for i in range(_background_instances.size()):
		var bg = _background_instances[i]
		var config = background_layers[i]
		
		if is_instance_valid(bg) and config:
			bg.set_scroll_speed(config.scroll_speed * multiplier)

func get_background_layer(index: int) -> LoopingBackground:
	"""Get a specific background layer instance"""
	if index >= 0 and index < _background_instances.size():
		return _background_instances[index]
	return null
