extends Node

# Debug settings - easily toggle for development vs deployment
var show_debug_borders: bool = true
var show_collision_shapes: bool = false
var show_fps: bool = true
var debug_mode: bool = true

# Debug colors
var debug_border_color: Color = Color.YELLOW
var debug_border_width: float = 2.0

func _ready():
	# Auto-detect if we're in debug mode
	debug_mode = OS.is_debug_build()
	
	# Override for development
	if debug_mode:
		show_debug_borders = true
		show_collision_shapes = false
		show_fps = true
	else:
		# Production settings
		show_debug_borders = false
		show_collision_shapes = false
		show_fps = false

func toggle_debug_borders():
	show_debug_borders = !show_debug_borders
	EventBus.debug_borders_toggled.emit(show_debug_borders)

func add_debug_border(node: Node2D, color: Color = debug_border_color):
	if not show_debug_borders:
		return
	
	var border = ColorRect.new()
	border.name = "DebugBorder"
	border.color = Color.TRANSPARENT
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create border outline
	var border_style = StyleBoxFlat.new()
	border_style.border_color = color
	border_style.set_border_width_all(int(debug_border_width))
	border_style.bg_color = Color.TRANSPARENT
	
	# Get node bounds
	var bounds = _get_node_bounds(node)
	border.position = bounds.position - Vector2(debug_border_width, debug_border_width)
	border.size = bounds.size + Vector2(debug_border_width * 2, debug_border_width * 2)
	border.add_theme_stylebox_override("panel", border_style)
	
	node.add_child(border)
	border.z_index = 100  # Always on top

func _get_node_bounds(node: Node2D) -> Rect2:
	# Try to get bounds from different node types
	if node.has_method("get_rect"):
		return node.get_rect()
	elif node is CollisionShape2D and node.shape:
		var shape = node.shape
		if shape is RectangleShape2D:
			var size = shape.size
			return Rect2(-size/2, size)
		elif shape is CircleShape2D:
			var radius = shape.radius
			return Rect2(-Vector2(radius, radius), Vector2(radius * 2, radius * 2))
	elif node is Sprite2D:
		var sprite = node as Sprite2D
		if sprite.texture:
			var size = sprite.texture.get_size() * sprite.scale
			return Rect2(-size/2, size)
	
	# Default bounds
	return Rect2(-16, -16, 32, 32)