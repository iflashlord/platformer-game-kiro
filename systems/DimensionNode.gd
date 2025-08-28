extends Node
class_name DimensionNode

@export var active_layers: Array[int] = [0] # Which layers this node is active on
@export var auto_register: bool = true # Automatically register with DimensionManager
@export var affect_collision: bool = true # Enable/disable collision shapes
@export var affect_visibility: bool = true # Enable/disable sprites/visuals
@export var fade_transition: bool = false # Use fade transition instead of instant
@export var fade_duration: float = 0.2 # Duration of fade transition

var collision_shapes: Array[CollisionShape2D] = []
var sprites: Array[Node] = []
var original_modulate: Color = Color.WHITE
var is_layer_active: bool = true

func _ready():
	# Find all collision shapes and sprites in this node and children
	find_collision_shapes(self)
	find_sprites(self)
	
	# Store original modulate color
	if sprites.size() > 0 and sprites[0].has_method("get") and sprites[0].has_property("modulate"):
		original_modulate = sprites[0].modulate
	
	# Note: DimensionNode uses signal-based approach instead of registration
	# This avoids conflicts with DimensionManager's visibility control
	
	# Set initial state based on current active layer
	var current_layer_int = 0 if DimensionManager.get_current_layer() == "A" else 1
	set_layer_active(current_layer_int in active_layers)
	
	# Connect to layer change signal
	if not DimensionManager.layer_changed.is_connected(_on_layer_changed):
		DimensionManager.layer_changed.connect(_on_layer_changed)

func _exit_tree():
	# Disconnect signal
	if DimensionManager and DimensionManager.layer_changed.is_connected(_on_layer_changed):
		DimensionManager.layer_changed.disconnect(_on_layer_changed)
	
	# Note: No need to unregister since we use signal-based approach

func _on_layer_changed(new_layer: String):
	var current_layer_int = 0 if new_layer == "A" else 1
	set_layer_active(current_layer_int in active_layers)

func find_collision_shapes(node: Node):
	if node is CollisionShape2D:
		collision_shapes.append(node)
	
	for child in node.get_children():
		find_collision_shapes(child)

func find_sprites(node: Node):
	# Look for visual nodes (Sprite2D, AnimatedSprite2D, etc.)
	if node is Sprite2D or node is AnimatedSprite2D or node is TextureRect or node is ColorRect:
		sprites.append(node)
	elif node is CPUParticles2D or node is GPUParticles2D:
		sprites.append(node)
	elif node is Label:
		sprites.append(node)
	
	for child in node.get_children():
		find_sprites(child)

func set_layer_active(active: bool):
	if is_layer_active == active:
		return
	
	is_layer_active = active
	
	# Handle collision shapes
	if affect_collision:
		for shape in collision_shapes:
			if is_instance_valid(shape):
				shape.disabled = not active
	
	# Handle visual elements
	if affect_visibility:
		if fade_transition:
			fade_to_state(active)
		else:
			set_immediate_visibility(active)

func set_immediate_visibility(visible: bool):
	for sprite in sprites:
		if is_instance_valid(sprite):
			if sprite.has_method("set_visible"):
				sprite.visible = visible
			elif sprite.has_property("modulate"):
				sprite.modulate.a = 1.0 if visible else 0.0

func fade_to_state(visible: bool):
	var target_alpha = 1.0 if visible else 0.0
	
	for sprite in sprites:
		if is_instance_valid(sprite) and sprite.has_property("modulate"):
			var tween = create_tween()
			tween.tween_property(sprite, "modulate:a", target_alpha, fade_duration)

func add_to_layer(layer: int):
	if layer not in active_layers:
		active_layers.append(layer)
		# Update state if this layer is now active
		var current_layer_int = 0 if DimensionManager.get_current_layer() == "A" else 1
		if current_layer_int == layer:
			set_layer_active(true)

func remove_from_layer(layer: int):
	if layer in active_layers:
		active_layers.erase(layer)
		# Update state if we removed the currently active layer
		var current_layer_int = 0 if DimensionManager.get_current_layer() == "A" else 1
		if current_layer_int == layer:
			set_layer_active(false)

func is_active_on_layer(layer: int) -> bool:
	return layer in active_layers

func toggle_layer(layer: int):
	if layer in active_layers:
		remove_from_layer(layer)
	else:
		add_to_layer(layer)

# Debug function to print node state
func debug_print():
	print("DimensionNode: ", get_parent().name)
	print("  Active layers: ", active_layers)
	print("  Current state: ", "Active" if is_layer_active else "Inactive")
	print("  Collision shapes: ", collision_shapes.size())
	print("  Sprites: ", sprites.size())
