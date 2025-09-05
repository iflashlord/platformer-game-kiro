extends Node

# Deployment Configuration
# Set these values for production builds

const PRODUCTION_BUILD = false  # Set to true for deployment
const ENABLE_DEBUG_BORDERS = true  # Set to false for deployment
const ENABLE_DEBUG_LABELS = true  # Set to false for deployment
const ENABLE_CONSOLE_LOGS = true  # Set to false for deployment

func _ready():
	# Apply deployment settings
	if PRODUCTION_BUILD:
		_configure_for_production()
	else:
		_configure_for_development()

func _configure_for_production():
	# Disable all debug features for production
	DebugSettings.show_debug_borders = false
	DebugSettings.show_collision_shapes = false
	DebugSettings.show_fps = false
	DebugSettings.debug_mode = false
	
	# Hide debug labels
	_hide_debug_labels()
	
	print("Production mode enabled - debug features disabled")

func _configure_for_development():
	# Enable debug features for development
	DebugSettings.show_debug_borders = ENABLE_DEBUG_BORDERS
	DebugSettings.show_collision_shapes = false
	DebugSettings.show_fps = true
	DebugSettings.debug_mode = true
	
	print("Development mode enabled - debug features available")

func _hide_debug_labels():
	# Hide all debug labels in the scene tree
	var debug_labels = get_tree().get_nodes_in_group("debug_labels")
	for label in debug_labels:
		if label is Label:
			label.visible = false

# Quick deployment function - call this before building
func prepare_for_deployment():
	DebugSettings.show_debug_borders = false
	DebugSettings.show_collision_shapes = false
	DebugSettings.show_fps = false
	DebugSettings.debug_mode = false
	_hide_debug_labels()
	print("Game prepared for deployment - all debug features disabled")
