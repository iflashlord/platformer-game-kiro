@tool
extends Area2D
class_name DeathZone

signal player_killed(death_zone: DeathZone, player: Node2D)

@export var damage_amount: int = 1
@export var instant_kill: bool = true
@export_enum("pit", "lava", "water", "void", "spikes") var zone_type: String = "pit"
@export var respawn_player: bool = true
@export var width: int = 200 : set = set_width
@export var height: int = 50 : set = set_height
@export_group("Dimension")
@export var target_layer: String = "A"  # For dimension system compatibility
@export var visible_in_both_dimensions: bool = false  # Show in both dimensions A and B

var players_in_zone: Array[Node2D] = []

# Dimension system compatibility
var dimension_manager: Node
var is_active_in_current_layer: bool = true

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_graphics: NinePatchRect = $NinePatchRect
var visual_indicator: ColorRect = null
const SOUL_TEXTURE := preload("res://content/Graphics/Sprites/Characters/Double/character_beige_front.png")

func _ready():
	# Always setup visuals for editor preview
	call_deferred("_setup_visuals")
	
	# Skip runtime setup in editor mode
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
	
	# Setup dimension system
	_setup_dimension_system()

func _setup_visuals():
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
			visual_graphics.texture = preload("res://content/Graphics/Sprites/Tiles/Default/water_top_low.png")
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
	
	# Play visual feedback; let Player.die()/HealthSystem handle respawn timing
	create_death_effect(player)


	# Helper to make a circle polygon
func _make_circle(radius: float, segments: int = 24) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(segments):
		var ang = TAU * float(i) / float(segments)
		points.append(Vector2(cos(ang), sin(ang)) * radius)
	return points


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

	# Derive color by zone type
	var zone_color: Color
	match zone_type:
		"lava":
			zone_color = Color(1, 0.3, 0, 0.8)  # Orange
		"water":
			zone_color = Color(0, 0.3, 1, 0.8)  # Blue
		"void":
			zone_color = Color(0.5, 0, 0.5, 0.8)  # Purple
		"spikes":
			zone_color = Color(0.8, 0.8, 0.8, 0.8)  # Light gray
		_:
			zone_color = Color(1, 0, 0, 0.8)  # Red

	# Safely add to scene tree
	if get_tree() and get_tree().current_scene:
		var root = get_tree().current_scene

		# Circular burst effect (instead of square)
		var ring := Polygon2D.new()
		ring.polygon = _make_circle(18.0)
		ring.color = zone_color
		ring.global_position = player.global_position
		root.add_child(ring)
		var ring_tween = create_tween()
		ring_tween.parallel().tween_property(ring, "scale", Vector2(2.0, 2.0), 0.5)
		ring_tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.5)
		ring_tween.tween_callback(ring.queue_free)

		# Soul rising effect using front character texture (2 seconds, alpha 0.4)
		var soul := Sprite2D.new()
		soul.texture = SOUL_TEXTURE
		soul.global_position = player.global_position
		soul.modulate = Color(1, 1, 1, 0.4)
		soul.scale = Vector2(0.2, 0.2)
		root.add_child(soul)
		# Animate the soul rising
		var soul_tween = create_tween()
		soul_tween.parallel().tween_property(soul, "global_position", soul.global_position + Vector2(0, -80), 2.0)
		# Keep alpha constant; add subtle scale up to match feel
		soul_tween.parallel().tween_property(soul, "scale", Vector2(0.24, 0.24), 2.0)
		soul_tween.tween_callback(soul.queue_free)
		# Wait for the soul animation to finish before returning
		await soul_tween.finished
	else:
		# If no scene tree, just wait 2s to simulate animation duration
		await get_tree().create_timer(2.0).timeout

func _update_visual_and_collision():
	# Update visual graphics (NinePatchRect)
	if visual_graphics and is_instance_valid(visual_graphics):
		visual_graphics.size = Vector2(width, height)
		visual_graphics.position = Vector2(0, -height/2)
	
	# Update visual indicator
	if visual_indicator and is_instance_valid(visual_indicator):
		visual_indicator.size = Vector2(width, height)
		visual_indicator.position = Vector2(0, -height/2)
	
	# CRITICAL FIX: Always create a new RectangleShape2D instance to avoid shared resources
	if collision_shape and is_instance_valid(collision_shape):
		var shape = RectangleShape2D.new()
		collision_shape.shape = shape
		
		# CRITICAL: Collision shape must match visual size exactly
		shape.size = Vector2(width, height)  # Exact same size as visual
		collision_shape.position = Vector2(width / 2, height / 2)  # Centered on visual
	
	# Validate that collision shape matches visuals exactly
	_validate_collision_alignment()
	
	if not Engine.is_editor_hint():
		print("💀 Updated DeathZone: Size=", Vector2(width, height), " Type=", zone_type)
	
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
	if is_inside_tree():
		_update_visual_and_collision()
		# Force update in editor
		if Engine.is_editor_hint():
			notify_property_list_changed()

func set_height(new_height: int):
	height = maxf(new_height, 8.0)  # Minimum height of 8 pixels 
	if is_inside_tree():
		_update_visual_and_collision()
		# Force update in editor
		if Engine.is_editor_hint():
			notify_property_list_changed()

# Validation method to ensure collision shape matches visuals exactly
func _validate_collision_alignment():
	if not visual_graphics or not collision_shape:
		return
	
	var shape = collision_shape.shape as RectangleShape2D
	if not shape:
		return
	
	# Ensure collision shape size matches visual size exactly
	var visual_size = visual_graphics.size
	var collision_size = shape.size
	
	if not visual_size.is_equal_approx(collision_size):
		push_warning("DeathZone: Collision shape size mismatch! Visual: " + str(visual_size) + " vs Collision: " + str(collision_size))
		# Force correction
		shape.size = visual_size
	
	# Ensure collision shape is centered on visual
	var expected_position = Vector2(visual_size.x / 2, visual_size.y / 2)
	if not collision_shape.position.is_equal_approx(expected_position):
		push_warning("DeathZone: Collision shape position mismatch! Expected: " + str(expected_position) + " vs Actual: " + str(collision_shape.position))
		# Force correction
		collision_shape.position = expected_position

# Validation method to ensure DeathZone is properly configured
func _validate_configuration():
	if not collision_shape:
		push_error("DeathZone: CollisionShape2D node not found!")
		return false
	
	if not visual_graphics:
		push_error("DeathZone: NinePatchRect node not found!")
		return false
	
	if width <= 0 or height <= 0:
		push_warning("DeathZone: Invalid size: " + str(Vector2(width, height)))
		width = 200
		height = 50
	
	return true

# Method to refresh the entire DeathZone (useful for editor changes)
func refresh_death_zone():
	if _validate_configuration():
		_update_visual_and_collision()
		setup_zone_appearance()
		
		# Force editor update
		if Engine.is_editor_hint():
			notify_property_list_changed()

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
	collision_layer = 64 if is_active_in_current_layer else 0
	collision_mask = 2 if is_active_in_current_layer else 0
