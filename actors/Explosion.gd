extends RigidBody2D
class_name Bomb

enum BombPower {
	LOW,
	MEDIUM,
	HIGH
}

@export var bomb_power: BombPower = BombPower.LOW
@export var bomb_size_scale: float = 0.6 
@export var explosion_radius: float = 100.0
@export var damage: float = 1.0
@export var fuse_time: float = 3.0
@export var roll_time: float = 2.0

# Power variant stats (half size for better gameplay)
var power_configs = {
	BombPower.LOW: {
		"radius": 8.0,
		"damage": 1.0,
		"fuse_time": 4.0,
		"shake_strength": 60
	},
	BombPower.MEDIUM: {
		"radius": 12.0,
		"damage": 1.0,
		"fuse_time": 3.0,
		"shake_strength": 90
	},
	BombPower.HIGH: {
		"radius": 16.0,
		"damage": 2.0,
		"fuse_time": 2.0,
		"shake_strength": 120
	}
}

var fuse_timer: float = 0.0
var has_exploded: bool = false
var is_rolling: bool = false
var collision_disabled: bool = false

# Performance optimization - cache bodies in explosion area (simplified)
var bodies_in_explosion_area: Array[Node] = []
var is_simple_mode: bool = false  # Enable for ultra performance

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var explosion_area: Area2D = $ExplosionArea
@onready var explosion_collision: CollisionShape2D = $ExplosionArea/ExplosionCollisionShape2D

func _ready():
	# Ultra performance check: Activate simple mode very early
	var active_bombs = get_tree().get_nodes_in_group("bombs")
	if active_bombs.size() > 3:  # Ultra-low threshold for zero lag
		is_simple_mode = true  # Enable ultra-simplified behavior
		print("⚡ Zero-lag mode activated (", active_bombs.size(), " bombs)")
		
		# Aggressively limit bombs in scene to prevent any lag
		if active_bombs.size() > 5:
			for i in range(active_bombs.size() - 5):
				var old_bomb = active_bombs[i]
				if is_instance_valid(old_bomb) and old_bomb != self:
					old_bomb.queue_free()
	
	# Add to groups for chain reactions
	add_to_group("bombs")
	add_to_group("interactive")
	
	# Apply power configuration
	apply_power_config()
	
	# Validate configuration for production safety
	_validate_configuration()
	
	# Set collision shape for bomb physics (scaled size)
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 8.0 * bomb_size_scale # Scaled bomb radius for rolling
	collision_shape.shape = circle_shape
	
	# Set up explosion area collision
	var explosion_shape = CircleShape2D.new()
	explosion_shape.radius = explosion_radius
	explosion_collision.shape = explosion_shape
	
	# Set bomb sprite with scaled size
	sprite.texture = load("res://content/Graphics/Sprites/Tiles/Default/bomb.png")
	sprite.scale = Vector2(bomb_size_scale, bomb_size_scale)
	
	# Connect collision signals (skip in simple mode for performance)
	if explosion_area and not is_simple_mode:
		explosion_area.body_entered.connect(_on_explosion_area_entered)
		explosion_area.body_exited.connect(_on_explosion_area_exited)
	elif is_simple_mode:
		# Disable area monitoring entirely in simple mode
		explosion_area.monitoring = false
	
	# Make bomb round and bouncy
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.4
	physics_material_override.friction = 0.8
	
	# Enable contact monitoring for collision detection (ultra-optimized)
	if not is_simple_mode:
		contact_monitor = true
		max_contacts_reported = 2  # Ultra-minimal for zero lag
		# Connect body collision signals
		body_entered.connect(_on_body_entered)
	else:
		# Reduce physics interactions in simple mode but keep gravity
		contact_monitor = false
		max_contacts_reported = 1  # Minimal contact monitoring
		# DON'T freeze physics - bombs should still fall with gravity
		print("⚡ Zero-lag mode: Reduced physics interactions for performance")
	
	# Production ready - no particle dependencies

func apply_power_config():
	var config = power_configs[bomb_power]
	explosion_radius = config["radius"] * bomb_size_scale
	damage = config["damage"]
	fuse_time = config["fuse_time"]

func _physics_process(delta):
	if has_exploded or collision_disabled:
		return
	
	# Skip ALL processing in simple mode for zero lag
	if is_simple_mode:
		fuse_timer += delta
		# Instant explosion in simple mode - no visual effects
		if fuse_timer >= fuse_time * 0.5:  # Explode faster in simple mode
			explode()
		return
		
	fuse_timer += delta
	
	# Minimal visual feedback only in normal mode
	if fuse_timer > fuse_time * 0.8:
		# Ultra-simple flash - no complex calculations
		var flash_on = int(fuse_timer * 3.0) % 2 == 0  # Flash 1.5 times per second
		sprite.modulate = Color.RED if flash_on else Color.WHITE
	
	# Check if fuse expired
	if fuse_timer >= fuse_time:
		explode()

func _on_body_entered(body):
	if has_exploded or collision_disabled or not body:
		return
		
	# Explode immediately when touching the player (but not boss)
	if body.is_in_group("player") and not body.is_in_group("boss"):
		print("💥 Bomb touched player - exploding!")
		
		# Throw player away immediately before explosion
		_throw_player_away(body)
		
		# Small delay to let knockback register before explosion effects
		await get_tree().create_timer(0.05).timeout
		
		explode()
	# Explode when touching InteractiveCrate (TNT crates)
	elif body.is_in_group("crates"):
		print("💥 Bomb touched TNT crate - exploding!")
		explode()
	# Explode on hard impact with other objects (not during rolling phase)  
	elif not is_rolling and body != self and not body.is_in_group("enemy") and not body.is_in_group("boss"):
		print("💥 Bomb hard impact with ", body.name, " - exploding!")
		explode()

func _on_explosion_area_entered(body):
	if not has_exploded:
		bodies_in_explosion_area.append(body)
		return
		
	# Process radiation effects immediately for bodies entering after explosion
	_process_radiation_damage(body)

func _on_explosion_area_exited(body):
	bodies_in_explosion_area.erase(body)

func _process_radiation_damage(body):
	# Radiation effect only affects player, not enemies or GiantBoss
	if body.is_in_group("player") and not body.is_in_group("boss") and body.has_method("take_damage"):
		# Apply radiation damage
		body.take_damage(damage)
		print("💥 Player took ", damage, " radiation damage from bomb explosion")
		
		# Apply controlled explosion knockback (limited to 100-200 pixels)
		_apply_explosion_knockback(body)
	
	# Trigger TNT crates in radiation area
	elif body.is_in_group("crates") and body.has_method("start_explosion_countdown"):
		if "is_exploding" in body and not body.is_exploding:
			body.start_explosion_countdown()
			print("💥 Radiation triggered TNT crate: ", body.name)

func explode():
	if has_exploded:
		return
		
	has_exploded = true
	collision_disabled = true
	
	# Hide the bomb sprite immediately
	sprite.visible = false
	
	if is_simple_mode:
		# Ultra-simple explosion for maximum performance
		_simple_explode()
	else:
		# Standard explosion with all effects
		_full_explode()

func _simple_explode():
	# Absolutely minimal explosion - zero effects for zero lag
	
	# Only tiny screen shake if FX exists
	if FX:
		FX.shake(20)  # Minimal shake
	
	# Ultra-simple player damage check (no complex calculations)
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and not player.is_in_group("boss"):
		var diff = player.global_position - global_position
		var distance_squared = diff.x * diff.x + diff.y * diff.y  # Avoid sqrt
		var radius_squared = explosion_radius * explosion_radius
		
		if distance_squared <= radius_squared:
			if player.has_method("take_damage"):
				player.take_damage(damage)
			# Limited simple knockback (max ~100 pixels)
			if "velocity" in player:
				var push = diff.normalized() * 100.0  # Reduced from 150 to 100
				player.velocity += push
	
	# Instant cleanup - no waiting at all
	queue_free()

func _full_explode():
	# Enable explosion area to detect bodies in range
	explosion_area.monitoring = true
	
	# Use power-based effects
	var config = power_configs[bomb_power]
	var shake_strength = config["shake_strength"]
	
	# Simple red explosion effect - no particles
	_create_red_explosion_effect()
	
	# Visual and audio effects based on bomb power
	match bomb_power:
		BombPower.HIGH:
			if FX:
				FX.hit_stop(80) # Reduced hit-stop
				FX.shake(shake_strength)
			if Audio:
				Audio.play_sfx("big_explosion")
		BombPower.MEDIUM:
			if FX:
				FX.hit_stop(50)  # Reduced hit-stop
				FX.shake(shake_strength)
			if Audio:
				Audio.play_sfx("explosion")
		BombPower.LOW:
			if FX:
				FX.shake(shake_strength)
			if Audio:
				Audio.play_sfx("small_explosion")
	
	# Direct explosion damage check for player (more reliable)
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and not player.is_in_group("boss"):
		var distance = global_position.distance_to(player.global_position)
		if distance <= explosion_radius:
			print("💥 Player in explosion range! Distance: ", distance, " Radius: ", explosion_radius)
			
			# Apply damage directly
			if player.has_method("take_damage"):
				player.take_damage(damage)
				print("💔 Applied ", damage, " damage to player")
			elif HealthSystem and HealthSystem.has_method("lose_heart"):
				HealthSystem.lose_heart()
				print("💔 Applied heart damage via HealthSystem")
			
			# Apply explosion knockback
			_apply_explosion_knockback(player)
		else:
			print("💥 Player outside explosion radius: ", distance, " > ", explosion_radius)
	
	# Process radiation damage for all bodies in explosion area (as backup)
	for body in bodies_in_explosion_area:
		if body != player:  # Avoid double-damage on player
			_process_radiation_damage(body)
	
	# Chain reaction - trigger nearby TNT crates and bombs
	trigger_nearby_tnts()
	
	print("💥 Bomb (", _get_power_name(), ") exploded with radius: ", explosion_radius, " damage: ", damage)
	
	# Wait for particles to finish, then remove the bomb
	await get_tree().create_timer(1.5).timeout  # Reduced from 2.0
	queue_free()

func trigger_nearby_tnts():
	# Skip ALL chain reactions for zero lag
	return

func _trigger_delayed_bomb(bomb: Node):
	if is_instance_valid(bomb) and bomb.has_method("explode"):
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(bomb) and not bomb.has_exploded:
			bomb.explode()

func setup(power: BombPower = BombPower.MEDIUM, size_scale: float = 0.3):
	bomb_power = power
	bomb_size_scale = size_scale
	apply_power_config()
	
	fuse_timer = 0.0
	has_exploded = false
	is_rolling = true
	
	# Update collision shapes with new scale
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 8.0 * bomb_size_scale
	collision_shape.shape = circle_shape
	
	# Update explosion area collision shape
	var explosion_shape = CircleShape2D.new()
	explosion_shape.radius = explosion_radius
	explosion_collision.shape = explosion_shape
	
	# Reset visuals with proper scale
	sprite.scale = Vector2(bomb_size_scale, bomb_size_scale)
	sprite.modulate.a = 1.0

func setup_legacy(radius: float, dmg: float):
	# Legacy setup for backward compatibility
	explosion_radius = radius
	damage = dmg
	fuse_timer = 0.0
	has_exploded = false
	is_rolling = true
	
	# Update explosion area collision shape
	var explosion_shape = CircleShape2D.new()
	explosion_shape.radius = radius
	explosion_collision.shape = explosion_shape
	
	# Reset visuals with current scale
	sprite.scale = Vector2(bomb_size_scale, bomb_size_scale)
	sprite.modulate.a = 1.0

func reset():
	fuse_timer = 0.0
	has_exploded = false
	is_rolling = true
	collision_disabled = false
	bodies_in_explosion_area.clear()
	sprite.scale = Vector2(bomb_size_scale, bomb_size_scale)
	sprite.modulate = Color.WHITE
	sprite.visible = true
	
	# Reset explosion area monitoring
	if explosion_area:
		explosion_area.monitoring = false

func _create_red_explosion_effect():
	# Production-ready red flash explosion - no particles, no lag
	if not sprite:
		return
		
	# Instant red flash
	sprite.modulate = Color.RED
	sprite.scale = Vector2(bomb_size_scale * 1.5, bomb_size_scale * 1.5)  # Slightly bigger on explosion
	
	# Quick fade to transparent using simple timer
	get_tree().create_timer(0.1).timeout.connect(func():
		if is_instance_valid(sprite):
			sprite.modulate = Color.TRANSPARENT
			sprite.scale = Vector2(bomb_size_scale, bomb_size_scale)
	)

func _get_power_name() -> String:
	match bomb_power:
		BombPower.LOW: return "LOW"
		BombPower.MEDIUM: return "MEDIUM"
		BombPower.HIGH: return "HIGH"
		_: return "UNKNOWN"

# Production-ready cleanup
func _exit_tree():
	bodies_in_explosion_area.clear()

# Error recovery - validate configuration
func _validate_configuration():
	if explosion_radius <= 0:
		explosion_radius = 100.0
		push_warning("Invalid explosion radius, reset to default: 100.0")
	
	if damage <= 0:
		damage = 1.0
		push_warning("Invalid damage value, reset to default: 1.0")
	
	if fuse_time <= 0:
		fuse_time = 3.0
		push_warning("Invalid fuse time, reset to default: 3.0")

func get_explosion_info() -> Dictionary:
	return {
		"power": bomb_power,
		"power_name": _get_power_name(),
		"radius": explosion_radius,
		"damage": damage,
		"fuse_time": fuse_time,
		"has_exploded": has_exploded,
		"is_rolling": is_rolling,
		"remaining_time": max(0.0, fuse_time - fuse_timer)
	}

func _throw_player_away(player: Node):
	if not player or not is_instance_valid(player):
		return
	
	# Calculate direction from bomb to player
	var direction_to_player = (player.global_position - global_position)
	
	# Safety check: if player is at same position as bomb, use default direction
	if direction_to_player.length() < 0.1:
		direction_to_player = Vector2(1, -0.5) # Default: right and up
	else:
		direction_to_player = direction_to_player.normalized()
	
	# Calculate limited knockback force (max 150 pixels displacement)
	var base_knockback_force = 150.0  # Reduced from 400 to limit displacement
	var power_multiplier = 1.0
	
	match bomb_power:
		BombPower.LOW:
			power_multiplier = 0.8  # 120 pixels max
		BombPower.MEDIUM:
			power_multiplier = 1.0  # 150 pixels max
		BombPower.HIGH:
			power_multiplier = 1.2  # 180 pixels max
	
	var knockback_force = base_knockback_force * power_multiplier
	
	# Add upward component for more dramatic effect
	var knockback_vector = direction_to_player * knockback_force
	knockback_vector.y -= knockback_force * 0.5 # Add upward force
	
	# Apply knockback to player
	if player.has_method("apply_knockback"):
		# Use player's knockback method if available
		player.apply_knockback(knockback_vector)
	elif player.has_method("set_velocity"):
		# Direct velocity setting for CharacterBody2D
		player.set_velocity(knockback_vector)
	elif "velocity" in player:
		# Direct velocity assignment
		player.velocity = knockback_vector
	elif player is RigidBody2D:
		# Apply impulse for RigidBody2D
		player.apply_central_impulse(knockback_vector)
	
	# Add extra screen shake for direct collision impact
	if FX:
		var impact_shake = knockback_force / 200.0 # Scale shake with force
		FX.shake(impact_shake)
	
	print("💨 Knocked player away with force: ", knockback_vector.length(), " in direction: ", direction_to_player)

func _apply_explosion_knockback(player: Node):
	if not player or not is_instance_valid(player):
		return
	
	# Calculate direction from bomb to player
	var direction_to_player = (player.global_position - global_position)
	var distance = direction_to_player.length()
	
	# Safety check: if player is at same position as bomb, use default direction
	if distance < 0.1:
		direction_to_player = Vector2(1, -0.5) # Default: right and up
		distance = 0.1 # Small distance to avoid division by zero
	else:
		direction_to_player = direction_to_player.normalized()
	
	# Distance-based knockback (weaker at longer distances)
	var max_distance = explosion_radius
	var distance_factor = 1.0 - min(distance / max_distance, 1.0) # 1.0 at center, 0.0 at edge
	
	# Calculate limited radiation knockback (max 100-150 pixels)
	var base_knockback_force = 120.0 # Much weaker for radiation
	var power_multiplier = 1.0
	
	match bomb_power:
		BombPower.LOW:
			power_multiplier = 0.8  # ~96 pixels max
		BombPower.MEDIUM:
			power_multiplier = 1.0  # ~120 pixels max
		BombPower.HIGH:
			power_multiplier = 1.2  # ~144 pixels max
	
	var knockback_force = base_knockback_force * power_multiplier * distance_factor
	
	# Add upward component for dramatic effect
	var knockback_vector = direction_to_player * knockback_force
	knockback_vector.y -= knockback_force * 0.3 # Less upward force than direct collision
	
	# Apply knockback to player
	if player.has_method("apply_knockback"):
		# Use player's knockback method if available
		player.apply_knockback(knockback_vector)
	elif player.has_method("set_velocity"):
		# Add to existing velocity for CharacterBody2D
		if "velocity" in player:
			player.velocity += knockback_vector
		else:
			player.set_velocity(knockback_vector)
	elif "velocity" in player:
		# Add to existing velocity
		player.velocity += knockback_vector
	elif player is RigidBody2D:
		# Apply impulse for RigidBody2D
		player.apply_central_impulse(knockback_vector)
	
	print("💨 Explosion knockback applied with force: ", knockback_vector.length(), " (distance factor: ", distance_factor, ")")

func _apply_simple_knockback(player: Node, distance: float):
	# Ultra-simple knockback without complex calculations
	if not player or not is_instance_valid(player):
		return
	
	# Simple direction calculation
	var direction = (player.global_position - global_position).normalized()
	if direction.length() < 0.1:
		direction = Vector2(1, -0.5)  # Default direction
	
	# Limited knockback force for simple mode
	var knockback_force = 100.0 * (1.0 - min(distance / explosion_radius, 1.0))  # Max 100 pixels
	var knockback_vector = direction * knockback_force
	knockback_vector.y -= knockback_force * 0.15  # Small upward push
	
	# Apply knockback using simplest method available
	if "velocity" in player:
		player.velocity += knockback_vector
	elif player.has_method("apply_knockback"):
		player.apply_knockback(knockback_vector)
	
	print("💨 Simple knockback applied")
