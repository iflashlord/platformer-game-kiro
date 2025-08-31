extends Node2D
class_name ParallaxBackgroundSystem

## Advanced parallax background system with multiple layers
## Supports different textures per dimension layer and configurable parallax speeds

signal all_backgrounds_ready

@export_group("System Settings")
@export var auto_find_camera: bool = true
@export var follow_camera: bool = true

# Background layer configuration
@export_group("Background Layers")
@export var background_layers: Array[BackgroundLayerConfig] = []

# Internal variables
var _camera: Camera2D
var _background_instances: Array[LoopingBackground] = []
var _is_ready: bool = false

@onready var _dimension_manager: Node = get_node("/root/DimensionManager")

func _ready():
	if auto_find_camera:
		_find_camera()
	
	_setup_background_layers()
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
		
		# Layer-specific textures
		bg.layer_a_texture = config.layer_a_texture
		bg.layer_b_texture = config.layer_b_texture
		bg.use_different_textures_per_layer = config.use_different_textures_per_layer
		
		add_child(bg)
		_background_instances.append(bg)
		
		print("🌄 Created background layer: ", bg.name, " (z: ", config.z_index, ")")

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