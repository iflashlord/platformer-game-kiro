extends Resource
class_name BackgroundLayerConfig

## Configuration resource for individual background layers in the ParallaxBackgroundSystem

@export_group("Texture Settings")
@export var texture: Texture2D
@export var layer_a_texture: Texture2D
@export var layer_b_texture: Texture2D
@export var use_different_textures_per_layer: bool = false

@export_group("Movement Settings")
@export var scroll_speed: Vector2 = Vector2(-50, 0)
@export var parallax_factor: Vector2 = Vector2(0.5, 0.5)
@export var auto_scroll: bool = true
@export var loop_seamlessly: bool = true
@export var horizontal_gap: int = 0
@export var vertical_gap: int = 0

@export_group("Visual Settings")
@export var modulate_color: Color = Color.WHITE
@export var z_index: int = -10
@export var scale_factor: Vector2 = Vector2.ONE

@export_group("Layer Info")
@export var layer_name: String = ""
@export var description: String = ""

@export_group("Dimension")
@export var target_layer: String = "A"  # For dimension system compatibility
@export var visible_in_both_dimensions: bool = false  # Show in both dimensions A and B

func _init():
	# Set default values
	pass

# Utility functions
func duplicate_config() -> BackgroundLayerConfig:
	"""Create a copy of this configuration"""
	var new_config = BackgroundLayerConfig.new()
	
	new_config.texture = texture
	new_config.layer_a_texture = layer_a_texture
	new_config.layer_b_texture = layer_b_texture
	new_config.use_different_textures_per_layer = use_different_textures_per_layer
	
	new_config.scroll_speed = scroll_speed
	new_config.parallax_factor = parallax_factor
	new_config.auto_scroll = auto_scroll
	new_config.loop_seamlessly = loop_seamlessly
	
	new_config.modulate_color = modulate_color
	new_config.z_index = z_index
	new_config.scale_factor = scale_factor
	
	new_config.layer_name = layer_name
	new_config.description = description
	
	new_config.target_layer = target_layer
	new_config.visible_in_both_dimensions = visible_in_both_dimensions
	
	return new_config

func create_far_background() -> BackgroundLayerConfig:
	"""Create a configuration for a far background layer (slow parallax)"""
	var config = BackgroundLayerConfig.new()
	config.scroll_speed = Vector2(-20, 0)
	config.parallax_factor = Vector2(0.1, 0.1)
	config.z_index = -20
	config.layer_name = "Far Background"
	return config

func create_mid_background() -> BackgroundLayerConfig:
	"""Create a configuration for a mid background layer (medium parallax)"""
	var config = BackgroundLayerConfig.new()
	config.scroll_speed = Vector2(-40, 0)
	config.parallax_factor = Vector2(0.3, 0.3)
	config.z_index = -15
	config.layer_name = "Mid Background"
	return config

func create_near_background() -> BackgroundLayerConfig:
	"""Create a configuration for a near background layer (fast parallax)"""
	var config = BackgroundLayerConfig.new()
	config.scroll_speed = Vector2(-60, 0)
	config.parallax_factor = Vector2(0.7, 0.7)
	config.z_index = -10
	config.layer_name = "Near Background"
	return config