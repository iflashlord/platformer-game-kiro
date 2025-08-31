extends Node2D
class_name LoopingBackground

## A component for creating infinitely looping backgrounds with parallax support
## Works with the dimension system to show different backgrounds per layer

signal background_looped

@export_group("Background Settings")
@export var texture: Texture2D
@export var scroll_speed: Vector2 = Vector2(-50, 0)  # Pixels per second
@export var parallax_factor: Vector2 = Vector2(0.5, 0.5)  # 0.0 = no movement, 1.0 = same as camera
@export var auto_scroll: bool = true
@export var loop_seamlessly: bool = true

@export_group("Layer Settings")
@export var layer_a_texture: Texture2D
@export var layer_b_texture: Texture2D
@export var use_different_textures_per_layer: bool = false

@export_group("Visual Settings")
@export var modulate_color: Color = Color.WHITE
@export var z_index: int = -10  # Behind other objects by default
@export var scale_factor: Vector2 = Vector2.ONE

# Internal variables
var _sprites: Array[Sprite2D] = []
var _camera: Camera2D
var _texture_size: Vector2
var _current_offset: Vector2 = Vector2.ZERO
var _current_layer: String = "A"

@onready var _dimension_manager: Node = get_node("/root/DimensionManager")

func _ready():
	# Set z_index for layering
	z_index = z_index
	
	# Connect to dimension manager if available
	if _dimension_manager:
		_dimension_manager.layer_changed.connect(_on_layer_changed)
		_current_layer = _dimension_manager.get_current_layer()
	
	# Find the camera
	_find_camera()
	
	# Setup the background
	_setup_background()
	
	print("🖼️ LoopingBackground initialized - Layer: ", _current_layer)

func _find_camera():
	"""Find the main camera in the scene"""
	# Try to find camera in common locations
	var cameras = get_tree().get_nodes_in_group("cameras")
	if cameras.size() > 0:
		_camera = cameras[0]
		return
	
	# Fallback: search for any Camera2D
	_camera = get_viewport().get_camera_2d()
	
	if not _camera:
		print("⚠️ LoopingBackground: No camera found, parallax will not work")

func _setup_background():
	"""Create the sprite instances for seamless looping"""
	# Clear existing sprites
	for sprite in _sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_sprites.clear()
	
	# Get the appropriate texture
	var current_texture = _get_current_texture()
	if not current_texture:
		print("⚠️ LoopingBackground: No texture assigned")
		return
	
	_texture_size = current_texture.get_size() * scale_factor
	
	# Calculate how many sprites we need for seamless looping
	var viewport_size = get_viewport().get_visible_rect().size
	var sprites_needed_x = max(3, ceil(viewport_size.x / _texture_size.x) + 2)
	var sprites_needed_y = max(3, ceil(viewport_size.y / _texture_size.y) + 2) if scroll_speed.y != 0 else 1
	
	# Create sprites
	for x in range(sprites_needed_x):
		for y in range(sprites_needed_y):
			var sprite = Sprite2D.new()
			sprite.texture = current_texture
			sprite.modulate = modulate_color
			sprite.scale = scale_factor
			
			# Position sprites in a grid
			sprite.position = Vector2(
				x * _texture_size.x,
				y * _texture_size.y
			)
			
			add_child(sprite)
			_sprites.append(sprite)
	
	print("🖼️ Created ", _sprites.size(), " background sprites")

func _process(delta):
	if not auto_scroll:
		return
	
	# Update scroll offset
	_current_offset += scroll_speed * delta
	
	# Apply parallax if camera exists
	if _camera:
		var camera_pos = _camera.global_position
		var parallax_offset = camera_pos * parallax_factor
		global_position = -parallax_offset + _current_offset
	else:
		global_position = _current_offset
	
	# Handle looping
	if loop_seamlessly:
		_handle_looping()

func _handle_looping():
	"""Reset position when we've scrolled far enough to maintain seamless loop"""
	var loop_threshold = _texture_size
	
	# Horizontal looping
	if abs(_current_offset.x) >= loop_threshold.x:
		var loops = floor(abs(_current_offset.x) / loop_threshold.x)
		_current_offset.x -= sign(_current_offset.x) * loops * loop_threshold.x
		background_looped.emit()
	
	# Vertical looping
	if abs(_current_offset.y) >= loop_threshold.y:
		var loops = floor(abs(_current_offset.y) / loop_threshold.y)
		_current_offset.y -= sign(_current_offset.y) * loops * loop_threshold.y
		background_looped.emit()

func _get_current_texture() -> Texture2D:
	"""Get the appropriate texture based on current layer"""
	if use_different_textures_per_layer:
		match _current_layer:
			"A":
				return layer_a_texture if layer_a_texture else texture
			"B":
				return layer_b_texture if layer_b_texture else texture
			_:
				return texture
	else:
		return texture

func _on_layer_changed(new_layer: String):
	"""Handle dimension layer changes"""
	_current_layer = new_layer
	
	if use_different_textures_per_layer:
		# Recreate background with new texture
		_setup_background()
		print("🖼️ Background updated for layer: ", new_layer)

# Public API
func set_scroll_speed(new_speed: Vector2):
	"""Change the scroll speed at runtime"""
	scroll_speed = new_speed

func set_parallax_factor(new_factor: Vector2):
	"""Change the parallax factor at runtime"""
	parallax_factor = new_factor

func pause_scrolling():
	"""Stop automatic scrolling"""
	auto_scroll = false

func resume_scrolling():
	"""Resume automatic scrolling"""
	auto_scroll = true

func reset_position():
	"""Reset the background to its starting position"""
	_current_offset = Vector2.ZERO

func set_texture_for_layer(layer: String, new_texture: Texture2D):
	"""Set a specific texture for a layer"""
	match layer:
		"A":
			layer_a_texture = new_texture
		"B":
			layer_b_texture = new_texture
	
	if _current_layer == layer:
		_setup_background()

func get_current_scroll_offset() -> Vector2:
	"""Get the current scroll offset"""
	return _current_offset