extends CharacterBody2D
class_name EnemyCharger

signal player_detected(player: Player)
signal charge_started
signal charge_completed
signal enemy_defeated

enum ChargerState {
	IDLE,
	DETECTING,
	WINDING_UP,
	CHARGING,
	RECOVERING,
	STUNNED
}

@export var detection_radius: float = 150.0
@export var charge_speed: float = 400.0
@export var windup_time: float = 1.0
@export var charge_distance: float = 200.0
@export var recovery_time: float = 1.5
@export var stun_time: float = 2.0
@export var health: int = 2
@export var damage_to_player: int = 1

var current_state: ChargerState = ChargerState.IDLE
var state_timer: float = 0.0
var target_player: Player = null
var charge_direction: Vector2 = Vector2.ZERO
var charge_start_position: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_collision: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var dimension_node: DimensionNode = $DimensionNode
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var windup_particles: CPUParticles2D = $WindupParticles
@onready var charge_particles: CPUParticles2D = $ChargeParticles

func _ready():
	# Add to enemy group
	add_to_group("enemies")
	
	# Store original position
	original_position = global_position
	
	# Setup detection area
	setup_detection_area()
	
	# Connect signals
	detection_area.body_entered.connect(_on_player_entered_detection)
	detection_area.body_exited.connect(_on_player_exited_detection)
	
	# Start in idle state
	set_state(ChargerState.IDLE)

func _physics_process(delta):
	if get_tree().paused:
		return
	
	state_timer += delta
	
	match current_state:
		ChargerState.IDLE:
			handle_idle_state(delta)
		ChargerState.DETECTING:
			handle_detecting_state(delta)
		ChargerState.WINDING_UP:
			handle_windup_state(delta)
		ChargerState.CHARGING:
			handle_charging_state(delta)
		ChargerState.RECOVERING:
			handle_recovery_state(delta)
		ChargerState.STUNNED:
			handle_stunned_state(delta)
	
	move_and_slide()

func setup_detection_area():
	# Create circular detection area
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = detection_radius
	detection_collision.shape = circle_shape

func set_state(new_state: ChargerState):
	# Exit current state
	exit_state(current_state)
	
	# Set new state
	current_state = new_state
	state_timer = 0.0
	
	# Enter new state
	enter_state(new_state)

func enter_state(state: ChargerState):
	match state:
		ChargerState.IDLE:
			velocity = Vector2.ZERO
			if animation_player:
				animation_player.play("idle")
		ChargerState.DETECTING:
			if animation_player:
				animation_player.play("alert")
		ChargerState.WINDING_UP:
			velocity = Vector2.ZERO
			if animation_player:
				animation_player.play("windup")
			if windup_particles:
				windup_particles.emitting = true
			# Visual warning
			sprite.modulate = Color.ORANGE
		ChargerState.CHARGING:
			charge_started.emit()
			if animation_player:
				animation_player.play("charge")
			if charge_particles:
				charge_particles.emitting = true
			# Store charge start position
			charge_start_position = global_position
		ChargerState.RECOVERING:
			velocity = Vector2.ZERO
			if animation_player:
				animation_player.play("recover")
			sprite.modulate = Color.WHITE
		ChargerState.STUNNED:
			velocity = Vector2.ZERO
			if animation_player:
				animation_player.play("stunned")
			sprite.modulate = Color.BLUE

func exit_state(state: ChargerState):
	match state:
		ChargerState.WINDING_UP:
			if windup_particles:
				windup_particles.emitting = false
		ChargerState.CHARGING:
			if charge_particles:
				charge_particles.emitting = false
			charge_completed.emit()

func handle_idle_state(delta):
	# Look for player in detection range
	if target_player and is_player_in_range():
		set_state(ChargerState.DETECTING)

func handle_detecting_state(delta):
	if not target_player or not is_player_in_range():
		set_state(ChargerState.IDLE)
		return
	
	# Face the player
	var direction_to_player = (target_player.global_position - global_position).normalized()
	sprite.flip_h = direction_to_player.x < 0
	
	# Start charging after detection delay
	if state_timer >= 0.5:
		prepare_charge()

func handle_windup_state(delta):
	# Blink warning effect
	var blink_speed = 10.0
	sprite.modulate.a = (sin(state_timer * blink_speed) + 1.0) / 2.0 + 0.5
	
	if state_timer >= windup_time:
		set_state(ChargerState.CHARGING)

func handle_charging_state(delta):
	# Move in charge direction
	velocity = charge_direction * charge_speed
	
	# Check if traveled charge distance or hit wall
	var distance_traveled = global_position.distance_to(charge_start_position)
	if distance_traveled >= charge_distance or is_on_wall():
		set_state(ChargerState.RECOVERING)

func handle_recovery_state(delta):
	if state_timer >= recovery_time:
		set_state(ChargerState.IDLE)

func handle_stunned_state(delta):
	if state_timer >= stun_time:
		set_state(ChargerState.IDLE)

func prepare_charge():
	if not target_player:
		return
	
	# Calculate charge direction
	charge_direction = (target_player.global_position - global_position).normalized()
	
	# Start windup
	set_state(ChargerState.WINDING_UP)

func is_player_in_range() -> bool:
	if not target_player:
		return false
	
	return global_position.distance_to(target_player.global_position) <= detection_radius

#func is_on_wall() -> bool:
	#return is_on_wall_only()

func _on_player_entered_detection(body):
	if body is Player:
		target_player = body
		player_detected.emit(body)
		print("Player entered charger detection range")

func _on_player_exited_detection(body):
	if body is Player and body == target_player:
		target_player = null
		print("Player exited charger detection range")

func _on_body_entered(body):
	if body is Player and current_state == ChargerState.CHARGING:
		# Damage player during charge
		if body.has_method("take_damage"):
			body.take_damage(damage_to_player)
		else:
			body.die()
		
		# Stun self after hitting player
		set_state(ChargerState.STUNNED)

func take_damage(amount: int = 1):
	health -= amount
	
	# Visual feedback
	FX.shake(150)
	sprite.modulate = Color.RED
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	if health <= 0:
		defeat()
	else:
		# Stun on damage
		set_state(ChargerState.STUNNED)

func defeat():
	enemy_defeated.emit()
	
	# Death effects
	FX.shake(250)
	FX.flash_screen(Color.RED, 0.2)
	
	# Death animation
	if animation_player:
		animation_player.play("death")
	
	# Disable collision
	collision_shape.disabled = true
	detection_collision.disabled = true
	
	# Remove after delay
	await get_tree().create_timer(1.5).timeout
	queue_free()

func reset_to_original_position():
	global_position = original_position
	set_state(ChargerState.IDLE)
	health = 2
