extends CharacterBody2D
class_name FlyingEnemy

signal enemy_defeated(enemy: FlyingEnemy, points: int)
signal enemy_stomped(enemy: FlyingEnemy, player: Node2D, points: int)
signal player_detected(enemy: FlyingEnemy, player: Node2D)
signal player_damaged(enemy: FlyingEnemy, player: Node2D, damage: int)

@export var enemy_type: String = "bee"
@export var flight_speed: float = 80.0
@export var damage_amount: int = 1
@export var points_value: int = 200
@export var health: int = 1
@export var detection_range: float = 120.0

# Flight pattern settings
@export_enum("Horizontal", "Sine Wave", "Circular", "Chase Player", "Vertical") var flight_pattern: String = "Horizontal"
@export var pattern_amplitude: float = 50.0  # For sine wave and circular patterns
@export var pattern_frequency: float = 2.0   # Speed of pattern oscillation
@export var patrol_distance: float = 300.0   # Distance to travel before turning around

# AI Enhancement settings
@export_group("AI Behavior")
@export var pathfinding_attempts: int = 3  # Maximum pathfinding attempts before fallback
@export var obstacle_avoidance_sensitivity: float = 32.0  # Detection range for obstacles
@export var chase_detection_radius_multiplier: float = 5.0  # Multiplier for chase detection radius
@export var patrol_speed: float = 80.0  # Speed during patrol mode
@export var ai_update_frequency: float = 30.0  # AI update frequency in FPS
@export_group("Dimension")
@export var target_layer: String = "A"  # For dimension system compatibility
@export var visible_in_both_dimensions: bool = false  # Show in both dimensions A and B

var start_position: Vector2
var direction: int = 1
var is_alive: bool = true
var current_health: int
var damage_cooldown: float = 0.0
var damage_cooldown_time: float = 0.5
var time_elapsed: float = 0.0
var player_target: Node2D = null
var chase_speed: float = 100.0
var turn_around_cooldown: float = 0.0
var turn_around_cooldown_time: float = 0.2

# Dimension system compatibility
var dimension_manager: Node
var is_active_in_current_layer: bool = true

@onready var label: Label = $EnemyLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_collision: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var damage_collision: CollisionShape2D = $DamageArea/CollisionShape2D
@onready var enemy_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("enemies")
	add_to_group("flying_enemies")
	
	start_position = global_position
	current_health = health
	
	# Set appearance based on enemy type
	setup_enemy_appearance()
	
	# Set initial sprite direction
	update_sprite_direction()
	
	# Setup detection area
	setup_detection_area()
	
	# Connect detection signals
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
	
	# Connect damage signals
	if damage_area:
		damage_area.body_entered.connect(_on_damage_area_entered)
		damage_area.body_exited.connect(_on_damage_area_exited)
	
	if ErrorHandler:
		ErrorHandler.debug("Flying enemy initialized: " + enemy_type + " at " + str(global_position))
	
	# Setup dimension system
	if not Engine.is_editor_hint():
		_setup_dimension_system()

func _physics_process(delta):
	if not is_alive:
		return
	
	# Update damage cooldown
	if damage_cooldown > 0:
		damage_cooldown -= delta
	
	# Update turn around cooldown
	if turn_around_cooldown > 0:
		turn_around_cooldown -= delta
	
	time_elapsed += delta
	
	# Calculate movement based on flight pattern
	match flight_pattern:
		"Horizontal":
			_move_horizontal(delta)
		"Sine Wave":
			_move_sine_wave(delta)
		"Circular":
			_move_circular(delta)
		"Chase Player":
			_move_chase_player(delta)
		"Vertical":
			_move_vertical(delta)
	
	# Apply movement (no gravity for flying enemies)
	move_and_slide()

func _move_horizontal(delta):
	"""Simple horizontal movement with turning at boundaries"""
	velocity.x = flight_speed * direction
	velocity.y = 0
	
	# Check if we've traveled too far from start position and are still moving away
	var distance_from_start = abs(global_position.x - start_position.x)
	if distance_from_start > patrol_distance and turn_around_cooldown <= 0:
		# Only turn around if we're moving away from start position
		var moving_away_from_start = (global_position.x - start_position.x) * direction > 0
		if moving_away_from_start:
			turn_around()

func _move_sine_wave(delta):
	"""Sine wave flight pattern"""
	velocity.x = flight_speed * direction
	
	# Calculate sine wave for vertical movement
	var sine_offset = sin(time_elapsed * pattern_frequency) * pattern_amplitude
	var target_y = start_position.y + sine_offset
	
	# Smooth movement towards target Y position
	var y_diff = target_y - global_position.y
	velocity.y = y_diff * 2.0  # Adjust multiplier for responsiveness
	
	# Check horizontal boundaries
	var distance_from_start = abs(global_position.x - start_position.x)
	if distance_from_start > patrol_distance and turn_around_cooldown <= 0:
		# Only turn around if we're moving away from start position
		var moving_away_from_start = (global_position.x - start_position.x) * direction > 0
		if moving_away_from_start:
			turn_around()

func _move_circular(delta):
	"""Circular flight pattern"""
	var angle = time_elapsed * pattern_frequency
	var target_x = start_position.x + cos(angle) * pattern_amplitude
	var target_y = start_position.y + sin(angle) * pattern_amplitude * 0.5  # Elliptical
	
	# Move towards target position
	var target_pos = Vector2(target_x, target_y)
	var direction_to_target = (target_pos - global_position).normalized()
	velocity = direction_to_target * flight_speed

func _move_chase_player(delta):
	"""Chase the player when detected, otherwise patrol horizontally"""
	if player_target and is_instance_valid(player_target):
		# Chase the player
		var direction_to_player = (player_target.global_position - global_position).normalized()
		velocity = direction_to_player * chase_speed
		
		# Face the player
		if direction_to_player.x > 0:
			direction = 1
		else:
			direction = -1
		update_sprite_direction()
	else:
		# Default to horizontal patrol
		_move_horizontal(delta)

func _move_vertical(delta):
	"""Vertical movement pattern"""
	velocity.x = 0
	velocity.y = flight_speed * direction
	
	# Check if we've traveled too far from start position and are still moving away
	var distance_from_start = abs(global_position.y - start_position.y)
	if distance_from_start > patrol_distance and turn_around_cooldown <= 0:
		# Only turn around if we're moving away from start position
		var moving_away_from_start = (global_position.y - start_position.y) * direction > 0
		if moving_away_from_start:
			turn_around()

func setup_enemy_appearance():
	"""Setup enemy appearance and stats based on type"""
	match enemy_type:
		"bee":
			enemy_sprite.play("bee")
			flight_speed = 70.0
			points_value = 200
			damage_amount = 1
			enemy_sprite.modulate = Color.YELLOW
		"fly":
			enemy_sprite.play("fly")
			flight_speed = 120.0
			points_value = 150
			damage_amount = 1
			enemy_sprite.modulate = Color.WHITE
		"ladybug_fly":
			enemy_sprite.play("ladybug_fly")
			flight_speed = 70.0
			points_value = 250
			damage_amount = 1
			enemy_sprite.modulate = Color.RED
		"bat":
			# Use fly animation for bat (could add custom bat sprites later)
			enemy_sprite.play("fly")
			flight_speed = 100.0
			points_value = 300
			damage_amount = 1
			enemy_sprite.modulate = Color(0.3, 0.3, 0.3)  # Dark gray
		"wasp":
			enemy_sprite.play("bee")
			flight_speed = 110.0
			points_value = 350
			damage_amount = 2
			enemy_sprite.modulate = Color(1.0, 0.5, 0.0)  # Orange
		_:
			enemy_sprite.play("bee")
			flight_speed = 80.0
			points_value = 200
			damage_amount = 1

func setup_detection_area():
	"""Setup detection area for player detection"""
	if not detection_area:
		return
	
	# Create larger detection area for flying enemies
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(detection_range, detection_range)
	detection_collision.shape = rect_shape
	
	# Set collision layers for detection
	detection_area.collision_layer = 0
	detection_area.collision_mask = 2  # Player layer

func turn_around():
	"""Turn around and flip sprite"""
	direction *= -1
	turn_around_cooldown = turn_around_cooldown_time
	update_sprite_direction()
	
	if ErrorHandler:
		ErrorHandler.debug(enemy_type.capitalize() + " flying enemy turned around")

func update_sprite_direction():
	"""Update sprite direction based on movement"""
	if direction > 0:
		enemy_sprite.scale.x = -abs(enemy_sprite.scale.x)
	else:
		enemy_sprite.scale.x = abs(enemy_sprite.scale.x)

func _on_detection_area_entered(body):
	"""Handle player detection"""
	if body.is_in_group("player") and is_alive:
		player_target = body
		player_detected.emit(self, body)
		if ErrorHandler:
			ErrorHandler.debug(enemy_type.capitalize() + " flying enemy detected player")

func _on_detection_area_exited(body):
	"""Handle player leaving detection area"""
	if body.is_in_group("player") and is_alive:
		if flight_pattern != "Chase Player":
			player_target = null
		if ErrorHandler:
			ErrorHandler.debug(enemy_type.capitalize() + " flying enemy lost sight of player")

func _on_damage_area_entered(body):
	"""Handle damage collision with player"""
	if not body.is_in_group("player") or not is_alive:
		return
	
	# Check damage cooldown
	if damage_cooldown > 0:
		return
	
	if ErrorHandler:
		ErrorHandler.debug("Flying enemy damage collision with: " + body.name)
	
	var player_velocity = body.velocity if "velocity" in body else Vector2.ZERO
	
	# Check if this is a stomp (player above enemy and falling down)
	var player_above_enemy = body.global_position.y < global_position.y - 8
	var player_falling = player_velocity.y > 50
	
	if player_above_enemy and player_falling:
		# Player stomped the flying enemy
		take_damage(1, true)
		# Bounce player upward
		if "velocity" in body:
			body.velocity.y = -400
		if "is_jumping" in body:
			body.is_jumping = true
	else:
		# Flying enemy damages player
		damage_player_with_pushback(body)
		damage_cooldown = damage_cooldown_time

func _on_damage_area_exited(body):
	"""Handle player leaving damage area"""
	if body.is_in_group("player"):
		# Reset any visual effects
		setup_enemy_appearance()

func damage_player_with_pushback(player):
	"""Damage the player and apply pushback"""
	if not is_alive:
		return
	
	# Calculate pushback direction (away from flying enemy)
	var pushback_force = 250.0
	var direction_to_player = (player.global_position - global_position).normalized()
	var pushback_direction = Vector2(direction_to_player.x, -0.4)  # Push away + upward
	
	# Apply pushback to player
	if "velocity" in player:
		player.velocity.x = pushback_direction.x * pushback_force
		player.velocity.y = pushback_direction.y * pushback_force
	
	# Damage the player
	if player.has_method("take_damage"):
		player.take_damage(damage_amount)
	elif HealthSystem and HealthSystem.has_method("lose_heart"):
		HealthSystem.lose_heart()
	
	# Emit signal
	player_damaged.emit(self, player, damage_amount)
	
	# Visual feedback
	create_damage_effect()

func create_damage_effect():
	"""Create visual feedback for damage"""
	# Screen flash
	if FX and FX.has_method("flash_screen"):
		FX.flash_screen(Color.RED, 0.15)
	
	# Screen shake
	if FX and FX.has_method("shake"):
		FX.shake(8)

func take_damage(amount: int = 1, from_stomp: bool = false):
	"""Take damage and handle death"""
	if not is_alive:
		return
	
	current_health -= amount
	
	# Visual feedback for taking damage
	enemy_sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(enemy_sprite, "modulate", Color.WHITE, 0.2)
	tween.tween_callback(setup_enemy_appearance)  # Restore original color
	
	if ErrorHandler:
		if from_stomp:
			ErrorHandler.debug(enemy_type.capitalize() + " flying enemy stomped! (" + str(current_health) + "/" + str(health) + " HP)")
		else:
			ErrorHandler.debug(enemy_type.capitalize() + " flying enemy took " + str(amount) + " damage (" + str(current_health) + "/" + str(health) + " HP)")
	
	if current_health <= 0:
		defeat(from_stomp)

func defeat(from_stomp: bool = false):
	"""Handle enemy defeat"""
	if not is_alive:
		return
	
	is_alive = false
	
	# Audio feedback
	if Audio:
		Audio.play_sfx("enemy_hurt")
	
	# Screen shake
	if FX and FX.has_method("shake"):
		FX.shake(80)
	
	# Add score
	if Game:
		Game.add_score(points_value)
	
	# Emit appropriate signal
	if from_stomp:
		enemy_stomped.emit(self, null, points_value)
		if ErrorHandler:
			ErrorHandler.debug(enemy_type.capitalize() + " flying enemy stomped! +" + str(points_value) + " points")
	else:
		enemy_defeated.emit(self, points_value)
		if ErrorHandler:
			ErrorHandler.debug(enemy_type.capitalize() + " flying enemy defeated! +" + str(points_value) + " points")
	
	# Create defeat effect
	create_defeat_effect(from_stomp)

func create_defeat_effect(from_stomp: bool = false):
	"""Create visual effect for enemy defeat"""
	# Disable collision
	collision_shape.set_deferred("disabled", true)
	if detection_area:
		detection_collision.set_deferred("disabled", true)
	if damage_area:
		damage_collision.set_deferred("disabled", true)
	
	# Create floating text effect
	var effect_label = Label.new()
	effect_label.text = "+" + str(points_value)
	effect_label.add_theme_font_size_override("font_size", 16)
	
	# Different colors for stomp vs regular defeat
	if from_stomp:
		effect_label.add_theme_color_override("font_color", Color.ORANGE)
		effect_label.text = "STOMP! +" + str(points_value)
	else:
		effect_label.add_theme_color_override("font_color", Color.CYAN)
		effect_label.text = "FLY DOWN! +" + str(points_value)
	
	effect_label.position = global_position + Vector2(-40, -40)
	get_tree().current_scene.add_child(effect_label)
	
	# Animate the effect
	var scene_tween = get_tree().create_tween()
	scene_tween.parallel().tween_property(effect_label, "position", effect_label.position + Vector2(0, -60), 1.2)
	scene_tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.2)
	scene_tween.tween_callback(func(): 
		if is_instance_valid(effect_label):
			effect_label.queue_free()
	)
	
	# Death animation - flying enemies fall down
	var death_tween = create_tween()
	if from_stomp:
		# Squash and fall for stomp
		death_tween.parallel().tween_property(self, "scale", Vector2(1.3, 0.4), 0.3)
		death_tween.parallel().tween_property(self, "rotation", PI * 2, 0.8)
		death_tween.parallel().tween_property(self, "position", global_position + Vector2(0, 100), 0.8)
		death_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)
	else:
		# Spin and fall
		death_tween.parallel().tween_property(self, "rotation", PI * 4, 1.0)
		death_tween.parallel().tween_property(self, "position", global_position + Vector2(0, 150), 1.0)
		death_tween.parallel().tween_property(self, "modulate:a", 0.0, 1.0)
	
	death_tween.tween_callback(queue_free)

# Utility functions for level designers
func set_flight_pattern(pattern: String, amplitude: float = 50.0, frequency: float = 2.0):
	"""Set the flight pattern for this enemy"""
	flight_pattern = pattern
	pattern_amplitude = amplitude
	pattern_frequency = frequency

func set_patrol_area(center: Vector2, distance: float):
	"""Set the patrol area for this flying enemy"""
	start_position = center
	patrol_distance = distance
	global_position = center

func set_enemy_stats(new_type: String, new_health: int = 1, new_speed: float = 80.0):
	"""Set enemy type and stats"""
	enemy_type = new_type
	health = new_health
	current_health = new_health
	flight_speed = new_speed
	setup_enemy_appearance()

func set_chase_behavior(enable_chase: bool, chase_spd: float = 100.0):
	"""Enable or disable chase behavior"""
	if enable_chase:
		flight_pattern = "Chase Player"
		chase_speed = chase_spd
	else:
		flight_pattern = "Horizontal"

# Dimension system methods
func _setup_dimension_system():
	# Only setup dimension system at runtime
	if Engine.is_editor_hint():
		return
		
	# Find dimension manager
	dimension_manager = get_tree().get_first_node_in_group("dimension_managers")
	if not dimension_manager and has_node("/root/DimensionManager"):
		dimension_manager = get_node("/root/DimensionManager")
	
	if dimension_manager:
		dimension_manager.layer_changed.connect(_on_layer_changed)
		_update_for_layer(dimension_manager.get_current_layer())

func _on_layer_changed(new_layer: String):
	_update_for_layer(new_layer)

func _update_for_layer(current_layer: String):
	# If visible in both dimensions, always active. Otherwise check target layer.
	is_active_in_current_layer = visible_in_both_dimensions or (current_layer == target_layer)
	
	# Update visibility and collision based on layer
	visible = is_active_in_current_layer
	collision_layer = 4 if is_active_in_current_layer else 0  # Enemy layer is 4
	collision_mask = 1 if is_active_in_current_layer else 0   # Collide with world layer 1
	
	# Also update detection and damage areas
	if detection_area:
		detection_area.collision_layer = 32 if is_active_in_current_layer else 0
		detection_area.collision_mask = 2 if is_active_in_current_layer else 0
	if damage_area:
		damage_area.collision_layer = 8 if is_active_in_current_layer else 0
		damage_area.collision_mask = 2 if is_active_in_current_layer else 0
