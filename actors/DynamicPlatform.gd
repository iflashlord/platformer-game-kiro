@tool
extends StaticBody2D
class_name DynamicPlatform

enum PlatformType {
	YELLOW,
	GREEN,
	EMPTY
}

# Core platform properties - simple and direct
@export var width: float = 96.0: set = _set_width
@export var height: float = 32.0: set = _set_height
@export var platform_type: PlatformType = PlatformType.YELLOW: set = _set_platform_type
@export var is_breakable: bool = false: set = _set_breakable
@export var break_delay: float = 3.0  # Time before breaking after first touch
@export var shake_duration: float = 2.0  # Time to shake before breaking
@export var target_layer: String = "A"  # For dimension system compatibility

# Node references - using NinePatchRect for proper 9-slice
@onready var nine_patch: NinePatchRect = $NinePatchRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var breakable_component: Node = $BreakableComponent

# Dimension system compatibility
var dimension_manager: Node
var is_active_in_current_layer: bool = true

# Platform textures
var platform_textures = {
	PlatformType.YELLOW: preload("res://content/Graphics/Sprites/Tiles/Default/block_yellow.png"),
	PlatformType.GREEN: preload("res://content/Graphics/Sprites/Tiles/Default/block_green.png"),
	PlatformType.EMPTY: preload("res://content/Graphics/Sprites/Tiles/Default/block_empty.png")
}

func _ready():
	# Setup platform (works in both editor and runtime)
	_setup_platform()
	
	# Runtime-only setup
	if not Engine.is_editor_hint():
		# Setup dimension system
		_setup_dimension_system()
		
		# Setup breakable mechanics if enabled
		if is_breakable:
			_setup_breakable_component()
		
		print("🧱 DynamicPlatform created - Type: ", PlatformType.keys()[platform_type], " Size: ", Vector2(width, height), " Breakable: ", is_breakable)
	else:
		# Editor setup - ensure platform is visible and properly configured
		_update_visual_and_collision()
		print("🎨 DynamicPlatform in editor - Type: ", PlatformType.keys()[platform_type], " Size: ", Vector2(width, height))

func _setup_dimension_system():
	# Only setup dimension system at runtime
	if Engine.is_editor_hint():
		return
		
	# Find dimension manager
	dimension_manager = get_tree().get_first_node_in_group("dimension_managers")
	if not dimension_manager and has_node("/root/DimensionManager"):
		dimension_manager = get_node("/root/DimensionManager")
	
	if dimension_manager:
		dimension_manager.layer_changed.connect(_on_layer_changed)
		_update_for_layer(dimension_manager.get_current_layer())

func _setup_platform():
	# Get reference to existing NinePatchRect or create one
	if not nine_patch:
		nine_patch = get_node("NinePatchRect") if has_node("NinePatchRect") else null
	
	if not nine_patch:
		nine_patch = NinePatchRect.new()
		nine_patch.name = "NinePatchRect"
		add_child(nine_patch)
		if Engine.is_editor_hint():
			nine_patch.owner = get_tree().edited_scene_root
	
	# Setup collision shape
	if not collision_shape:
		collision_shape = get_node("CollisionShape2D") if has_node("CollisionShape2D") else null
	
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)
		if Engine.is_editor_hint():
			collision_shape.owner = get_tree().edited_scene_root
	
	# Update visual and collision to match current properties
	_update_visual_and_collision()

func _update_visual_and_collision():
	if not nine_patch or not collision_shape:
		return
	
	# Set texture based on platform type
	nine_patch.texture = platform_textures[platform_type]
	
	# Configure 9-slice margins for proper scaling
	var texture = nine_patch.texture
	if texture:
		var texture_size = texture.get_size()
		# Use 1/4 of texture size as margins for good 9-slice effect
		var margin_x = int(texture_size.x / 4)
		var margin_y = int(texture_size.y / 4)
		
		nine_patch.patch_margin_left = margin_x
		nine_patch.patch_margin_top = margin_y
		nine_patch.patch_margin_right = margin_x
		nine_patch.patch_margin_bottom = margin_y
	
	# Set size directly using width and height
	nine_patch.size = Vector2(width, height)
	nine_patch.position = Vector2.ZERO
	
	# Update collision shape to match exactly
	var shape = collision_shape.shape as RectangleShape2D
	if not shape:
		shape = RectangleShape2D.new()
		collision_shape.shape = shape
	
	# Set collision size to match visual dimensions exactly
	shape.size = Vector2(width, height)
	collision_shape.position = Vector2(width / 2, height / 2)
	
	# Update breakable component detection area if it exists
	if breakable_component and breakable_component.has_method("update_detection_area"):
		breakable_component.update_detection_area()
	elif is_breakable and breakable_component:
		# Ensure breakable component knows about size changes
		breakable_component.platform_size_changed(Vector2(width, height))
	
	if not Engine.is_editor_hint():
		print("🧱 Updated platform: Size=", Vector2(width, height), " 9-slice margins=", Vector2(nine_patch.patch_margin_left, nine_patch.patch_margin_top))

func _setup_breakable_component():
	# Only setup breakable mechanics at runtime
	if Engine.is_editor_hint():
		return
	
	# Get or create breakable component
	if not breakable_component:
		breakable_component = get_node("BreakableComponent") if has_node("BreakableComponent") else null
	
	if breakable_component and breakable_component.has_method("setup"):
		# Wait a frame to ensure BreakableComponent's _ready() has run
		await get_tree().process_frame
		breakable_component.setup(self, break_delay, shake_duration)
		print("🔧 BreakableComponent setup complete")
	else:
		print("⚠️ BreakableComponent not found - disabling breakable functionality")
		is_breakable = false

# Editor-specific method to handle property changes
func _get_configuration_warnings():
	var warnings = []
	
	if width <= 0 or height <= 0:
		warnings.append("Platform width and height must be positive values")
	
	if not nine_patch:
		warnings.append("NinePatchRect node is missing")
	
	if not collision_shape:
		warnings.append("CollisionShape2D node is missing")
	
	return warnings

func _on_layer_changed(new_layer: String):
	_update_for_layer(new_layer)

func _update_for_layer(current_layer: String):
	is_active_in_current_layer = (current_layer == target_layer)
	
	# Update visibility and collision based on layer
	visible = is_active_in_current_layer
	collision_layer = 1 if is_active_in_current_layer else 0
	collision_mask = 1 if is_active_in_current_layer else 0
	
	if collision_shape:
		collision_shape.disabled = not is_active_in_current_layer

# Public methods for runtime configuration
func set_platform_type(new_type: PlatformType):
	platform_type = new_type
	_update_visual_and_collision()

func set_platform_size(new_width: float, new_height: float):
	width = new_width
	height = new_height
	_update_visual_and_collision()

# Method to reset platform for object pooling
func reset_platform():
	# Reset to default state
	platform_type = PlatformType.YELLOW
	width = 96.0
	height = 32.0
	is_breakable = false
	break_delay = 3.0
	shake_duration = 2.0
	target_layer = "A"
	
	# Reset breakable component if it exists
	if breakable_component and breakable_component.has_method("reset_state"):
		breakable_component.reset_state()
	
	# Reset visual state
	visible = true
	collision_layer = 1
	collision_mask = 1
	if collision_shape:
		collision_shape.disabled = false
	
	_update_visual_and_collision()
	print("🔄 Platform reset for reuse")

# Method to configure platform in one call (useful for pooling)
func configure_platform(config: Dictionary):
	if config.has("position"):
		global_position = config.position
	if config.has("type"):
		platform_type = config.type
	if config.has("width"):
		width = config.width
	if config.has("height"):
		height = config.height
	if config.has("breakable"):
		is_breakable = config.breakable
	if config.has("break_delay"):
		break_delay = config.break_delay
	if config.has("shake_duration"):
		shake_duration = config.shake_duration
	if config.has("target_layer"):
		target_layer = config.target_layer
	
	_update_visual_and_collision()
	
	if is_breakable and not Engine.is_editor_hint():
		_setup_breakable_component()

# Property setters for inspector changes
func _set_width(value: float):
	width = maxf(value, 8.0)  # Minimum width of 8 pixels
	if is_inside_tree():
		_update_visual_and_collision()
		# Force update in editor
		if Engine.is_editor_hint():
			notify_property_list_changed()

func _set_height(value: float):
	height = maxf(value, 8.0)  # Minimum height of 8 pixels
	if is_inside_tree():
		_update_visual_and_collision()
		# Force update in editor
		if Engine.is_editor_hint():
			notify_property_list_changed()

func _set_platform_type(value: PlatformType):
	platform_type = value
	if is_inside_tree():
		_update_visual_and_collision()

func _set_breakable(value: bool):
	is_breakable = value
	if is_breakable and is_inside_tree() and not Engine.is_editor_hint():
		_setup_breakable_component()

# Validation method to ensure platform is properly configured
func _validate_configuration():
	if not nine_patch:
		push_error("DynamicPlatform: NinePatchRect node not found!")
		return false
	
	if not collision_shape:
		push_error("DynamicPlatform: CollisionShape2D node not found!")
		return false
	
	if width <= 0 or height <= 0:
		push_warning("DynamicPlatform: Invalid platform size: " + str(Vector2(width, height)))
		width = 96.0
		height = 32.0
	
	return true

# Method to refresh the entire platform (useful for editor changes)
func refresh_platform():
	if _validate_configuration():
		_update_visual_and_collision()
		if not Engine.is_editor_hint() and is_breakable:
			_setup_breakable_component()
		
		# Force editor update
		if Engine.is_editor_hint():
			notify_property_list_changed()