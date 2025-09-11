extends Area2D
class_name Portal

signal portal_entered(player: Player)

@export var portal_type: String = "finish"
@export var destination_level: String = ""
@export var is_active: bool = true

@onready var portal_sprite: Control = $PortalSprite
@onready var outer_ring: ColorRect = $PortalSprite/OuterRing
@onready var middle_ring: ColorRect = $PortalSprite/MiddleRing
@onready var inner_core: ColorRect = $PortalSprite/InnerCore
@onready var particles: CPUParticles2D = $PortalParticles
@onready var activation_particles: CPUParticles2D = $ActivationParticles
@onready var spiral_particles: CPUParticles2D = $SpiralParticles
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var activation_sound: AudioStreamPlayer2D = $ActivationSound

var player_in_portal: bool = false
var activation_timer: float = 0.0
var activation_delay: float = 1.0

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Make portal rings round
	_make_portal_round()
	
	# Setup portal appearance based on type
	_setup_portal_appearance()
	
	# Start portal animation
	_create_portal_animation()
	
	print("Portal created: ", portal_type)

func _make_portal_round():
	# Create circular masks for each ring to make them round
	if outer_ring:
		outer_ring.pivot_offset = outer_ring.size / 2
		# Create a circular clip using a shader or just round the corners
		# For now, we'll use rotation and scaling to create a round effect
	if middle_ring:
		middle_ring.pivot_offset = middle_ring.size / 2
	if inner_core:
		inner_core.pivot_offset = inner_core.size / 2

func _setup_portal_appearance():
	match portal_type:
		"finish":
			outer_ring.color = Color(0.3, 0.6, 1.0, 0.8)
			middle_ring.color = Color(0.6, 0.9, 1.0, 0.6)
			inner_core.color = Color(0.9, 1.0, 1.0, 0.9)
			particles.color = Color(0.5, 0.8, 1.0, 1.0)
		"next_level":
			outer_ring.color = Color(0.6, 1.0, 0.3, 0.8)
			middle_ring.color = Color(0.8, 1.0, 0.6, 0.6)
			inner_core.color = Color(1.0, 1.0, 0.9, 0.9)
			particles.color = Color(0.8, 1.0, 0.5, 1.0)
		"secret":
			outer_ring.color = Color(1.0, 0.3, 0.6, 0.8)
			middle_ring.color = Color(1.0, 0.6, 0.8, 0.6)
			inner_core.color = Color(1.0, 0.9, 1.0, 0.9)
			particles.color = Color(1.0, 0.5, 0.8, 1.0)

func _create_portal_animation():
	# Outer ring rotation (slow)
	var outer_tween: Tween = create_tween()
	outer_tween.set_loops(10)
	outer_tween.tween_property(outer_ring, "rotation", TAU, 4.0)
	
	# Middle ring rotation (medium, opposite direction)
	var middle_tween: Tween = create_tween()
	middle_tween.set_loops(10)
	middle_tween.tween_property(middle_ring, "rotation", -TAU, 3.0)
	
	# Inner core rotation (fast)
	var core_tween: Tween = create_tween()
	core_tween.set_loops(10)
	core_tween.tween_property(inner_core, "rotation", TAU, 2.0)
	
	# Pulsing animation for middle ring
	var pulse_tween: Tween = create_tween()
	pulse_tween.set_loops(10)
	pulse_tween.tween_property(middle_ring, "scale", Vector2(1.1, 1.1), 1.5)
	pulse_tween.tween_property(middle_ring, "scale", Vector2(1.0, 1.0), 1.5)
	
	# Core pulsing (faster)
	var core_pulse_tween: Tween = create_tween()
	core_pulse_tween.set_loops(10)
	core_pulse_tween.tween_property(inner_core, "scale", Vector2(1.2, 1.2), 1.0)
	core_pulse_tween.tween_property(inner_core, "scale", Vector2(1.0, 1.0), 1.0)

func _process(delta):
	if player_in_portal and is_active:
		activation_timer += delta
		
		# Visual feedback during activation
		var progress = activation_timer / activation_delay
		var pulse_intensity = 1.0 + sin(activation_timer * 15.0) * 0.4 * progress
		
		# Intensify all rings
		outer_ring.modulate = Color.WHITE * pulse_intensity
		middle_ring.modulate = Color.WHITE * pulse_intensity
		inner_core.modulate = Color.WHITE * (1.0 + pulse_intensity * 0.5)
		
		# Increase particle emission dramatically
		particles.amount = int(50 + progress * 100)
		
		# Start spiral particles when halfway through activation
		if progress > 0.5 and not spiral_particles.emitting:
			spiral_particles.emitting = true
		
		if activation_timer >= activation_delay:
			_activate_portal()

func _on_body_entered(body):
	if body.is_in_group("player") and is_active:
		player_in_portal = true
		activation_timer = 0.0
		
		# Spectacular entry effects
		create_entry_effects()
		
		# Visual and audio feedback with fallbacks
		if has_node("/root/FX"):
			if FX.has_method("flash_screen"):
				FX.flash_screen(Color.CYAN * 0.3, 0.5)
		
		if has_node("/root/Audio"):
			if Audio.has_method("play_sfx"):
				Audio.play_sfx("portal_enter")
		
		print("🌀 Player entered portal - spectacular activation sequence started!")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_portal = false
		activation_timer = 0.0
		
		# Reset visual effects
		outer_ring.modulate = Color.WHITE
		middle_ring.modulate = Color.WHITE
		inner_core.modulate = Color.WHITE
		particles.amount = 50
		spiral_particles.emitting = false
		
		print("Player exited portal - effects reset")

func _activate_portal():
	if not is_active:
		return
	
	is_active = false
	player_in_portal = false
	
	# Get the player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# SPECTACULAR activation effects
	create_activation_effects()
	
	# Portal activation effects with fallbacks
	if has_node("/root/FX"):
		if FX.has_method("flash_screen"):
			FX.flash_screen(Color.WHITE * 0.7, 1.0)
		if FX.has_method("shake"):
			FX.shake(100)
	
	if has_node("/root/Audio"):
		if Audio.has_method("play_sfx"):
			Audio.play_sfx("portal_activate")
	
	# Emit signal
	portal_entered.emit(player)
	
	print("🌀✨ PORTAL FULLY ACTIVATED! Type: ", portal_type, " - SPECTACULAR EFFECTS!")
	
	# Handle different portal types
	match portal_type:
		"finish":
			_handle_level_completion()
		"next_level":
			_handle_level_transition()
		"secret":
			_handle_secret_area()

func _handle_level_completion():
	# Get current level from Game system
	var current_level = Game.current_level
	
	# Find the level script to trigger completion
	var level_node = get_tree().current_scene
	if level_node.has_method("_complete_level"):
		# Wait a moment for effects
		await get_tree().create_timer(0.5).timeout
		level_node._complete_level()
	else:
		print("Warning: Level node doesn't have _complete_level method")

func _handle_level_transition():
	if destination_level != "":
		await get_tree().create_timer(0.5).timeout
		LevelLoader.load_level(destination_level)
	else:
		print("Warning: No destination level set for transition portal")

func _handle_secret_area():
	# Could lead to secret levels or bonus areas
	print("Secret portal activated - implement secret area logic")

func create_entry_effects():
	# Burst of particles when player enters
	activation_particles.amount = 60
	activation_particles.emitting = true
	activation_particles.restart()
	
	# Ring expansion effect
	var entry_tween: Tween = create_tween()
	entry_tween.parallel().tween_property(outer_ring, "scale", Vector2(1.3, 1.3), 0.3)
	entry_tween.parallel().tween_property(middle_ring, "scale", Vector2(1.2, 1.2), 0.3)
	entry_tween.parallel().tween_property(inner_core, "scale", Vector2(1.4, 1.4), 0.3)
	entry_tween.parallel().tween_property(outer_ring, "scale", Vector2(1.0, 1.0), 0.3)
	entry_tween.parallel().tween_property(middle_ring, "scale", Vector2(1.0, 1.0), 0.3)
	entry_tween.parallel().tween_property(inner_core, "scale", Vector2(1.0, 1.0), 0.3)

func create_activation_effects():
	# MASSIVE particle explosion
	activation_particles.amount = 150
	activation_particles.lifetime = 2.0
	activation_particles.initial_velocity_max = 300.0
	activation_particles.emitting = true
	activation_particles.restart()
	
	# Spiral particles go crazy
	spiral_particles.amount = 120
	spiral_particles.initial_velocity_max = 200.0
	spiral_particles.emitting = true
	spiral_particles.restart()
	
	# Ring explosion effect
	var explosion_tween: Tween = create_tween()
	explosion_tween.parallel().tween_property(outer_ring, "scale", Vector2(2.0, 2.0), 0.5)
	explosion_tween.parallel().tween_property(middle_ring, "scale", Vector2(1.8, 1.8), 0.5)
	explosion_tween.parallel().tween_property(inner_core, "scale", Vector2(2.2, 2.2), 0.5)
	
	# Fade out rings during explosion
	explosion_tween.parallel().tween_property(outer_ring, "modulate:a", 0.0, 0.8)
	explosion_tween.parallel().tween_property(middle_ring, "modulate:a", 0.0, 0.8)
	explosion_tween.parallel().tween_property(inner_core, "modulate:a", 0.0, 0.8)
	
	# Create additional explosion particles manually
	create_manual_explosion_particles()

func create_manual_explosion_particles():
	# Create 20 manual particles that fly outward
	for i in range(20):
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)
		particle.color = Color(randf_range(0.8, 1.0), randf_range(0.8, 1.0), 1.0, 1.0)
		particle.position = global_position
		get_tree().current_scene.add_child(particle)
		
		# Random outward direction
		var angle = randf() * TAU
		var direction = Vector2(cos(angle), sin(angle))
		var distance = randf_range(100, 300)
		
		# Animate particle
		var tween: Tween = create_tween()
		tween.parallel().tween_property(particle, "position", global_position + direction * distance, 1.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 1.5)
		tween.parallel().tween_property(particle, "scale", Vector2(2.0, 2.0), 0.5)
		tween.parallel().tween_property(particle, "scale", Vector2(0.0, 0.0), 1.0)
		tween.tween_callback(particle.queue_free)

func set_portal_active(active: bool):
	is_active = active
	modulate = Color.WHITE if active else Color.GRAY
	particles.emitting = active
	if not active:
		spiral_particles.emitting = false
