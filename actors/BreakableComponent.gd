extends Node
class_name BreakableComponent

signal break_started
signal break_completed
signal shake_started

# Configuration
var platform: DynamicPlatform
var break_delay: float = 3.0
var shake_duration: float = 2.0
var is_breaking: bool = false
var is_shaking: bool = false

# Node references - simplified, no Area2D needed
@onready var break_timer: Timer = $BreakTimer
@onready var shake_timer: Timer = $ShakeTimer
@onready var break_particles: GPUParticles2D = $BreakParticles

# Shake effect variables
var original_position: Vector2
var shake_intensity: float = 2.0
var shake_frequency: float = 20.0

func _ready():
	# Get node references
	if not break_timer:
		break_timer = get_node("BreakTimer") if has_node("BreakTimer") else null
	if not shake_timer:
		shake_timer = get_node("ShakeTimer") if has_node("ShakeTimer") else null
	if not break_particles:
		break_particles = get_node("BreakParticles") if has_node("BreakParticles") else null
	
	# Connect timer signals
	if break_timer:
		break_timer.timeout.connect(_on_break_timer_timeout)
	
	if shake_timer:
		shake_timer.timeout.connect(_on_shake_timer_timeout)
	
	print("🔧 BreakableComponent ready")

func setup(parent_platform: DynamicPlatform, delay: float, shake_time: float):
	platform = parent_platform
	break_delay = delay
	shake_duration = shake_time
	
	# Store original position for shake effect
	if platform:
		original_position = platform.position
	
	# Configure timers
	if break_timer:
		break_timer.wait_time = break_delay
		break_timer.one_shot = true
	
	if shake_timer:
		shake_timer.wait_time = shake_duration
		shake_timer.one_shot = true
	
	print("🔧 BreakableComponent setup complete - Delay: ", break_delay, "s, Shake: ", shake_duration, "s")

# Method called by platform when player lands on it
func player_landed_on_platform():
	if is_breaking:
		return  # Already breaking
	
	print("🦶 Player landed on breakable platform!")
	_start_breaking_sequence()

func _start_breaking_sequence():
	if is_breaking:
		return
	
	is_breaking = true
	break_started.emit()
	
	print("💥 Breaking sequence started - will break in ", break_delay, " seconds")
	
	# Start the break timer
	if break_timer:
		break_timer.start()
	
	# Start shaking after a short delay
	await get_tree().create_timer(break_delay - shake_duration).timeout
	_start_shaking()

func _start_shaking():
	if not platform or is_shaking:
		return
	
	is_shaking = true
	shake_started.emit()
	
	print("🫨 Platform started shaking!")
	
	# Start shake timer
	if shake_timer:
		shake_timer.start()

func _process(delta):
	if is_shaking and platform:
		# Apply shake effect using ticks for time
		var time = Time.get_ticks_msec() / 1000.0
		var shake_offset = Vector2(
			sin(time * shake_frequency) * shake_intensity,
			cos(time * shake_frequency * 1.5) * shake_intensity * 0.5
		)
		platform.position = original_position + shake_offset

func _on_shake_timer_timeout():
	print("🫨 Shake timer finished")
	is_shaking = false
	
	# Reset position
	if platform:
		platform.position = original_position

func _on_break_timer_timeout():
	print("💥 Platform breaking!")
	_break_platform()

func _break_platform():
	if not platform:
		return
	
	# Stop shaking
	is_shaking = false
	if platform:
		platform.position = original_position
	
	# Emit particles
	if break_particles:
		break_particles.emitting = true
	
	# Play break sound (if audio system exists)
	if has_node("/root/Audio"):
		var audio = get_node("/root/Audio")
		if audio.has_method("play_sfx"):
			audio.play_sfx("platform_break")
	
	# Hide platform and disable collision
	if platform:
		platform.visible = false
		if platform.collision_shape:
			platform.collision_shape.disabled = true
	
	break_completed.emit()
	
	print("💥 Platform broken!")
	
	# Auto-respawn after a delay (optional)
	await get_tree().create_timer(5.0).timeout
	_respawn_platform()

func _respawn_platform():
	if not platform:
		return
	
	print("🔄 Platform respawning...")
	
	# Reset state
	is_breaking = false
	is_shaking = false
	
	# Show platform and enable collision
	platform.visible = true
	if platform.collision_shape:
		platform.collision_shape.disabled = false
	
	# Stop particles
	if break_particles:
		break_particles.emitting = false
	
	print("✨ Platform respawned!")

func reset_state():
	# Reset to initial state (useful for object pooling)
	is_breaking = false
	is_shaking = false
	
	# Stop timers
	if break_timer and break_timer.time_left > 0:
		break_timer.stop()
	if shake_timer and shake_timer.time_left > 0:
		shake_timer.stop()
	
	# Reset position
	if platform:
		platform.position = original_position
		platform.visible = true
		if platform.collision_shape:
			platform.collision_shape.disabled = false
	
	# Stop particles
	if break_particles:
		break_particles.emitting = false
	
	print("🔄 BreakableComponent reset")

# Method to configure breaking parameters at runtime
func configure(delay: float, shake_time: float, intensity: float = 2.0):
	break_delay = delay
	shake_duration = shake_time
	shake_intensity = intensity
	
	if break_timer:
		break_timer.wait_time = break_delay
	if shake_timer:
		shake_timer.wait_time = shake_duration
	
	print("🔧 BreakableComponent reconfigured - Delay: ", break_delay, "s, Shake: ", shake_duration, "s, Intensity: ", shake_intensity)