extends StaticBody2D
class_name Spike

signal player_damaged(player: Player)

@export var damage: int = 1
@export var auto_scroll_speed: float = 0.0
@export var spike_direction: Vector2 = Vector2.UP
@export var retract_on_hit: bool = false
@export var retract_time: float = 2.0

var is_extended: bool = true
var is_retracting: bool = false
var retract_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var dimension_node: DimensionNode = $DimensionNode
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Add to hazards group
	add_to_group("hazards")
	add_to_group("spikes")
	
	# Connect damage area
	if damage_area:
		damage_area.body_entered.connect(_on_player_entered)
	
	# Set spike appearance based on direction
	setup_spike_direction()
	
	# Start animation
	if animation_player:
		animation_player.play("idle")

func _physics_process(delta):
	# Handle auto-scroll movement
	if auto_scroll_speed != 0.0:
		global_position.x += auto_scroll_speed * delta
	
	# Handle retraction
	if is_retracting:
		retract_timer += delta
		if retract_timer >= retract_time:
			extend_spike()

func setup_spike_direction():
	# Rotate sprite based on spike direction
	if spike_direction == Vector2.UP:
		sprite.rotation = 0
	elif spike_direction == Vector2.DOWN:
		sprite.rotation = PI
	elif spike_direction == Vector2.LEFT:
		sprite.rotation = -PI/2
	elif spike_direction == Vector2.RIGHT:
		sprite.rotation = PI/2

func _on_player_entered(body):
	if body is Player and is_extended:
		damage_player(body)

func damage_player(player: Player):
	player_damaged.emit(player)
	
	# Damage the player
	if player.has_method("take_damage"):
		player.take_damage(damage)
	else:
		player.die()
	
	# Visual feedback
	FX.shake(100)
	FX.flash_screen(Color.RED, 0.1)
	
	# Retract if configured
	if retract_on_hit:
		retract_spike()
	
	print("Spike damaged player for ", damage, " damage")

func retract_spike():
	if not is_extended or is_retracting:
		return
	
	is_extended = false
	is_retracting = true
	retract_timer = 0.0
	
	# Visual retraction
	if animation_player:
		animation_player.play("retract")
	
	# Disable collision temporarily
	collision_shape.disabled = true
	if damage_area:
		damage_area.get_child(0).disabled = true

func extend_spike():
	is_extended = true
	is_retracting = false
	
	# Visual extension
	if animation_player:
		animation_player.play("extend")
	
	# Re-enable collision
	collision_shape.disabled = false
	if damage_area:
		damage_area.get_child(0).disabled = false

func set_auto_scroll_speed(speed: float):
	auto_scroll_speed = speed

func is_spike_extended() -> bool:
	return is_extended