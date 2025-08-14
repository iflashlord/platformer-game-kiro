extends CharacterBody2D
class_name Player

signal jumped
signal landed
signal died

# Movement constants - exposed for easy tweaking
@export var gravity: float = 980.0
@export var max_speed: float = 200.0
@export var acceleration: float = 800.0
@export var air_acceleration: float = 400.0
@export var friction: float = 600.0
@export var jump_velocity: float = -400.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

# Variable jump mechanics
@export var min_jump_velocity: float = -200.0
@export var apex_boost: float = 0.5

# Double jump mechanics
@export var max_jumps: int = 2
var current_jumps: int = 0
var double_jump_available: bool = false

# Internal state
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var is_jumping: bool = false
var has_jumped: bool = false

@onready var sprite: ColorRect = $PlayerSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var camera: PlayerCamera = get_node_or_null("PlayerCamera")
@onready var dust_particles: CPUParticles2D = get_node_or_null("DustParticles")
@onready var land_particles: CPUParticles2D = get_node_or_null("LandParticles")

# Visual effects
var original_sprite_scale: Vector2
var is_squashing: bool = false
var last_fall_velocity: float = 0.0

func _ready():
	print("🎮 Player _ready() called")
	
	# Add to player group for respawn system
	add_to_group("player")
	
	# Check if sprite exists
	if sprite:
		print("✅ Player sprite found")
		# Store original sprite scale for squash/stretch effects
		original_sprite_scale = sprite.scale
	else:
		print("❌ Player sprite not found!")
		original_sprite_scale = Vector2.ONE
	
	# Check other components
	print("🔍 Player components:")
	print("  Collision shape: ", collision_shape != null)
	print("  Camera: ", camera != null)
	print("  Dust particles: ", dust_particles != null)
	print("  Land particles: ", land_particles != null)
	
	# Setup dust particles
	if dust_particles:
		dust_particles.emitting = false
	if land_particles:
		land_particles.emitting = false

func _physics_process(delta):
	handle_gravity(delta)
	handle_coyote_time(delta)
	handle_jump_buffer(delta)
	handle_jump()
	handle_movement(delta)
	handle_sprite_flip()
	
	# Store previous floor state
	was_on_floor = is_on_floor()
	
	move_and_slide()
	
	# Check for landing
	if is_on_floor() and not was_on_floor:
		_handle_landing()
		landed.emit()
		has_jumped = false
		current_jumps = 0  # Reset jump count on landing
		print("Player landed")
	
	# Store fall velocity for landing impact
	if not is_on_floor():
		last_fall_velocity = velocity.y

func handle_gravity(delta):
	if not is_on_floor():
		# Apply apex boost when near the peak of jump
		if velocity.y > -50 and velocity.y < 50 and is_jumping:
			velocity.y += gravity * apex_boost * delta
		else:
			velocity.y += gravity * delta
	else:
		is_jumping = false

func handle_coyote_time(delta):
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
		if coyote_timer <= 0:
			coyote_timer = 0.0

func handle_jump_buffer(delta):
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
		print("Jump buffered - timer: ", jump_buffer_timer)
	
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
		if jump_buffer_timer <= 0:
			jump_buffer_timer = 0.0
			print("Jump buffer expired")

func handle_jump():
	# Handle jump input
	if Input.is_action_just_pressed("jump"):
		# First jump (ground or coyote time)
		if (is_on_floor() or coyote_timer > 0) and current_jumps == 0:
			perform_jump()
			coyote_timer = 0.0
		# Double jump (in air)
		elif current_jumps < max_jumps and not is_on_floor():
			perform_jump()
	
	# Execute buffered jump
	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0) and current_jumps == 0:
		perform_jump()
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
	
	# Variable jump height - release jump early for shorter jump
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y = max(velocity.y * 0.5, min_jump_velocity)
		is_jumping = false

func perform_jump():
	velocity.y = jump_velocity
	is_jumping = true
	current_jumps += 1
	jumped.emit()
	
	# Visual effects for jump
	_handle_takeoff()
	
	# Different effects for double jump
	if current_jumps == 2:
		# Double jump effects
		FX.flash_screen(Color.CYAN * 0.2, 0.1)
		Audio.play_sfx("double_jump")
		print("Player double jumped")
	else:
		Audio.play_sfx("jump")
		print("Player jumped")
	
	# Track jump in persistence
	Persistence.update_statistics("total_jumps", 1)

func handle_movement(delta):
	var input_dir = Input.get_axis("move_left", "move_right")
	var was_moving = abs(velocity.x) > 10
	
	if input_dir != 0:
		# Use different acceleration based on ground state
		var accel = acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, input_dir * max_speed, accel * delta)
		
		# Emit dust particles when running on ground
		if is_on_floor() and abs(velocity.x) > 50:
			_emit_dust_particles()
	else:
		# Apply friction only when on ground
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			
			# Stop dust when stopping
			if was_moving and abs(velocity.x) <= 10:
				_stop_dust_particles()

func handle_sprite_flip():
	#if velocity.x > 0:
		#sprite.scale.x = abs(sprite.scale.x)  # Face right
	#elif velocity.x < 0:
		#sprite.scale.x = -abs(sprite.scale.x)  # Face left
	#
	# Handle dimension flip input
	if Input.is_action_just_pressed("dimension_flip"):
		# Dimension flip with VFX
		if DimensionManager.toggle_layer():
			print("Player triggered dimension flip")
	
	# Debug shake test
	if Input.is_action_just_pressed("debug_shake"):
		FX.shake(300) # 300ms shake

func die():
	print("💀 Player.die() called")
	died.emit()
	
	# Disable player input during death sequence
	set_physics_process(false)
	
	# Track death in persistence
	if Game and Game.current_level != "":
		Persistence.increment_level_deaths(Game.current_level)
		print("📊 Death recorded for level: ", Game.current_level)
	
	# Notify health system (will handle heart loss and respawn)
	if EventBus:
		print("📡 Sending death event to HealthSystem")
		EventBus.player_died.emit(self)
	else:
		print("❌ EventBus not available!")
		return
	
	# Wait for HealthSystem to process the death
	print("⏱️ Waiting for HealthSystem to process death...")
	await get_tree().create_timer(0.2).timeout
	
	# Only respawn if still have health, otherwise HealthSystem handles game over
	if HealthSystem and HealthSystem.is_alive():
		print("💖 Still have hearts - respawning at checkpoint")
		# Re-enable physics before respawn
		set_physics_process(true)
		if Respawn:
			Respawn.respawn_player()
		else:
			print("❌ Respawn system not available!")
	else:
		print("💀 No hearts left - HealthSystem will handle game over")
		# Don't re-enable physics, let game over handle it

func _on_death_zone_entered():
	die()

# Visual Effects Functions
func _handle_landing():
	# Determine impact strength based on fall velocity
	var impact_strength = last_fall_velocity
	
	# Notify event bus
	EventBus.notify_player_landed(self, impact_strength)
	
	# Squash sprite on landing
	_squash_sprite()
	
	# Emit landing particles
	_emit_landing_particles()
	
	# Landing effects without screen shake
	if impact_strength > 300:
		EventBus.request_sfx("heavy_land", global_position)
	elif impact_strength > 150:
		EventBus.request_sfx("land", global_position)
	else:
		EventBus.request_sfx("soft_land", global_position)

func _handle_takeoff():
	# Stretch sprite on takeoff
	_stretch_sprite()
	
	# Stop dust particles
	_stop_dust_particles()
	
	# Use event bus for sound
	EventBus.request_sfx("jump", global_position)

func _squash_sprite():
	if is_squashing:
		return
	
	is_squashing = true
	var tween = create_tween()
	
	# Preserve horizontal flip direction
	var flip_sign = sign(sprite.scale.x)
	var base_scale_x = abs(original_sprite_scale.x) * flip_sign
	
	# Squash down
	tween.tween_property(sprite, "scale", Vector2(base_scale_x * 1.2, original_sprite_scale.y * 0.8), 0.1)
	# Return to normal
	tween.tween_property(sprite, "scale", Vector2(base_scale_x, original_sprite_scale.y), 0.2)
	tween.tween_callback(func(): is_squashing = false)

func _stretch_sprite():
	if is_squashing:
		return
	
	is_squashing = true
	var tween = create_tween()
	
	# Preserve horizontal flip direction
	var flip_sign = sign(sprite.scale.x)
	var base_scale_x = abs(original_sprite_scale.x) * flip_sign
	
	# Stretch up
	tween.tween_property(sprite, "scale", Vector2(base_scale_x * 0.8, original_sprite_scale.y * 1.2), 0.1)
	# Return to normal
	tween.tween_property(sprite, "scale", Vector2(base_scale_x, original_sprite_scale.y), 0.2)
	tween.tween_callback(func(): is_squashing = false)

func _emit_dust_particles():
	if dust_particles and not dust_particles.emitting:
		dust_particles.emitting = true

func _stop_dust_particles():
	if dust_particles and dust_particles.emitting:
		dust_particles.emitting = false

func _emit_landing_particles():
	if land_particles:
		land_particles.restart()
		land_particles.emitting = true
		
		# Stop after a short burst
		var timer = Timer.new()
		timer.wait_time = 0.3
		timer.one_shot = true
		add_child(timer)
		timer.start()
		timer.timeout.connect(func():
			land_particles.emitting = false
			timer.queue_free()
		)
		
	
