@tool
extends Area2D
class_name DangerousSpike

# Signals
signal player_damaged(spike: DangerousSpike, player: Node2D, damage: int)
signal spike_retracted
signal spike_extended

# Basic Properties
@export_group("Damage")
@export var damage_amount: int = 1: set = set_damage_amount
@export var knockback_force: float = 100.0
@export var damage_type: String = "spike"

@export_group("Direction")
@export var spike_direction: Vector2 = Vector2.UP: set = set_spike_direction

@export_group("Behavior")
@export var retract_on_hit: bool = false
@export var retract_time: float = 2.0
@export var auto_retract_cycle: bool = false
@export var cycle_time: float = 3.0
@export var warning_time: float = 0.5
@export var show_warning: bool = true

@export_group("Visual")
@export var spike_scale: float = 0.75: set = set_spike_scale
@export var use_background: bool = false: set = set_use_background
@export var glow_effect: bool = true

@export_group("Retract Animation")
@export var retract_fade: bool = true
@export var retract_move: bool = true
@export var retract_alpha: float = 0.5
@export var move_distance: float = 18.0

@export_group("Audio")
@export var damage_sound: String = "spike_hit"
@export var retract_sound: String = "spike_retract"
@export var extend_sound: String = "spike_extend"

@export_group("Dimensions")
@export var target_layer: String = "A": set = set_target_layer
@export var visible_in_both_dimensions: bool = false: set = set_visible_in_both_dimensions
@export var fade_on_dimension_change: bool = true
@export var dimension_transition_time: float = 0.3

var is_extended: bool = true
var is_retracting: bool = false
var retract_timer: float = 0.0
var cycle_timer: float = 0.0
var current_layer: String = "A"
var is_active_in_current_layer: bool = true
var dimension_manager: Node


@onready var spike_sprite: Sprite2D = $Sprite2D
@onready var background_rect: ColorRect = $SpikeSprite
@onready var label: Label = $SpikeLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var base_position: Vector2 = Vector2.ZERO

func _ready():
	add_to_group("hazards")
	add_to_group("spikes")
	add_to_group("dangerous_spikes")
	
	# Set initial scale
	if spike_sprite:
		spike_sprite.scale = Vector2(spike_scale, spike_scale)
		spike_sprite.position = Vector2.ZERO
		base_position = spike_sprite.position
	
	# Set appearance based on direction
	setup_spike_appearance()
	
	# Update collision size to match sprite scale
	_update_collision_size()
	
	# Set background visibility
	if background_rect:
		background_rect.visible = use_background
	
	# Only connect signals if not in editor
	if not Engine.is_editor_hint():
		# Connect collision
		body_entered.connect(_on_body_entered)
		
		# Setup dimension system (same as PatrolEnemy)
		_setup_dimensions()

func _notification(what):
	if what == NOTIFICATION_EDITOR_POST_SAVE:
		# Update appearance when scene is saved in editor
		setup_spike_appearance()

func _process(delta):
	# Skip process in editor
	if Engine.is_editor_hint():
		return
		
	# Handle retraction timer
	if is_retracting:
		retract_timer += delta
		if retract_timer >= retract_time:
			extend_spike()
	
	# Handle auto cycle
	if auto_retract_cycle:
		cycle_timer += delta
		if cycle_timer >= cycle_time:
			cycle_timer = 0.0
			if is_extended:
				retract_spike()
			else:
				extend_spike()

func setup_spike_appearance():
	# Ensure nodes are available (important for editor preview)
	if not spike_sprite:
		spike_sprite = get_node_or_null("Sprite2D")
	if not background_rect:
		background_rect = get_node_or_null("SpikeSprite")
	if not label:
		label = get_node_or_null("SpikeLabel")
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape2D")
	
	if not spike_sprite:
		return
	
	# Set sprite color/modulate based on danger level
	match damage_amount:
		1:
			spike_sprite.modulate = Color(0.8, 0.8, 0.8, 1)  # Light gray
			if background_rect:
				background_rect.color = Color(0.6, 0.6, 0.6, 0.3)
		2:
			spike_sprite.modulate = Color(1.0, 0.6, 0.6, 1)  # Red tint
			if background_rect:
				background_rect.color = Color(0.8, 0.4, 0.4, 0.4)
		3:
			spike_sprite.modulate = Color(0.6, 0.6, 1.0, 1)  # Blue tint (deadly)
			if background_rect:
				background_rect.color = Color(0.4, 0.4, 0.8, 0.5)
		_:
			spike_sprite.modulate = Color.WHITE
			if background_rect:
				background_rect.color = Color(0.6, 0.6, 0.6, 0.3)
	
	# Set rotation and position based on direction
	match spike_direction:
		Vector2.UP:
			spike_sprite.rotation = 0
			label.text = "🔺"
		Vector2.DOWN:
			spike_sprite.rotation = PI
			label.text = "🔻"
		Vector2.LEFT:
			spike_sprite.rotation = -PI/2
			label.text = "◀️"
		Vector2.RIGHT:
			spike_sprite.rotation = PI/2
			label.text = "▶️"
		_:
			spike_sprite.rotation = 0
			label.text = "🔺"
	
	# Update collision size to match the current scale
	_update_collision_size()

func _on_body_entered(body):
	if body.is_in_group("player") and is_extended and _can_damage_player():
		damage_player(body)

func _can_damage_player() -> bool:
	"""Check if spike can damage player based on dimension layer"""
	return is_active_in_current_layer

func damage_player(player):
	# Check if player is invincible first
	if player.has_method("is_player_invincible") and player.is_player_invincible():
		print("🔺 Player is invincible, no damage dealt")
		return
	
	# Apply knockback first
	if knockback_force > 0:
		var knockback_dir = (player.global_position - global_position).normalized()
		if player.has_method("apply_knockback"):
			player.apply_knockback(knockback_dir * knockback_force)
		elif player.has_method("velocity"):
			player.velocity += knockback_dir * knockback_force
	
	# Check if player has invincibility and use take_damage method
	if player.has_method("take_damage"):
		player.take_damage(damage_amount)
	elif HealthSystem and HealthSystem.has_method("lose_heart"):
		# Fallback to direct HealthSystem call
		for i in range(damage_amount):
			HealthSystem.lose_heart()
	
	# Play sound
	_play_sound(damage_sound)
	
	# Emit signal
	player_damaged.emit(self, player, damage_amount)
	
	# Visual feedback
	create_damage_effect()
	
	# Retract if configured
	if retract_on_hit:
		retract_spike()
	
	print("🔺 Spike attempted to damage player for ", damage_amount, " damage")

func create_damage_effect():
	# Screen flash
	if FX and FX.has_method("flash_screen"):
		FX.flash_screen(Color.RED, 0.2)
	
	# Screen shake
	if FX and FX.has_method("shake"):
		FX.shake(150)
	
	# Damage number effect
	var damage_label = Label.new()
	damage_label.text = "-" + str(damage_amount)
	damage_label.add_theme_font_size_override("font_size", 16)
	damage_label.add_theme_color_override("font_color", Color.RED)
	damage_label.position = global_position + Vector2(-10, -30)
	get_tree().current_scene.add_child(damage_label)
	
	# Animate damage number
	var tween = create_tween()
	tween.parallel().tween_property(damage_label, "position", damage_label.position + Vector2(0, -40), 0.8)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(damage_label.queue_free)

func retract_spike():
	if not is_extended or is_retracting:
		return
	
	is_extended = false
	is_retracting = true
	retract_timer = 0.0
	
	# Play sound
	_play_sound(retract_sound)
	
	# Emit signal
	spike_retracted.emit()
	
	

	# Visual retraction - animate the sprite
	if spike_sprite:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		# Always scale down
		var target_scale = Vector2(spike_scale * 0.5, spike_scale * 0.3)
		tween.parallel().tween_property(spike_sprite, "scale", target_scale, 0.3)
		
		# Optional position movement
		if retract_move:
			var move_offset = _get_retract_offset()
			tween.parallel().tween_property(spike_sprite, "position", base_position + move_offset, 0.3)
		
		# Optional alpha fade
		if retract_fade:
			tween.parallel().tween_property(spike_sprite, "modulate:a", retract_alpha, 0.3)

		# Also animate background if present and visible
		if background_rect and background_rect.visible:
			tween.parallel().tween_property(background_rect, "scale", Vector2(1.0, 0.3), 0.3)
			if retract_fade:
				tween.parallel().tween_property(background_rect, "modulate:a", retract_alpha, 0.3)
	
	# Disable collision temporarily
	collision_shape.disabled = true
	
	print("🔺 Spike retracted")

func extend_spike():
	is_extended = true
	is_retracting = false
	
	# Play sound
	_play_sound(extend_sound)
	
	# Emit signal
	spike_extended.emit()
	
	# Visual extension - animate the sprite back to normal
	if spike_sprite:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		# Scale back up
		var target_scale = Vector2(spike_scale, spike_scale)
		tween.parallel().tween_property(spike_sprite, "scale", target_scale, 0.2)
		
		# Return to base position if movement was used
		if retract_move:
			tween.parallel().tween_property(spike_sprite, "position", base_position, 0.2)
		
		# Restore opacity if fade was used
		if retract_fade:
			tween.parallel().tween_property(spike_sprite, "modulate:a", 1.0, 0.2)
		
		# Also animate background if present and visible
		if background_rect and background_rect.visible:
			tween.parallel().tween_property(background_rect, "scale", Vector2.ONE, 0.2)
			if retract_fade:
				tween.parallel().tween_property(background_rect, "modulate:a", 1.0, 0.2)
	
	# Re-enable collision
	collision_shape.disabled = false
	
	print("🔺 Spike extended")

func set_damage(new_damage: int):
	damage_amount = new_damage
	setup_spike_appearance()

func set_auto_cycle(enabled: bool, cycle_duration: float = 3.0):
	auto_retract_cycle = enabled
	cycle_time = cycle_duration
	cycle_timer = 0.0

# Helper functions

func _play_sound(sound_name: String):
	"""Play sound effect"""
	if sound_name != "" and Audio and Audio.has_method("play_sfx"):
		Audio.play_sfx(sound_name)

func get_spike_info() -> Dictionary:
	"""Get information about the spike state"""
	return {
		"damage_amount": damage_amount,
		"is_extended": is_extended,
		"is_retracting": is_retracting,
		"direction": spike_direction,
		"position": global_position
	}

func set_spike_properties(properties: Dictionary):
	"""Set multiple spike properties at once"""
	if properties.has("damage_amount"):
		damage_amount = properties.damage_amount
	if properties.has("spike_direction"):
		spike_direction = properties.spike_direction
	if properties.has("retract_on_hit"):
		retract_on_hit = properties.retract_on_hit
	if properties.has("auto_retract_cycle"):
		auto_retract_cycle = properties.auto_retract_cycle
	if properties.has("cycle_time"):
		cycle_time = properties.cycle_time
	
	# Update appearance after setting properties
	setup_spike_appearance()

# Property setters for editor preview

func set_damage_amount(value: int):
	damage_amount = value
	if _is_spike_ready():
		setup_spike_appearance()

func set_spike_direction(value: Vector2):
	spike_direction = value
	if _is_spike_ready():
		setup_spike_appearance()

func set_spike_scale(value: float):
	spike_scale = value
	if _is_spike_ready():
		_update_spike_scale()

func set_use_background(value: bool):
	use_background = value
	if _is_spike_ready():
		_update_background_visibility()

# Helper functions for editor preview

func _update_spike_scale():
	if spike_sprite:
		spike_sprite.scale = Vector2(spike_scale, spike_scale)
	_update_collision_size()

func _update_background_visibility():
	if background_rect:
		background_rect.visible = use_background

func _update_collision_size():
	"""Update collision shape size to match spike scale"""
	if not collision_shape or not collision_shape.shape:
		return
	
	# Get the base size from the sprite texture or use defaults
	var base_size = Vector2(27, 16)  # Default size from the scene
	if spike_sprite and spike_sprite.texture:
		var texture_size = spike_sprite.texture.get_size()
		# Scale texture size to reasonable collision size
		base_size = texture_size * 0.7  # Adjust factor for better collision detection
	
	# Scale the collision shape to match visual scale
	var scaled_size = base_size * spike_scale
	
	# Apply different scaling based on spike direction for better collision
	match spike_direction:
		Vector2.UP, Vector2.DOWN:
			# For vertical spikes, make collision slightly narrower
			scaled_size.x *= 0.8
		Vector2.LEFT, Vector2.RIGHT:
			# For horizontal spikes, make collision slightly shorter
			scaled_size.y *= 0.8
	
	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = scaled_size
	elif collision_shape.shape is CircleShape2D:
		# Use the smaller dimension for radius
		collision_shape.shape.radius = min(scaled_size.x, scaled_size.y) * 0.5
	
	print("🔺 Updated collision size to: ", scaled_size, " (scale: ", spike_scale, ")")

func _is_spike_ready() -> bool:
	# Check if we're in the scene tree and nodes are available
	return is_inside_tree() and spike_sprite != null

# Dimension system functions

func _setup_dimensions():
	"""Initialize dimension system - only at runtime (same as PatrolEnemy)"""
	if Engine.is_editor_hint():
		return
	
	print("🔺 Setting up dimensions for spike")
	
	# Find dimension manager (same logic as PatrolEnemy)
	dimension_manager = get_tree().get_first_node_in_group("dimension_managers")
	if not dimension_manager and has_node("/root/DimensionManager"):
		dimension_manager = get_node("/root/DimensionManager")
	
	if dimension_manager:
		print("🔺 Found dimension manager, connecting signals")
		dimension_manager.layer_changed.connect(_on_layer_changed)
		_update_for_layer(dimension_manager.get_current_layer())
	else:
		print("🔺 Warning: No dimension manager found!")

func _connect_dimension_signals():
	"""Connect dimension signals - handled in _setup_dimensions"""
	pass

func _on_layer_changed(new_layer: String):
	"""Handle layer change"""
	_update_for_layer(new_layer)

func _update_for_layer(layer: String):
	"""Update spike state based on current layer (exact PatrolEnemy logic)"""
	print("🔺 Updating for layer: ", layer, " target: ", target_layer, " both_dims: ", visible_in_both_dimensions)
	
	current_layer = layer
	
	# If visible in both dimensions, always active. Otherwise check target layer.
	is_active_in_current_layer = visible_in_both_dimensions or (layer == target_layer)
	
	print("🔺 Spike active: ", is_active_in_current_layer)
	
	# Update visibility and collision based on layer (same as PatrolEnemy)
	visible = is_active_in_current_layer
	
	# Update collision layers like PatrolEnemy  
	collision_layer = 32 if is_active_in_current_layer else 0  # Hazard layer
	collision_mask = 2 if is_active_in_current_layer else 0   # Player layer
	
	print("🔺 Set collision_layer: ", collision_layer, " collision_mask: ", collision_mask)

func _fade_to_dimension_state():
	"""Smoothly fade in/out based on layer state"""
	var target_alpha = 1.0 if is_active_in_current_layer else 0.3
	
	if spike_sprite:
		var tween = create_tween()
		tween.tween_property(spike_sprite, "modulate:a", target_alpha, dimension_transition_time)
	
	if background_rect and background_rect.visible:
		var tween2 = create_tween()
		tween2.tween_property(background_rect, "modulate:a", target_alpha, dimension_transition_time)

# Property setters for dimensions

func set_target_layer(value: String):
	target_layer = value
	if _is_spike_ready() and dimension_manager:
		_update_for_layer(current_layer)

func set_visible_in_both_dimensions(value: bool):
	visible_in_both_dimensions = value
	if _is_spike_ready() and dimension_manager:
		_update_for_layer(current_layer)

# Animation helper functions

func _get_retract_offset() -> Vector2:
	"""Get movement offset based on spike direction"""
	match spike_direction:
		Vector2.UP:
			return Vector2(0, move_distance)  # Move down when retracting
		Vector2.DOWN:
			return Vector2(0, -move_distance)  # Move up when retracting  
		Vector2.LEFT:
			return Vector2(move_distance, 0)  # Move right when retracting
		Vector2.RIGHT:
			return Vector2(-move_distance, 0)  # Move left when retracting
		_:
			return Vector2(0, move_distance)  # Default: move down
