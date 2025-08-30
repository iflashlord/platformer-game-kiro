@tool
extends StaticBody2D
class_name DynamicPlatform

enum PlatformType {
	YELLOW,
	GREEN,
	EMPTY,
	STRONG,
	BRIDGE,
	BRIDGE_LOGS,
	LAVA,
	CHAIN,
	DIRT_TOP_LEFT,
	DIRT_TOP_CENTER,
	DIRT_TOP_RIGHT
}

# Core platform properties - simple and direct
@export var width: float = 64.0: set = _set_width
@export var height: float = 64.0: set = _set_height
@export_group("Patch Margins")
@export var patch_margin_left: float = 23: set = _set_patch_margin_left
@export var patch_margin_right: float = 23: set = _set_patch_margin_right
@export var patch_margin_top: float = 23: set = _set_patch_margin_top
@export var patch_margin_bottom: float = 23: set = _set_patch_margin_bottom
@export var platform_type: PlatformType = PlatformType.YELLOW: set = _set_platform_type
@export_group("Nine Patch Stretch")
@export var axis_stretch_horizontal: NinePatchRect.AxisStretchMode = NinePatchRect.AXIS_STRETCH_MODE_STRETCH: set = _set_axis_stretch_horizontal
@export var axis_stretch_vertical: NinePatchRect.AxisStretchMode = NinePatchRect.AXIS_STRETCH_MODE_STRETCH: set = _set_axis_stretch_vertical
@export var is_breakable: bool = false: set = _set_breakable
@export var break_delay: float = 3.0  # Time before breaking after first touch
@export var shake_duration: float = 2.0  # Time to shake before breaking
@export_group("Respawn Settings")
@export var auto_respawn: bool = true  # Whether platform should respawn after breaking
@export var respawn_delay: float = 5.0  # Time in seconds before respawning (only if auto_respawn is true)
@export_group("Dimension")
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
	PlatformType.EMPTY: preload("res://content/Graphics/Sprites/Tiles/Default/block_strong_empty.png"),
	PlatformType.STRONG: preload("res://content/Graphics/Sprites/Tiles/Default/block_strong_empty.png"),
	PlatformType.BRIDGE: preload("res://content/Graphics/Sprites/Tiles/Default/bridge.png"),
	PlatformType.BRIDGE_LOGS: preload("res://content/Graphics/Sprites/Tiles/Default/bridge_logs.png"),
	PlatformType.LAVA: preload("res://content/Graphics/Sprites/Tiles/Default/lava.png"),
	PlatformType.CHAIN: preload("res://content/Graphics/Sprites/Tiles/Default/chain.png"),
	PlatformType.DIRT_TOP_LEFT: preload("res://content/Graphics/Sprites/Tiles/Default/terrain_dirt_block_top_left.png"),
	PlatformType.DIRT_TOP_CENTER: preload("res://content/Graphics/Sprites/Tiles/Default/terrain_dirt_block_top.png"),
	PlatformType.DIRT_TOP_RIGHT: preload("res://content/Graphics/Sprites/Tiles/Default/terrain_dirt_block_top_right.png")
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
		
		# Add simple collision detection for breakable platforms
		if is_breakable:
			_setup_player_detection()
		
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
		# Set individual patch margins for precise control
		nine_patch.patch_margin_left = int(patch_margin_left)
		nine_patch.patch_margin_right = int(patch_margin_right)
		nine_patch.patch_margin_top = int(patch_margin_top)
		nine_patch.patch_margin_bottom = int(patch_margin_bottom)
	
	# Configure axis stretch modes
	nine_patch.axis_stretch_horizontal = axis_stretch_horizontal
	nine_patch.axis_stretch_vertical = axis_stretch_vertical
	
	# Set size directly using width and height
	nine_patch.size = Vector2(width, height)
	nine_patch.position = Vector2.ZERO
	
	# CRITICAL FIX: Always create a new RectangleShape2D instance to avoid shared resources
	var shape = RectangleShape2D.new()
	collision_shape.shape = shape
	
	# CRITICAL: Collision shape must ALWAYS match NinePatchRect size exactly
	shape.size = Vector2(width, height)  # Exact same size as visual
	collision_shape.position = Vector2(width / 2, height / 2)  # Centered on visual
	
	# No need for separate detection area updates - using direct collision detection
	
	# Update particles to match platform size (BreakableComponent handles positioning)
	# Call this after a frame to ensure all size updates are complete
	if breakable_component and breakable_component.has_method("update_particles_for_platform_size") and not Engine.is_editor_hint():
		call_deferred("_update_particles_deferred")
	
	# Validate that collision shape matches NinePatchRect exactly
	_validate_collision_alignment()
	
	if not Engine.is_editor_hint():
		print("🧱 Updated platform: Size=", Vector2(width, height), " Margins L/R/T/B=", Vector4(nine_patch.patch_margin_left, nine_patch.patch_margin_right, nine_patch.patch_margin_top, nine_patch.patch_margin_bottom))

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
		breakable_component.setup(self, break_delay, shake_duration, auto_respawn, respawn_delay)
		
		# Connect to breakable component signals
		if not breakable_component.break_started.is_connected(_on_break_started):
			breakable_component.break_started.connect(_on_break_started)
		if not breakable_component.break_completed.is_connected(_on_break_completed):
			breakable_component.break_completed.connect(_on_break_completed)
		if not breakable_component.shake_started.is_connected(_on_shake_started):
			breakable_component.shake_started.connect(_on_shake_started)
		
		print("🔧 BreakableComponent setup complete - Auto respawn: ", auto_respawn, " Delay: ", respawn_delay, "s")
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
	auto_respawn = true
	respawn_delay = 5.0
	target_layer = "A"
	axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	
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
	if config.has("auto_respawn"):
		auto_respawn = config.auto_respawn
	if config.has("respawn_delay"):
		respawn_delay = config.respawn_delay
	if config.has("target_layer"):
		target_layer = config.target_layer
	if config.has("axis_stretch_horizontal"):
		axis_stretch_horizontal = config.axis_stretch_horizontal
	if config.has("axis_stretch_vertical"):
		axis_stretch_vertical = config.axis_stretch_vertical
	
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


# Deferred particle update to ensure size changes are complete
func _update_particles_deferred():
	if breakable_component and breakable_component.has_method("update_particles_for_platform_size"):
		breakable_component.update_particles_for_platform_size()
		print("🎆 Particles updated for platform size: ", Vector2(width, height))

# Validation method to ensure collision shape matches NinePatchRect exactly
func _validate_collision_alignment():
	if not nine_patch or not collision_shape:
		return
	
	var shape = collision_shape.shape as RectangleShape2D
	if not shape:
		return
	
	# Ensure collision shape size matches NinePatchRect size exactly
	var nine_patch_size = nine_patch.size
	var collision_size = shape.size
	
	if not nine_patch_size.is_equal_approx(collision_size):
		push_warning("DynamicPlatform: Collision shape size mismatch! NinePatch: " + str(nine_patch_size) + " vs Collision: " + str(collision_size))
		# Force correction
		shape.size = nine_patch_size
	
	# Ensure collision shape is centered on NinePatchRect
	var expected_position = Vector2(nine_patch_size.x / 2, nine_patch_size.y / 2)
	if not collision_shape.position.is_equal_approx(expected_position):
		push_warning("DynamicPlatform: Collision shape position mismatch! Expected: " + str(expected_position) + " vs Actual: " + str(collision_shape.position))
		# Force correction
		collision_shape.position = expected_position

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

# Signal handlers for breakable component
func _on_break_started():
	print("🧱 Platform break sequence started")
	# Could add visual effects, sound, etc.

func _on_shake_started():
	print("🧱 Platform started shaking")
	# Could add screen shake, sound effects, etc.

func _on_break_completed():
	print("🧱 Platform break completed")
	# Platform is now broken and invisible

# Simple player detection for breakable platforms using collision detection
func _setup_player_detection():
	# Use a timer to periodically check if player is on this platform
	var detection_timer = Timer.new()
	detection_timer.wait_time = 0.05  # Check every 0.05 seconds for better responsiveness
	detection_timer.timeout.connect(_check_for_player)
	add_child(detection_timer)
	detection_timer.start()

func _check_for_player():
	if not is_breakable or not breakable_component:
		return
	
	# Get the player
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.is_on_floor():
		return
	
	# Use the actual NinePatchRect bounds for accurate detection
	var player_pos = player.global_position
	var platform_rect = Rect2(global_position, Vector2(width, height))
	
	# Check if player is standing on top of the platform
	# Player should be within horizontal bounds and just above the platform surface
	var horizontal_overlap = player_pos.x >= platform_rect.position.x - 5 and player_pos.x <= platform_rect.position.x + platform_rect.size.x + 5
	var vertical_overlap = player_pos.y >= platform_rect.position.y - 20 and player_pos.y <= platform_rect.position.y + 10
	
	if horizontal_overlap and vertical_overlap:
		# Player is on the platform! Trigger breaking
		if breakable_component.has_method("player_landed_on_platform"):
			breakable_component.player_landed_on_platform()
			# Stop the detection timer to prevent multiple triggers
			var timer = get_children().filter(func(child): return child is Timer and child.timeout.is_connected(_check_for_player))
			if timer.size() > 0:
				timer[0].stop()


func _set_patch_margin_left(value: float):
	patch_margin_left = value
	if is_inside_tree():
		_update_visual_and_collision()
		# Force update in editor
		if Engine.is_editor_hint():
			notify_property_list_changed()

func _set_patch_margin_right(value: float):
	patch_margin_right = value
	if is_inside_tree():
		_update_visual_and_collision()
		# Force update in editor
		if Engine.is_editor_hint():
			notify_property_list_changed()

func _set_patch_margin_top(value: float):
	patch_margin_top = value
	if is_inside_tree():
		_update_visual_and_collision()
		# Force update in editor
		if Engine.is_editor_hint():
			notify_property_list_changed()

func _set_patch_margin_bottom(value: float):
	patch_margin_bottom = value
	if is_inside_tree():
		_update_visual_and_collision()
		# Force update in editor
		if Engine.is_editor_hint():
			notify_property_list_changed()

func _set_axis_stretch_horizontal(value: NinePatchRect.AxisStretchMode):
	axis_stretch_horizontal = value
	if is_inside_tree():
		_update_visual_and_collision()
		# Force update in editor
		if Engine.is_editor_hint():
			notify_property_list_changed()

func _set_axis_stretch_vertical(value: NinePatchRect.AxisStretchMode):
	axis_stretch_vertical = value
	if is_inside_tree():
		_update_visual_and_collision()
		# Force update in editor
		if Engine.is_editor_hint():
			notify_property_list_changed()
