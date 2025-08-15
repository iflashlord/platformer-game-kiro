extends Area2D
class_name DeathZone

signal player_killed(death_zone: DeathZone, player: Node2D)

@export var damage_amount: int = 1
@export var instant_kill: bool = true
@export var zone_type: String = "pit"
@export var respawn_player: bool = true

var players_in_zone: Array[Node2D] = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_indicator: ColorRect = null

func _ready():
	add_to_group("death_zones")
	add_to_group("hazards")
	
	# Set up collision detection
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set collision layers
	collision_layer = 64  # Death zone layer
	collision_mask = 2    # Player layer
	
	# Create visual indicator if none exists
	if not has_node("VisualIndicator"):
		create_visual_indicator()
	else:
		visual_indicator = $VisualIndicator
	
	# Set appearance based on zone type
	setup_zone_appearance()

func create_visual_indicator():
	visual_indicator = ColorRect.new()
	visual_indicator.name = "VisualIndicator"
	
	# Get the collision shape size to match visual
	if collision_shape and collision_shape.shape:
		var shape = collision_shape.shape
		if shape is RectangleShape2D:
			var rect_shape = shape as RectangleShape2D
			visual_indicator.size = rect_shape.size
			visual_indicator.position = -rect_shape.size / 2
		elif shape is CircleShape2D:
			var circle_shape = shape as CircleShape2D
			var diameter = circle_shape.radius * 2
			visual_indicator.size = Vector2(diameter, diameter)
			visual_indicator.position = Vector2(-circle_shape.radius, -circle_shape.radius)
	else:
		# Default size
		visual_indicator.size = Vector2(100, 50)
		visual_indicator.position = Vector2(-50, -25)
	
	add_child(visual_indicator)

func setup_zone_appearance():
	if not visual_indicator:
		return
	
	match zone_type:
		"pit":
			visual_indicator.color = Color(0.1, 0.1, 0.1, 0.8)  # Dark pit
		"lava":
			visual_indicator.color = Color(1, 0.3, 0, 0.8)  # Orange lava
		"water":
			visual_indicator.color = Color(0, 0.3, 1, 0.6)  # Blue water
		"void":
			visual_indicator.color = Color(0.2, 0, 0.5, 0.9)  # Purple void
		"spikes":
			visual_indicator.color = Color(0.6, 0.6, 0.6, 0.8)  # Gray spikes
		_:
			visual_indicator.color = Color(0.5, 0, 0, 0.7)  # Default red

func _on_body_entered(body):
	print("💀 DeathZone collision detected with: ", body.name, " (groups: ", body.get_groups(), ")")
	if body.is_in_group("player"):
		print("💀 Player entered death zone: ", zone_type)
		players_in_zone.append(body)
		kill_player(body)
	else:
		print("💀 Non-player entered death zone")

func _on_body_exited(body):
	if body.is_in_group("player") and body in players_in_zone:
		players_in_zone.erase(body)

func kill_player(player):
	# Emit signal for tracking
	player_killed.emit(self, player)
	
	if instant_kill:
		# Instant death
		print("💀 Instant kill in ", zone_type, " death zone")
		
		# Apply damage through HealthSystem
		if HealthSystem:
			if HealthSystem.has_method("kill_player"):
				HealthSystem.kill_player()
			elif HealthSystem.has_method("take_damage"):
				# Take all remaining health
				var remaining_health = HealthSystem.get_current_health()
				HealthSystem.take_damage(remaining_health)
		
		# Fallback: call player's die method directly
		if player.has_method("die"):
			player.die()
	else:
		# Gradual damage
		print("💔 Taking ", damage_amount, " damage in ", zone_type, " death zone")
		
		if HealthSystem and HealthSystem.has_method("take_damage"):
			HealthSystem.take_damage(damage_amount)
		elif player.has_method("take_damage"):
			player.take_damage(damage_amount)
	
	# Visual feedback
	create_death_effect(player)
	
	# Respawn player if configured
	if respawn_player and Respawn and Respawn.has_method("respawn_player"):
		# Small delay before respawn
		await get_tree().create_timer(0.5).timeout
		Respawn.respawn_player()

func create_death_effect(player):
	# Screen flash
	if FX and FX.has_method("flash_screen"):
		match zone_type:
			"lava":
				FX.flash_screen(Color.ORANGE, 0.3)
			"water":
				FX.flash_screen(Color.BLUE, 0.3)
			"void":
				FX.flash_screen(Color.PURPLE, 0.3)
			_:
				FX.flash_screen(Color.RED, 0.3)
	
	# Screen shake
	if FX and FX.has_method("shake"):
		FX.shake(200)
	
	# Death particles effect (simple color animation)
	var death_effect = ColorRect.new()
	death_effect.size = Vector2(50, 50)
	death_effect.position = player.global_position + Vector2(-25, -25)
	death_effect.color = Color.RED
	get_tree().current_scene.add_child(death_effect)
	
	# Animate death effect
	var tween = create_tween()
	tween.parallel().tween_property(death_effect, "scale", Vector2(2.0, 2.0), 0.5)
	tween.parallel().tween_property(death_effect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(death_effect.queue_free)

func set_zone_type(new_type: String):
	zone_type = new_type
	setup_zone_appearance()

func set_instant_kill(enabled: bool):
	instant_kill = enabled

func set_damage_amount(amount: int):
	damage_amount = amount
	instant_kill = false  # If setting damage, assume not instant kill