extends CharacterBody2D
class_name PatrolEnemy

signal enemy_defeated(enemy: PatrolEnemy, points: int)
signal enemy_stomped(enemy: PatrolEnemy, player: Node2D, points: int)
signal player_detected(enemy: PatrolEnemy, player: Node2D)
signal player_damaged(enemy: PatrolEnemy, player: Node2D, damage: int)

@export_enum("mouse", "barnacle", "bee", "fish_blue", "fish_yellow", "flog", "fly", "ladybug", "ladybug_fly", "saw", "slime_fire", "slime_green", "slime_normal", "slime_spike", "snail", "worm_blue", "worm_ring") var enemy_type: String = "mouse"
@export var patrol_speed: float = 65.0
@export var patrol_distance: float = 150.0
@export var damage_amount: int = 1
@export var points_value: int = 150
@export var health: int = 1
@export var detection_range: float = 90.0
@export_group("Dimension")
@export var target_layer: String = "A"  # For dimension system compatibility
@export var visible_in_both_dimensions: bool = false  # Show in both dimensions A and B

var start_position: Vector2
var direction: int = 1
var is_alive: bool = true
var current_health: int
var damage_cooldown: float = 0.0
var damage_cooldown_time: float = 0.5  # Prevent rapid damage

# Dimension system compatibility
var dimension_manager: Node
var is_active_in_current_layer: bool = true

@onready var label: Label = $EnemyLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_collision: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var damage_collision: CollisionShape2D = $DamageArea/CollisionShape2D

# get mouse animated sprite and play default aniamtion
@onready var enemy_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("enemies")

	enemy_sprite.play("mouse")
	
	start_position = global_position
	current_health = health
	
	# Set appearance based on enemy type
	setup_enemy_appearance()
	
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
	
	print("👹 Enemy initialized: ", enemy_type, " at ", global_position)
	
	# Setup dimension system
	if not Engine.is_editor_hint():
		_setup_dimension_system()

func _physics_process(delta):
	if not is_alive:
		return
	
	# Update damage cooldown
	if damage_cooldown > 0:
		damage_cooldown -= delta
	
	# Simple patrol movement
	velocity.x = patrol_speed * direction
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += 980 * delta
	
	move_and_slide()
	
	# Check for wall collisions and turn around
	check_wall_collisions()
	
	# Check for edges and turn around
	check_edge_detection()
	
	# Movement and collision is now handled by damage area signals

func setup_enemy_appearance():
	match enemy_type:
		"mouse":
			enemy_sprite.play("mouse")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1
		"barnacle":
			enemy_sprite.play("barnacle")
			patrol_speed = 80.0
			points_value = 150
			damage_amount = 1
		"bee":
			enemy_sprite.play("bee")
			patrol_speed = 70.0
			points_value = 150
			damage_amount = 1
		"fish_blue":
			enemy_sprite.play("fish_blue")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1
		"fish_yellow":
			enemy_sprite.play("fish_yellow")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1
		"flog":
			enemy_sprite.play("flog")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1
		"fly":
			enemy_sprite.play("fly")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1
		"ladybug":
			enemy_sprite.play("ladybug")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1
		"ladybug_fly":
			enemy_sprite.play("ladybug_fly")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1
		"saw":
			enemy_sprite.play("saw")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1
		"slime_fire":
			enemy_sprite.play("slime_fire")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1
		"slime_green":
			enemy_sprite.play("slime_green")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1
		"slime_normal":
			enemy_sprite.play("slime_normal")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1
		"slime_spike":
			enemy_sprite.play("slime_spike")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1
		"snail":
			enemy_sprite.play("snail")
			patrol_speed = 25.0
			points_value = 150
			damage_amount = 1
		"worm_blue":
			enemy_sprite.play("worm_blue")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1
		"worm_ring":
			enemy_sprite.play("worm_ring")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1

		_:
			enemy_sprite.play("mouse")
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1

func setup_detection_area():
	if not detection_area:
		return
	
	# Create detection collision shape
	# var circle_shape = CircleShape2D.new()
	# circle_shape.radius = detection_range
	# detection_collision.shape = circle_shape
	
	var rect_shape = RectangleShape2D.new()
	rect_shape.extents = Vector2(detection_range, detection_range)
	detection_collision.shape = rect_shape
	
	# Set collision layers for detection
	detection_area.collision_layer = 0
	detection_area.collision_mask = 2  # Player layer

func flip_sprite():
	# Flip the animated sprite horizontally to match direction
	enemy_sprite.scale.x = -enemy_sprite.scale.x
 

func check_wall_collisions():
	# Check if we hit a wall or obstacle
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		var collision_normal = collision.get_normal()
		
		# Skip player collisions (handled by damage area)
		if collider and collider.is_in_group("player"):
			continue
		
		# Check if this is a wall collision (horizontal normal)
		if abs(collision_normal.x) > 0.7:  # Normal pointing left or right
			print("👹 ", enemy_type.capitalize(), " hit wall! Normal: ", collision_normal)
			turn_around()
			break  # Only process one collision per frame

func check_edge_detection():
	# Only check for edges when on the ground
	if not is_on_floor():
		return
	
	# Cast a ray downward from the front of the enemy to detect edges
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.new()
	
	# Start from the front edge of the enemy
	var front_offset = direction * 16  # Half the enemy width + a bit more
	var start_pos = global_position + Vector2(front_offset, 0)
	var end_pos = start_pos + Vector2(0, 32)  # Check 32 pixels down
	
	query.from = start_pos
	query.to = end_pos
	query.collision_mask = 1  # Ground layer
	
	var result = space_state.intersect_ray(query)
	
	# If no ground detected ahead, turn around
	if result.is_empty():
		print("👹 ", enemy_type.capitalize(), " detected edge! Turning around")
		turn_around()

func turn_around():
	# Change direction
	direction *= -1
	
	# Flip sprite to face new direction
	flip_sprite()
	
	# Move slightly away from the wall to prevent getting stuck
	global_position.x += direction * 2
	
	print("👹 ", enemy_type.capitalize(), " turned around! New direction: ", direction)

func _on_detection_area_entered(body):
	if body.is_in_group("player") and is_alive:
		player_detected.emit(self, body)
		print("👁️ ", enemy_type.capitalize(), " detected player!")

func _on_detection_area_exited(body):
	if body.is_in_group("player") and is_alive:
		print("👁️ ", enemy_type.capitalize(), " lost sight of player")

func _on_damage_area_entered(body):
	print("👹 🚨 DAMAGE AREA ENTERED - Body: ", body.name, " Groups: ", body.get_groups())
	 
	if not body.is_in_group("player") or not is_alive:
		print("👹 Not player or enemy dead - ignoring")
		return
	
	# Check damage cooldown
	if damage_cooldown > 0:
		print("👹 Damage on cooldown - ignoring (", damage_cooldown, "s remaining)")
		return
	
	print("👹 🎯 VALID DAMAGE COLLISION with: ", body.name)
	print("👹 Player pos: ", body.global_position, " Enemy pos: ", global_position)
	
	var player_velocity = body.velocity if "velocity" in body else Vector2.ZERO
	
	# Check if this is a stomp (player above enemy and falling down)
	var player_above_enemy = body.global_position.y < global_position.y - 8
	var player_falling = player_velocity.y > 50  # Must be falling with some speed
	
	print("� STOMP rCHECK: player_above=", player_above_enemy, " falling=", player_falling, " vel_y=", player_velocity.y)
	
	if player_above_enemy and player_falling:
		print("👹 🦶 Player is stomping this enemy!")
		take_damage(1, true)
		# Bounce player upward
		if "velocity" in body:
			body.velocity.y = -400  # Bounce force
		if "is_jumping" in body:
			body.is_jumping = true
	else:
		print("👹 💥 Player hit enemy from side - applying damage and pushback")
		damage_player_with_pushback(body, Vector2.ZERO)
		# Set damage cooldown to prevent rapid damage
		damage_cooldown = damage_cooldown_time

func _on_damage_area_exited(body):
	if body.is_in_group("player"):
		print("👹 Player left damage area")
		# Reset enemy color
		setup_enemy_appearance()  # This will restore the original color

func damage_player_with_pushback(player, collision_normal: Vector2):
	if not is_alive:
		print("👹 Enemy is dead - no damage")
		return
	
	print("👹 ATTEMPTING TO DAMAGE PLAYER")
	print("👹 Player pos: ", player.global_position, " Enemy pos: ", global_position)
	print("👹 Player has take_damage method: ", player.has_method("take_damage"))
	print("👹 Player invincible: ", player.has_method("is_player_invincible") and player.is_player_invincible())
	
	# Simple approach: determine pushback based on player position relative to enemy
	var pushback_force = 200.0
	var direction_to_player = (player.global_position - global_position).normalized()
	var pushback_direction = Vector2(direction_to_player.x, -0.3)  # Push away from enemy + slight upward
	
	print("👹 Direction to player: ", direction_to_player)
	print("👹 Pushback direction: ", pushback_direction)
	
	# Apply pushback to player FIRST
	if "velocity" in player:
		player.velocity.x = pushback_direction.x * pushback_force
		player.velocity.y = pushback_direction.y * pushback_force
		print("👹 Applied pushback velocity: ", player.velocity)
	
	# Damage the player - use the method we know exists
	var damage_applied = false
	
	print("👹 Attempting to call player.take_damage(", damage_amount, ")")
	if player.has_method("take_damage"):
		player.take_damage(damage_amount)
		damage_applied = true
		print("👹 ✅ Successfully called player.take_damage()")
	else:
		print("👹 ❌ Player doesn't have take_damage method!")
		# Try alternative methods
		if has_node("/root/HealthSystem") and HealthSystem.has_method("lose_heart"):
			HealthSystem.lose_heart()
			damage_applied = true
			print("👹 ✅ Used HealthSystem.lose_heart() as fallback")
	
	if not damage_applied:
		print("👹 ❌ CRITICAL: Could not apply damage to player!")
		print("👹 Available methods: ", player.get_method_list())
	
	# Emit signal
	player_damaged.emit(self, player, damage_amount)
	
	# Visual feedback
	create_damage_effect()
	
	print("👹 ", enemy_type.capitalize(), " finished damage attempt")

func create_damage_effect():
	# Screen flash
	if FX and FX.has_method("flash_screen"):
		FX.flash_screen(Color.RED, 0.15)
	
	# Screen shake
	if FX and FX.has_method("shake"):
		FX.shake(10)
	

func take_damage(amount: int = 1, from_stomp: bool = false):
	if not is_alive:
		return
	
	current_health -= amount
	
	# Visual feedback for taking damage
	enemy_sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(enemy_sprite, "modulate", Color.WHITE, 0.2)
	
	if from_stomp:
		print("🦶 ", enemy_type.capitalize(), " stomped! (", current_health, "/", health, " HP)")
	else:
		print("👹 ", enemy_type.capitalize(), " took ", amount, " damage (", current_health, "/", health, " HP)")
	
	if current_health <= 0:
		defeat(from_stomp)

func defeat(from_stomp: bool = false):
	if not is_alive:
		return
	
	is_alive = false


	# Audio feedback
	if Audio:
		Audio.play_sfx("enemy_hurt")
	
	# Screen shake
	if FX and FX.has_method("shake"):
		FX.shake(100)

	# Add score
	Game.add_score(points_value)
	
	# Emit appropriate signal
	if from_stomp:
		enemy_stomped.emit(self, null, points_value)  # Player reference would be passed separately
		print("🦶 ", enemy_type.capitalize(), " stomped! +", points_value, " points")
	else:
		enemy_defeated.emit(self, points_value)
		print("👹 ", enemy_type.capitalize(), " defeated! +", points_value, " points")
	
	# Create defeat effect
	create_defeat_effect(from_stomp)

func create_defeat_effect(from_stomp: bool = false):
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
		effect_label.add_theme_color_override("font_color", Color.BLACK)
		effect_label.text = "+" + str(points_value)
	else:
		effect_label.add_theme_color_override("font_color", Color.BLACK)
	
	effect_label.position = global_position + Vector2(-30, -30)
	get_tree().current_scene.add_child(effect_label)
	
	# Animate the effect with a scene-based tween (not tied to this enemy)
	var scene_tween = get_tree().create_tween()
	scene_tween.parallel().tween_property(effect_label, "position", effect_label.position + Vector2(0, -50), 1.0)
	scene_tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.0)
	scene_tween.tween_callback(func(): 
		if is_instance_valid(effect_label):
			effect_label.queue_free()
	)

	
	# Different death animation for stomp
	var death_tween = create_tween()
	if from_stomp:
		# Squash effect for stomp
		death_tween.parallel().tween_property(self, "scale", Vector2(1.2, 0.3), 0.2)
		death_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	else:
		# Regular shrink effect
		death_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
		death_tween.parallel().tween_property(self, "scale", Vector2(0.5, 0.5), 0.5)
	
	death_tween.tween_callback(queue_free)

func set_patrol_points(point_a: Vector2, point_b: Vector2):
	start_position = point_a
	patrol_distance = abs(point_b.x - point_a.x)
	global_position = point_a

func set_enemy_stats(new_type: String, new_health: int = 1, new_speed: float = 75.0):
	enemy_type = new_type
	health = new_health
	current_health = new_health
	patrol_speed = new_speed
	setup_enemy_appearance()

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
