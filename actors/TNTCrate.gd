extends Crate
class_name TNTCrate

@export var fuse_time: float = 3.0
@export var explosion_radius: float = 150.0
@export var explosion_damage: float = 2.0

var is_fuse_lit: bool = false
var fuse_timer: float = 0.0
var countdown_label: Label = null
var radius_indicator: ColorRect = null

@onready var fuse_light: Sprite2D = $FuseLight
@onready var tnt_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	super._ready()
	crate_type = "tnt"
	health = 1
	tnt_sprite.play("default")
	
	# Create countdown label
	countdown_label = Label.new()
	countdown_label.position = Vector2(-10, -35)
	countdown_label.add_theme_font_size_override("font_size", 16)
	countdown_label.add_theme_color_override("font_color", Color.RED)
	countdown_label.visible = false
	add_child(countdown_label)

func _process(delta):
	super._process(delta)
	
	if is_fuse_lit:
		fuse_timer += delta
		var remaining_time = fuse_time - fuse_timer
		
		# Blinking fuse effect
		var blink_speed = lerp(2.0, 10.0, fuse_timer / fuse_time)
		fuse_light.modulate.a = (sin(fuse_timer * blink_speed) + 1.0) / 2.0
		
		# Show countdown label
		if countdown_label:
			countdown_label.text = str(ceil(remaining_time))
			countdown_label.visible = true
			# Flash effect
			var flash_speed = lerp(2.0, 8.0, fuse_timer / fuse_time)
			modulate = Color.RED if sin(fuse_timer * flash_speed) > 0 else Color.WHITE
		
		if fuse_timer >= fuse_time:
			detonate()

func on_player_interaction(player: Player):
	if not is_fuse_lit:
		light_fuse()

func take_damage(amount: int = 1):
	if not is_fuse_lit:
		light_fuse()

func light_fuse():
	if is_fuse_lit:
		return
	
	is_fuse_lit = true
	fuse_timer = 0.0
	
	# Visual feedback
	tnt_sprite.modulate = Color.ORANGE
	fuse_light.visible = true
	
	# Show explosion radius indicator
	create_explosion_radius_indicator()
	
	# Audio feedback
	print("TNT fuse lit! Exploding in ", fuse_time, " seconds!")

func create_explosion_radius_indicator():
	radius_indicator = ColorRect.new()
	radius_indicator.name = "ExplosionRadiusIndicator"
	radius_indicator.size = Vector2(explosion_radius * 2, explosion_radius * 2)
	radius_indicator.position = Vector2(-explosion_radius, -explosion_radius)
	radius_indicator.color = Color(1, 0, 0, 0.2)
	add_child(radius_indicator)
	
	# Animate the indicator
	var tween = create_tween()
	tween.set_loops(10)
	tween.tween_property(radius_indicator, "modulate:a", 0.1, 0.5)
	tween.tween_property(radius_indicator, "modulate:a", 0.3, 0.5)

func detonate():
	if health <= 0:
		return
	
	print("💥 TNT EXPLOSION!")
	
	# Damage player in radius
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance <= explosion_radius:
			if HealthSystem and HealthSystem.has_method("lose_heart"):
				HealthSystem.lose_heart()
			elif player.has_method("take_damage"):
				player.take_damage(int(explosion_damage))
			apply_explosion_knockback(player, distance)
	
	# Chain reaction with other crates
	var nearby_crates = get_tree().get_nodes_in_group("crates")
	for crate in nearby_crates:
		if crate != self and crate.has_method("light_fuse"):
			var crate_distance = global_position.distance_to(crate.global_position)
			if crate_distance <= explosion_radius * 0.8:
				if crate.crate_type == "tnt":
					crate.light_fuse()
	
	# Visual explosion effect
	create_explosion_effect()
	
	# Hide countdown label and radius indicator
	if countdown_label:
		countdown_label.visible = false
	if radius_indicator:
		radius_indicator.queue_free()
	
	# Destroy the crate and update health
	health = 0
	break_crate()

func apply_explosion_knockback(player, distance: float):
	var knockback_direction = (player.global_position - global_position).normalized()
	var max_knockback = 600.0
	var knockback_strength = max_knockback * (1.0 - (distance / explosion_radius))
	knockback_strength = max(knockback_strength, 200.0)
	if "velocity" in player:
		player.velocity += knockback_direction * knockback_strength
		player.velocity.y -= 200.0
	if FX and FX.has_method("shake"):
		FX.shake(100)

func create_explosion_effect():
	var explosion_sprite = ColorRect.new()
	explosion_sprite.size = Vector2(explosion_radius * 2, explosion_radius * 2)
	explosion_sprite.position = Vector2(-explosion_radius, -explosion_radius)
	explosion_sprite.color = Color(1, 0.5, 0, 0.7)
	add_child(explosion_sprite)
	var tween = create_tween()
	tween.parallel().tween_property(explosion_sprite, "scale", Vector2(1.5, 1.5), 0.3)
	tween.parallel().tween_property(explosion_sprite, "modulate:a", 0.0, 0.3)
	if FX and FX.has_method("shake"):
		FX.shake(100)
