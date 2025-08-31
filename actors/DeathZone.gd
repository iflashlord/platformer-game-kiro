@tool
extends Area2D
class_name DeathZone

signal player_killed(death_zone: DeathZone, player: Node2D)

@export var damage_amount: int = 1
@export var instant_kill: bool = true
@export var zone_type: String = "pit"
@export var respawn_player: bool = true
@export var width: int = 200 : set = set_width
@export var height: int = 50 : set = set_height

var players_in_zone: Array[Node2D] = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_graphics: NinePatchRect = $NinePatchRect
var visual_indicator: ColorRect = null

func _ready():
	# Skip setup in editor mode
	if Engine.is_editor_hint():
		return
		
	add_to_group("death_zones")
	add_to_group("hazards")

	
	# Set up collision detection
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	
	# Set collision layers
	collision_layer = 64  # Death zone layer
	collision_mask = 2    # Player layer
	
	# Wait for scene to be fully loaded before setting up visuals
	call_deferred("_setup_visuals")

func _setup_visuals():
	if Engine.is_editor_hint():
		return
		
	# Create visual indicator if none exists
	if not has_node("VisualIndicator"):
		create_visual_indicator()
	else:
		visual_indicator = $VisualIndicator
	
	# Update all components with proper positioning
	_update_visual_and_collision()

	# Set appearance based on zone type
	setup_zone_appearance()

func create_visual_indicator():
	if not _validate_setup():
		return
	
	visual_indicator = ColorRect.new()
	visual_indicator.name = "VisualIndicator"

	
	# Just create the visual indicator, positioning will be handled by _update_visual_and_collision()
	visual_indicator.size = Vector2(width, height)
	visual_indicator.position = Vector2(0, -height/2)
	
	# Add to scene tree safely
	add_child(visual_indicator)

func setup_zone_appearance():
	if not visual_indicator or not is_instance_valid(visual_indicator):
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

func _validate_setup() -> bool:
	if not collision_shape:
		push_error("DeathZone: CollisionShape2D not found")
		return false
	
	if not collision_shape.shape:
		push_error("DeathZone: CollisionShape2D has no shape assigned")
		return false
	
	return true

func _on_body_entered(body):
	if Engine.is_editor_hint():
		return
		
	print("💀 DeathZone collision detected with: ", body.name, " (groups: ", body.get_groups(), ")")
	if body.is_in_group("player"):
		print("💀 Player entered death zone: ", zone_type)
		players_in_zone.append(body)
		kill_player(body)
	else:
		print("💀 Non-player entered death zone")

func _on_body_exited(body):
	if Engine.is_editor_hint():
		return
		
	if body.is_in_group("player") and body in players_in_zone:
		players_in_zone.erase(body)

func _exit_tree():
	# Clean up any remaining references
	players_in_zone.clear()
	
	# Disconnect signals if connected
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	if body_exited.is_connected(_on_body_exited):
		body_exited.disconnect(_on_body_exited)

func kill_player(player):
	# Emit signal for tracking
	player_killed.emit(self, player)
	
	if instant_kill:
		# Instant death
		print("💀 Instant kill in ", zone_type, " death zone")
		
		# Apply damage through HealthSystem if available
		var health_system_found = false
		if has_node("/root/HealthSystem"):
			var health_system = get_node("/root/HealthSystem")
			if health_system.has_method("kill_player"):
				health_system.kill_player()
				health_system_found = true
			elif health_system.has_method("take_damage"):
				health_system.take_damage(999)  # Large damage for instant kill
				health_system_found = true
		
		# Fallback: call player's die method directly
		if not health_system_found and player.has_method("die"):
			player.die()
	else:
		# Gradual damage
		print("💔 Taking ", damage_amount, " damage in ", zone_type, " death zone")
		
		var damage_applied = false
		if has_node("/root/HealthSystem"):
			var health_system = get_node("/root/HealthSystem")
			if health_system.has_method("take_damage"):
				health_system.take_damage(damage_amount)
				damage_applied = true
		
		if not damage_applied and player.has_method("take_damage"):
			player.take_damage(damage_amount)
	
	# Visual feedback
	create_death_effect(player)
	
	# Respawn player if configured
	if respawn_player and has_node("/root/Respawn"):
		var respawn_system = get_node("/root/Respawn")
		if respawn_system.has_method("respawn_player"):
			# Small delay before respawn
			await get_tree().create_timer(0.5).timeout
			respawn_system.respawn_player()

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
	death_effect.size = Vector2(45, 45)
	death_effect.position = player.global_position + Vector2(-30, -30)
	death_effect.color = Color.RED
	
	# Safely add to scene tree
	if get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(death_effect)
		
		# Animate death effect
		var tween = create_tween()
		tween.parallel().tween_property(death_effect, "scale", Vector2(2.0, 2.0), 0.5)
		tween.parallel().tween_property(death_effect, "modulate:a", 0.0, 0.5)
		tween.tween_callback(death_effect.queue_free)

func _update_visual_and_collision():
	# Update visual graphics
	if visual_graphics and is_instance_valid(visual_graphics):
		visual_graphics.size = Vector2(width, height)
		visual_graphics.position = Vector2(0, -height/2)
	
	# Update visual indicator
	if visual_indicator and is_instance_valid(visual_indicator):
		visual_indicator.size = Vector2(width, height)
		visual_indicator.position = Vector2(0, -height/2)
	
	# Update collision shape
	if collision_shape and is_instance_valid(collision_shape) and collision_shape.shape:
		if collision_shape.shape is RectangleShape2D:
			var rect_shape = collision_shape.shape as RectangleShape2D
			rect_shape.size = Vector2(width, height)
			collision_shape.position = Vector2(width/2, 0)
	
func set_zone_type(new_type: String):
	zone_type = new_type
	setup_zone_appearance()

func set_instant_kill(enabled: bool):
	instant_kill = enabled

func set_damage_amount(amount: int):
	damage_amount = amount
	instant_kill = false  # If setting damage, assume not instant kill

func set_width(new_width: int):
	width = maxf(new_width, 8.0)  # Minimum width of 8 pixels 
	_update_visual_and_collision()
	# Force update in editor
	if Engine.is_editor_hint():
		notify_property_list_changed()

func set_height(new_height: int):
	height = maxf(new_height, 8.0)  # Minimum height of 8 pixels 
	_update_visual_and_collision()
	# Force update in editor
	if Engine.is_editor_hint():
		notify_property_list_changed()
