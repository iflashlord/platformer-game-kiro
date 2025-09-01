extends Area2D
class_name TeleportGate

## A teleport gate that can transport players between locations
## Supports dimension layers through LayerObject integration

@export var teleport_target: TeleportGate  # Direct reference to partner gate
@export var teleport_cooldown: float = 1.0  # Prevent rapid teleporting
@export var teleport_offset: Vector2 = Vector2(0, -20)  # Offset from target position
@export_enum("A", "B", "Both") var target_layer: String = "A"  # Which dimension layer this gate belongs to
@export var auto_register_layer: bool = true  # Automatically register with DimensionManager

var is_active: bool = true
var cooldown_timer: float = 0.0
var _layer_object: LayerObject

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var port_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	
	# Configure Area2D
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2  # Detect player (player is on layer 2)
	
	# Setup dimension layer support
	if auto_register_layer:
		_setup_layer_object()
	
	print("TeleportGate ready - monitoring: ", monitoring, " mask: ", collision_mask)
	print("TeleportGate target: ", teleport_target, " layer: ", target_layer)

func _process(delta):
	# Handle cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_active = true
	
	# Update visual state
	update_visual_state()

func _on_body_entered(body):
	print("🌀 TeleportGate: Body entered ", name, " (layer: ", target_layer, ", active: ", is_active, ")")
	
	if not body.is_in_group("player"):
		print("Not a player, ignoring")
		return
	
	# Check if this teleport gate is active in the current dimension
	if not is_active_in_current_dimension():
		print("🌀 TeleportGate: Ignoring player entry - not active in current dimension (", target_layer, ")")
		return
	
	if not is_active:
		print("Gate not active (cooldown)")
		return
		
	if not teleport_target:
		print("No teleport target set!")
		return
	
	# Check if target gate is also active in current dimension
	if not teleport_target.is_active_in_current_dimension():
		print("🌀 TeleportGate: Target gate not active in current dimension")
		return
	
	print("All checks passed, teleporting...")
	teleport_player(body)

func teleport_player(player):
	if not teleport_target or not is_active:
		return
	
	print("Teleporting player")
	
	# Play teleport sound effect
	Audio.play_sfx("teleport")
	
	# Deactivate both gates temporarily
	is_active = false
	cooldown_timer = teleport_cooldown
	teleport_target.is_active = false
	teleport_target.cooldown_timer = teleport_cooldown
	
	# Calculate teleport position
	var teleport_position = teleport_target.global_position + teleport_offset
	
	# Simple teleport effects
	create_simple_effect(global_position)
	create_simple_effect(teleport_position)
	
	# Move player
	player.global_position = teleport_position
	
	print("Player teleported successfully!")

func create_simple_effect(pos: Vector2):
	# Create simple particle burst
	for i in range(10):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color.CYAN
		particle.position = pos + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		get_tree().current_scene.add_child(particle)
		
		# Simple fade animation
		var tween = create_tween()
		tween.tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)

func update_visual_state():
	if not port_sprite:
		return
	
	# Check if gate is active in current dimension
	var dimension_active = is_active_in_current_dimension()
	
	if is_active and dimension_active:
		# Active state - bright cyan with simple pulse
		var pulse = (sin(Time.get_unix_time_from_system() * 2.0) + 1.0) / 2.0
		port_sprite.modulate.a = 0.8 + (pulse * 0.2)
		port_sprite.modulate = Color.CYAN
	elif dimension_active:
		# Inactive state (cooldown) but in correct dimension - dimmed
		port_sprite.modulate.a = 0.4
		port_sprite.modulate = Color.CYAN
	else:
		# Not in correct dimension - very dim and different color
		port_sprite.modulate.a = 0.2
		port_sprite.modulate = Color.GRAY

# Dimension layer support methods
func _setup_layer_object():
	"""Setup LayerObject component for dimension support"""
	if target_layer == "Both":
		# For "Both", we don't use LayerObject since we want to be visible in all dimensions
		print("🌀 TeleportGate: Setup for both dimensions - no layer object needed")
		return
	
	_layer_object = LayerObject.new()
	_layer_object.target_layer = target_layer
	_layer_object.auto_register = true
	add_child(_layer_object)
	print("🌀 TeleportGate: Setup layer object for layer ", target_layer)

func set_layer(layer: String):
	"""Change which dimension layer this teleport gate belongs to"""
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
	
	print("🌀 TeleportGate: Changed from layer ", old_layer, " to layer ", layer)

func is_active_in_current_dimension() -> bool:
	"""Check if this teleport gate is active in the current dimension"""
	# If target_layer is "Both", always active
	if target_layer == "Both":
		return true
	
	var dimension_manager = get_tree().get_first_node_in_group("dimension_managers")
	if not dimension_manager:
		if has_node("/root/DimensionManager"):
			dimension_manager = get_node("/root/DimensionManager")
	
	if dimension_manager and dimension_manager.has_method("is_layer_active"):
		return dimension_manager.is_layer_active(target_layer)
	
	# Fallback: assume active if no dimension manager
	return true
