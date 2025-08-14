extends RigidBody2D
class_name RollingBoulder

signal player_crushed(player: Player)
signal boulder_destroyed

@export var roll_speed: float = 100.0
@export var auto_scroll_speed: float = 50.0
@export var damage: int = 1
@export var destroy_on_wall: bool = true
@export var bounce_force: float = 200.0
@export var max_lifetime: float = 30.0

var lifetime_timer: float = 0.0
var is_rolling: bool = true
var roll_direction: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var dimension_node: DimensionNode = $DimensionNode
@onready var dust_particles: CPUParticles2D = $DustParticles
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Add to hazards group
	add_to_group("hazards")
	add_to_group("boulders")
	
	# Connect damage area
	if damage_area:
		damage_area.body_entered.connect(_on_player_entered)
	
	# Connect collision detection
	body_entered.connect(_on_body_collision)
	
	# Set initial velocity
	linear_velocity.x = roll_speed * roll_direction
	
	# Start rolling animation
	if animation_player:
		animation_player.play("roll")
	
	# Start dust particles
	if dust_particles:
		dust_particles.emitting = true

func _physics_process(delta):
	lifetime_timer += delta
	
	# Auto-scroll movement
	if auto_scroll_speed != 0.0:
		global_position.x += auto_scroll_speed * delta
	
	# Maintain rolling speed
	if is_rolling and abs(linear_velocity.x) < roll_speed * 0.8:
		linear_velocity.x = roll_speed * roll_direction
	
	# Rotate sprite based on movement
	if is_rolling:
		sprite.rotation += (linear_velocity.x / 50.0) * delta
	
	# Check for walls
	if destroy_on_wall and is_colliding_with_wall():
		destroy_boulder()
	
	# Destroy after max lifetime
	if lifetime_timer >= max_lifetime:
		destroy_boulder()

func _on_player_entered(body):
	if body is Player:
		crush_player(body)

func _on_body_collision(body):
	if body is Player:
		crush_player(body)
	elif body.is_in_group("enemies"):
		# Crush enemies
		if body.has_method("take_damage"):
			body.take_damage(999) # Instant kill
	elif body.is_in_group("crates"):
		# Destroy crates
		if body.has_method("break_crate"):
			body.break_crate()

func crush_player(player: Player):
	player_crushed.emit(player)
	
	# Damage/kill the player
	if player.has_method("take_damage"):
		player.take_damage(damage)
	else:
		player.die()
	
	# Dramatic effects
	FX.shake(300)
	FX.flash_screen(Color.RED, 0.2)
	FX.hit_stop(150)
	
	# Bounce the player
	if player.has_method("apply_central_impulse"):
		var bounce_dir = (player.global_position - global_position).normalized()
		player.velocity += bounce_dir * bounce_force
	
	print("Boulder crushed player!")

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
	FX.shake(200)
	
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