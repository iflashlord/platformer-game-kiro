extends RigidBody2D
class_name Bomb

enum BombPower {
	LOW,
	MEDIUM,
	HIGH
}

@export var bomb_power: BombPower = BombPower.MEDIUM
@export var explosion_radius: float = 100.0
@export var damage: float = 1.0
@export var fuse_time: float = 3.0
@export var roll_time: float = 2.0

# Power variant stats
var power_configs = {
	BombPower.LOW: {
		"radius": 16.0,
		"damage": 1.0,
		"fuse_time": 4.0,
		"shake_strength": 60
	},
	BombPower.MEDIUM: {
		"radius": 24.0,
		"damage": 1.0,
		"fuse_time": 3.0,
		"shake_strength": 90
	},
	BombPower.HIGH: {
		"radius": 32.0,
		"damage": 2.0,
		"fuse_time": 2.0,
		"shake_strength": 120
	}
}

var fuse_timer: float = 0.0
var has_exploded: bool = false
var is_rolling: bool = false
var collision_disabled: bool = false

# Performance optimization - cache bodies in explosion area
var bodies_in_explosion_area: Array[Node] = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var explosion_area: Area2D = $ExplosionArea
@onready var explosion_collision: CollisionShape2D = $ExplosionArea/ExplosionCollisionShape2D
@onready var explosion_particles: GPUParticles2D = get_node_or_null("ExplosionParticles")
@onready var smoke_particles: GPUParticles2D = get_node_or_null("SmokeParticles")
@onready var explosion_light: PointLight2D = get_node_or_null("ExplosionLight")

func _ready():
	# Add to groups for chain reactions
	add_to_group("bombs")
	add_to_group("interactive")
	
	# Apply power configuration
	apply_power_config()
	
	# Validate configuration for production safety
	_validate_configuration()
	
	# Set collision shape for bomb physics (smaller than explosion)
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 8.0 # Small bomb radius for rolling
	collision_shape.shape = circle_shape
	
	# Set up explosion area collision
	var explosion_shape = CircleShape2D.new()
	explosion_shape.radius = explosion_radius
	explosion_collision.shape = explosion_shape
	
	# Set bomb sprite
	sprite.texture = load("res://content/Graphics/Sprites/Tiles/Default/bomb.png")
	
	# Connect collision signals
	if explosion_area:
		explosion_area.body_entered.connect(_on_explosion_area_entered)
		explosion_area.body_exited.connect(_on_explosion_area_exited)
	
	# Make bomb round and bouncy
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.3
	physics_material_override.friction = 0.8
	
	# Enable contact monitoring for collision detection
	contact_monitor = true
	max_contacts_reported = 10
	
	# Connect body collision signals
	body_entered.connect(_on_body_entered)
	
	# Ensure explosion light is initially off
	if explosion_light:
		explosion_light.enabled = false

func apply_power_config():
	var config = power_configs[bomb_power]
	explosion_radius = config["radius"]
	damage = config["damage"]
	fuse_time = config["fuse_time"]

func _physics_process(delta):
	if has_exploded or collision_disabled:
		return
		
	fuse_timer += delta
	
	# Visual feedback - bomb gets more unstable as it approaches explosion
	if fuse_timer > fuse_time * 0.7:
		var flash_intensity = sin(fuse_timer * 20.0) * 0.3 + 0.7
		sprite.modulate = Color(1.0, flash_intensity, flash_intensity)
	
	# Check if rolling time is over or fuse expired
	if fuse_timer >= roll_time:
		is_rolling = false
		explode() # Explode after rolling time expires
		return
		
	if fuse_timer >= fuse_time:
		explode()

func _on_body_entered(body):
	if has_exploded or collision_disabled or not body:
		return
		
	# Explode immediately when touching the player
	if body.is_in_group("player"):
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
	if body.is_in_group("player") and body.has_method("take_damage"):
		# Apply radiation damage
		body.take_damage(damage)
		print("💥 Player took ", damage, " radiation damage from bomb explosion")
		
		# Apply explosion knockback (weaker than direct collision)
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
	
	# Enable explosion area to detect bodies in range
	explosion_area.monitoring = true
	
	# Use power-based effects
	var config = power_configs[bomb_power]
	var shake_strength = config["shake_strength"]
	
	# Start particle effects
	_create_explosion_effects()
	
	# Visual and audio effects based on bomb power
	match bomb_power:
		BombPower.HIGH:
			if FX:
				FX.hit_stop(150) # Longer hit-stop
				FX.shake(shake_strength) # Strong screen shake
			if Audio:
				Audio.play_sfx("big_explosion")
		BombPower.MEDIUM:
			if FX:
				FX.hit_stop(90)
				FX.shake(shake_strength)
			if Audio:
				Audio.play_sfx("explosion")
		BombPower.LOW:
			if FX:
				FX.shake(shake_strength)
			if Audio:
				Audio.play_sfx("small_explosion")
	
	# Process radiation damage for all bodies in explosion area
	for body in bodies_in_explosion_area:
		_process_radiation_damage(body)
	
	# Chain reaction - trigger nearby TNT crates and bombs
	trigger_nearby_tnts()
	
	# Create explosion visual effect
	print("💥 Bomb (", _get_power_name(), ") exploded with radius: ", explosion_radius, " damage: ", damage)
	
	# Wait for particles to finish, then remove the bomb
	await get_tree().create_timer(2.0).timeout
	queue_free()

func trigger_nearby_tnts():
	if not is_instance_valid(self) or not get_tree():
		return
		
	# Check for InteractiveCrate TNT crates
	var nearby_crates = get_tree().get_nodes_in_group("crates")
	for crate in nearby_crates:
		if not is_instance_valid(crate) or crate == self:
			continue
			
		if crate.has_method("start_explosion_countdown"):
			var crate_distance = global_position.distance_to(crate.global_position)
			if crate_distance <= explosion_radius * 0.8: # Chain reaction radius
				print("💥 Bomb chain reaction with TNT crate at distance: ", crate_distance)
				if "is_exploding" in crate and not crate.is_exploding:
					crate.start_explosion_countdown()
	
	# Check for other bombs in the area
	var nearby_bombs = get_tree().get_nodes_in_group("bombs")
	for bomb in nearby_bombs:
		if not is_instance_valid(bomb) or bomb == self:
			continue
			
		if bomb.has_method("explode") and not bomb.has_exploded:
			var bomb_distance = global_position.distance_to(bomb.global_position)
			if bomb_distance <= explosion_radius * 0.7: # Slightly smaller radius for bomb-to-bomb
				print("💥 Bomb chain reaction with another bomb at distance: ", bomb_distance)
				# Add small delay to create a cascading effect
				_trigger_delayed_bomb(bomb)

func _trigger_delayed_bomb(bomb: Node):
	if is_instance_valid(bomb) and bomb.has_method("explode"):
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(bomb) and not bomb.has_exploded:
			bomb.explode()

func setup(power: BombPower = BombPower.MEDIUM):
	bomb_power = power
	apply_power_config()
	
	fuse_timer = 0.0
	has_exploded = false
	is_rolling = true
	
	# Update explosion area collision shape
	var explosion_shape = CircleShape2D.new()
	explosion_shape.radius = explosion_radius
	explosion_collision.shape = explosion_shape
	
	# Reset visuals
	sprite.scale = Vector2(1.0, 1.0)
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
	
	# Reset visuals
	sprite.scale = Vector2(1.0, 1.0)
	sprite.modulate.a = 1.0

func reset():
	fuse_timer = 0.0
	has_exploded = false
	is_rolling = true
	collision_disabled = false
	bodies_in_explosion_area.clear()
	sprite.scale = Vector2(1.0, 1.0)
	sprite.modulate = Color.WHITE
	sprite.visible = true
	
	# Reset explosion area monitoring
	if explosion_area:
		explosion_area.monitoring = false
		
	# Reset particle effects
	if explosion_particles:
		explosion_particles.emitting = false
	if smoke_particles:
		smoke_particles.emitting = false
	if explosion_light:
		explosion_light.enabled = false

func _create_explosion_effects():
	# Create explosion light flash
	if explosion_light:
		explosion_light.enabled = true
		explosion_light.energy = 2.0
		var light_tween = create_tween()
		light_tween.tween_property(explosion_light, "energy", 0.0, 0.5)
		light_tween.tween_callback(func(): explosion_light.enabled = false)
	
	# Start explosion particles
	if explosion_particles:
		explosion_particles.emitting = true
		
		# Scale particle amount and speed based on bomb power (adapted for smaller explosions)
		match bomb_power:
			BombPower.HIGH:
				explosion_particles.amount = 30
				explosion_particles.process_material.initial_velocity_min = 40.0
				explosion_particles.process_material.initial_velocity_max = 80.0
			BombPower.MEDIUM:
				explosion_particles.amount = 20
				explosion_particles.process_material.initial_velocity_min = 30.0
				explosion_particles.process_material.initial_velocity_max = 60.0
			BombPower.LOW:
				explosion_particles.amount = 15
				explosion_particles.process_material.initial_velocity_min = 20.0
				explosion_particles.process_material.initial_velocity_max = 40.0
	
	# Start smoke particles
	if smoke_particles:
		smoke_particles.emitting = true

func _get_power_name() -> String:
	match bomb_power:
		BombPower.LOW: return "LOW"
		BombPower.MEDIUM: return "MEDIUM"
		BombPower.HIGH: return "HIGH"
		_: return "UNKNOWN"

# Production-ready cleanup
func _exit_tree():
	bodies_in_explosion_area.clear()
	if explosion_particles:
		explosion_particles.emitting = false
	if smoke_particles:
		smoke_particles.emitting = false

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
	
	# Calculate knockback force based on bomb power
	var base_knockback_force = 400.0
	var power_multiplier = 1.0
	
	match bomb_power:
		BombPower.LOW:
			power_multiplier = 0.8
		BombPower.MEDIUM:
			power_multiplier = 1.0
		BombPower.HIGH:
			power_multiplier = 1.4
	
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
	
	# Calculate knockback force based on bomb power and distance
	var base_knockback_force = 250.0 # Weaker than direct collision
	var power_multiplier = 1.0
	
	match bomb_power:
		BombPower.LOW:
			power_multiplier = 0.6
		BombPower.MEDIUM:
			power_multiplier = 0.8
		BombPower.HIGH:
			power_multiplier = 1.2
	
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
