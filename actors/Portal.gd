extends Area2D
class_name Portal

signal portal_entered(player: Player)

@export var portal_type: String = "finish"
@export var destination_level: String = ""
@export var is_active: bool = true

@onready var portal_sprite: ColorRect = $PortalSprite
@onready var inner_glow: ColorRect = $InnerGlow
@onready var core: ColorRect = $Core
@onready var particles: CPUParticles2D = $PortalParticles
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var activation_sound: AudioStreamPlayer2D = $ActivationSound

var player_in_portal: bool = false
var activation_timer: float = 0.0
var activation_delay: float = 1.0

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Setup portal appearance based on type
	_setup_portal_appearance()
	
	# Start portal animation
	_create_portal_animation()
	
	print("Portal created: ", portal_type)

func _setup_portal_appearance():
	match portal_type:
		"finish":
			portal_sprite.color = Color(0.3, 0.6, 1.0, 0.8)
			inner_glow.color = Color(0.6, 0.9, 1.0, 0.6)
			core.color = Color(0.9, 1.0, 1.0, 0.9)
		"next_level":
			portal_sprite.color = Color(0.6, 1.0, 0.3, 0.8)
			inner_glow.color = Color(0.8, 1.0, 0.6, 0.6)
			core.color = Color(1.0, 1.0, 0.9, 0.9)
		"secret":
			portal_sprite.color = Color(1.0, 0.3, 0.6, 0.8)
			inner_glow.color = Color(1.0, 0.6, 0.8, 0.6)
			core.color = Color(1.0, 0.9, 1.0, 0.9)

func _create_portal_animation():
	# Simple rotation animation using a tween
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(portal_sprite, "rotation", TAU, 3.0)
	
	# Pulsing animation for inner glow
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(inner_glow, "scale", Vector2(1.2, 1.2), 1.5)
	pulse_tween.tween_property(inner_glow, "scale", Vector2(1.0, 1.0), 1.5)

func _process(delta):
	if player_in_portal and is_active:
		activation_timer += delta
		
		# Visual feedback during activation
		var progress = activation_timer / activation_delay
		var pulse_intensity = 1.0 + sin(activation_timer * 10.0) * 0.3 * progress
		
		portal_sprite.modulate = Color.WHITE * pulse_intensity
		inner_glow.modulate = Color.WHITE * pulse_intensity
		
		# Increase particle emission
		particles.amount = int(30 + progress * 20)
		
		if activation_timer >= activation_delay:
			_activate_portal()

func _on_body_entered(body):
	if body.is_in_group("player") and is_active:
		player_in_portal = true
		activation_timer = 0.0
		
		# Visual and audio feedback
		FX.flash_screen(Color.CYAN * 0.2, 0.3)
		Audio.play_sfx("portal_enter")
		
		print("Player entered portal - activating...")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_portal = false
		activation_timer = 0.0
		
		# Reset visual effects
		portal_sprite.modulate = Color.WHITE
		inner_glow.modulate = Color.WHITE
		particles.amount = 30

func _activate_portal():
	if not is_active:
		return
	
	is_active = false
	player_in_portal = false
	
	# Get the player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Portal activation effects
	FX.flash_screen(Color.WHITE * 0.5, 0.8)
	FX.shake(300)
	Audio.play_sfx("portal_activate")
	
	# Massive particle burst
	particles.amount = 100
	particles.emitting = true
	
	# Emit signal
	portal_entered.emit(player)
	
	print("🌀 Portal activated! Type: ", portal_type)
	
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

func set_portal_active(active: bool):
	is_active = active
	modulate = Color.WHITE if active else Color.GRAY
	particles.emitting = active
