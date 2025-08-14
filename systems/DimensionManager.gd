extends Node

signal layer_changed(active_layer: int)

enum DimensionLayer {
	LAYER_A = 0,
	LAYER_B = 1
}

var active_layer: int = DimensionLayer.LAYER_A
var current_layer: String = "A"
var flip_cooldown: float = 0.4
var cooldown_timer: float = 0.0
var can_flip: bool = true

var registered_nodes: Array[DimensionNode] = []

func _ready():
	# Set process mode to always so it works during pause
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	# Handle cooldown timer
	if cooldown_timer > 0:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			can_flip = true

func toggle_layer():
	if not can_flip:
		return false
	
	var new_layer = DimensionLayer.LAYER_B if active_layer == DimensionLayer.LAYER_A else DimensionLayer.LAYER_A
	return set_active_layer(new_layer)

func set_active_layer(layer: int) -> bool:
	if not can_flip or layer == active_layer:
		return false
	
	# Start cooldown
	can_flip = false
	cooldown_timer = flip_cooldown
	
	# Update active layer
	var previous_layer = active_layer
	active_layer = layer
	current_layer = "A" if layer == DimensionLayer.LAYER_A else "B"
	
	# Visual effects
	FX.flash_screen(Color.WHITE, 0.1)
	FX.hit_stop(120) # 120ms hit stop
	
	# Update all registered nodes
	update_dimension_nodes()
	
	# Emit signal
	layer_changed.emit(active_layer)
	
	print("Dimension flipped: Layer ", previous_layer, " -> Layer ", active_layer)
	return true

func register_node(node: DimensionNode):
	if node not in registered_nodes:
		registered_nodes.append(node)
		# Immediately update the node to current layer state
		node.set_layer_active(active_layer in node.active_layers)

func unregister_node(node: DimensionNode):
	if node in registered_nodes:
		registered_nodes.erase(node)

func update_dimension_nodes():
	for node in registered_nodes:
		if is_instance_valid(node):
			node.set_layer_active(active_layer in node.active_layers)
		else:
			# Clean up invalid nodes
			registered_nodes.erase(node)

func get_active_layer() -> int:
	return active_layer

func get_layer_name(layer: int) -> String:
	match layer:
		DimensionLayer.LAYER_A:
			return "Layer A"
		DimensionLayer.LAYER_B:
			return "Layer B"
		_:
			return "Unknown"

func is_on_cooldown() -> bool:
	return not can_flip

func get_cooldown_remaining() -> float:
	return max(0.0, cooldown_timer)

func set_layer(layer_name: String) -> bool:
	var layer_int = DimensionLayer.LAYER_A if layer_name == "A" else DimensionLayer.LAYER_B
	return set_active_layer(layer_int)