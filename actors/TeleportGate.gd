extends Area2D
class_name TeleportGate

@export var teleport_target: TeleportGate  # Direct reference to partner gate
@export var teleport_cooldown: float = 1.0  # Prevent rapid teleporting
@export var teleport_offset: Vector2 = Vector2(0, -20)  # Offset from target position

var is_active: bool = true
var cooldown_timer: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var port_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	
	# Configure Area2D
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2  # Detect player (player is on layer 2)
	
	print("TeleportGate ready - monitoring: ", monitoring, " mask: ", collision_mask)
	print("TeleportGate target: ", teleport_target)

func _process(delta):
	# Handle cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_active = true
	
	# Update visual state
	update_visual_state()

func _on_body_entered(body):
	print("Body entered gate: ", body.name, " Groups: ", body.get_groups())
	
	if not body.is_in_group("player"):
		print("Not a player, ignoring")
		return
	
	if not is_active:
		print("Gate not active (cooldown)")
		return
		
	if not teleport_target:
		print("No teleport target set!")
		return
	
	print("All checks passed, teleporting...")
	teleport_player(body)

func teleport_player(player):
	if not teleport_target or not is_active:
		return
	
	print("Teleporting player")
	
	# Play teleport sound effect
	Audio.play_sfx("teleport")
	
	# Deactivate both gates temporarily
	is_active = false
	cooldown_timer = teleport_cooldown
	teleport_target.is_active = false
	teleport_target.cooldown_timer = teleport_cooldown
	
	# Calculate teleport position
	var teleport_position = teleport_target.global_position + teleport_offset
	
	# Simple teleport effects
	create_simple_effect(global_position)
	create_simple_effect(teleport_position)
	
	# Move player
	player.global_position = teleport_position
	
	print("Player teleported successfully!")

func create_simple_effect(pos: Vector2):
	# Create simple particle burst
	for i in range(10):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color.CYAN
		particle.position = pos + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		get_tree().current_scene.add_child(particle)
		
		# Simple fade animation
		var tween = create_tween()
		tween.tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)

func update_visual_state():
	if not port_sprite:
		return
	
	if is_active:
		# Active state - bright cyan with simple pulse
		var pulse = (sin(Time.get_unix_time_from_system() * 2.0) + 1.0) / 2.0
		port_sprite.modulate.a = 0.8 + (pulse * 0.2)
	else:
		# Inactive state - dimmed
		port_sprite.modulate.a = 0.4
