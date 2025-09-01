extends Area2D
class_name HintArea

## A hint area that displays a message when the player enters and hides it when they exit
## Supports dimension layers through LayerObject integration

@export var hint_message: String = "Enter your hint message here"
@export var hint_title: String = ""
@export var auto_hide_delay: float = 0.0  # 0 = manual hide only
@export var show_once_only: bool = false
@export_enum("A", "B", "Both") var target_layer: String = "A"  # Which dimension layer this hint belongs to
@export var auto_register_layer: bool = true  # Automatically register with DimensionManager

var _has_been_shown: bool = false
var _hide_timer: Timer
var _layer_object: LayerObject
var _is_currently_showing: bool = false  # Track if this hint area is currently showing a hint

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Setup auto-hide timer if needed
	if auto_hide_delay > 0:
		_hide_timer = Timer.new()
		_hide_timer.wait_time = auto_hide_delay
		_hide_timer.one_shot = true
		_hide_timer.timeout.connect(_on_auto_hide_timeout)
		add_child(_hide_timer)
	
	# Setup dimension layer support
	if auto_register_layer:
		_setup_layer_object()
	
	# Ensure we're monitoring the right collision layers
	collision_layer = 0  # Don't collide with anything
	collision_mask = 2   # Only detect player (layer 2)

func _on_body_entered(body: Node2D):
	if not body.has_method("is_player"):
		return
	
	print("🌀 HintArea: Player entered ", name, " (layer: ", target_layer, ", active: ", is_active_in_current_dimension(), ")")
	
	# Check if this hint area is active in the current dimension
	if not is_active_in_current_dimension():
		print("🌀 HintArea: Ignoring player entry - not active in current dimension (", target_layer, ")")
		return
		
	if show_once_only and _has_been_shown:
		print("🌀 HintArea: Ignoring player entry - already shown once")
		return

	# Audio feedback
	# if Audio:
	# 	Audio.play_sfx("hint")
	
		
	_show_hint()
	_has_been_shown = true

func _on_body_exited(body: Node2D):
	if not body.has_method("is_player"):
		return
	
	print("🌀 HintArea: Player exited ", name, " (layer: ", target_layer, ", currently showing: ", _is_currently_showing, ")")
	
	# Always hide hint when player exits, regardless of dimension state
	# This ensures that if this hint area showed a hint, it can hide it
	_hide_hint()

func _show_hint():
	# Mark this hint area as currently showing
	_is_currently_showing = true
	
	# Send signal to UI system to show hint
	EventBus.hint_requested.emit(hint_message, hint_title)
	
	# Start auto-hide timer if configured
	if _hide_timer and auto_hide_delay > 0:
		_hide_timer.start()

func _hide_hint():
	# Only hide if this hint area is currently showing a hint
	if not _is_currently_showing:
		return
	
	# Mark as no longer showing
	_is_currently_showing = false
	
	# Stop auto-hide timer
	if _hide_timer:
		_hide_timer.stop()
	
	# Send signal to UI system to hide hint
	EventBus.hint_dismissed.emit()

func _on_auto_hide_timeout():
	_hide_hint()

# Method to manually trigger hint (useful for scripted events)
func trigger_hint():
	_show_hint()

# Method to reset the "shown once" state
func reset_shown_state():
	_has_been_shown = false

# Method to force hide hint (useful for cleanup)
func force_hide_hint():
	"""Force hide the hint regardless of current state"""
	if _is_currently_showing:
		print("🌀 HintArea: Force hiding hint for ", name)
		_hide_hint()

# Dimension layer support methods
func _setup_layer_object():
	"""Setup LayerObject component for dimension support"""
	if target_layer == "Both":
		# For "Both", we don't use LayerObject since we want to be visible in all dimensions
		print("🌀 HintArea: Setup for both dimensions - no layer object needed")
		return
	
	_layer_object = LayerObject.new()
	_layer_object.target_layer = target_layer
	_layer_object.auto_register = true
	add_child(_layer_object)
	print("🌀 HintArea: Setup layer object for layer ", target_layer)

func set_layer(layer: String):
	"""Change which dimension layer this hint area belongs to"""
	var old_layer = target_layer
	target_layer = layer
	
	# Handle transition to/from "Both"
	if old_layer == "Both" and layer != "Both":
		# Transitioning from "Both" to specific layer - need to create LayerObject
		_setup_layer_object()
	elif old_layer != "Both" and layer == "Both":
		# Transitioning from specific layer to "Both" - remove LayerObject
		if _layer_object:
			_layer_object.queue_free()
			_layer_object = null
		# Make sure we're visible
		visible = true
	elif layer != "Both" and _layer_object:
		# Normal layer change
		_layer_object.set_layer(layer)
	
	print("🌀 HintArea: Changed from layer ", old_layer, " to layer ", layer)

func is_active_in_current_dimension() -> bool:
	"""Check if this hint area is active in the current dimension"""
	# If target_layer is "Both", always active
	if target_layer == "Both":
		return true
	
	var dimension_manager = get_tree().get_first_node_in_group("dimension_managers")
	if not dimension_manager:
		if has_node("/root/DimensionManager"):
			dimension_manager = get_node("/root/DimensionManager")
	
	if dimension_manager and dimension_manager.has_method("is_layer_active"):
		var is_active = dimension_manager.is_layer_active(target_layer)
		
		# If this hint area was showing a hint but is no longer active, hide it
		if not is_active and _is_currently_showing:
			print("🌀 HintArea: Hiding hint due to dimension change - no longer active")
			_hide_hint()
		
		return is_active
	
	# Fallback: assume active if no dimension manager
	return true