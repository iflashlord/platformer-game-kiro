extends CharacterBody2D
class_name PatrolEnemy

signal enemy_defeated(enemy: PatrolEnemy, points: int)
signal player_detected(enemy: PatrolEnemy, player: Node2D)
signal player_damaged(enemy: PatrolEnemy, player: Node2D, damage: int)

@export var enemy_type: String = "goblin"
@export var patrol_speed: float = 75.0
@export var patrol_distance: float = 150.0
@export var damage_amount: int = 1
@export var points_value: int = 150
@export var health: int = 1
@export var detection_range: float = 100.0

var start_position: Vector2
var direction: int = 1
var is_alive: bool = true
var current_health: int

@onready var sprite: ColorRect = $EnemySprite
@onready var label: Label = $EnemyLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_collision: CollisionShape2D = $DetectionArea/CollisionShape2D

func _ready():
	add_to_group("enemies")
	
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

func _physics_process(delta):
	if not is_alive:
		return
	
	# Simple patrol movement
	velocity.x = patrol_speed * direction
	
	# Check if we've moved too far from start position
	#var distance_from_start = abs(global_position.x - start_position.x)
	#if distance_from_start > patrol_distance:
	#	print("👹 Enemy reached patrol limit, turning around")
	#	direction *= -1
	#	flip_sprite()
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += 980 * delta
	
	move_and_slide()
	
	# Check for player collision (damage)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			print("👹 Enemy collided with player!")
			damage_player(collider)

func setup_enemy_appearance():
	match enemy_type:
		"goblin":
			sprite.color = Color(0, 0.8, 0, 1)  # Green
			label.text = "👹"
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1
		"orc":
			sprite.color = Color(0.6, 0.3, 0.1, 1)  # Brown
			label.text = "👺"
			patrol_speed = 50.0
			points_value = 200
			damage_amount = 2
		"skeleton":
			sprite.color = Color(0.9, 0.9, 0.9, 1)  # White
			label.text = "💀"
			patrol_speed = 60.0
			points_value = 175
			damage_amount = 1
		"demon":
			sprite.color = Color(1, 0, 1, 1)  # Magenta
			label.text = "😈"
			patrol_speed = 100.0
			points_value = 300
			damage_amount = 2
		_:
			sprite.color = Color(1, 0, 1, 1)
			label.text = "👹"
			patrol_speed = 75.0
			points_value = 150
			damage_amount = 1

func setup_detection_area():
	if not detection_area:
		return
	
	# Create detection collision shape
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = detection_range
	detection_collision.shape = circle_shape
	
	# Set collision layers for detection
	detection_area.collision_layer = 0
	detection_area.collision_mask = 2  # Player layer

func flip_sprite():
	sprite.scale.x = -sprite.scale.x
	label.scale.x = -label.scale.x

func _on_detection_area_entered(body):
	if body.is_in_group("player") and is_alive:
		player_detected.emit(self, body)
		print("👁️ ", enemy_type.capitalize(), " detected player!")

func _on_detection_area_exited(body):
	if body.is_in_group("player") and is_alive:
		print("👁️ ", enemy_type.capitalize(), " lost sight of player")

func damage_player(player):
	if not is_alive:
		return
	
	# Check if player has invincibility and use take_damage method
	if player.has_method("take_damage"):
		player.take_damage(damage_amount)
	elif HealthSystem and HealthSystem.has_method("lose_heart"):
		# Fallback to direct HealthSystem call
		for i in range(damage_amount):
			HealthSystem.lose_heart()
	
	# Emit signal
	player_damaged.emit(self, player, damage_amount)
	
	# Visual feedback
	create_damage_effect()
	
	print("👹 ", enemy_type.capitalize(), " attempted to damage player for ", damage_amount, " damage")

func create_damage_effect():
	# Screen flash
	if FX and FX.has_method("flash_screen"):
		FX.flash_screen(Color.RED, 0.15)
	
	# Screen shake
	if FX and FX.has_method("shake"):
		FX.shake(100)

func take_damage(amount: int = 1):
	if not is_alive:
		return
	
	current_health -= amount
	
	# Visual feedback for taking damage
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	print("👹 ", enemy_type.capitalize(), " took ", amount, " damage (", current_health, "/", health, " HP)")
	
	if current_health <= 0:
		defeat()

func defeat():
	if not is_alive:
		return
	
	is_alive = false
	
	# Add score
	Game.add_score(points_value)
	
	# Emit signal
	enemy_defeated.emit(self, points_value)
	
	# Create defeat effect
	create_defeat_effect()
	
	print("👹 ", enemy_type.capitalize(), " defeated! +", points_value, " points")

func create_defeat_effect():
	# Disable collision
	collision_shape.disabled = true
	if detection_area:
		detection_collision.disabled = true
	
	# Create floating text effect
	var effect_label = Label.new()
	effect_label.text = "+" + str(points_value)
	effect_label.add_theme_font_size_override("font_size", 16)
	effect_label.add_theme_color_override("font_color", Color.YELLOW)
	effect_label.position = global_position + Vector2(-20, -30)
	get_tree().current_scene.add_child(effect_label)
	
	# Animate the effect
	var tween = create_tween()
	tween.parallel().tween_property(effect_label, "position", effect_label.position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(effect_label.queue_free)
	
	# Animate enemy disappearing
	var death_tween = create_tween()
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
