extends Node2D

## Example scene demonstrating the LoopingBackground and ParallaxBackgroundSystem

@onready var simple_background: LoopingBackground = $SimpleBackground
@onready var parallax_system: ParallaxBackgroundSystem = $ParallaxBackgroundSystem
@onready var camera: Camera2D = $Camera2D

func _ready():
	print("🎮 Background Example Scene loaded")
	
	# Setup simple background example
	_setup_simple_background()
	
	# Setup parallax system example
	_setup_parallax_system()
	
	# Add camera to group for easy finding
	camera.add_to_group("cameras")

func _setup_simple_background():
	"""Configure the simple looping background"""
	if not simple_background:
		return
	
	# Try to load a background texture
	var bg_texture = _load_background_texture()
	if bg_texture:
		simple_background.texture = bg_texture
		simple_background.scroll_speed = Vector2(-30, 0)
		simple_background.parallax_factor = Vector2(0.2, 0.2)
		#simple_background.z_index = -20
		print("🖼️ Simple background configured")

func _setup_parallax_system():
	"""Configure the parallax background system with multiple layers"""
	if not parallax_system:
		return
	
	# Create background layer configurations
	var far_layer = BackgroundLayerConfig.new()
	far_layer.texture = _load_background_texture("sky")
	far_layer.scroll_speed = Vector2(-10, 0)
	far_layer.parallax_factor = Vector2(0.1, 0.1)
	far_layer.z_index = -30
	far_layer.layer_name = "Sky"
	far_layer.modulate_color = Color(0.8, 0.9, 1.0)  # Slight blue tint
	
	var mid_layer = BackgroundLayerConfig.new()
	mid_layer.texture = _load_background_texture("trees")
	mid_layer.scroll_speed = Vector2(-25, 0)
	mid_layer.parallax_factor = Vector2(0.3, 0.3)
	mid_layer.z_index = -20
	mid_layer.layer_name = "Trees"
	
	var near_layer = BackgroundLayerConfig.new()
	near_layer.texture = _load_background_texture("grass")
	near_layer.scroll_speed = Vector2(-40, 0)
	near_layer.parallax_factor = Vector2(0.6, 0.6)
	near_layer.z_index = -10
	near_layer.layer_name = "Foreground"
	
	# Add layers to the system
	parallax_system.background_layers = [far_layer, mid_layer, near_layer]
	
	print("🌄 Parallax system configured with ", parallax_system.background_layers.size(), " layers")

func _load_background_texture(type: String = "") -> Texture2D:
	"""Try to load a background texture from available assets"""
	var texture_paths = [
		"res://content/Graphics/Vector/Backgrounds/background_solid_sky.svg",
		"res://content/Graphics/Vector/Backgrounds/background_solid_grass.svg",
		"res://content/Graphics/Vector/Backgrounds/background_fade_trees.svg",
		"res://content/Graphics/Vector/Backgrounds/background_color_desert.svg"
	]
	
	# Try to find a specific type
	if type != "":
		for path in texture_paths:
			if type in path:
				var texture = load(path)
				if texture:
					return texture
	
	# Fallback to first available texture
	for path in texture_paths:
		var texture = load(path)
		if texture:
			return texture
	
	print("⚠️ No background textures found")
	return null

func _input(event):
	"""Handle input for testing the background system"""
	if event.is_action_pressed("ui_accept"):  # Space key
		# Toggle dimension layer
		var dimension_manager = get_node("/root/DimensionManager")
		if dimension_manager:
			dimension_manager.toggle_layer()
	
	if event.is_action_pressed("ui_select"):  # Enter key
		# Pause/resume scrolling
		if simple_background:
			if simple_background.auto_scroll:
				simple_background.pause_scrolling()
				parallax_system.pause_all_scrolling()
				print("⏸️ Background scrolling paused")
			else:
				simple_background.resume_scrolling()
				parallax_system.resume_all_scrolling()
				print("▶️ Background scrolling resumed")

func _process(delta):
	"""Move camera for testing parallax effect"""
	if Input.is_action_pressed("ui_right"):
		camera.global_position.x += 100 * delta
	elif Input.is_action_pressed("ui_left"):
		camera.global_position.x -= 100 * delta
	
	if Input.is_action_pressed("ui_up"):
		camera.global_position.y -= 100 * delta
	elif Input.is_action_pressed("ui_down"):
		camera.global_position.y += 100 * delta
