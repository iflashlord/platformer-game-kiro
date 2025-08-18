extends Area2D
class_name LevelPortal

@export var next_level: String = ""
@export var portal_name: String = "Level Complete"

@onready var portal_sprite: Node2D = $PortalSprite
@onready var outer_ring: Node2D = $PortalSprite/OuterRing
@onready var inner_glow: Node2D = $PortalSprite/InnerGlow
@onready var core: Node2D = $PortalSprite/Core
@onready var particles: CPUParticles2D = $Particles
@onready var completion_particles: CPUParticles2D = $CompletionParticles
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
	# Animate the portal glow and rotation
	glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.parallel().tween_property(inner_glow, "modulate", Color(1, 1, 1, 0.3), 1.5)
	glow_tween.parallel().tween_property(inner_glow, "modulate", Color(1, 1, 1, 0.9), 1.5)
	glow_tween.parallel().tween_property(core, "modulate", Color(0.8, 0.8, 1, 0.6), 1.5)
	glow_tween.parallel().tween_property(core, "modulate", Color(1, 1, 1, 1), 1.5)
	
	# Continuous rotation for outer ring
	var rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(outer_ring, "rotation", TAU, 3.0)
	
	# Counter-rotation for inner glow
	var inner_rotation_tween = create_tween()
	inner_rotation_tween.set_loops()
	inner_rotation_tween.tween_property(inner_glow, "rotation", -TAU, 4.0)

func _animate_portal():
	# Random color shifts for magical effect
	var colors = [
		Color(0.5, 1, 1, 0.8),    # Cyan
		Color(0.7, 0.5, 1, 0.8),  # Purple
		Color(0.5, 1, 0.7, 0.8),  # Green
		Color(1, 0.7, 0.5, 0.8)   # Orange
	]
	
	var new_color = colors[randi() % colors.size()]
	outer_ring.modulate = new_color
	particles.color = new_color

func _on_body_entered(body):
	print("🌀 Portal collision detected with: ", body.name, " (groups: ", body.get_groups(), ")")
	if body is Player and not is_activated:
		print("🌀 Valid player collision, activating portal")
		_activate_portal(body)
	else:
		print("🌀 Invalid collision or already activated")

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
		FX.shake(800)  # 800ms shake
		FX.flash_screen(Color.CYAN * 0.7, 0.8)
	
	# Stop existing tweens
	if glow_tween:
		glow_tween.kill()
	
	# Massive particle burst
	if particles:
		particles.amount = 200
		particles.initial_velocity_max = 150.0
		particles.scale_amount_max = 2.0
		particles.emitting = true
	
	# Activate completion particles
	if completion_particles:
		completion_particles.emitting = true
		completion_particles.amount = 150
		completion_particles.initial_velocity_max = 200.0
	
	# Portal expansion and glow animation
	var completion_tween = create_tween()
	completion_tween.set_parallel(true)
	
	# Scale up the entire portal
	completion_tween.tween_property(portal_sprite, "scale", Vector2(2.0, 2.0), 1.0)
	
	# Bright flash effect
	completion_tween.tween_property(outer_ring, "modulate", Color.WHITE * 2.0, 0.3)
	completion_tween.tween_property(inner_glow, "modulate", Color.WHITE * 3.0, 0.3)
	completion_tween.tween_property(core, "modulate", Color.WHITE * 4.0, 0.3)
	
	# Then fade to bright colors
	completion_tween.tween_property(outer_ring, "modulate", Color.CYAN * 1.5, 0.7)
	completion_tween.tween_property(inner_glow, "modulate", Color.WHITE * 1.8, 0.7)
	completion_tween.tween_property(core, "modulate", Color.YELLOW * 2.0, 0.7)
	
	# Rapid spin effect
	completion_tween.tween_property(outer_ring, "rotation", outer_ring.rotation + PI * 6, 1.5)
	completion_tween.tween_property(inner_glow, "rotation", inner_glow.rotation - PI * 4, 1.5)
	
	# Pulsing effect
	var pulse_tween = create_tween()
	pulse_tween.set_loops(3)
	pulse_tween.tween_property(portal_sprite, "scale", Vector2(2.2, 2.2), 0.2)
	pulse_tween.tween_property(portal_sprite, "scale", Vector2(1.8, 1.8), 0.2)

func _complete_level():
	print("🎉 Level completed via portal!")
	
	# Collect completion data
	var completion_data = {
		"level_name": Game.current_level,
		"completion_time": 60.0,
		"score": 1000,
		"hearts_remaining": 5,
		"gems_found": 0,
		"total_gems": 0
	}
	
	# Get actual data from systems
	if GameTimer:
		completion_data.completion_time = GameTimer.get_current_time()
	
	if Game:
		completion_data.score = Game.get_score()
	
	if HealthSystem:
		completion_data.hearts_remaining = HealthSystem.get_current_health()
	
	# Get gem data from LevelManager if available
	var level_manager = get_tree().get_first_node_in_group("level_managers")
	if not level_manager:
		# Try to find it in the current scene
		level_manager = get_tree().current_scene.get_node_or_null("LevelManager")
	
	if level_manager:
		var stats = level_manager.get_level_stats()
		completion_data.gems_found = stats.gems_collected
		completion_data.total_gems = stats.total_gems
		
		# Trigger level completion in manager
		level_manager.trigger_level_completion()
	
	# Mark level as completed in persistence
	if Game.current_level != "":
		Persistence.complete_level(Game.current_level, completion_data.completion_time, completion_data.score)
		print("✅ Level completion saved: ", Game.current_level)
	
	# Show level results
	show_level_results(completion_data)

func show_level_results(completion_data: Dictionary):
	print("📊 LevelPortal: Attempting to show level results")
	print("📊 Current scene: ", get_tree().current_scene.name if get_tree().current_scene else "None")
	
	# Check if results are already showing
	var existing_results = get_tree().get_nodes_in_group("level_results")
	print("📊 Existing results instances: ", existing_results.size())
	if existing_results.size() > 0:
		print("📊 Level results already showing, skipping")
		return
	
	print("📊 Creating new LevelResults instance")
	
	# Load and show the LevelResults scene
	var results_scene = preload("res://ui/LevelResults.tscn")
	var results_instance = results_scene.instantiate()
	
	# Add to group to prevent duplicates
	results_instance.add_to_group("level_results")
	
	# Add to the current scene
	get_tree().current_scene.add_child(results_instance)
	
	# Setup the results with completion data
	results_instance.setup_results(completion_data)
	
	print("📊 LevelResults instance created and added to scene")
