extends Node
class_name BreakableComponent

signal break_started
signal break_completed
signal shake_started

# Configuration
var platform: DynamicPlatform
var break_delay: float = 3.0
var shake_duration: float = 2.0
var auto_respawn: bool = true
var respawn_delay: float = 5.0
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

func setup(parent_platform: DynamicPlatform, delay: float, shake_time: float, should_respawn: bool = true, respawn_time: float = 5.0):
	platform = parent_platform
	break_delay = delay
	shake_duration = shake_time
	auto_respawn = should_respawn
	respawn_delay = respawn_time
	
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
	
	# Configure particles to match platform size - wait a frame to ensure platform is fully initialized
	await get_tree().process_frame
	_setup_particles()
	
	print("🔧 BreakableComponent setup complete - Delay: ", break_delay, "s, Shake: ", shake_duration, "s, Auto respawn: ", auto_respawn, " Respawn delay: ", respawn_delay, "s")

# Method to update particles when platform size changes
func update_particles_for_platform_size():
	_setup_particles()

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

	# Start low-level particle emission during shaking
	_set_particle_emission_level("shaking")
	
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
	
	# Stop shaking particles
	if break_particles:
		break_particles.emitting = false
	
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
	
	# No particles during breaking - only visual break effects from platform
	print("💥 Platform breaking - no particles needed")
	
	# Play break sound (if audio system exists)
	if has_node("/root/Audio"):
		var audio = get_node("/root/Audio")
		if audio.has_method("play_sfx"):
			audio.play_sfx("platform_break")
	
	# Hide platform and disable collision AFTER particles start
	if platform:
		platform.visible = false
		if platform.collision_shape:
			platform.collision_shape.disabled = true
	
	break_completed.emit()
	
	print("💥 Platform broken!")
	
	# Auto-respawn after a delay (only if enabled)
	if auto_respawn:
		print("⏰ Platform will respawn in ", respawn_delay, " seconds")
		await get_tree().create_timer(respawn_delay).timeout
		_respawn_platform()
	else:
		print("🚫 Platform will not respawn (auto_respawn disabled)")

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
	
	# Reset position to original
	platform.position = original_position
	
	# Stop particles
	if break_particles:
		break_particles.emitting = false
	
	# Re-enable player detection for breakable platforms
	if platform.has_method("_setup_player_detection"):
		platform._setup_player_detection()
	
	print("✨ Platform respawned and ready to break again!")

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
func configure(delay: float, shake_time: float, intensity: float = 2.0, should_respawn: bool = true, respawn_time: float = 5.0):
	break_delay = delay
	shake_duration = shake_time
	shake_intensity = intensity
	auto_respawn = should_respawn
	respawn_delay = respawn_time
	
	if break_timer:
		break_timer.wait_time = break_delay
	if shake_timer:
		shake_timer.wait_time = shake_duration
	
	print("🔧 BreakableComponent reconfigured - Delay: ", break_delay, "s, Shake: ", shake_duration, "s, Intensity: ", shake_intensity, " Auto respawn: ", auto_respawn, " Respawn delay: ", respawn_delay, "s")

# Public method to manually respawn the platform (useful for level design)
func manual_respawn():
	if platform and not platform.visible:
		_respawn_platform()
		print("🔄 Platform manually respawned")

# Public method to force break the platform (useful for scripted events)
func force_break():
	if not is_breaking:
		print("💥 Platform force broken!")
		_break_platform()

# Setup particles to match platform size and position
func _setup_particles():
	if not break_particles or not platform:
		return
	
	# CRITICAL FIX: Position particles at the center of the platform using platform.position
	# Since platform.position works better, use it directly with platform center offset
	var particle_center = Vector2(platform.width / 2, platform.height / 2)
	var current_position = platform.position
	var adjusted_position = platform.position + particle_center  # Adjust for platform center
	break_particles.position = adjusted_position  # Position relative to platform center
	
	# Use platform texture for particles to match the platform material
	if platform.nine_patch and platform.nine_patch.texture:
		break_particles.texture = platform.nine_patch.texture
	
	# Configure emission shape to match platform dimensions exactly
	var material = break_particles.process_material as ParticleProcessMaterial
	if material:
		# Set emission shape to box to cover platform area
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		material.emission_box_extents = Vector3(platform.width / 2, platform.height / 2, 0)
		
		# Configure particles to look like platform pieces
		material.direction = Vector3(0, -1, 0)
		material.spread = 45.0
		material.initial_velocity_min = 30.0
		material.initial_velocity_max = 100.0
		material.angular_velocity_min = -180.0
		material.angular_velocity_max = 180.0
		material.gravity = Vector3(0, 980, 0)  # Realistic gravity
		material.scale_min = 0.2
		material.scale_max = 0.6
		
		# Set color to match platform type
		match platform.platform_type:
			platform.PlatformType.YELLOW:
				material.color = Color(1.0, 0.9, 0.6, 1.0)
			platform.PlatformType.GREEN:
				material.color = Color(0.6, 1.0, 0.6, 1.0)
			platform.PlatformType.EMPTY:
				material.color = Color(0.8, 0.8, 0.8, 1.0)
			_:
				material.color = Color.WHITE
	
	print("🎆 Particles configured - Platform size: ", Vector2(platform.width, platform.height), " Particle position: ", break_particles.position, " Texture: ", break_particles.texture.resource_path if break_particles.texture else "None")

# Set particle emission for shaking only
func _set_particle_emission_level(level: String):
	if not break_particles or not platform:
		return
	
	# Scale particle amount based on platform size
	var platform_area = platform.width * platform.height
	var base_area = 96.0 * 32.0  # Default platform size
	var particle_scale = platform_area / base_area
	
	if level == "shaking":
		# Low emission during shaking - just dust/debris
		break_particles.amount = int(15 * particle_scale)
		break_particles.emitting = true
		var material = break_particles.process_material as ParticleProcessMaterial
		if material:
			material.initial_velocity_min = 10.0
			material.initial_velocity_max = 30.0
			material.scale_min = 0.1
			material.scale_max = 0.3
		print("🫨 Shaking particles started - Dust and debris effect")
