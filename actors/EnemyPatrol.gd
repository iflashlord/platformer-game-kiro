extends CharacterBody2D
class_name EnemyPatrol

signal player_detected(player: Player)
signal enemy_defeated
signal enemy_respawned

@export var patrol_speed: float = 50.0
@export var waypoints: Array[Vector2] = []
@export var ledge_detection_distance: float = 32.0
@export var turn_on_wall: bool = true
@export var turn_on_ledge: bool = true
@export var health: int = 1
@export var damage_to_player: int = 1

var current_waypoint_index: int = 0
var direction: int = 1
var is_alive: bool = true
var is_turning: bool = false
var turn_timer: float = 0.0
var turn_duration: float = 0.5

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ledge_detector: RayCast2D = $LedgeDetector
@onready var player_detector: Area2D = $PlayerDetector
@onready var dimension_node: DimensionNode = $DimensionNode
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Add to enemy group
	add_to_group("enemies")
	
	# Setup detectors
	setup_detectors()
	
	# Start patrol animation
	if animation_player:
		animation_player.play("walk")
	
	# Initialize waypoint system
	if waypoints.is_empty():
		# Create default waypoints if none specified
		waypoints = [global_position - Vector2(100, 0), global_position + Vector2(100, 0)]

func _physics_process(delta):
	if not is_alive or get_tree().paused:
		return
	
	handle_turning(delta)
	
	if not is_turning:
		handle_patrol_movement(delta)
		check_obstacles()
	
	move_and_slide()

func setup_detectors():
	# Setup wall detector
	wall_detector.target_position = Vector2(ledge_detection_distance * direction, 0)
	wall_detector.collision_mask = 1 # Ground layer
	
	# Setup ledge detector
	ledge_detector.target_position = Vector2(ledge_detection_distance * direction, ledge_detection_distance)
	ledge_detector.collision_mask = 1 # Ground layer
	
	# Connect player detector
	if player_detector:
		player_detector.body_entered.connect(_on_player_detected)

func handle_patrol_movement(delta):
	if waypoints.size() < 2:
		return
	
	var target_waypoint = waypoints[current_waypoint_index]
	var distance_to_waypoint = global_position.distance_to(target_waypoint)
	
	# Check if reached waypoint
	if distance_to_waypoint < 10.0:
		# Move to next waypoint
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()
		target_waypoint = waypoints[current_waypoint_index]
	
	# Move towards waypoint
	var move_direction = (target_waypoint - global_position).normalized()
	velocity.x = move_direction.x * patrol_speed
	
	# Update sprite direction
	update_sprite_direction(move_direction.x)

func check_obstacles():
	var should_turn = false
	
	# Check for walls
	if turn_on_wall and wall_detector.is_colliding():
		should_turn = true
		print("Enemy hit wall, turning around")
	
	# Check for ledges
	if turn_on_ledge and not ledge_detector.is_colliding() and is_on_floor():
		should_turn = true
		print("Enemy reached ledge, turning around")
	
	if should_turn:
		start_turn()

func start_turn():
	if is_turning:
		return
	
	is_turning = true
	turn_timer = 0.0
	velocity.x = 0
	
	# Play turn animation
	if animation_player:
		animation_player.play("turn")

func handle_turning(delta):
	if not is_turning:
		return
	
	turn_timer += delta
	
	if turn_timer >= turn_duration:
		complete_turn()

func complete_turn():
	is_turning = false
	direction *= -1
	
	# Update detector positions
	wall_detector.target_position = Vector2(ledge_detection_distance * direction, 0)
	ledge_detector.target_position = Vector2(ledge_detection_distance * direction, ledge_detection_distance)
	
	# Resume walking animation
	if animation_player:
		animation_player.play("walk")

func update_sprite_direction(move_x: float):
	if abs(move_x) > 0.1:
		sprite.flip_h = move_x < 0

func _on_player_detected(body):
	if body is Player:
		player_detected.emit(body)
		# Damage player on contact
		if body.has_method("take_damage"):
			body.take_damage(damage_to_player)
		else:
			body.die()

func take_damage(amount: int = 1):
	if not is_alive:
		return
	
	health -= amount
	
	# Visual feedback
	FX.shake(100)
	sprite.modulate = Color.RED
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	if health <= 0:
		defeat()

func defeat():
	if not is_alive:
		return
	
	is_alive = false
	enemy_defeated.emit()
	
	# Death animation
	if animation_player:
		animation_player.play("death")
	
	# Disable collision
	collision_shape.disabled = true
	
	# Visual effects
	FX.shake(200)
	
	# Remove after animation
	await get_tree().create_timer(1.0).timeout
	queue_free()

func respawn():
	is_alive = true
	health = 1
	collision_shape.disabled = false
	sprite.modulate = Color.WHITE
	
	# Reset position to first waypoint
	if waypoints.size() > 0:
		global_position = waypoints[0]
		current_waypoint_index = 0
	
	# Resume animations
	if animation_player:
		animation_player.play("walk")
	
	enemy_respawned.emit()

func set_waypoints(new_waypoints: Array[Vector2]):
	waypoints = new_waypoints
	current_waypoint_index = 0