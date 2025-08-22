extends Node2D
class_name DebugBorder

var border_color: Color = Color.YELLOW
var border_width: float = 2.0
var target_node: Node2D
var border_rect: Rect2

func _ready():
	if not DebugSettings.show_debug_borders:
		visible = false
		return
	 
	# Get target node (parent)
	target_node = get_parent()
	_calculate_border_rect()

func _draw():
	if not DebugSettings.show_debug_borders:
		return
	
	# Draw border outline
	draw_rect(border_rect, border_color, false, border_width)
	
	# Draw corner markers
	var corner_size = 4.0
	var corners = [
		border_rect.position,
		border_rect.position + Vector2(border_rect.size.x, 0),
		border_rect.position + border_rect.size,
		border_rect.position + Vector2(0, border_rect.size.y)
	]
	
	for corner in corners:
		draw_circle(corner, corner_size, border_color)

func _calculate_border_rect():
	if not target_node:
		return
	
	var bounds = _get_node_bounds(target_node)
	border_rect = Rect2(bounds.position - Vector2(border_width, border_width), 
						bounds.size + Vector2(border_width * 2, border_width * 2))

func _get_node_bounds(node: Node2D) -> Rect2:
	# Try to get bounds from different node types
	if node is Sprite2D:
		var sprite = node as Sprite2D
		if sprite.texture:
			var size = sprite.texture.get_size() * sprite.scale
			if sprite.region_enabled:
				size = sprite.region_rect.size * sprite.scale
			return Rect2(-size/2, size)
	elif node is CollisionShape2D and node.shape:
		var shape = node.shape
		if shape is RectangleShape2D:
			var size = shape.size
			return Rect2(-size/2, size)
		elif shape is CircleShape2D:
			var radius = shape.radius
			return Rect2(-Vector2(radius, radius), Vector2(radius * 2, radius * 2))
	
	# Try to find collision shape in children
	for child in node.get_children():
		if child is CollisionShape2D and child.shape:
			return _get_node_bounds(child)
	
	# Check if parent has ColorRect children (for platform sprites)
	for child in node.get_children():
		if child is ColorRect:
			var rect = child as ColorRect
			return Rect2(rect.position, rect.size)
	
	# Default bounds
	return Rect2(-16, -16, 32, 32)
 

func set_border_color(color: Color):
	border_color = color
	queue_redraw()

func set_border_width(width: float):
	border_width = width
	_calculate_border_rect()
	queue_redraw()
