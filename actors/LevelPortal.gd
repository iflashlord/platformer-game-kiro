extends Area2D
class_name LevelPortal

@export var next_level: String = ""
@export var portal_name: String = "Level Complete"

@onready var portal_sprite: ColorRect = $PortalSprite
@onready var inner_glow: ColorRect = $InnerGlow
@onready var particles: CPUParticles2D = get_node_or_null("Particles")
@onready var animation_timer: Timer = $AnimationTimer

var is_activated: bool = false
var glow_tween: Tween

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	animation_timer.timeout.connect(_animate_portal)
	
	# Add to portal group
	add_to_group("portals")
	
	print("🌀 Level Portal created: ", portal_name)
	
	# Start portal animation
	_start_portal_animation()

func _start_portal_animation():
	# Animate the portal glow
	glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(inner_glow, "modulate", Color(1, 1, 1, 0.2), 1.0)
	glow_tween.tween_property(inner_glow, "modulate", Color(1, 1, 1, 0.8), 1.0)

func _animate_portal():
	# Random color shifts for magical effect
	var colors = [
		Color(0.5, 1, 1, 0.7),    # Cyan
		Color(0.7, 0.5, 1, 0.7),  # Purple
		Color(0.5, 1, 0.7, 0.7),  # Green
		Color(1, 0.7, 0.5, 0.7)   # Orange
	]
	
	portal_sprite.color = colors[randi() % colors.size()]

func _on_body_entered(body):
	if body is Player and not is_activated:
		_activate_portal(body)

func _activate_portal(player: Player):
	if is_activated:
		return
		
	is_activated = true
	print("🌀 Player entered portal: ", portal_name)
	
	# Stop player movement
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	
	# Visual effects
	_play_completion_effects()
	
	# Audio feedback
	if Audio:
		Audio.play_sfx("portal_enter")  # Will gracefully fail if sound doesn't exist
	
	# Wait for effects then complete level
	await get_tree().create_timer(2.0).timeout
	_complete_level()

func _play_completion_effects():
	print("✨ Playing portal completion effects")
	
	# Screen shake and flash
	if FX:
		FX.shake(500)  # 500ms shake
		FX.flash_screen(Color.CYAN * 0.5, 0.5)
	
	# Enhanced particles
	if particles:
		particles.amount = 100
		particles.initial_velocity_max = 100.0
		particles.emitting = true
	
	# Portal animation
	var completion_tween = create_tween()
	completion_tween.parallel().tween_property(portal_sprite, "scale", Vector2(1.5, 1.5), 0.5)
	completion_tween.parallel().tween_property(inner_glow, "scale", Vector2(2.0, 2.0), 0.5)
	completion_tween.parallel().tween_property(portal_sprite, "modulate", Color.WHITE, 0.5)
	
	# Spin effect
	completion_tween.parallel().tween_property(self, "rotation", rotation + PI * 2, 1.0)

func _complete_level():
	print("🎉 Level completed via portal!")
	
	# Mark level as completed in persistence
	if Game.current_level != "":
		var completion_time = 60.0  # Default completion time
		var completion_score = 1000  # Default score
		
		# Get actual time from GameTimer if available
		if GameTimer:
			completion_time = GameTimer.get_current_time()
		
		# Get actual score from Game if available
		if Game:
			completion_score = Game.get_score()
		
		Persistence.complete_level(Game.current_level, completion_time, completion_score)
		print("✅ Level completion saved: ", Game.current_level, " Time: ", completion_time, " Score: ", completion_score)
	
	# Go to level select
	print("🗺️ Returning to level select")
	get_tree().change_scene_to_file("res://ui/LevelMap.tscn")
