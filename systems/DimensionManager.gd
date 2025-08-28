extends Node

signal layer_changed(new_layer: String)

var current_layer: String = "A"
var layer_objects: Dictionary = {}

func _ready():
	# Make this a singleton-like autoload
	add_to_group("dimension_managers")
	print("🌀 DimensionManager initialized - Current layer: ", current_layer)

func set_layer(new_layer: String):
	if new_layer == current_layer:
		return
	
	var old_layer = current_layer
	current_layer = new_layer
	
	print("🌀 Switching from layer ", old_layer, " to ", new_layer)
	
	# Update all registered layer objects
	_update_layer_objects()
	
	# Emit signal for other systems
	layer_changed.emit(new_layer)

func get_current_layer() -> String:
	return current_layer

func register_layer_object(obj: Node, layer: String):
	"""Register an object to be shown/hidden based on layer"""
	if not layer_objects.has(layer):
		layer_objects[layer] = []
	
	layer_objects[layer].append(obj)
	
	# Set initial visibility
	var should_be_visible = (layer == current_layer)
	_set_object_visibility(obj, should_be_visible)
	
	print("🌀 Registered object ", obj.name, " to layer ", layer, " (visible: ", should_be_visible, ")")

func unregister_layer_object(obj: Node, layer: String):
	"""Remove an object from layer management"""
	if layer_objects.has(layer):
		layer_objects[layer].erase(obj)

func _update_layer_objects():
	"""Update visibility of all layer objects"""
	print("🌀 Updating layer objects for layer: ", current_layer)
	
	for layer in layer_objects.keys():
		var objects = layer_objects[layer]
		var should_be_visible = (layer == current_layer)
		
		print("🌀 Layer ", layer, " objects: ", objects.size(), " (should be visible: ", should_be_visible, ")")
		
		for obj in objects:
			if is_instance_valid(obj):
				_set_object_visibility(obj, should_be_visible)
				print("  - ", obj.name, " visibility set to: ", should_be_visible)
			else:
				# Clean up invalid objects
				objects.erase(obj)
				print("  - Removed invalid object from layer ", layer)

# Utility functions
func is_layer_active(layer: String) -> bool:
	return current_layer == layer

func toggle_layer():
	var new_layer = "B" if current_layer == "A" else "A"
	set_layer(new_layer)

func get_inactive_layer() -> String:
	return "B" if current_layer == "A" else "A"

func _set_object_visibility(obj: Node, visible: bool):
	"""Set visibility for an object, handling different node types"""
	if obj is DimensionNode:
		# DimensionNode handles its own visibility logic
		obj.set_layer_active(visible)
	elif obj.has_property("visible"):
		# Standard CanvasItem nodes
		obj.visible = visible
	else:
		# For other node types, we can't control visibility directly
		print("⚠️ Warning: Cannot set visibility for node type: ", obj.get_class())
