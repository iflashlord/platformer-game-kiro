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
@export var horizontal_gap: int = 0
@export var vertical_gap: int = 0

@export_group("Loop Control")
@export var loop_start_point: Vector2 = Vector2.ZERO  # Starting point for the loop
@export var loop_end_point: Vector2 = Vector2.ZERO   # End point for the loop (0 means infinite)
@export var reset_position: Vector2 = Vector2.ZERO   # Position to reset to when reaching loop_end_point
@export var loop_left: bool = true    # Enable looping when scrolling left
@export var loop_right: bool = true   # Enable looping when scrolling right
@export var loop_up: bool = true      # Enable looping when scrolling up
@export var loop_down: bool = true    # Enable looping when scrolling down

@export_group("Layer Settings")
@export var layer_a_texture: Texture2D
@export var layer_b_texture: Texture2D
@export var use_different_textures_per_layer: bool = false

@export_group("Visual Settings")
@export var modulate_color: Color = Color.WHITE
#@export var z_index: int = -10  # Behind other objects by default
@export var scale_factor: Vector2 = Vector2.ONE

@export_group("Dimension")
@export var target_layer: String = "A"  # For dimension system compatibility
@export var visible_in_both_dimensions: bool = false  # Show in both dimensions A and B

# Internal variables
var _sprites: Array[Sprite2D] = []
var _camera: Camera2D
var _texture_size: Vector2
var _current_offset: Vector2 = Vector2.ZERO
var _current_layer: String = "A"
var is_active_in_current_layer: bool = true

@onready var _dimension_manager: Node = get_node("/root/DimensionManager")

func _ready():
	# Set z_index for layering
	z_index = z_index
	
	# Connect to dimension manager if available
	if _dimension_manager:
		_dimension_manager.layer_changed.connect(_on_layer_changed)
		_current_layer = _dimension_manager.get_current_layer()
		_update_for_layer(_current_layer)
	
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
	
	# Calculate how many sprites we need based on looping directions
	var viewport_size = (get_viewport().get_visible_rect().size * 5)
	var sprites_needed_x = 1
	var sprites_needed_y = 1
	
	# Calculate horizontal sprites needed
	if (loop_left and scroll_speed.x < 0) or (loop_right and scroll_speed.x > 0):
		sprites_needed_x = max(3, ceil(viewport_size.x / _texture_size.x) + 2)
	else:
		sprites_needed_x = max(2, ceil(viewport_size.x / _texture_size.x))
	
	# Calculate vertical sprites needed
	if scroll_speed.y != 0 and ((loop_up and scroll_speed.y < 0) or (loop_down and scroll_speed.y > 0)):
		sprites_needed_y = max(3, ceil(viewport_size.y / _texture_size.y) + 2)
	elif scroll_speed.y != 0:
		sprites_needed_y = max(2, ceil(viewport_size.y / _texture_size.y))
	
	# Create sprites
	for x in range(sprites_needed_x):
		for y in range(sprites_needed_y):
			var sprite = Sprite2D.new()
			sprite.texture = current_texture
			sprite.modulate = modulate_color
			sprite.scale = scale_factor
			
			# Position sprites in a grid starting from loop_start_point
			sprite.position = Vector2(
				loop_start_point.x + (x * _texture_size.x),
				loop_start_point.y + (y * _texture_size.y)
			)
			
			add_child(sprite)

			# Adjust for viewport to avoid flickering on start
			var viewport_width = get_viewport().get_visible_rect().size.x
			sprite.position -= Vector2(viewport_width, 0)
			
			_sprites.append(sprite)
	
	print("🖼️ Created ", _sprites.size(), " background sprites")

func _process(delta):
	if not auto_scroll:
		return
	
	# Update scroll offset
	# _current_offset += scroll_speed * delta
	
	# Apply parallax if camera exists
	if _camera:
		var camera_pos = _camera.global_position
		var parallax_offset = camera_pos * parallax_factor
		# add random parallax offset to avoid jittering
		# parallax_offset += Vector2(randf(), randf()) * 0.01
		global_position = -parallax_offset + _current_offset
		
		# move background by the size of viewport down to keep it in view
		global_position.y += get_viewport().get_visible_rect().size.y

		# add gap
		global_position.x += horizontal_gap
		global_position.y += vertical_gap
		
	else:
		global_position = _current_offset
 
	
	# Handle looping
	if loop_seamlessly:
		_handle_looping()

func _handle_looping():
	"""Reset position when we've scrolled far enough to maintain seamless loop while respecting loop limits and directions"""
	# Skip if no texture
	if not _texture_size:
		return
		
	# Check if we've reached the loop end point
	if loop_end_point != Vector2.ZERO:
		# Handle horizontal looping based on direction settings
		if scroll_speed.x < 0 and loop_left and global_position.x <= -loop_end_point.x:
			global_position.x = reset_position.x
			emit_signal("background_looped")
		elif scroll_speed.x > 0 and loop_right and global_position.x >= loop_end_point.x:
			global_position.x = reset_position.x
			emit_signal("background_looped")
			
		# Handle vertical looping based on direction settings
		if scroll_speed.y < 0 and loop_up and global_position.y <= -loop_end_point.y:
			global_position.y = reset_position.y
			emit_signal("background_looped")
		elif scroll_speed.y > 0 and loop_down and global_position.y >= loop_end_point.y:
			global_position.y = reset_position.y
			emit_signal("background_looped")
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
	_update_for_layer(new_layer)

func _update_for_layer(current_layer: String):
	"""Update visibility and texture based on dimension layer"""
	# If visible in both dimensions, always active. Otherwise check target layer.
	is_active_in_current_layer = visible_in_both_dimensions or (current_layer == target_layer)
	
	# Update visibility based on layer
	visible = is_active_in_current_layer
	
	# Update texture if using different textures per layer
	if use_different_textures_per_layer and is_active_in_current_layer:
		# Recreate background with new texture
		_setup_background()
		print("🖼️ Background updated for layer: ", current_layer, " (active: ", is_active_in_current_layer, ")")

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

#func reset_position():
	#"""Reset the background to its starting position"""
	#_current_offset = Vector2.ZERO

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
