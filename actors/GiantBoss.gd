extends CharacterBody2D
class_name GiantBoss

signal boss_defeated
signal boss_damaged(current_health: int, max_health: int)
signal tnt_placed(position: Vector2)

# Difficulty Settings
@export_enum("Easy", "Medium", "Hard") var difficulty: String = "Medium"
@export var max_health: int = 5
@export var walk_speed: float = 50.0
@export var fly_speed: float = 80.0
@export var jump_force: float = -400.0
@export var tnt_scene: PackedScene
@export var bomb_scene: PackedScene # New bomb system

@export var flying_enemy_scene: PackedScene
@export var patrol_enemy_scene: PackedScene

@export var damage_amount: int = 1

# Dimension system properties
@export var target_layer: String = "A" # For dimension system compatibility
@export var visible_in_both_dimensions: bool = true # Boss should be visible in both dimensions

# Enemy behavior configuration per phase
@export_group("Phase 1 - Walking")
@export var phase1_patrol_speed: float = 65.0
@export var phase1_patrol_jump_limit: int = 0 # No jumping in walking phase
@export var phase1_patrol_detection_range: float = 90.0
@export var phase1_spawn_limit: int = 0 # No enemies in walking phase
@export var phase1_max_tnt_crates: int = 10
@export var phase1_max_bombs: int = 5
@export var phase1_max_patrol_enemies: int = 0
@export var phase1_max_flying_enemies: int = 0

@export_group("Phase 2 - Jumping")
@export var phase2_patrol_speed: float = 75.0
@export var phase2_patrol_jump_limit: int = 3 # Limited jumping for ground enemies
@export var phase2_patrol_detection_range: float = 120.0
@export var phase2_spawn_limit: int = 2
@export var phase2_max_tnt_crates: int = 8
@export var phase2_max_bombs: int = 8
@export var phase2_max_patrol_enemies: int = 4
@export var phase2_max_flying_enemies: int = 0

@export_group("Phase 3 - Charging")
@export var phase3_patrol_speed: float = 85.0
@export var phase3_patrol_jump_limit: int = 5 # More jumping when charging
@export var phase3_patrol_detection_range: float = 150.0
@export var phase3_spawn_limit: int = 3
@export var phase3_flying_speed: float = 60.0
@export var phase3_flying_altitude_limit: float = 200.0 # How high they can fly
@export var phase3_flying_spawn_limit: int = 1
@export var phase3_max_tnt_crates: int = 6
@export var phase3_max_bombs: int = 12
@export var phase3_max_patrol_enemies: int = 6
@export var phase3_max_flying_enemies: int = 2

@export_group("Phase 4 - Flying")
@export var phase4_patrol_speed: float = 90.0
@export var phase4_patrol_jump_limit: int = 8 # Maximum ground jumping
@export var phase4_patrol_detection_range: float = 180.0
@export var phase4_spawn_limit: int = 2
@export var phase4_flying_speed: float = 80.0
@export var phase4_flying_altitude_limit: float = 300.0
@export var phase4_flying_spawn_limit: int = 3
@export var phase4_flying_chase_range: float = 250.0 # How close they stay to player
@export var phase4_max_tnt_crates: int = 4
@export var phase4_max_bombs: int = 15
@export var phase4_max_patrol_enemies: int = 4
@export var phase4_max_flying_enemies: int = 6

# Difficulty modifiers (set based on difficulty)
var difficulty_health_multiplier: float = 1.0
var difficulty_speed_multiplier: float = 1.0
var difficulty_attack_frequency: float = 1.0
var difficulty_enemy_spawn_rate: float = 1.0
var difficulty_damage_multiplier: float = 1.0

# Movement patterns for each phase
enum MovementPhase {
	WALKING,
	JUMPING,
	CHARGING,
	FLYING,
	DEFEATED
}

var current_health: int
var current_phase: MovementPhase = MovementPhase.WALKING
var direction: int = 1
var can_be_damaged: bool = true
var damage_immunity_time: float = 2.0 # 2 seconds of invincibility
var is_invincible: bool = false
var invincibility_flash_timer: float = 0.0
var invincibility_flash_interval: float = 0.1 # Flash every 0.1 seconds
var tnt_drop_timer: float = 0.0
var tnt_drop_interval: float = 3.0
# Enhanced AI variables
var enemy_spawn_timer: float = 0.0
var enemy_spawn_interval: float = 5.0

var flying_enemies_spawned: int = 0
var max_flying_enemies_per_phase: int = 2

# Current phase item counters
var current_tnt_crates_dropped: int = 0
var current_bombs_dropped: int = 0
var current_patrol_enemies_spawned: int = 0
var current_flying_enemies_spawned: int = 0

# Warning system for professional game feel
var attack_warning_timer: float = 0.0
var attack_warning_duration: float = 1.0  # 1 second warning
var is_warning_active: bool = false
var warning_ui: Control = null

# Professional game features
var attack_telegraph_indicators: Array[Node2D] = []
var combo_streak: int = 0
var enrage_visual_intensity: float = 1.0
var phase_transition_cooldown: float = 0.0

# Smart AI tracking
var player_last_position: Vector2
var player_velocity_history: Array[Vector2] = []
var predicted_player_position: Vector2
var attack_cooldown: float = 0.0
var combo_attack_count: int = 0
var is_enraged: bool = false
var defensive_mode: bool = false
var target_position: Vector2
var ai_state_timer: float = 0.0
var last_player_damage_time: float = 0.0
var consecutive_hits: int = 0

# Advanced movement
var movement_target: Vector2
var path_waypoints: Array[Vector2] = []
var current_waypoint: int = 0
var is_circling_player: bool = false
var circle_angle: float = 0.0
var terrain_knowledge: Array[Vector2] = []
var was_in_air: bool = false  # Track if boss was airborne for landing detection

# Dimension system compatibility
var dimension_manager: Node
var is_active_in_current_layer: bool = true

# Node references
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var stomp_detector: Area2D = $StompDetector
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var health_bar: ProgressBar = get_node_or_null("HealthBar")
@onready var phase_indicator: Label = get_node_or_null("PhaseIndicator")
@onready var damage_timer: Timer = $DamageTimer
@onready var tnt_timer: Timer = get_node_or_null("TNTTimer")
@onready var state_machine: Node = get_node_or_null("StateMachine")
@onready var attack_warning_timer_node: Timer = get_node_or_null("AttackWarningTimer")

# Animation and effects
@onready var hit_effect: GPUParticles2D = get_node_or_null("HitEffect")
@onready var dust_effect: GPUParticles2D = get_node_or_null("DustEffect")

func _ready():
	# Setup difficulty first
	_setup_difficulty()
	
	current_health = int(max_health * difficulty_health_multiplier)
	max_health = current_health # Update max_health for calculations
	
	_setup_connections()
	_update_health_display()
	_setup_phase(MovementPhase.WALKING)
	
	# Configure collision layers (using bit positions)
	collision_layer = 4 # Enemy layer (bit 2)
	collision_mask = 1 # World layer (bit 0) - but we'll exclude platforms
	
	# Setup platform passthrough for boss mobility
	_setup_platform_passthrough()
	
	# Setup damage area
	if damage_area:
		damage_area.collision_layer = 8 # Hazard layer (bit 3)
		damage_area.collision_mask = 2 # Player layer (bit 1)
	
	# Initialize AI
	_initialize_ai_system()
	_learn_terrain_layout()
	
	# Setup dimension system
	_setup_boss_dimensions()
	_setup_dimension_system()
	
	# Setup professional warning system connections
	if attack_warning_timer_node:
		attack_warning_timer_node.timeout.connect(_hide_attack_warning)
	
	print("🏆 GiantBoss initialized with difficulty: ", difficulty, " - Health: ", current_health)

func _setup_connections():
	stomp_detector.body_entered.connect(_on_stomp_detector_body_entered)
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	if tnt_timer:
		tnt_timer.timeout.connect(_on_tnt_timer_timeout)
	boss_damaged.connect(_on_boss_damaged)

func _physics_process(delta):
	if current_phase == MovementPhase.DEFEATED:
		return
	
	# Update invincibility system
	_update_invincibility(delta)
	
	# Update AI systems
	_update_ai_tracking(delta)
	_update_ai_state(delta)
	_handle_smart_movement(delta)
	_handle_intelligent_attacks(delta)
	_handle_enemy_spawning(delta)
	
	# Update professional game systems
	_update_enrage_effects()
	_update_phase_transition_cooldown(delta)

	_update_detectors()
	
	move_and_slide()
	
	# Check for collisions after movement
	_handle_movement_collisions()

func _setup_difficulty():
	match difficulty:
		"Easy":
			difficulty_health_multiplier = 0.6 # 60% health (3 hearts instead of 5)
			difficulty_speed_multiplier = 0.7 # 70% speed
			difficulty_attack_frequency = 0.5 # 50% attack frequency (longer intervals)
			difficulty_enemy_spawn_rate = 0.6 # 60% enemy spawn rate
			difficulty_damage_multiplier = 1.0 # Normal damage to player
			max_flying_enemies_per_phase = 1
			enemy_spawn_interval = 8.0 # Longer spawn intervals
			tnt_drop_interval = 5.0 # Longer TNT intervals
			print("⭐ Easy Mode: Reduced health, slower attacks, fewer enemies")
			
		"Medium":
			difficulty_health_multiplier = 1.0 # Normal health (5 hearts)
			difficulty_speed_multiplier = 1.0 # Normal speed
			difficulty_attack_frequency = 1.0 # Normal attack frequency
			difficulty_enemy_spawn_rate = 1.0 # Normal enemy spawn rate
			difficulty_damage_multiplier = 1.0 # Normal damage
			max_flying_enemies_per_phase = 2
			enemy_spawn_interval = 5.0
			tnt_drop_interval = 3.0
			print("⚖️ Medium Mode: Balanced experience")
			
		"Hard":
			difficulty_health_multiplier = 1.5 # 150% health (7-8 hearts)
			difficulty_speed_multiplier = 1.4 # 140% speed
			difficulty_attack_frequency = 1.8 # 180% attack frequency (faster attacks)
			difficulty_enemy_spawn_rate = 1.6 # 160% enemy spawn rate
			difficulty_damage_multiplier = 1.0 # Normal damage (could increase to 2)
			max_flying_enemies_per_phase = 4
			enemy_spawn_interval = 3.0 # Shorter spawn intervals
			tnt_drop_interval = 1.8 # Faster TNT drops
			# Additional hard mode features
			damage_amount = 2 # Double damage to player
			print("💀 Hard Mode: Increased health, faster attacks, more enemies, double damage!")
	
	# Apply speed multipliers to base values
	walk_speed *= difficulty_speed_multiplier
	fly_speed *= difficulty_speed_multiplier

func _initialize_ai_system():
	# Initialize AI variables
	player_velocity_history.clear()
	player_velocity_history.resize(10) # Track last 10 frames
	target_position = global_position
	movement_target = global_position
	print("🧠 Boss AI System Initialized")

func _learn_terrain_layout():
	# Learn about the level boundaries and platforms
	terrain_knowledge.clear()
	var space_state = get_world_2d().direct_space_state
	
	# Sample terrain points around the level
	for x in range(-600, 600, 100):
		for y in range(-200, 200, 50):
			var test_pos = global_position + Vector2(x, y)
			var query = PhysicsRayQueryParameters2D.create(test_pos, test_pos + Vector2(0, 100))
			query.collision_mask = 1 # World layer
			var result = space_state.intersect_ray(query)
			if result:
				terrain_knowledge.append(result.position)

func _update_ai_tracking(delta):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Track player movement history for prediction
	var current_player_pos = player.global_position
	if player_last_position != Vector2.ZERO:
		var player_velocity = (current_player_pos - player_last_position) / delta
		player_velocity_history.push_back(player_velocity)
		if player_velocity_history.size() > 10:
			player_velocity_history.pop_front()
	
	player_last_position = current_player_pos
	
	# Predict where player will be
	_predict_player_movement()
	
	# Update AI state timers
	ai_state_timer += delta
	attack_cooldown -= delta

func _predict_player_movement():
	if player_velocity_history.is_empty():
		predicted_player_position = player_last_position
		return
	
	# Average recent velocities for prediction
	var avg_velocity = Vector2.ZERO
	for vel in player_velocity_history:
		avg_velocity += vel
	avg_velocity /= player_velocity_history.size()
	
	# Predict position 0.5 seconds ahead
	predicted_player_position = player_last_position + (avg_velocity * 0.5)

func _update_ai_state(_delta):
	# Check for enrage conditions
	var health_ratio = float(current_health) / max_health
	is_enraged = health_ratio <= 0.4 # Enrage at 40% health
	
	# Check if player is being too aggressive (defensive mode)
	if Time.get_ticks_msec() - last_player_damage_time < 3000: # 3 seconds
		consecutive_hits += 1
		if consecutive_hits >= 2:
			defensive_mode = true
			ai_state_timer = 0.0
	else:
		consecutive_hits = 0
		if ai_state_timer > 5.0: # Exit defensive mode after 5 seconds
			defensive_mode = false

func _handle_smart_movement(delta):
	# Apply gravity for all phases except flying
	if current_phase != MovementPhase.FLYING and not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
	
	# Enhanced movement based on phase and AI state
	match current_phase:
		MovementPhase.WALKING:
			_handle_intelligent_walking(delta)
		MovementPhase.JUMPING:
			_handle_intelligent_jumping(delta)
		MovementPhase.CHARGING:
			_handle_intelligent_charging(delta)
		MovementPhase.FLYING:
			_handle_intelligent_flying(delta)

func _handle_intelligent_walking(_delta):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if defensive_mode:
		# Keep distance from player when defensive
		if distance_to_player < 200:
			direction = -sign(player.global_position.x - global_position.x)
		else:
			direction = sign(player.global_position.x - global_position.x)
	else:
		# Normal approach behavior but smarter
		var target_x = predicted_player_position.x
		direction = sign(target_x - global_position.x)
	
	# Wall and cliff detection
	if wall_detector.is_colliding() or not ground_detector.is_colliding():
		direction *= -1
		# Add small jump to avoid getting stuck
		if is_on_floor() and randf() < 0.3:
			velocity.y = jump_force * 0.5
	
	# Vary speed based on distance and state
	var speed_multiplier = 1.0
	if is_enraged:
		speed_multiplier = 1.5
	if defensive_mode:
		speed_multiplier = 0.7
	
	velocity.x = walk_speed * direction * speed_multiplier
	sprite.flip_h = direction < 0
	sprite.play("walk")
	_update_detector_positions()

func _handle_intelligent_jumping(_delta):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	var player_above = player.global_position.y < global_position.y - 50
	
	# Track if boss is airborne
	if not is_on_floor():
		was_in_air = true
	
	# Smart jumping strategy
	if player_above and distance_to_player < 150:
		# Player is above, jump more frequently to reach them
		if is_on_floor() and randf() < 0.08: # 8% chance per frame
			velocity.y = jump_force
			sprite.play("jump")
			_create_dust_effect()
			was_in_air = true
	elif distance_to_player > 300:
		# Player is far, jump to close distance
		if is_on_floor() and randf() < 0.05: # 5% chance per frame
			velocity.y = jump_force * 0.8
			sprite.play("jump")
			was_in_air = true
	elif is_on_floor() and randf() < 0.03:
		# Normal jumping
		velocity.y = jump_force * 1.2
		sprite.play("jump")
		was_in_air = true
	
	# Horizontal movement toward predicted position
	var target_x = predicted_player_position.x
	direction = sign(target_x - global_position.x)
	
	if wall_detector.is_colliding():
		direction *= -1
	
	var speed_multiplier = 1.8 if is_enraged else 1.5
	velocity.x = walk_speed * speed_multiplier * direction
	sprite.flip_h = direction < 0
	_update_detector_positions()
	
	# Landing detection with screen shake
	if is_on_floor() and was_in_air:
		sprite.play("walk")
		# Screen shake on landing during jumping phase
		if FX:
			FX.shake(100) # Strong shake intensity for boss landing
		_create_dust_effect()
		was_in_air = false  # Reset airborne state
		print("💥 Boss landed with MASSIVE impact - screen shake 200!")
	elif is_on_floor() and sprite.animation != "jump":
		sprite.play("walk")

func _handle_intelligent_charging(_delta):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Smart charging with prediction
	if distance_to_player > 100:
		# Charge toward predicted position
		var target_x = predicted_player_position.x
		direction = sign(target_x - global_position.x)
	else:
		# Too close, create some distance
		direction = -sign(player.global_position.x - global_position.x)
	
	# Enhanced wall collision response
	if wall_detector.is_colliding():
		direction *= -1
		_create_screen_shake(1.5)
		# Create screen shake on wall hit
	
	var speed_multiplier = 3.0 if is_enraged else 2.5
	if defensive_mode:
		speed_multiplier *= 0.8
	
	velocity.x = walk_speed * speed_multiplier * direction
	sprite.flip_h = direction < 0
	sprite.play("charge")
	_update_detector_positions()

func _handle_intelligent_flying(delta):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		velocity = Vector2.ZERO
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if defensive_mode:
		# Fly in circles around player when defensive
		_handle_circle_flight(player, delta)
	elif is_enraged:
		# Aggressive direct assault
		_handle_aggressive_flight(player)
	else:
		# Smart approach with evasion
		_handle_tactical_flight(player, distance_to_player)
	
	sprite.play("fly")

func _handle_circle_flight(player: Node2D, delta: float):
	var center = player.global_position
	var radius = 200.0
	circle_angle += 2.0 * delta # Circle speed
	
	var target_pos = center + Vector2(
		cos(circle_angle) * radius,
		sin(circle_angle) * radius - 50 # Slightly above player
	)
	
	var direction_to_target = (target_pos - global_position).normalized()
	velocity = direction_to_target * fly_speed * 1.2
	sprite.flip_h = direction_to_target.x < 0

func _handle_aggressive_flight(_player: Node2D):
	# Direct aggressive approach to predicted position
	var target = predicted_player_position
	var direction_to_target = (target - global_position).normalized()
	
	velocity = direction_to_target * fly_speed * 1.8
	sprite.flip_h = direction_to_target.x < 0

func _handle_tactical_flight(player: Node2D, distance: float):
	var target = predicted_player_position
	
	# Maintain optimal distance
	if distance < 100:
		# Too close, back away
		var away_direction = (global_position - player.global_position).normalized()
		velocity = away_direction * fly_speed * 0.8
	elif distance > 250:
		# Too far, approach
		var approach_direction = (target - global_position).normalized()
		velocity = approach_direction * fly_speed
	else:
		# Good distance, move parallel to player
		var player_velocity = Vector2.ZERO
		if player_velocity_history.size() > 0:
			player_velocity = player_velocity_history.back()
		
		# Move perpendicular to player movement
		var perpendicular = Vector2(-player_velocity.y, player_velocity.x).normalized()
		velocity = perpendicular * fly_speed * 0.6
	
	sprite.flip_h = velocity.x < 0

func _update_detector_positions():
	wall_detector.position.x = abs(wall_detector.position.x) * direction
	wall_detector.scale.x = direction
	ground_detector.position.x = abs(ground_detector.position.x) * direction

func _handle_walking_movement(_delta):
	# Simple walking with wall detection
	if wall_detector.is_colliding() or not ground_detector.is_colliding():
		direction *= -1
		sprite.flip_h = direction < 0
		wall_detector.scale.x = direction
		ground_detector.position.x = abs(ground_detector.position.x) * direction
	
	velocity.x = walk_speed * direction
	sprite.play("walk")

func _handle_jumping_movement(_delta):
	# Periodic jumping while moving
	if wall_detector.is_colliding():
		direction *= -1
		sprite.flip_h = direction < 0
		wall_detector.scale.x = direction
	
	velocity.x = walk_speed * 1.5 * direction
	
	# Jump periodically
	if is_on_floor() and randf() < 0.02: # 2% chance per frame
		velocity.y = jump_force
		sprite.play("jump")
		_create_dust_effect()
	elif is_on_floor():
		sprite.play("walk")

func _handle_charging_movement(_delta):
	# Fast charging with direction changes
	if wall_detector.is_colliding():
		direction *= -1
		sprite.flip_h = direction < 0
		wall_detector.scale.x = direction
		_create_screen_shake()
	
	velocity.x = walk_speed * 2.5 * direction
	sprite.play("charge")

func _handle_flying_movement(_delta):
	# Flying AI - follows player (no gravity applied)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var target_pos = player.global_position
		var direction_to_player = (target_pos - global_position).normalized()
		
		velocity = direction_to_player * fly_speed
		sprite.flip_h = direction_to_player.x < 0
	else:
		# No player found, hover in place
		velocity = Vector2.ZERO
	
	sprite.play("fly")

func _handle_intelligent_attacks(delta):
	tnt_drop_timer += delta
	attack_cooldown -= delta
	
	# Smart TNT dropping based on player position and AI state
	var adjusted_interval = tnt_drop_interval / difficulty_attack_frequency
	if tnt_drop_timer >= adjusted_interval:
		_execute_smart_tnt_attack()
		tnt_drop_timer = 0.0
		
		# Dynamic interval based on health and state
		var base_interval = 3.0 * (float(current_health) / max_health)
		if is_enraged:
			base_interval *= 0.6
		if defensive_mode:
			base_interval *= 1.5
		
		# Apply difficulty modifier
		base_interval /= difficulty_attack_frequency
		tnt_drop_interval = max(0.5, base_interval) # Minimum 0.5s for hard mode
	
	# Combo attacks when not in cooldown
	if attack_cooldown <= 0.0:
		_try_combo_attack()
	
	# Execute special combo attacks in later phases when enraged
	if is_enraged and current_phase in [MovementPhase.CHARGING, MovementPhase.FLYING]:
		if randf() < 0.02:  # 2% chance per frame when enraged
			_execute_combo_attack()

func _execute_smart_tnt_attack():
	if not tnt_scene or not is_on_floor():
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Check TNT limits
	var phase_config = _get_current_phase_config()
	var max_tnt = phase_config.get("max_tnt_crates", 999)
	
	if current_tnt_crates_dropped >= max_tnt:
		print("🚫 Smart TNT limit reached: ", current_tnt_crates_dropped, "/", max_tnt)
		return
	
	# Strategic TNT placement
	var drop_positions = _calculate_strategic_tnt_positions(player)
	
	# Limit actual drops by remaining capacity
	var can_drop = min(drop_positions.size(), max_tnt - current_tnt_crates_dropped)
	
	for i in can_drop:
		var pos = drop_positions[i]
		
		# Choose between TNT and Bomb for strategic placement
		var use_bomb = bomb_scene and randf() < 0.3 # 30% chance for bombs in strategic placement
		
		if use_bomb:
			var bomb_instance = bomb_scene.instantiate()
			get_parent().add_child(bomb_instance)
			bomb_instance.global_position = pos
			
			# Set bomb power based on phase for strategic placement
			var bomb_power = _get_bomb_power_for_phase()
			if bomb_instance.has_method("setup"):
				bomb_instance.setup(bomb_power)
				
			tnt_placed.emit(pos)
			current_tnt_crates_dropped += 1
		elif tnt_scene:
			var tnt_instance = tnt_scene.instantiate()
			tnt_instance.crate_type = "tnt"
			get_parent().add_child(tnt_instance)
			tnt_instance.global_position = pos
			tnt_placed.emit(pos)
			current_tnt_crates_dropped += 1
	
	print("💣 Smart TNT: ", can_drop, " dropped (", current_tnt_crates_dropped, "/", max_tnt, ")")
	
	# Audio feedback
	if Audio:
		Audio.play_sfx("spring")

func _calculate_strategic_tnt_positions(player: Node2D) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var player_pos = player.global_position
	
	if defensive_mode:
		# Create TNT barriers
		positions.append(global_position + Vector2(-80, 32))
		positions.append(global_position + Vector2(80, 32))
		if is_enraged:
			positions.append(global_position + Vector2(0, 32))
	else:
		# Predictive TNT placement
		positions.append(predicted_player_position + Vector2(0, 32))
		
		if is_enraged and current_phase == MovementPhase.FLYING:
			# Carpet bombing when enraged and flying
			positions.append(player_pos + Vector2(-100, 32))
			positions.append(player_pos + Vector2(100, 32))
		elif combo_attack_count > 0:
			# Multi-TNT combo
			positions.append(player_pos + Vector2(-60, 32))
			positions.append(player_pos + Vector2(60, 32))
	
	return positions

func _try_combo_attack():
	if attack_cooldown > 0.0:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var distance = global_position.distance_to(player.global_position)
	var health_ratio = float(current_health) / max_health
	
	# Different combo attacks based on phase and conditions
	if current_phase == MovementPhase.FLYING and distance < 150:
		_execute_dive_bomb_combo()
	elif current_phase == MovementPhase.CHARGING and health_ratio < 0.5:
		_execute_charge_slam_combo()
	elif is_enraged and distance > 200:
		_execute_ranged_assault_combo()

func _execute_dive_bomb_combo():
	combo_attack_count = 3
	attack_cooldown = 2.0
	
	# Dive toward player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		velocity = (player.global_position - global_position).normalized() * fly_speed * 2.0
		_create_screen_shake(0.5)
		
		# Enhanced diving effect

func _execute_charge_slam_combo():
	combo_attack_count = 2
	attack_cooldown = 3.0
	
	# Enhanced charge with ground slam effect
	velocity.x *= 1.5
	_create_screen_shake(1.0)
	
	# Spawn ground enemies on impact
	_spawn_patrol_enemy()

func _execute_ranged_assault_combo():
	combo_attack_count = 4
	attack_cooldown = 4.0
	
	# Rapid enemy spawning
	_spawn_flying_enemy()
	
	# Increase aggression temporarily
	fly_speed *= 1.3

func _drop_tnt():
	if not is_on_floor():
		return
		
	# Check TNT limit for current phase
	var phase_config = _get_current_phase_config()
	var max_tnt = phase_config.get("max_tnt_crates", 999)
	
	if current_tnt_crates_dropped >= max_tnt:
		print("🚫 TNT limit reached for current phase: ", current_tnt_crates_dropped, "/", max_tnt)
		return
	
	# Randomly choose between TNT and Bomb (60/40 chance favoring bombs)
	var use_bomb = bomb_scene and randf() < 0.6
	
	if use_bomb:
		_drop_bomb()
	elif tnt_scene:
		# Start attack warning (professional game telegraphing)
		_show_attack_warning("💥 TNT INCOMING!")
		
		# Wait for warning duration
		await get_tree().create_timer(attack_warning_duration).timeout
		
		# Double-check after delay
		if not tnt_scene or current_tnt_crates_dropped >= max_tnt:
			_hide_attack_warning()
			return
		
		var tnt_instance = tnt_scene.instantiate()
		get_parent().add_child(tnt_instance)
		
		# Wait for TNT to be ready
		await get_tree().process_frame
		
		# Set to TNT type (for InteractiveCrate)
		if "crate_type" in tnt_instance:
			tnt_instance.crate_type = "tnt"
		
		# Start TNT from boss center and throw it
		tnt_instance.global_position = global_position
		_throw_item_from_boss(tnt_instance, Vector2(direction * randf_range(60, 120), 40))
		
		# Hide warning when TNT is dropped
		_hide_attack_warning()
		
		# Increment counter
		current_tnt_crates_dropped += 1
		
		tnt_placed.emit(tnt_instance.global_position)
		
		# Audio feedback
		if Audio:
			Audio.play_sfx("spring")
		
		print("💥 Boss dropped TNT crate! (", current_tnt_crates_dropped, "/", max_tnt, ")")

func _drop_bomb():
	if not bomb_scene:
		return
	
	# Check bomb limit for current phase
	var phase_config = _get_current_phase_config()
	var max_bombs = phase_config.get("max_bombs", 999)
	
	if current_bombs_dropped >= max_bombs:
		print("🚫 Bomb limit reached for current phase: ", current_bombs_dropped, "/", max_bombs)
		return
	
	# Start attack warning (professional game telegraphing)
	_show_attack_warning("💣 BOMB INCOMING!")
	
	# Wait for warning duration, then drop bomb
	await get_tree().create_timer(attack_warning_duration).timeout
	
	# Double-check bomb scene still exists after delay
	if not bomb_scene or current_bombs_dropped >= max_bombs:
		_hide_attack_warning()
		return
		
	var bomb_instance = bomb_scene.instantiate()
	get_parent().add_child(bomb_instance)
	
	# Start bomb from boss center
	bomb_instance.global_position = global_position
	
	# Set bomb power based on phase
	var bomb_power = _get_bomb_power_for_phase()
	if bomb_instance.has_method("setup"):
		bomb_instance.setup(bomb_power)
	
	# Calculate target position and throw bomb there
	var target_offset = Vector2(direction * randf_range(80, 150), randf_range(40, 80))
	_throw_item_from_boss(bomb_instance, target_offset)
	
	# Hide warning when bomb is dropped
	_hide_attack_warning()
	
	# Increment bomb counter
	current_bombs_dropped += 1
	
	tnt_placed.emit(bomb_instance.global_position)
	
	# Audio feedback
	if Audio:
		Audio.play_sfx("whoosh")
	
	print("💣 Boss dropped ", _get_bomb_power_name(bomb_power), " bomb! (", current_bombs_dropped, "/", max_bombs, ")")

func _get_bomb_power_for_phase() -> Bomb.BombPower:
	# Get bomb power enum based on boss phase  
	match current_phase:
		MovementPhase.WALKING:
			return Bomb.BombPower.LOW
		MovementPhase.JUMPING:
			return Bomb.BombPower.LOW
		MovementPhase.CHARGING:
			return Bomb.BombPower.MEDIUM
		MovementPhase.FLYING:
			return Bomb.BombPower.HIGH
		_:
			return Bomb.BombPower.MEDIUM # Default to MEDIUM

func _get_bomb_power_name(power: Bomb.BombPower) -> String:
	match power:
		Bomb.BombPower.LOW: return "low-power"
		Bomb.BombPower.MEDIUM: return "medium-power"
		Bomb.BombPower.HIGH: return "high-power"
		_: return "unknown-power"

func _throw_item_from_boss(item: Node, target_offset: Vector2):
	if not item or not is_instance_valid(item):
		return
	
	# Calculate target position
	var target_position = global_position + target_offset
	
	# Handle RigidBody2D items (like bombs)
	if item is RigidBody2D:
		# Calculate throw velocity needed to reach target
		var distance = target_offset
		var throw_force = 300.0 # Base throwing strength
		
		# Calculate trajectory (simple parabolic throw)
		var velocity_x = distance.x * 3.0 # Horizontal component
		var velocity_y = -abs(distance.x) * 2.0 - 150.0 # Upward arc based on distance
		
		var throw_velocity = Vector2(velocity_x, velocity_y)
		item.linear_velocity = throw_velocity
		
		# Add some spin for visual effect
		if item.has_method("set_angular_velocity"):
			item.angular_velocity = randf_range(-5.0, 5.0)
		elif "angular_velocity" in item:
			item.angular_velocity = randf_range(-5.0, 5.0)
			
		print("🎯 Boss threw item with velocity: ", throw_velocity)
	
	# Handle other items (like TNT crates) with tween animation
	else:
		var throw_tween = create_tween()
		throw_tween.set_parallel(true)
		
		# Animate position with arc trajectory
		var arc_height = 60.0
		var mid_position = Vector2(
			global_position.x + target_offset.x * 0.5,
			global_position.y - arc_height
		)
		
		# Create arc motion using two tweens
		throw_tween.tween_method(_update_item_arc_position.bind(item, global_position, mid_position, target_position), 0.0, 1.0, 0.8)
		
		# Add rotation for visual effect
		throw_tween.tween_property(item, "rotation", randf_range(-2.0, 2.0), 0.8)
		
		print("🎯 Boss threw item to position: ", target_position)

func _update_item_arc_position(item: Node, start_pos: Vector2, mid_pos: Vector2, end_pos: Vector2, progress: float):
	if not is_instance_valid(item):
		return
	
	# Quadratic Bezier curve for arc trajectory
	var pos1 = start_pos.lerp(mid_pos, progress)
	var pos2 = mid_pos.lerp(end_pos, progress)
	item.global_position = pos1.lerp(pos2, progress)

# Professional attack warning system
func _show_attack_warning(warning_text: String):
	is_warning_active = true
	
	# Create warning UI if it doesn't exist
	if not warning_ui:
		warning_ui = _create_warning_ui()
	
	if warning_ui:
		warning_ui.visible = true
		var warning_label = warning_ui.get_node_or_null("WarningLabel")
		if warning_label:
			warning_label.text = warning_text
	
	# Visual warning on boss (flash red)
	var flash_tween = create_tween()
	flash_tween.set_loops(int(attack_warning_duration * 5))  # Flash 5 times per second
	flash_tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	# Audio warning
	if Audio:
		Audio.play_sfx("warning")

func _hide_attack_warning():
	is_warning_active = false
	
	if warning_ui:
		warning_ui.visible = false
	
	# Reset boss sprite color
	sprite.modulate = Color.WHITE

func _create_warning_ui() -> Control:
	# Create a simple warning overlay
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer to show above everything
	get_tree().current_scene.add_child(canvas_layer)
	
	var warning_control = Control.new()
	warning_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(warning_control)
	
	var warning_label = Label.new()
	warning_label.name = "WarningLabel"
	warning_label.text = "⚠️ WARNING!"
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warning_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	warning_label.add_theme_font_size_override("font_size", 48)
	warning_label.add_theme_color_override("font_color", Color.RED)
	warning_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	warning_label.add_theme_constant_override("shadow_offset_x", 3)
	warning_label.add_theme_constant_override("shadow_offset_y", 3)
	warning_control.add_child(warning_label)
	
	return warning_control

# Platform passthrough system for boss mobility
func _setup_platform_passthrough():
	# Use a timer to periodically add collision exceptions for platforms
	var platform_timer = Timer.new()
	platform_timer.wait_time = 0.5
	platform_timer.timeout.connect(_refresh_platform_exceptions)
	add_child(platform_timer)
	platform_timer.start()
	
	# Initial setup
	_refresh_platform_exceptions()
	
	print("🚫 Boss platform passthrough enabled - Boss can move through DynamicPlatforms")

func _refresh_platform_exceptions():
	# Find all DynamicPlatforms and add them to collision exceptions
	var platforms = get_tree().get_nodes_in_group("dynamic_platforms")
	var exceptions_added = 0
	
	for platform in platforms:
		if platform is StaticBody2D and is_instance_valid(platform):
			add_collision_exception_with(platform)
			exceptions_added += 1
	
	# Also find platforms by class type in case they're not grouped yet
	var all_nodes = get_tree().get_nodes_in_group("platforms")
	for node in all_nodes:
		if node.has_method("_set_platform_type"):  # Duck typing to identify DynamicPlatforms
			if node is StaticBody2D and is_instance_valid(node):
				add_collision_exception_with(node)
				exceptions_added += 1
	
	if exceptions_added > 0:
		print("🚫 Added ", exceptions_added, " platform collision exceptions for boss mobility")

# Professional game attack telegraphing
func _create_attack_telegraph(attack_position: Vector2, attack_type: String = "bomb"):
	var telegraph = Node2D.new()
	get_parent().add_child(telegraph)
	telegraph.global_position = attack_position
	
	# Create visual indicator
	var indicator_sprite = Sprite2D.new()
	telegraph.add_child(indicator_sprite)
	
	# Different indicators for different attack types
	match attack_type:
		"bomb":
			indicator_sprite.modulate = Color.RED
		"tnt":
			indicator_sprite.modulate = Color.ORANGE
		"charge":
			indicator_sprite.modulate = Color.YELLOW
	
	# Scale animation for telegraph
	var scale_tween = create_tween()
	scale_tween.set_loops(-1)
	scale_tween.tween_property(indicator_sprite, "scale", Vector2(1.5, 1.5), 0.5)
	scale_tween.tween_property(indicator_sprite, "scale", Vector2(1.0, 1.0), 0.5)
	
	# Store reference for cleanup
	attack_telegraph_indicators.append(telegraph)
	
	# Auto cleanup after warning duration
	get_tree().create_timer(attack_warning_duration).timeout.connect(
		func(): 
			if is_instance_valid(telegraph):
				telegraph.queue_free()
			attack_telegraph_indicators.erase(telegraph)
	)

# Advanced enrage system
func _update_enrage_effects():
	if is_enraged:
		enrage_visual_intensity = min(enrage_visual_intensity + 0.02, 2.0)
		
		# Visual enrage effects
		sprite.modulate = Color(1.0, 1.0 - (enrage_visual_intensity - 1.0) * 0.5, 1.0 - (enrage_visual_intensity - 1.0) * 0.5)
		
		# Particle effects for enrage
		if hit_effect:
			hit_effect.amount = int(50 * enrage_visual_intensity)
	else:
		enrage_visual_intensity = max(enrage_visual_intensity - 0.01, 1.0)
		sprite.modulate = Color.WHITE

# Professional combo system
func _execute_combo_attack():
	combo_streak += 1
	var combo_name = ""
	
	match combo_streak:
		1:
			combo_name = "Triple Bomb Barrage"
			_triple_bomb_attack()
		2:
			combo_name = "TNT Rain"
			_tnt_rain_attack()
		3:
			combo_name = "Devastating Blast"
			_devastating_blast_attack()
			combo_streak = 0  # Reset combo
	
	print("🔥 Boss executing combo: ", combo_name, " (streak: ", combo_streak, ")")

func _triple_bomb_attack():
	_show_attack_warning("💣💣💣 TRIPLE BOMB BARRAGE!")
	
	for i in range(3):
		var delay = i * 0.3
		get_tree().create_timer(attack_warning_duration + delay).timeout.connect(
			func(): 
				if bomb_scene:
					var bomb = bomb_scene.instantiate()
					get_parent().add_child(bomb)
					bomb.global_position = global_position + Vector2(direction * (50 + i * 30), 32)
					if bomb.has_method("setup"):
						bomb.setup(_get_bomb_power_for_phase())
					current_bombs_dropped += 1
		)

func _tnt_rain_attack():
	_show_attack_warning("💥💥 TNT RAIN INCOMING!")
	
	for i in range(4):
		var delay = i * 0.4
		get_tree().create_timer(attack_warning_duration + delay).timeout.connect(
			func():
				if tnt_scene:
					var tnt = tnt_scene.instantiate()
					get_parent().add_child(tnt)
					tnt.global_position = global_position + Vector2(randf_range(-100, 100), -100 + i * 20)
					await get_tree().process_frame
					if tnt.has_method("set_crate_type"):
						tnt.set_crate_type("tnt")
					current_tnt_crates_dropped += 1
		)

func _devastating_blast_attack():
	_show_attack_warning("🌋 DEVASTATING BLAST - TAKE COVER!")
	
	get_tree().create_timer(attack_warning_duration * 1.5).timeout.connect(
		func():
			# Screen shake
			FX.shake(300);
			
			# Multiple bombs in pattern
			var positions = [
				global_position + Vector2(-150, 32),
				global_position + Vector2(150, 32),
				global_position + Vector2(0, -50),
				global_position + Vector2(-75, 32),
				global_position + Vector2(75, 32)
			]
			
			for pos in positions:
				if bomb_scene:
					var bomb = bomb_scene.instantiate()
					get_parent().add_child(bomb)
					bomb.global_position = pos
					if bomb.has_method("setup"):
						bomb.setup(Bomb.BombPower.HIGH)
					current_bombs_dropped += 1
	)

func _update_phase_transition_cooldown(delta):
	if phase_transition_cooldown > 0:
		phase_transition_cooldown -= delta

func _handle_enemy_spawning(delta):
	enemy_spawn_timer += delta
	var spawn_interval = enemy_spawn_interval / difficulty_enemy_spawn_rate
	
	if enemy_spawn_timer >= spawn_interval:
		_spawn_enemies()
		# Also drop flying enemies in later phases
		if current_phase in [MovementPhase.CHARGING, MovementPhase.FLYING]:
			_drop_flying_enemies()
		enemy_spawn_timer = 0.0


func _spawn_enemies():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Get phase-specific configuration
	var phase_config = _get_current_phase_config()
	
	match current_phase:
		MovementPhase.WALKING:
			if phase_config.spawn_limit > 0:
				_spawn_tactical_ground_enemies(player, phase_config)
		MovementPhase.JUMPING:
			_spawn_tactical_ground_enemies(player, phase_config)
		MovementPhase.CHARGING:
			_spawn_aggressive_ground_enemies(player, phase_config)
		MovementPhase.FLYING:
			_spawn_air_support_enemies(player, phase_config)

func _get_current_phase_config() -> Dictionary:
	var config = {}
	
	match current_phase:
		MovementPhase.WALKING:
			config = {
				"patrol_speed": phase1_patrol_speed,
				"patrol_jump_limit": phase1_patrol_jump_limit,
				"detection_range": phase1_patrol_detection_range,
				"spawn_limit": phase1_spawn_limit,
				"flying_speed": 0.0,
				"altitude_limit": 0.0,
				"flying_spawn_limit": 0,
				"chase_range": 0.0,
				"max_tnt_crates": phase1_max_tnt_crates,
				"max_bombs": phase1_max_bombs,
				"max_patrol_enemies": phase1_max_patrol_enemies,
				"max_flying_enemies": phase1_max_flying_enemies
			}
		MovementPhase.JUMPING:
			config = {
				"patrol_speed": phase2_patrol_speed,
				"patrol_jump_limit": phase2_patrol_jump_limit,
				"detection_range": phase2_patrol_detection_range,
				"spawn_limit": phase2_spawn_limit,
				"flying_speed": 0.0,
				"altitude_limit": 0.0,
				"flying_spawn_limit": 0,
				"chase_range": 0.0,
				"max_tnt_crates": phase2_max_tnt_crates,
				"max_bombs": phase2_max_bombs,
				"max_patrol_enemies": phase2_max_patrol_enemies,
				"max_flying_enemies": phase2_max_flying_enemies
			}
		MovementPhase.CHARGING:
			config = {
				"patrol_speed": phase3_patrol_speed,
				"patrol_jump_limit": phase3_patrol_jump_limit,
				"detection_range": phase3_patrol_detection_range,
				"spawn_limit": phase3_spawn_limit,
				"flying_speed": phase3_flying_speed,
				"altitude_limit": phase3_flying_altitude_limit,
				"flying_spawn_limit": phase3_flying_spawn_limit,
				"chase_range": 150.0,
				"max_tnt_crates": phase3_max_tnt_crates,
				"max_bombs": phase3_max_bombs,
				"max_patrol_enemies": phase3_max_patrol_enemies,
				"max_flying_enemies": phase3_max_flying_enemies
			}
		MovementPhase.FLYING:
			config = {
				"patrol_speed": phase4_patrol_speed,
				"patrol_jump_limit": phase4_patrol_jump_limit,
				"detection_range": phase4_patrol_detection_range,
				"spawn_limit": phase4_spawn_limit,
				"flying_speed": phase4_flying_speed,
				"altitude_limit": phase4_flying_altitude_limit,
				"flying_spawn_limit": phase4_flying_spawn_limit,
				"chase_range": phase4_flying_chase_range,
				"max_tnt_crates": phase4_max_tnt_crates,
				"max_bombs": phase4_max_bombs,
				"max_patrol_enemies": phase4_max_patrol_enemies,
				"max_flying_enemies": phase4_max_flying_enemies
			}
	
	# Apply difficulty modifiers
	config.patrol_speed *= difficulty_speed_multiplier
	config.flying_speed *= difficulty_speed_multiplier
	config.spawn_limit = int(config.spawn_limit * difficulty_enemy_spawn_rate)
	config.flying_spawn_limit = int(config.flying_spawn_limit * difficulty_enemy_spawn_rate)
	
	return config

func _spawn_tactical_ground_enemies(player: Node2D, config: Dictionary = {}):
	var max_patrol = config.get("max_patrol_enemies", 999)
	if not patrol_enemy_scene or config.get("spawn_limit", 0) <= 0 or current_patrol_enemies_spawned >= max_patrol:
		if current_patrol_enemies_spawned >= max_patrol:
			print("🚫 Patrol enemy limit reached: ", current_patrol_enemies_spawned, "/", max_patrol)
		return
	
	var spawn_count = min(1, config.get("spawn_limit", 1))
	var can_spawn = min(spawn_count, max_patrol - current_patrol_enemies_spawned)
	
	for i in can_spawn:
		var patrol_instance = patrol_enemy_scene.instantiate()
		get_parent().add_child(patrol_instance)
		
		# Spawn enemies to flank player
		var player_pos = player.global_position
		var spawn_left = global_position + Vector2(-250, 0)
		var spawn_right = global_position + Vector2(250, 0)
		
		# Choose spawn position based on player location
		var spawn_pos = spawn_left if player_pos.x > global_position.x else spawn_right
		patrol_instance.global_position = spawn_pos
		
		# Configure enemy with phase-specific settings
		_configure_patrol_enemy(patrol_instance, config)
		
		# Setup dimensions
		_setup_enemy_dimensions(patrol_instance)
		
		# Increment counter
		current_patrol_enemies_spawned += 1
	
	print("🏃 Spawned ", can_spawn, " tactical patrol enemies (", current_patrol_enemies_spawned, "/", max_patrol, ")")

func _spawn_aggressive_ground_enemies(_player: Node2D, config: Dictionary = {}):
	var max_patrol = config.get("max_patrol_enemies", 999)
	if not patrol_enemy_scene or config.get("spawn_limit", 0) <= 0 or current_patrol_enemies_spawned >= max_patrol:
		if current_patrol_enemies_spawned >= max_patrol:
			print("🚫 Patrol enemy limit reached: ", current_patrol_enemies_spawned, "/", max_patrol)
		return
	
	# Spawn multiple enemies when charging
	var base_count = config.get("spawn_limit", 2)
	var spawn_count = base_count + (1 if is_enraged else 0)
	var can_spawn = min(spawn_count, max_patrol - current_patrol_enemies_spawned)
	
	for i in can_spawn:
		var patrol_instance = patrol_enemy_scene.instantiate()
		get_parent().add_child(patrol_instance)
		
		# Random spawn positions around boss
		var angle = randf() * TAU
		var distance = randf_range(150, 300)
		var spawn_offset = Vector2(cos(angle) * distance, 0)
		patrol_instance.global_position = global_position + spawn_offset
		
		# Configure enemy with phase-specific settings
		_configure_patrol_enemy(patrol_instance, config)
		
		# Setup dimensions
		_setup_enemy_dimensions(patrol_instance)
		
		# Increment counter
		current_patrol_enemies_spawned += 1
	
	print("⚡ Spawned ", can_spawn, " aggressive patrol enemies (", current_patrol_enemies_spawned, "/", max_patrol, ")")

func _spawn_air_support_enemies(player: Node2D, config: Dictionary = {}):
	var max_flying = config.get("max_flying_enemies", 999)
	if not flying_enemy_scene or current_flying_enemies_spawned >= max_flying:
		if current_flying_enemies_spawned >= max_flying:
			print("🚫 Flying enemy limit reached: ", current_flying_enemies_spawned, "/", max_flying)
		return
	
	var base_count = config.get("flying_spawn_limit", 1)
	var spawn_count = base_count + (1 if is_enraged else 0)
	var can_spawn = min(spawn_count, max_flying - current_flying_enemies_spawned)
	
	for i in can_spawn:
		var flying_instance = flying_enemy_scene.instantiate()
		get_parent().add_child(flying_instance)
		
		# Strategic air spawn positions with altitude limits
		var player_pos = player.global_position
		var altitude_limit = config.get("altitude_limit", 200.0)
		var spawn_positions = [
			player_pos + Vector2(-200, -min(150, altitude_limit)), # Left high
			player_pos + Vector2(200, -min(150, altitude_limit)), # Right high
			global_position + Vector2(0, -min(200, altitude_limit)) # Above boss
		]
		
		var spawn_pos = spawn_positions[i % spawn_positions.size()]
		flying_instance.global_position = spawn_pos
		
		# Configure enemy with phase-specific settings
		_configure_flying_enemy(flying_instance, config, i)
		
		# Setup dimensions
		_setup_enemy_dimensions(flying_instance)
		
		# Update counters
		flying_enemies_spawned += 1
		current_flying_enemies_spawned += 1
	
	print("🦅 Spawned ", can_spawn, " flying enemies (", current_flying_enemies_spawned, "/", max_flying, ")")

func _configure_patrol_enemy(patrol_instance, config: Dictionary):
	await get_tree().process_frame
	
	# Set enemy type based on phase
	var enemy_types = []
	match current_phase:
		MovementPhase.JUMPING:
			enemy_types = ["mouse", "snail"] # Fast, agile enemies
		MovementPhase.CHARGING:
			enemy_types = ["worm", "snail"] # Aggressive enemies
		_:
			enemy_types = ["mouse", "snail", "worm"]
	
	if patrol_instance.has_method("set_enemy_stats"):
		var enemy_type = enemy_types[randi() % enemy_types.size()]
		var speed = config.get("patrol_speed", 65.0)
		patrol_instance.set_enemy_stats(enemy_type, 1, speed)
	
	# Set detection range
	if "detection_range" in patrol_instance:
		patrol_instance.detection_range = config.get("detection_range", 90.0)
	
	# Set patrol distance based on phase
	if patrol_instance.has_method("set_patrol_area"):
		var patrol_distance = config.get("detection_range", 150.0)
		patrol_instance.set_patrol_area(patrol_instance.global_position, patrol_distance)
	
	print("🏃 Configured patrol enemy - Speed: ", config.get("patrol_speed", 65.0), " Jump Limit: ", config.get("patrol_jump_limit", 0))

func _configure_flying_enemy(flying_instance, config: Dictionary, index: int):
	await get_tree().process_frame
	
	# Set different behavior patterns for variety
	var behavior_patterns = [
		"Chase Player", # Direct aggressive chase
		"Sine Wave", # Wave pattern around player
		"Circular" # Circular pattern
	]
	
	var enemy_types = ["bee", "fly", "ladybug"]
	var pattern = behavior_patterns[index % behavior_patterns.size()]
	var enemy_type = enemy_types[index % enemy_types.size()]
	
	# Configure enemy properties with phase limits
	if flying_instance.has_method("set_enemy_stats"):
		var speed = config.get("flying_speed", 60.0)
		flying_instance.set_enemy_stats(enemy_type, 1, speed)
	
	if flying_instance.has_method("set_flight_pattern"):
		var altitude = config.get("altitude_limit", 200.0)
		if pattern == "Chase Player":
			flying_instance.set_flight_pattern("Chase Player", min(30.0, altitude * 0.15), 3.0)
			# Enable chase behavior with limited range
			if flying_instance.has_method("set_chase_behavior"):
				var chase_speed = min(config.get("flying_speed", 70.0), 100.0) # Cap chase speed
				flying_instance.set_chase_behavior(true, chase_speed)
		elif pattern == "Sine Wave":
			flying_instance.set_flight_pattern("Sine Wave", min(40.0, altitude * 0.2), 2.5)
		else: # Circular
			flying_instance.set_flight_pattern("Circular", min(60.0, altitude * 0.3), 1.5)
	
	# Set patrol area to limit flight range
	var player = get_tree().get_first_node_in_group("player")
	if player and flying_instance.has_method("set_patrol_area"):
		var chase_range = config.get("chase_range", 180.0)
		flying_instance.set_patrol_area(player.global_position, chase_range)
	
	print("🦅 Configured flying enemy: ", enemy_type, " Pattern: ", pattern, " Speed: ", config.get("flying_speed", 60.0), " Alt Limit: ", config.get("altitude_limit", 200.0))

func _spawn_patrol_enemy():
	var patrol_instance = patrol_enemy_scene.instantiate()
	get_parent().add_child(patrol_instance)
	
	# Spawn to left or right of boss
	var spawn_offset = Vector2(randf_range(-200, 200), 0)
	patrol_instance.global_position = global_position + spawn_offset
	
	# Set random enemy type
	var enemy_types = ["mouse", "snail", "worm"]
	if patrol_instance.has_method("set_enemy_type"):
		patrol_instance.set_enemy_type(enemy_types[randi() % enemy_types.size()])
	
	# Setup dimensions
	_setup_enemy_dimensions(patrol_instance)

func _spawn_flying_enemy():
	var flying_instance = flying_enemy_scene.instantiate()
	get_parent().add_child(flying_instance)
	
	# Spawn above the boss area
	var spawn_offset = Vector2(randf_range(-300, 300), randf_range(-200, -100))
	flying_instance.global_position = global_position + spawn_offset
	
	# Set different enemy types for variety
	var enemy_types = ["bee", "fly", "ladybug"]
	if flying_instance.has_method("set_enemy_type"):
		flying_instance.set_enemy_type(enemy_types[randi() % enemy_types.size()])
	
	# Setup dimensions
	_setup_enemy_dimensions(flying_instance)

func _drop_flying_enemies():
	# Check flying enemy limits
	var phase_config = _get_current_phase_config()
	var max_flying = phase_config.get("max_flying_enemies", 999)
	
	if not flying_enemy_scene or current_flying_enemies_spawned >= max_flying:
		if current_flying_enemies_spawned >= max_flying:
			print("🚫 Flying enemy drop limit reached: ", current_flying_enemies_spawned, "/", max_flying)
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Drop 1-3 flying enemies from above based on difficulty
	var drop_count = 1
	match difficulty:
		"Easy":
			drop_count = 1
		"Medium":
			drop_count = randi_range(1, 2)
		"Hard":
			drop_count = randi_range(2, 3)
	
	# Limit by phase maximum
	var can_drop = min(drop_count, max_flying - current_flying_enemies_spawned)
	
	print("💧 Boss dropping ", can_drop, " flying enemies (", current_flying_enemies_spawned, "/", max_flying, ")!")
	
	for i in can_drop:
		var flying_instance = flying_enemy_scene.instantiate()
		get_parent().add_child(flying_instance)
		
		# Drop close to player position but from above
		var player_pos = player.global_position
		var drop_offset = Vector2(randf_range(-100, 100), randf_range(-250, -150))
		flying_instance.global_position = player_pos + drop_offset
		
		# Configure enemy behavior after instantiation
		_configure_dropped_flying_enemy(flying_instance, i)
		
		# Create dramatic drop effect
		_create_enemy_drop_effect(flying_instance.global_position)
		
		# Increment counter
		current_flying_enemies_spawned += 1

func _configure_dropped_flying_enemy(flying_instance, index: int):
	# Get current phase configuration for dropped enemies
	var config = _get_current_phase_config()
	
	# Use the standard flying enemy configuration
	_configure_flying_enemy(flying_instance, config, index)
	
	# Make sure they work in both dimensions
	_setup_enemy_dimensions(flying_instance)
	
	print("💧 Configured dropped flying enemy with phase limits")

func _create_enemy_drop_effect(drop_position: Vector2):
	# Create multiple visual effects for dramatic impact
	if hit_effect:
		var temp_effect = hit_effect.duplicate()
		get_parent().add_child(temp_effect)
		temp_effect.global_position = drop_position
		temp_effect.emitting = true
		# Remove after effect finishes
		await get_tree().create_timer(2.0).timeout
		if temp_effect:
			temp_effect.queue_free()
	
	# Screen shake for impact
	_create_screen_shake(0.8)
	
	# Dust effect at drop location
	if dust_effect:
		var dust_copy = dust_effect.duplicate()
		get_parent().add_child(dust_copy)
		dust_copy.global_position = position + Vector2(0, 50)
		dust_copy.emitting = true
		# Clean up
		await get_tree().create_timer(1.5).timeout
		if dust_copy:
			dust_copy.queue_free()


func _setup_boss_dimensions():
	# Add to boss group for dimension system
	add_to_group("dimension_objects")
	add_to_group("bosses")
	
	print("🌍 Boss configured for both dimensions A and B")

func _setup_enemy_dimensions(enemy_instance):
	# Wait for enemy to be ready first
	await get_tree().process_frame
	
	# Configure spawned enemies for both dimensions - ALWAYS visible in both
	if enemy_instance.has_method("set_target_layer"):
		enemy_instance.set_target_layer("A")
	elif "target_layer" in enemy_instance:
		enemy_instance.target_layer = "A"
	
	# CRITICAL: Make sure enemies are visible in both dimensions
	if enemy_instance.has_method("set_visible_in_both_dimensions"):
		enemy_instance.set_visible_in_both_dimensions(true)
	elif "visible_in_both_dimensions" in enemy_instance:
		enemy_instance.visible_in_both_dimensions = true
	else:
		# Force set the property even if not exported
		enemy_instance.set("visible_in_both_dimensions", true)
	
	# Add to dimension groups
	enemy_instance.add_to_group("dimension_objects")
	
	# Force update for current dimension to ensure immediate visibility
	if enemy_instance.has_method("_update_for_layer") and dimension_manager:
		enemy_instance._update_for_layer(dimension_manager.get_current_layer())
	
	print("🌍 Enemy configured for both dimensions A and B - Type: ", enemy_instance.enemy_type if "enemy_type" in enemy_instance else "Unknown")

func _setup_spawned_enemies_dimensions():
	# Apply dimension settings to all spawned enemies
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if enemy != self: # Don't apply to boss itself
			_setup_enemy_dimensions(enemy)

func _update_detectors():
	# Update detector positions based on direction
	wall_detector.position.x = abs(wall_detector.position.x) * direction
	ground_detector.position.x = abs(ground_detector.position.x) * direction

func _on_stomp_detector_body_entered(body):
	if body.is_in_group("player") and can_be_damaged and not is_invincible:
		# Only take damage if player is above the boss (stomping from top)
		if body.global_position.y < global_position.y - 32:
			_take_damage()
			
			# Bounce player up
			if body.has_method("bounce"):
				body.bounce()
		else:
			# Player tried to damage from side/bottom during invincibility
			if is_invincible:
				print("🛡️ Boss is invincible! Cannot damage from this angle.")

func _on_damage_area_body_entered(body):
	if body.is_in_group("player"):
		# Damage player when they collide with boss body
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
		
		# Enhanced knockback based on boss movement and phase
		_apply_player_knockback(body)
		
		# Screen shake and effects
		if FX:
			FX.shake(100)
		
		print("🥊 Boss hit player - applying knockback!")
	
	# Check for TNT crate collision
	if body.is_in_group("crates"):
		_handle_crate_collision(body)

func _apply_player_knockback(player: Node2D):
	# Calculate knockback direction based on boss movement direction and position
	var push_direction = (player.global_position - global_position).normalized()
	
	# Base knockback force varies by phase
	var base_force = 300.0
	match current_phase:
		MovementPhase.WALKING:
			base_force = 350.0
		MovementPhase.JUMPING:
			base_force = 400.0
		MovementPhase.CHARGING:
			base_force = 500.0 # Stronger knockback when charging
		MovementPhase.FLYING:
			base_force = 450.0
	
	# Add boss movement velocity to knockback (if boss is moving fast, stronger knockback)
	var movement_bonus = velocity.length() * 0.3
	var total_force = base_force + movement_bonus
	
	# Apply difficulty multiplier
	total_force *= difficulty_damage_multiplier
	
	# Apply knockback based on boss direction for more realistic physics
	var boss_direction_bonus = Vector2(direction * 100, -50) # Add horizontal push in boss direction + slight upward
	var final_knockback = push_direction * total_force + boss_direction_bonus
	
	# Apply the knockback
	if player.has_method("set_velocity"):
		player.velocity += final_knockback
	elif "velocity" in player:
		player.velocity += final_knockback
	
	# Add slight screen shake based on knockback strength
	if FX:
		var shake_intensity = min(total_force / 10, 120)
		FX.shake(shake_intensity)
	
	print("💨 Applied knockback force: ", total_force, " in direction: ", push_direction)

func _handle_crate_collision(crate: Node2D):
	# Check if it's a TNT crate
	if crate.has_method("start_explosion_countdown") and "crate_type" in crate:
		if crate.crate_type == "tnt" and not crate.is_exploding:
			print("💥 Boss triggered TNT crate!")
			crate.start_explosion_countdown()
			
			# Audio feedback
			if Audio:
				Audio.play_sfx("click")
			
			# Small screen shake for impact
			if FX:
				FX.shake(60)
	
	# Check if it's a Bomb (new bomb system)
	elif crate.is_in_group("bombs") and crate.has_method("explode"):
		if not crate.has_exploded:
			print("💣 Boss triggered bomb!")
			crate.explode()
			
			# Audio feedback  
			if Audio:
				Audio.play_sfx("impact")
			
			# Small screen shake for impact
			if FX:
				FX.shake(70)
	
	# Also handle regular InteractiveCrate collision (push them around)
	elif crate.is_in_group("interactive"):
		var push_direction = (crate.global_position - global_position).normalized()
		var push_force = 200.0
		
		# If crate has physics, push it
		if crate is RigidBody2D:
			crate.apply_central_impulse(push_direction * push_force)
		elif "velocity" in crate:
			crate.velocity += push_direction * push_force

func _handle_movement_collisions():
	# Check collisions that occurred during movement using get_slide_collision
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if not collider:
			continue
		
		# Skip DynamicPlatforms - boss should pass through them
		if collider.is_in_group("dynamic_platforms") or collider.is_in_group("platforms"):
			continue
			
		# Handle TNT crate collision during movement
		if collider.is_in_group("crates"):
			_handle_crate_collision(collider)
			
		# Handle other interactive objects
		elif collider.is_in_group("interactive"):
			_handle_interactive_collision(collider)

func _handle_interactive_collision(object: Node2D):
	# Push interactive objects out of the way
	var push_direction = (object.global_position - global_position).normalized()
	var push_force = 150.0 * difficulty_damage_multiplier
	
	if object is RigidBody2D:
		object.apply_central_impulse(push_direction * push_force)
	elif "velocity" in object:
		object.velocity += push_direction * push_force
	
	print("🚧 Boss pushed interactive object: ", object.name)

func _take_damage():
	if not can_be_damaged or is_invincible:
		print("🛡️ Boss damage blocked - invincible!")
		return
	
	print("💥 Boss taking damage! Health: ", current_health - 1, "/", max_health)
	
	# Track damage for AI adaptation
	last_player_damage_time = Time.get_ticks_msec()
	consecutive_hits += 1
	
	current_health -= 1
	
	# Start invincibility period
	_start_invincibility()
	
	# Adaptive response to damage
	if consecutive_hits >= 3:
		# Boss gets angry after multiple quick hits
		is_enraged = true
		fly_speed *= 1.2
		walk_speed *= 1.2
		print("🔥 Boss is ENRAGED!")
	
	boss_damaged.emit(current_health, max_health)
	_update_health_display()
	_create_hit_effect()
	_create_screen_shake()
	
	# Smart phase advancement
	if current_health <= 0:
		_defeat_boss()
	else:
		_advance_phase_intelligently()

func _advance_phase_intelligently():
	# Smart phase transitions based on AI state
	var _player = get_tree().get_first_node_in_group("player")
	var next_phase = MovementPhase.WALKING
	
	match current_health:
		4:
			next_phase = MovementPhase.JUMPING
			print("🦘 Boss entering JUMPING phase - Watch for tactical enemy spawns!")
		3:
			next_phase = MovementPhase.CHARGING
			print("⚡ Boss entering CHARGING phase - Aggressive ground assault!")
		2:
			next_phase = MovementPhase.FLYING
			print("🦅 Boss entering FLYING phase - Air superiority mode!")
		1:
			next_phase = MovementPhase.FLYING
			# Final desperate phase
			is_enraged = true
			fly_speed *= 1.8
			walk_speed *= 1.5
			tnt_drop_interval *= 0.4
			max_flying_enemies_per_phase = 4
			print("💀 Boss entering FINAL PHASE - EXTREME DANGER!")
	
	_setup_phase(next_phase)
	
	# Reset some AI states for new phase
	combo_attack_count = 0
	attack_cooldown = 1.0
	ai_state_timer = 0.0

func _advance_phase():
	match current_health:
		4:
			_setup_phase(MovementPhase.JUMPING)
		3:
			_setup_phase(MovementPhase.CHARGING)
		2:
			_setup_phase(MovementPhase.FLYING)
		1:
			_setup_phase(MovementPhase.FLYING)
			# Increase aggression
			fly_speed *= 1.5
			tnt_drop_interval *= 0.5

func _setup_phase(phase: MovementPhase):
	current_phase = phase
	
	# Reset all counters for new phase
	flying_enemies_spawned = 0
	current_tnt_crates_dropped = 0
	current_bombs_dropped = 0
	current_patrol_enemies_spawned = 0
	current_flying_enemies_spawned = 0
	
	print("🔄 Phase reset - All item counters cleared for new phase")
	
	if phase_indicator:
		match phase:
			MovementPhase.WALKING:
				phase_indicator.text = "WALKING"
				phase_indicator.modulate = Color.WHITE
			MovementPhase.JUMPING:
				phase_indicator.text = "JUMPING"
				phase_indicator.modulate = Color.YELLOW
			MovementPhase.CHARGING:
				phase_indicator.text = "CHARGING"
				phase_indicator.modulate = Color.ORANGE
			MovementPhase.FLYING:
				phase_indicator.text = "FLYING"
				phase_indicator.modulate = Color.RED
				# Disable gravity for flying - CharacterBody2D doesn't have set_gravity_scale
				# We'll handle this in the movement function instead
			MovementPhase.DEFEATED:
				phase_indicator.text = "DEFEATED"
				phase_indicator.modulate = Color.GREEN

func _defeat_boss():
	current_phase = MovementPhase.DEFEATED
	velocity = Vector2.ZERO
	
	# End any invincibility and prevent further damage
	is_invincible = true # Permanently invincible when defeated
	can_be_damaged = false
	sprite.modulate = Color.WHITE
	sprite.modulate.a = 1.0
	
	sprite.play("defeat")
	collision_shape.set_deferred("disabled", true)
	damage_area.set_deferred("monitoring", false)
	stomp_detector.set_deferred("monitoring", false)
	
	boss_defeated.emit()
	
	# Create victory effect
	_create_screen_shake(2.0)
	
	print("💀 Boss defeated! No longer takes damage.")

func _update_health_display():
	if health_bar:
		health_bar.value = (float(current_health) / max_health) * 100
		var health_ratio = float(current_health) / max_health
		health_bar.modulate = Color.RED.lerp(Color.GREEN, health_ratio)

func _create_hit_effect():
	if hit_effect:
		hit_effect.emitting = true
	
	# Enhanced flash effect for damage
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.tween_property(sprite, "modulate", Color.YELLOW, 0.1) # Additional flash
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _create_dust_effect():
	if dust_effect:
		dust_effect.emitting = true


func _create_screen_shake(intensity: float = 1.0):
	FX.shake(intensity * 100)

func _update_invincibility(delta):
	if is_invincible:
		invincibility_flash_timer += delta
		
		# Flash effect during invincibility
		if invincibility_flash_timer >= invincibility_flash_interval:
			invincibility_flash_timer = 0.0
			# Toggle sprite transparency for flashing effect
			var current_alpha = sprite.modulate.a
			sprite.modulate.a = 0.5 if current_alpha >= 1.0 else 1.0

func _start_invincibility():
	is_invincible = true
	can_be_damaged = false
	invincibility_flash_timer = 0.0
	
	# Start the damage timer for invincibility duration
	damage_timer.start(damage_immunity_time)
	
	# Visual feedback
	sprite.modulate = Color.WHITE
	
	# Update phase indicator to show invincibility
	if phase_indicator:
		var _original_text = phase_indicator.text
		phase_indicator.text = "🛡️ INVINCIBLE"
		phase_indicator.modulate = Color.CYAN
		
		# Restore original text after invincibility
		await damage_timer.timeout
		if phase_indicator and not is_invincible: # Check if still exists and not invincible again
			_update_phase_indicator_for_current_phase()
	
	print("🛡️ Boss invincibility started for ", damage_immunity_time, " seconds")

func _on_damage_timer_timeout():
	_end_invincibility()

func _end_invincibility():
	is_invincible = false
	can_be_damaged = true
	invincibility_flash_timer = 0.0
	
	# Restore normal appearance
	sprite.modulate = Color.WHITE
	sprite.modulate.a = 1.0
	
	# Restore phase indicator
	_update_phase_indicator_for_current_phase()
	
	print("🛡️ Boss invincibility ended - can be damaged again!")

func _update_phase_indicator_for_current_phase():
	if not phase_indicator:
		return
	
	FX.shake(300)

	match current_phase:
		MovementPhase.WALKING:
			phase_indicator.text = "WALKING"
			phase_indicator.modulate = Color.WHITE
		MovementPhase.JUMPING:
			phase_indicator.text = "JUMPING"
			phase_indicator.modulate = Color.YELLOW
		MovementPhase.CHARGING:
			phase_indicator.text = "CHARGING"
			phase_indicator.modulate = Color.ORANGE
		MovementPhase.FLYING:
			phase_indicator.text = "FLYING"
			phase_indicator.modulate = Color.RED
		MovementPhase.DEFEATED:
			phase_indicator.text = "DEFEATED"
			phase_indicator.modulate = Color.GREEN

func _on_tnt_timer_timeout():
	_drop_tnt()

func _on_boss_damaged(health: int, max_hp: int):
	# Connect to EventBus for UI updates
	if EventBus:
		EventBus.boss_health_changed.emit(health, max_hp)

# Dimension system methods
func _setup_dimension_system():
	# Find dimension manager
	if not Engine.is_editor_hint():
		dimension_manager = get_node_or_null("/root/DimensionManager")
		if dimension_manager:
			# Connect to dimension changes
			if dimension_manager.has_signal("layer_changed"):
				dimension_manager.layer_changed.connect(_on_layer_changed)
			
			# Initialize with current layer
			_update_for_layer(dimension_manager.get_current_layer())
			print("🌍 Boss dimension system initialized")
		else:
			print("⚠️ DimensionManager not found - dimension system disabled")

func _on_layer_changed(new_layer: String):
	_update_for_layer(new_layer)

func _update_for_layer(current_layer: String):
	# Boss is visible in both dimensions or only in target layer
	is_active_in_current_layer = visible_in_both_dimensions or (current_layer == target_layer)
	
	# Update visibility and collision
	visible = is_active_in_current_layer
	set_collision_layer_value(3, is_active_in_current_layer) # Boss collision layer (bit 2, value 4)
	
	# Update damage area
	if damage_area:
		damage_area.monitoring = is_active_in_current_layer
		damage_area.set_collision_layer_value(4, is_active_in_current_layer) # Hazard layer (bit 3, value 8)
	
	# Update stomp detector
	if stomp_detector:
		stomp_detector.monitoring = is_active_in_current_layer
	
	print("🌍 Boss updated for layer: ", current_layer, " - Active: ", is_active_in_current_layer)
