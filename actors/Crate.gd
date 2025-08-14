extends RigidBody2D
class_name Crate

signal broken(crate_type: String)

enum CrateState {
	IDLE,
	BOUNCING,
	EXPLODING,
	BROKEN
}

@export var crate_type: String = "basic"
@export var health: int = 1
@export var bounce_force: float = 300.0
@export var break_threshold: float = 200.0
@export var shard_count: int = 6
@export var shard_color: Color = Color.WHITE

var current_state: CrateState = CrateState.IDLE
var state_timer: float = 0.0
var original_position: Vector2

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var area: Area2D = $Area2D
@onready var area_collision: CollisionShape2D = $Area2D/CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	area.body_entered.connect(_on_area_body_entered)
	
	# Store original position
	original_position = global_position
	
	# Set initial state
	set_state(CrateState.IDLE)
	
	# Add to crate group
	add_to_group("crates")

func _physics_process(delta):
	state_timer += delta
	
	match current_state:
		CrateState.IDLE:
			handle_idle_state(delta)
		CrateState.BOUNCING:
			handle_bouncing_state(delta)
		CrateState.EXPLODING:
			handle_exploding_state(delta)
		CrateState.BROKEN:
			handle_broken_state(delta)
	
	# Check for high-speed impacts
	if linear_velocity.length() > break_threshold and current_state != CrateState.BROKEN:
		take_damage(1)

func set_state(new_state: CrateState):
	if current_state == new_state:
		return
	
	# Exit current state
	match current_state:
		CrateState.BOUNCING:
			exit_bouncing_state()
		CrateState.EXPLODING:
			exit_exploding_state()
	
	# Set new state
	current_state = new_state
	state_timer = 0.0
	
	# Enter new state
	match new_state:
		CrateState.IDLE:
			enter_idle_state()
		CrateState.BOUNCING:
			enter_bouncing_state()
		CrateState.EXPLODING:
			enter_exploding_state()
		CrateState.BROKEN:
			enter_broken_state()

func enter_idle_state():
	animation_player.play("idle")

func handle_idle_state(delta):
	# Base idle behavior - can be overridden
	pass

func enter_bouncing_state():
	animation_player.play("bounce")
	# Add upward force
	apply_central_impulse(Vector2(0, -bounce_force))

func handle_bouncing_state(delta):
	# Return to idle after bounce animation
	if state_timer > 0.5:
		set_state(CrateState.IDLE)

func exit_bouncing_state():
	pass

func enter_exploding_state():
	animation_player.play("explode")
	# Visual effects
	FX.shake(200)
	FX.flash_screen(Color.ORANGE, 0.1)

func handle_exploding_state(delta):
	# Transition to broken after explosion animation
	if state_timer > 0.3:
		set_state(CrateState.BROKEN)

func exit_exploding_state():
	pass

func enter_broken_state():
	# Hide sprite and disable collision
	sprite.visible = false
	collision_shape.disabled = true
	area_collision.disabled = true
	
	# Spawn shards and effects
	spawn_break_effects()
	
	# Emit signal
	broken.emit(crate_type)
	
	# Queue for removal
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout.connect(queue_free)

func handle_broken_state(delta):
	# Already handled in enter_broken_state
	pass

func spawn_break_effects():
	# Spawn shards using object pool
	ObjectPool.spawn_shards(global_position, shard_count, shard_color)
	
	# Override in derived classes for specific effects
	spawn_specific_effects()

func spawn_specific_effects():
	# Override in derived classes
	pass

func take_damage(amount: int = 1):
	if current_state == CrateState.BROKEN:
		return
	
	health -= amount
	
	if health <= 0:
		break_crate()
	else:
		# Bounce on damage
		set_state(CrateState.BOUNCING)

func break_crate():
	if current_state != CrateState.BROKEN:
		set_state(CrateState.EXPLODING)

func _on_body_entered(body):
	if body is Player and current_state == CrateState.IDLE:
		# Player landed on crate
		set_state(CrateState.BOUNCING)

func _on_area_body_entered(body):
	if body is Player:
		# Player touched crate area
		on_player_interaction(body)

func on_player_interaction(player: Player):
	# Override in derived classes
	take_damage(1)