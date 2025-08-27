extends Node
class_name BreakableComponent

signal break_started
signal break_completed

enum BreakState {
	STABLE,
	TOUCHED,
	SHAKING,
	BROKEN
}

var break_state: BreakState = BreakState.STABLE
var platform: DynamicPlatform
var original_position: Vector2
var shake_intensity: float = 2.0
var shake_time_elapsed: float = 0.0

# Configuration
var break_delay: float = 3.0
var shake_duration: float = 2.0

# Node references - with safe access
@onready var player_detector: Area2D = $PlayerDetector if has_node("PlayerDetector") else null
@onready var detection_collision: CollisionShape2D = $PlayerDetector/DetectionCollision if has_node("PlayerDetector/DetectionCollision") else null
@onready var break_timer: Timer = $BreakTimer if has_node("BreakTimer") else null
@onready var shake_timer: Timer = $ShakeTimer if has_node("ShakeTimer") else null
@onready var break_particles: GPUParticles2D = $BreakParticles if has_node("BreakParticles") else null

func setup(platform_node: DynamicPlatform, delay: float, duration: float):
	# Ensure this component is ready
	if not is_inside_tree():
		print("❌ BreakableComponent not ready yet")
		return
		
	platform = platform_node
	break_delay = delay
	shake_duration = duration
	original_position = platform.global_position
	
	# Setup timers with null checks
	if break_timer:
		break_timer.wait_time = maxf(break_delay - shake_duration, 0.1)
		break_timer.one_shot = true
		if not break_timer.timeout.is_connected(_start_shaking):
			break_timer.timeout.connect(_start_shaking)
	
	if shake_timer:
		shake_timer.wait_time = shake_duration
		shake_timer.one_shot = true
		if not shake_timer.timeout.is_connected(_break_platform):
			shake_timer.timeout.connect(_break_platform)
	
	# Setup player detection
	_setup_player_detection()
	
	# Setup particles
	_setup_break_particles()
	
	print("🔧 BreakableComponent configured: delay=", break_delay, " shake=", shake_duration)

func _setup_player_detection():
	if not player_detector or not detection_collision or not platform:
		print("⚠️ Cannot setup player detection - missing components")
		return
	
	# Create detection area above platform
	var area_shape = RectangleShape2D.new()
	area_shape.size = Vector2(platform.width, 8)  # Thin detection area on top
	detection_collision.shape = area_shape
	detection_collision.position = Vector2(platform.width / 2, -4)  # Above the platform
	
	# Connect signal
	if not player_detector.body_entered.is_connected(_on_player_detected):
		player_detector.body_entered.connect(_on_player_detected)
	
	print("🔍 Player detection area setup: Size=", area_shape.size, " Position=", detection_collision.position)

func _setup_break_particles():
	if not break_particles or not platform:
		print("⚠️ Cannot setup break particles - missing components")
		return
	
	# Configure particle system for breaking effect
	var material = ParticleProcessMaterial.new()
	
	# Emission
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(platform.width / 2, platform.height / 2, 0)
	
	# Movement
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 150.0
	material.gravity = Vector3(0, 980, 0)
	
	# Scale and rotation
	material.scale_min = 0.5
	material.scale_max = 1.5
	material.angular_velocity_min = -180.0
	material.angular_velocity_max = 180.0
	
	# Color (match platform type)
	var base_color = Color.WHITE
	match platform.platform_type:
		DynamicPlatform.PlatformType.YELLOW:
			base_color = Color.YELLOW
		DynamicPlatform.PlatformType.GREEN:
			base_color = Color.GREEN
		DynamicPlatform.PlatformType.EMPTY:
			base_color = Color.GRAY
	
	material.color = base_color
	
	break_particles.process_material = material
	break_particles.amount = 50
	break_particles.lifetime = 2.0
	break_particles.emitting = false
	
	# Position particles at platform center
	break_particles.position = Vector2(platform.width / 2, platform.height / 2)

# Method to handle platform size changes
func platform_size_changed(new_size: Vector2):
	if not platform:
		return
		
	# Update detection area
	_setup_player_detection()
	
	# Update particle system
	if break_particles and break_particles.process_material:
		var material = break_particles.process_material as ParticleProcessMaterial
		if material:
			material.emission_box_extents = Vector3(new_size.x / 2, new_size.y / 2, 0)
			break_particles.position = Vector2(new_size.x / 2, new_size.y / 2)

# Method to reset component state for object pooling
func reset_state():
	break_state = BreakState.STABLE
	shake_time_elapsed = 0.0
	platform = null
	original_position = Vector2.ZERO
	
	# Stop any running timers
	if break_timer and break_timer.timeout.is_connected(_start_shaking):
		break_timer.stop()
	if shake_timer and shake_timer.timeout.is_connected(_break_platform):
		shake_timer.stop()
	
	# Stop particles
	if break_particles:
		break_particles.emitting = false
	
	print("🔄 BreakableComponent reset")

func _physics_process(delta):
	# Handle shaking animation
	if break_state == BreakState.SHAKING and platform.is_active_in_current_layer:
		_update_shake(delta)

func _update_shake(delta):
	shake_time_elapsed += delta
	var shake_progress = shake_time_elapsed / shake_duration
	var current_intensity = shake_intensity * (1.0 - shake_progress * 0.5)  # Reduce intensity over time
	
	# Apply shake offset
	var shake_offset = Vector2(
		randf_range(-current_intensity, current_intensity),
		randf_range(-current_intensity, current_intensity)
	)
	platform.global_position = original_position + shake_offset

func _on_player_detected(body):
	print("🔍 Body entered detection area: ", body.name, " - State: ", BreakState.keys()[break_state])
	
	if break_state != BreakState.STABLE:
		return
	
	# Check if it's the player (more robust check)
	if body.name.begins_with("Player") or body.has_method("is_player") or body.get_class() == "CharacterBody2D":
		print("🎯 Player detected! Triggering break sequence")
		_trigger_break_sequence()

func _trigger_break_sequence():
	if break_state != BreakState.STABLE:
		return
	
	print("💥 Break sequence triggered!")
	break_state = BreakState.TOUCHED
	break_started.emit()
	
	# Start break timer with null check
	if break_timer:
		break_timer.start()
		print("⏰ Break timer started: ", break_timer.wait_time, " seconds")
	else:
		print("❌ Break timer not available, starting shake immediately")
		_start_shaking()
	
	# Emit event for audio
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").sfx_requested.emit("platform_touched", platform.global_position)

func _start_shaking():
	if break_state != BreakState.TOUCHED:
		return
	
	print("🔥 Platform started shaking!")
	break_state = BreakState.SHAKING
	shake_time_elapsed = 0.0
	
	# Start shake timer with null check
	if shake_timer:
		shake_timer.start()
		print("⏰ Shake timer started: ", shake_timer.wait_time, " seconds")
	else:
		print("❌ Shake timer not available, breaking immediately")
		_break_platform()
	
	# Emit event for audio
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").sfx_requested.emit("platform_shaking", platform.global_position)

func _break_platform():
	if break_state != BreakState.SHAKING:
		return
	
	break_state = BreakState.BROKEN
	
	# Reset position
	platform.global_position = original_position
	
	# Disable collision immediately - player can no longer stand on it
	platform.collision_layer = 0
	platform.collision_mask = 0
	if platform.collision_shape:
		platform.collision_shape.disabled = true
	
	# Hide platform nine patch
	if platform.nine_patch:
		platform.nine_patch.visible = false
	
	# Trigger particle effect if available
	if break_particles:
		break_particles.emitting = true
	
	# Emit events
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		event_bus.sfx_requested.emit("platform_break", platform.global_position)
		event_bus.screen_shake_requested.emit(150.0, 0.5)
	
	break_completed.emit()
	
	# Remove platform after particles finish (or immediately if no particles)
	var cleanup_time = break_particles.lifetime if break_particles else 1.0
	await get_tree().create_timer(cleanup_time).timeout
	if platform:
		platform.queue_free()

# Method to update detection area (called from DynamicPlatform)
func update_detection_area():
	_setup_player_detection()
