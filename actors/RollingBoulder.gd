extends RigidBody2D
class_name RollingBoulder

# Signals
signal player_crushed(player: Player)
signal boulder_destroyed
signal boulder_bounced
signal enemy_crushed

# Physics Properties
@export_group("Physics")
@export var roll_speed: float = 100.0
@export var boulder_radius: float = 16.0
@export var boulder_mass: float = 10.0
@export var friction_coefficient: float = 0.1
@export var bounce_force: float = 200.0
@export var gravity_scale_override: float = 1.0

# Movement Properties
@export_group("Movement")
@export var auto_scroll_speed: float = 50.0
@export var maintain_speed: bool = true
@export var speed_variance: float = 0.8
@export var can_change_direction: bool = false

# Behavior Properties
@export_group("Behavior")
@export var damage: int = 1
@export var destroy_on_wall: bool = true
@export var max_lifetime: float = 30.0
@export var crush_enemies: bool = true
@export var break_destructibles: bool = true
@export var can_be_pushed: bool = false

# Visual Properties
@export_group("Visual")
@export var boulder_color: Color = Color(0.6, 0.4, 0.2, 1)
@export var show_dust_trail: bool = true
@export var dust_intensity: float = 1.0
@export var rotation_multiplier: float = 1.0

# Audio Properties
@export_group("Audio")
@export var rolling_sound: String = "boulder_roll"
@export var crush_sound: String = "boulder_crush"
@export var destroy_sound: String = "boulder_destroy"
@export var bounce_sound: String = "boulder_bounce"

# Effects Properties
@export_group("Effects")
@export var screen_shake_on_crush: bool = true
@export var screen_flash_on_crush: bool = true
@export var hit_stop_duration: int = 150

# Internal state
var lifetime_timer: float = 0.0
var is_rolling: bool = true
var roll_direction: int = 1
var accumulated_rotation: float = 0.0
var wall_check_timer: float = 0.0
var last_velocity: Vector2 = Vector2.ZERO
var is_playing_rolling_sound: bool = false

# Node references
@onready var boulder_sprite: ColorRect = $BoulderSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var damage_collision: CollisionShape2D = $DamageArea/CollisionShape2D
@onready var dimension_node: DimensionNode = $DimensionNode
@onready var dust_particles: CPUParticles2D = $DustParticles
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Setup physics
	mass = boulder_mass
	gravity_scale = gravity_scale_override
	if not can_be_pushed:
		lock_rotation = false
		freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	
	# Add to groups
	add_to_group("hazards")
	add_to_group("boulders")
	add_to_group("rolling_objects")
	
	# Connect signals
	if damage_area:
		damage_area.body_entered.connect(_on_player_entered)
		damage_area.area_entered.connect(_on_area_entered)
	
	# Connect collision detection
	body_entered.connect(_on_body_collision)
	
	# Setup appearance
	setup_boulder_appearance()
	setup_collision_size()
	
	# Set initial velocity
	linear_velocity.x = roll_speed * roll_direction
	last_velocity = linear_velocity
	
	# Start animations and effects
	start_rolling_effects()
	
	print("Boulder spawned with speed: ", roll_speed, " direction: ", roll_direction)

func _physics_process(delta):
	lifetime_timer += delta
	wall_check_timer += delta
	
	# Auto-scroll movement
	if auto_scroll_speed != 0.0:
		global_position.x += auto_scroll_speed * delta
	
	# Maintain rolling speed if enabled
	if is_rolling and maintain_speed:
		var min_speed = roll_speed * speed_variance
		if abs(linear_velocity.x) < min_speed:
			linear_velocity.x = roll_speed * roll_direction
			_play_sound(rolling_sound)
	
	# Physics-accurate sprite rotation based on rolling motion
	update_boulder_rotation(delta)
	
	# Update sound effects
	update_rolling_sound()
	
	# Periodic wall checking (optimization)
	if destroy_on_wall and wall_check_timer >= 0.1:
		wall_check_timer = 0.0
		if is_colliding_with_wall():
			destroy_boulder()
	
	# Update dust particles based on speed
	update_dust_effects()
	
	# Check for direction change
	if can_change_direction:
		check_direction_change()
	
	# Store velocity for next frame
	last_velocity = linear_velocity
	
	# Destroy after max lifetime
	if lifetime_timer >= max_lifetime:
		destroy_boulder()

func _on_player_entered(body):
	if body is Player and is_rolling:
		crush_player(body)

func _on_area_entered(area):
	# Handle player attacks or projectiles
	var parent = area.get_parent()
	if parent and parent.is_in_group("player_attacks"):
		_handle_player_attack(parent)

func _on_body_collision(body):
	if not is_rolling:
		return
		
	if body is Player:
		crush_player(body)
	elif crush_enemies and body.is_in_group("enemies"):
		crush_enemy(body)
	elif break_destructibles and (body.is_in_group("crates") or body.is_in_group("destructibles")):
		break_destructible(body)
	elif body.is_in_group("walls") or body.is_in_group("terrain"):
		handle_wall_collision(body)

func crush_player(player: Player):
	player_crushed.emit(player)
	_play_sound(crush_sound)
	
	# Damage the player
	if player.has_method("take_damage"):
		player.take_damage(damage)
	elif player.has_method("die"):
		player.die()
	
	# Apply knockback
	if bounce_force > 0:
		var bounce_dir = (player.global_position - global_position).normalized()
		if player.has_method("apply_knockback"):
			player.apply_knockback(bounce_dir * bounce_force)
		elif player.has_method("velocity"):
			player.velocity += bounce_dir * bounce_force
	
	# Visual effects
	_play_crush_effects()
	
	print("Boulder crushed player!")

func crush_enemy(enemy):
	enemy_crushed.emit()
	_play_sound(crush_sound)
	
	# Instant kill enemies
	if enemy.has_method("take_damage"):
		enemy.take_damage(999)
	elif enemy.has_method("die"):
		enemy.die()
	
	_play_crush_effects()
	print("Boulder crushed enemy!")

func break_destructible(destructible):
	_play_sound(bounce_sound)
	
	# Break the destructible object
	if destructible.has_method("break_crate"):
		destructible.break_crate()
	elif destructible.has_method("destroy"):
		destructible.destroy()
	elif destructible.has_method("take_damage"):
		destructible.take_damage(999)
	
	# Small bounce effect
	boulder_bounced.emit()
	print("Boulder destroyed object!")

func is_colliding_with_wall() -> bool:
	# Check if boulder is stuck against a wall
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.new()
	query.from = global_position
	query.to = global_position + Vector2(roll_direction * 40, 0)
	query.collision_mask = 1 # Ground layer
	
	var result = space_state.intersect_ray(query)
	return result.size() > 0

func destroy_boulder():
	if not is_rolling:
		return
	
	is_rolling = false
	boulder_destroyed.emit()
	
	# Stop movement
	linear_velocity = Vector2.ZERO
	
	# Visual effects
	FX.shake(100)
	
	# Explosion particles
	if dust_particles:
		dust_particles.amount = 50
		dust_particles.emitting = true
	
	# Destruction animation
	if animation_player:
		animation_player.play("destroy")
	
	# Disable collision
	collision_shape.disabled = true
	if damage_area:
		damage_area.get_child(0).disabled = true
	
	# Remove after animation
	await get_tree().create_timer(1.0).timeout
	queue_free()

func set_roll_direction(direction: int):
	roll_direction = direction
	linear_velocity.x = roll_speed * roll_direction

func set_auto_scroll_speed(speed: float):
	auto_scroll_speed = speed

func boost_speed(multiplier: float):
	roll_speed *= multiplier
	linear_velocity.x = roll_speed * roll_direction

# New helper functions

func setup_boulder_appearance():
	"""Setup boulder visual appearance"""
	if boulder_sprite:
		boulder_sprite.color = boulder_color
		boulder_sprite.size = Vector2(boulder_radius * 2, boulder_radius * 2)
		boulder_sprite.position = Vector2(-boulder_radius, -boulder_radius)

func setup_collision_size():
	"""Setup collision shapes based on boulder radius"""
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = boulder_radius
	elif collision_shape and collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = Vector2(boulder_radius * 2, boulder_radius * 2)
	
	if damage_collision and damage_collision.shape is CircleShape2D:
		damage_collision.shape.radius = boulder_radius + 2
	elif damage_collision and damage_collision.shape is RectangleShape2D:
		damage_collision.shape.size = Vector2(boulder_radius * 2 + 4, boulder_radius * 2 + 4)

func update_boulder_rotation(delta: float):
	"""Physics-accurate rotation calculation"""
	if not is_rolling or not boulder_sprite:
		return
	
	# Calculate rotation based on circumference and distance traveled
	var distance_traveled = abs(linear_velocity.x) * delta
	var circumference = 2 * PI * boulder_radius
	var rotation_radians = (distance_traveled / circumference) * 2 * PI
	
	# Apply rotation in correct direction
	if linear_velocity.x > 0:
		accumulated_rotation += rotation_radians * rotation_multiplier
	else:
		accumulated_rotation -= rotation_radians * rotation_multiplier
	
	boulder_sprite.rotation = accumulated_rotation

func start_rolling_effects():
	"""Start rolling animations and effects"""
	# Start rolling animation
	if animation_player and animation_player.has_animation("roll"):
		animation_player.play("roll")
	
	# Start dust particles
	if show_dust_trail and dust_particles:
		dust_particles.emitting = true
		dust_particles.amount = int(10 * dust_intensity)
	
	# Start rolling sound
	_play_sound(rolling_sound)
	is_playing_rolling_sound = true

func update_dust_effects():
	"""Update dust particle effects based on movement"""
	if not dust_particles or not show_dust_trail:
		return
	
	var speed_ratio = abs(linear_velocity.x) / roll_speed
	dust_particles.amount = int(10 * dust_intensity * speed_ratio)
	
	if speed_ratio < 0.1:
		dust_particles.emitting = false
	else:
		dust_particles.emitting = true

func update_rolling_sound():
	"""Update rolling sound based on movement"""
	var is_moving = abs(linear_velocity.x) > 10.0
	
	if is_moving and not is_playing_rolling_sound:
		_play_sound(rolling_sound)
		is_playing_rolling_sound = true
	elif not is_moving and is_playing_rolling_sound:
		is_playing_rolling_sound = false

func check_direction_change():
	"""Check if boulder should change direction"""
	if sign(linear_velocity.x) != sign(last_velocity.x) and linear_velocity.x != 0:
		roll_direction = int(sign(linear_velocity.x))
		boulder_bounced.emit()
		_play_sound(bounce_sound)

func handle_wall_collision(wall):
	"""Handle collision with walls"""
	boulder_bounced.emit()
	_play_sound(bounce_sound)
	
	if can_change_direction:
		# Bounce off the wall
		roll_direction *= -1
		linear_velocity.x = roll_speed * roll_direction
	else:
		# Stop or slow down
		linear_velocity.x *= 0.5

func _handle_player_attack(attack):
	"""Handle player attacks on the boulder"""
	if can_be_pushed:
		var push_force = 50.0
		if attack.has_method("get_knockback_force"):
			push_force = attack.get_knockback_force()
		
		var push_dir = (global_position - attack.global_position).normalized()
		apply_central_impulse(push_dir * push_force)
		
		_play_sound(bounce_sound)
		boulder_bounced.emit()

func _play_crush_effects():
	"""Play visual effects when crushing something"""
	if screen_shake_on_crush and FX and FX.has_method("shake"):
		FX.shake(100)
	
	if screen_flash_on_crush and FX and FX.has_method("flash_screen"):
		FX.flash_screen(Color.RED, 0.2)
	
	if hit_stop_duration > 0 and FX and FX.has_method("hit_stop"):
		FX.hit_stop(hit_stop_duration)

func _play_sound(sound_name: String):
	"""Play sound effect"""
	if sound_name != "" and Audio and Audio.has_method("play_sfx"):
		Audio.play_sfx(sound_name)
