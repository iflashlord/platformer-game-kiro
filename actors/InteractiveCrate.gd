extends Area2D
class_name InteractiveCrate

signal crate_destroyed(crate: InteractiveCrate, points: int)
signal player_bounced(crate: InteractiveCrate, player: Node2D)

@export var crate_type: String = "basic"
@export var points_value: int = 50
@export var bounce_force: float = 500.0
@export var explosion_radius: float = 100.0
@export var explosion_countdown: int = 3

@onready var interactive_sprite: AnimatedSprite2D = $AnimatedSprite2D


var is_destroyed: bool = false
var is_exploding: bool = false
var explosion_timer: float = 0.0

@onready var sprite: ColorRect = $CrateSprite
@onready var label: Label = $CrateLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var countdown_label: Label = null

func _ready():
	add_to_group("crates")
	add_to_group("interactive")
	
	# Set appearance based on crate type
	setup_crate_appearance()
	
	# Create countdown label for TNT
	if crate_type == "tnt":
		interactive_sprite.play("tnt_idle")
		countdown_label = Label.new()
		countdown_label.position = Vector2(-10, -35)
		countdown_label.add_theme_font_size_override("font_size", 16)
		countdown_label.add_theme_color_override("font_color", Color.RED)
		countdown_label.visible = false
		add_child(countdown_label)
	
	# Connect collision
	body_entered.connect(_on_body_entered)
	
	# Set collision layers
	collision_layer = 16  # Interactive layer
	collision_mask = 2    # Player layer

func _process(delta):
	if is_exploding and crate_type == "tnt":
		interactive_sprite.play("tnt_exploding")
		explosion_timer += delta
		var remaining_time = explosion_countdown - explosion_timer
		
		if countdown_label:
			countdown_label.text = str(ceil(remaining_time))
			countdown_label.visible = true
			
			# Flash effect
			var flash_speed = lerp(2.0, 8.0, explosion_timer / explosion_countdown)
			modulate = Color.RED if sin(explosion_timer * flash_speed) > 0 else Color.WHITE
		
		if explosion_timer >= explosion_countdown:
			detonate()

func setup_crate_appearance():
	match crate_type:
		"basic":
			interactive_sprite.play("basic_idle")
			sprite.color = Color(0.6, 0.4, 0.2, 1)
			label.text = "📦"
			points_value = 50
		"bounce":
			interactive_sprite.play("bounce_idle")
			sprite.color = Color.YELLOW
			label.text = "🦘"
			points_value = 75
		"tnt":
			interactive_sprite.play("tnt_idle")
			sprite.color = Color(1, 0.3, 0.3, 1)
			label.text = "💥"
			points_value = 100
		"metal":
			interactive_sprite.play("metal_idle")
			sprite.color = Color(0.7, 0.7, 0.8, 1)
			label.text = "🔩"
			points_value = 150
		_:
			interactive_sprite.play("basic_idle")
			sprite.color = Color(0.6, 0.4, 0.2, 1)
			label.text = "📦"
			points_value = 50

func _on_body_entered(body):
	print("📦 Crate collision detected with: ", body.name, " (groups: ", body.get_groups(), ")")
	if body.is_in_group("player") and not is_destroyed:
		print("📦 Valid player collision, interacting with crate")
		interact_with_player(body)
	else:
		print("📦 Invalid collision or already destroyed")

func interact_with_player(player):
	match crate_type:
		"basic":
			bounce_player(player)
			destroy_crate()
		"bounce":
			bounce_player(player)
			destroy_crate()
		"tnt":
			start_explosion_countdown()
		"metal":
			# Metal crates are harder to break
			bounce_player(player)
			#destroy_crate()

func bounce_player(player):
	# Apply bounce force to player
	if "velocity" in player:
		player.velocity.y = -bounce_force
		if "is_jumping" in player:
			player.is_jumping = true
	
	# Emit signal
	player_bounced.emit(self, player)
	
	print("🦘 Player bounced with force: ", bounce_force)

func start_explosion_countdown():
	if is_exploding or is_destroyed:
		return
	
	is_exploding = true
	explosion_timer = 0.0
	
	print("💣 TNT countdown started! Explosion radius: ", explosion_radius)
	
	# Create visual explosion radius indicator
	create_explosion_radius_indicator()
	
	# Disable further collision during countdown
	collision_layer = 0

func create_explosion_radius_indicator():
	# Create a visual circle to show explosion radius
	var radius_indicator = ColorRect.new()
	radius_indicator.name = "ExplosionRadiusIndicator"
	radius_indicator.size = Vector2(explosion_radius * 2, explosion_radius * 2)
	radius_indicator.position = Vector2(-explosion_radius, -explosion_radius)
	radius_indicator.color = Color(1, 0, 0, 0.2)  # Semi-transparent red
	add_child(radius_indicator)
	
	# Animate the indicator
	var tween = create_tween()
	tween.set_loops(10)
	tween.tween_property(radius_indicator, "modulate:a", 0.1, 0.5)
	tween.tween_property(radius_indicator, "modulate:a", 0.3, 0.5)

func detonate():
	if is_destroyed:
		return
	
	print("💥 TNT EXPLOSION!")
	
	# Check for player in explosion radius
	var player = get_tree().get_first_node_in_group("player")
	print("💥 Looking for player... Found: ", player != null)
	if player:
		var distance = global_position.distance_to(player.global_position)
		print("💥 Player distance from explosion: ", distance, " (radius: ", explosion_radius, ")")
		if distance <= explosion_radius:
			print("💔 Player caught in explosion! Distance: ", distance)
			
			# Apply damage
			print("💥 Applying damage to player")
			print("💥 HealthSystem available: ", HealthSystem != null)
			if HealthSystem and HealthSystem.has_method("lose_heart"):
				var health_before = HealthSystem.get_current_health()
				HealthSystem.lose_heart()
				var health_after = HealthSystem.get_current_health()
				print("💔 Health changed from ", health_before, " to ", health_after)
			elif player.has_method("take_damage"):
				player.take_damage(1)
				print("💔 Called player.take_damage(1)")
			else:
				print("❌ No damage method found!")
			
			# Apply knockback force
			apply_explosion_knockback(player, distance)
		else:
			print("💥 Player outside explosion radius")
	
	# Check for other crates in explosion radius (chain reaction)
	var nearby_crates = get_tree().get_nodes_in_group("crates")
	for crate in nearby_crates:
		if crate != self and crate.has_method("start_explosion_countdown"):
			var crate_distance = global_position.distance_to(crate.global_position)
			if crate_distance <= explosion_radius * 0.8:  # Slightly smaller radius for chain reaction
				print("💥 Chain reaction with crate at distance: ", crate_distance)
				# Trigger other TNT crates
				if crate.crate_type == "tnt":
					crate.start_explosion_countdown()
	
	# Visual explosion effect
	create_explosion_effect()
	
	# Destroy the crate
	destroy_crate()

func destroy_crate():
	if is_destroyed:
		return
	
	is_destroyed = true
	
	# Add score
	Game.add_score(points_value)
	
	# Emit signal
	crate_destroyed.emit(self as InteractiveCrate, points_value)
	
	# Create destruction effect
	create_destruction_effect()
	
	print("📦 ", crate_type.capitalize(), " crate destroyed! +", points_value, " points")

func create_destruction_effect():
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	
	# Create floating text effect
	var effect_label = Label.new()
	effect_label.text = "+" + str(points_value)
	effect_label.add_theme_font_size_override("font_size", 14)
	effect_label.add_theme_color_override("font_color", Color.WHITE)
	effect_label.position = global_position + Vector2(-15, -25)
	get_tree().current_scene.add_child(effect_label)
	
	# Animate the effect
	var tween = create_tween()
	tween.parallel().tween_property(effect_label, "position", effect_label.position + Vector2(0, -40), 0.8)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(effect_label.queue_free)
	
	# Animate the crate destruction
	var item_tween = create_tween()
	item_tween.parallel().tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	item_tween.parallel().tween_property(self, "modulate", Color.GRAY, 0.1)
	item_tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.2)
	item_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	item_tween.tween_callback(queue_free)

func apply_explosion_knockback(player, distance: float):
	# Calculate knockback direction (away from explosion)
	var knockback_direction = (player.global_position - global_position).normalized()
	
	# Calculate knockback force based on distance (closer = stronger)
	var max_knockback = 600.0
	var knockback_strength = max_knockback * (1.0 - (distance / explosion_radius))
	knockback_strength = max(knockback_strength, 200.0)  # Minimum knockback
	
	# Apply knockback to player
	if "velocity" in player:
		player.velocity += knockback_direction * knockback_strength
		# Add some upward force
		player.velocity.y -= 200.0
		
		print("💥 Applied knockback: ", knockback_direction * knockback_strength)
	
	# Visual feedback for knockback
	if FX and FX.has_method("shake"):
		FX.shake(100)  # Stronger shake for explosion

func create_explosion_effect():
	# Create explosion visual
	var explosion_sprite = ColorRect.new()
	explosion_sprite.size = Vector2(explosion_radius * 2, explosion_radius * 2)
	explosion_sprite.position = Vector2(-explosion_radius, -explosion_radius)
	explosion_sprite.color = Color(1, 0.5, 0, 0.7)  # Orange explosion
	add_child(explosion_sprite)
	
	# Explosion animation
	var tween = create_tween()
	tween.parallel().tween_property(explosion_sprite, "scale", Vector2(1.5, 1.5), 0.3)
	tween.parallel().tween_property(explosion_sprite, "modulate:a", 0.0, 0.3)
	
	# Hide countdown label and radius indicator
	if countdown_label:
		countdown_label.visible = false
	
	var radius_indicator = get_node_or_null("ExplosionRadiusIndicator")
	if radius_indicator:
		radius_indicator.queue_free()
	
	# Screen shake effect
	if FX and FX.has_method("shake"):
		FX.shake(100)  # Increased shake for explosion
