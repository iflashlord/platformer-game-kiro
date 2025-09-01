extends CharacterBody2D
class_name GiantBoss

signal boss_defeated
signal boss_damaged(current_health: int, max_health: int)
signal tnt_placed(position: Vector2)

@export var max_health: int = 5
@export var walk_speed: float = 50.0
@export var fly_speed: float = 80.0
@export var jump_force: float = -400.0
@export var tnt_scene: PackedScene
@export var explosion_scene: PackedScene
@export var flying_enemy_scene: PackedScene
@export var patrol_enemy_scene: PackedScene
@export var interactive_crate_scene: PackedScene
@export var damage_amount: int = 1

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
var damage_immunity_time: float = 1.0
var tnt_drop_timer: float = 0.0
var tnt_drop_interval: float = 3.0
var enemy_spawn_timer: float = 0.0
var enemy_spawn_interval: float = 5.0
var crate_drop_timer: float = 0.0
var crate_drop_interval: float = 4.0
var flying_enemies_spawned: int = 0
var max_flying_enemies_per_phase: int = 2

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
@onready var audio_player: AudioStreamPlayer2D = get_node_or_null("AudioPlayer")

# Animation and effects
@onready var hit_effect: GPUParticles2D = get_node_or_null("HitEffect")
@onready var dust_effect: GPUParticles2D = get_node_or_null("DustEffect")
@onready var screen_shake_component: Node = get_node_or_null("ScreenShakeComponent")

func _ready():
	current_health = max_health
	_setup_connections()
	_update_health_display()
	_setup_phase(MovementPhase.WALKING)
	
	# Configure collision layers (using bit positions)
	collision_layer = 4  # Enemy layer (bit 2)
	collision_mask = 1   # World layer (bit 0)
	
	# Setup damage area
	if damage_area:
		damage_area.collision_layer = 8  # Hazard layer (bit 3)
		damage_area.collision_mask = 2   # Player layer (bit 1)

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
		
	_handle_movement(delta)
	_handle_tnt_dropping(delta)
	_handle_enemy_spawning(delta)
	_handle_crate_dropping(delta)
	_update_detectors()
	
	move_and_slide()

func _handle_movement(delta):
	# Apply gravity for all phases except flying
	if current_phase != MovementPhase.FLYING and not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
	
	match current_phase:
		MovementPhase.WALKING:
			_handle_walking_movement(delta)
		MovementPhase.JUMPING:
			_handle_jumping_movement(delta)
		MovementPhase.CHARGING:
			_handle_charging_movement(delta)
		MovementPhase.FLYING:
			_handle_flying_movement(delta)

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
	if is_on_floor() and randf() < 0.02:  # 2% chance per frame
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

func _handle_tnt_dropping(delta):
	tnt_drop_timer += delta
	if tnt_drop_timer >= tnt_drop_interval:
		_drop_tnt()
		tnt_drop_timer = 0.0
		
		# Decrease interval as health decreases
		tnt_drop_interval = max(1.0, 3.0 * (float(current_health) / max_health))

func _drop_tnt():
	if tnt_scene and is_on_floor():
		var tnt_instance = tnt_scene.instantiate()
		get_parent().add_child(tnt_instance)
		tnt_instance.global_position = global_position + Vector2(0, 32)
		
		tnt_placed.emit(tnt_instance.global_position)
		if audio_player:
			audio_player.play()

func _handle_enemy_spawning(delta):
	enemy_spawn_timer += delta
	if enemy_spawn_timer >= enemy_spawn_interval:
		_spawn_enemies()
		enemy_spawn_timer = 0.0

func _handle_crate_dropping(delta):
	crate_drop_timer += delta
	if crate_drop_timer >= crate_drop_interval:
		# Random chance to drop crate in any phase
		if randf() < 0.7:  # 70% chance
			_drop_interactive_crate()
		crate_drop_timer = 0.0

func _spawn_enemies():
	match current_phase:
		MovementPhase.JUMPING:
			# Spawn ground patrol enemies
			if patrol_enemy_scene:
				_spawn_patrol_enemy()
		MovementPhase.CHARGING:
			# Spawn more patrol enemies
			if patrol_enemy_scene:
				_spawn_patrol_enemy()
		MovementPhase.FLYING:
			# Spawn flying enemies (2 different types per phase)
			if flying_enemy_scene and flying_enemies_spawned < max_flying_enemies_per_phase:
				_spawn_flying_enemy()
				flying_enemies_spawned += 1

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

func _drop_interactive_crate():
	if interactive_crate_scene:
		var crate_instance = interactive_crate_scene.instantiate()
		get_parent().add_child(crate_instance)
		
		# Set crate type to TNT
		if crate_instance.has_method("set_crate_type"):
			crate_instance.set_crate_type("tnt")
		else:
			crate_instance.crate_type = "tnt"
		
		# Drop crate near boss
		var drop_offset = Vector2(randf_range(-100, 100), -50)
		crate_instance.global_position = global_position + drop_offset

func _update_detectors():
	# Update detector positions based on direction
	wall_detector.position.x = abs(wall_detector.position.x) * direction
	ground_detector.position.x = abs(ground_detector.position.x) * direction

func _on_stomp_detector_body_entered(body):
	if body.is_in_group("player") and can_be_damaged:
		# Only take damage if player is above the boss (stomping from top)
		if body.global_position.y < global_position.y - 32:
			_take_damage()
			
			# Bounce player up
			if body.has_method("bounce"):
				body.bounce()

func _on_damage_area_body_entered(body):
	if body.is_in_group("player"):
		# Damage player when they collide with boss body
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
		
		# Push player away from boss by modifying their velocity directly
		var push_direction = (body.global_position - global_position).normalized()
		var push_force = 300.0
		body.velocity += push_direction * push_force

func _take_damage():
	if not can_be_damaged:
		return
		
	current_health -= 1
	can_be_damaged = false
	damage_timer.start(damage_immunity_time)
	
	boss_damaged.emit(current_health, max_health)
	_update_health_display()
	_create_hit_effect()
	_create_screen_shake()
	
	if current_health <= 0:
		_defeat_boss()
	else:
		_advance_phase()

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
	
	# Reset enemy spawn counter for new phase
	flying_enemies_spawned = 0
	
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
	sprite.play("defeat")
	collision_shape.set_deferred("disabled", true)
	damage_area.set_deferred("monitoring", false)
	
	boss_defeated.emit()
	
	# Create victory effect
	_create_explosion_effect()
	_create_screen_shake(2.0)

func _update_health_display():
	if health_bar:
		health_bar.value = (float(current_health) / max_health) * 100
		var health_ratio = float(current_health) / max_health
		health_bar.modulate = Color.RED.lerp(Color.GREEN, health_ratio)

func _create_hit_effect():
	if hit_effect:
		hit_effect.emitting = true
	
	# Flash effect
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _create_dust_effect():
	if dust_effect:
		dust_effect.emitting = true

func _create_explosion_effect():
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_parent().add_child(explosion)
		explosion.global_position = global_position

func _create_screen_shake(intensity: float = 1.0):
	if screen_shake_component:
		screen_shake_component.shake(intensity)

func _on_damage_timer_timeout():
	can_be_damaged = true

func _on_tnt_timer_timeout():
	_drop_tnt()

func _on_boss_damaged(health: int, max_hp: int):
	# Connect to EventBus for UI updates
	if EventBus:
		EventBus.boss_health_changed.emit(health, max_hp)
