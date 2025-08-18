# Example: How to set up layers in your level
# Add this to your level script or create a separate setup script

extends Node2D

func _ready():
	setup_dimension_system()

func setup_dimension_system():
	# 1. Add DimensionManager to your level
	var dimension_manager = preload("res://systems/DimensionManager.gd").new()
	dimension_manager.name = "DimensionManager"
	add_child(dimension_manager)
	
	# 2. Connect to layer changes for custom logic
	dimension_manager.layer_changed.connect(_on_layer_changed)
	
	print("🌀 Dimension system setup complete!")

func _on_layer_changed(new_layer: String):
	print("🌀 Level responding to layer change: ", new_layer)
	
	# Example: Change background color based on layer
	if new_layer == "A":
		RenderingServer.set_default_clear_color(Color(0.2, 0.3, 0.5))  # Blue tint
	else:
		RenderingServer.set_default_clear_color(Color(0.5, 0.2, 0.3))  # Red tint