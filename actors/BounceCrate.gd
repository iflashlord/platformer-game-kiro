extends StaticBody2D
class_name BounceCrate

signal fruit_collected(position: Vector2, fruits_remaining: int)
signal box_depleted(position: Vector2)

@export var player_bounce_force: float = 300.0
@export var initial_fruit_count: int = 5
@export var bounce_cooldown: float = 0.3

var fruits_remaining: int = 5
var is_bouncing: bool = false
var bounce_timer: float = 0.0

@onready var sprite: ColorRect = $CrateSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_collision: CollisionShape2D = $DetectionArea/DetectionCollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var fruit_label: Label = $FruitLabel

func _ready():
	# Connect area signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# Configure Area2D to monitor bodies
	detection_area.monitoring = true
	detection_area.monitorable = false
	
	# Initialize fruit count
	fruits_remaining = initial_fruit_count
	update_display()
	
	# Set orange color for fruit box
	sprite.color = Color.ORANGE
	
	# Add to groups
	add_to_group("fruit_boxes")
	add_to_group("interactive_objects")
	
	# Start idle animation
	animation_player.play("idle")
	
	print("Fruit box initialized with ", fruits_remaining, " fruits")
	print("Detection area monitoring: ", detection_area.monitoring)
	print("Detection area collision mask: ", detection_area.collision_mask)

func _physics_process(delta):
	if is_bouncing:
		bounce_timer += delta
		if bounce_timer >= bounce_cooldown:
			is_bouncing = false
			bounce_timer = 0.0

func _on_detection_area_body_entered(body):
	print("Body entered detection area: ", body.name)
	
	# Simple check - if it's a CharacterBody2D (player) and we have fruits
	if body is CharacterBody2D and fruits_remaining > 0 and not is_bouncing:
		print("Player detected! Activating fruit box...")
		
		# For now, always bounce the player up to test basic functionality
		bounce_player_up(body)

func bounce_player_up(player):
	print("Bouncing player up!")
	
	# Set bouncing state
	is_bouncing = true
	bounce_timer = 0.0
	
	# Bounce the player upward
	if "velocity" in player:
		player.velocity.y = -player_bounce_force
		print("Set player velocity to: ", player.velocity.y)
	
	# Set player jumping state if available
	if "is_jumping" in player:
		player.is_jumping = true
	
	# Consume a fruit
	consume_fruit()
	
	# Play bounce animation
	animation_player.play("bounce")
	
	print("Player bounced on fruit box! Fruits remaining: ", fruits_remaining)

func hit_from_below(player):
	print("Player hit from below!")
	
	# Set bouncing state (no player bounce, just fruit consumption)
	is_bouncing = true
	bounce_timer = 0.0
	
	# Consume a fruit
	consume_fruit()
	
	# Play bounce animation
	animation_player.play("bounce")
	
	print("Player hit fruit box from below! Fruits remaining: ", fruits_remaining)

func consume_fruit():
	if fruits_remaining > 0:
		fruits_remaining -= 1
		update_display()
		
		# Emit signal for fruit collection
		fruit_collected.emit(global_position, fruits_remaining)
		
		print("Fruit consumed! Remaining: ", fruits_remaining)
		
		# Check if box is depleted
		if fruits_remaining <= 0:
			deplete_box()

func update_display():
	# Update the number display
	fruit_label.text = str(fruits_remaining)
	
	# Change color based on remaining fruits
	var color_intensity = float(fruits_remaining) / float(initial_fruit_count)
	sprite.color = Color.ORANGE.lerp(Color.DARK_ORANGE, 1.0 - color_intensity)

func deplete_box():
	# Box is empty, prepare for removal
	print("Fruit box depleted!")
	
	# Emit depletion signal
	box_depleted.emit(global_position)
	
	# Play depletion animation
	animation_player.play("deplete")
	
	# Disable collision and areas
	collision_shape.disabled = true
	detection_collision.disabled = true
	
	# Queue for removal after animation
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout.connect(queue_free)

func _on_detection_area_body_exited(body):
	print("Body exited detection area: ", body.name)
