extends RefCounted
class_name MovementState

# Movement vectors and direction
var velocity: Vector2 = Vector2.ZERO
var target_velocity: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var target_direction: Vector2 = Vector2.RIGHT

# Speed management
var speed: float = 80.0
var target_speed: float = 80.0
var max_speed: float = 200.0
var min_speed: float = 20.0

# Transition state
var is_transitioning: bool = false
var transition_progress: float = 0.0
var transition_duration: float = 0.5

# Movement mode tracking
var movement_mode: String = "patrol"
var last_mode_change_time: float = 0.0

# Smoothing parameters
var velocity_smoothing: float = 0.3
var direction_smoothing: float = 0.3
var speed_smoothing: float = 0.5

func _init(initial_speed: float = 80.0, initial_direction: Vector2 = Vector2.RIGHT):
	"""Initialize movement state with default values"""
	speed = initial_speed
	target_speed = initial_speed
	direction = initial_direction.normalized()
	target_direction = direction
	velocity = direction * speed

func update_movement(delta: float) -> void:
	"""Update movement state with smooth transitions"""
	# Update transition progress
	if is_transitioning:
		transition_progress += delta / transition_duration
		if transition_progress >= 1.0:
			transition_progress = 1.0
			is_transitioning = false
	
	# Smooth speed transition
	if abs(speed - target_speed) > 1.0:
		speed = lerp(speed, target_speed, speed_smoothing * delta / (1.0/60.0))
	else:
		speed = target_speed
	
	# Smooth direction transition
	if direction.distance_to(target_direction) > 0.01:
		direction = direction.lerp(target_direction, direction_smoothing * delta / (1.0/60.0)).normalized()
	else:
		direction = target_direction
	
	# Update target velocity based on current direction and speed
	target_velocity = direction * speed
	
	# Smooth velocity transition
	if velocity.distance_to(target_velocity) > 1.0:
		velocity = velocity.lerp(target_velocity, velocity_smoothing * delta / (1.0/60.0))
	else:
		velocity = target_velocity

func set_target_speed(new_speed: float, transition_time: float = 0.5) -> void:
	"""Set target speed with optional transition time"""
	new_speed = clamp(new_speed, min_speed, max_speed)
	
	if abs(target_speed - new_speed) > 1.0:
		target_speed = new_speed
		transition_duration = transition_time
		transition_progress = 0.0
		is_transitioning = true

func set_target_direction(new_direction: Vector2, transition_time: float = 0.3) -> void:
	"""Set target direction with optional transition time"""
	if new_direction.length() > 0:
		var normalized_direction = new_direction.normalized()
		
		if direction.distance_to(normalized_direction) > 0.01:
			target_direction = normalized_direction
			transition_duration = transition_time
			transition_progress = 0.0
			is_transitioning = true

func set_movement_mode(mode: String) -> void:
	"""Set movement mode and track mode changes"""
	if movement_mode != mode:
		movement_mode = mode
		last_mode_change_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second

func apply_force(force: Vector2, duration: float = 0.1) -> void:
	"""Apply an external force to the movement (for pushback, etc.)"""
	# Add force to current velocity temporarily
	velocity += force
	
	# Create a tween-like effect to return to normal velocity
	var force_decay_rate = 1.0 / duration
	# This would need to be handled in the update loop

func get_speed_ratio() -> float:
	"""Get current speed as ratio of max speed"""
	return speed / max_speed if max_speed > 0 else 0.0

func get_direction_change_rate() -> float:
	"""Get how quickly direction is changing (for animation)"""
	return direction.distance_to(target_direction)

func is_moving() -> bool:
	"""Check if currently moving"""
	return velocity.length() > 1.0

func is_changing_direction() -> bool:
	"""Check if currently changing direction"""
	return direction.distance_to(target_direction) > 0.01

func is_changing_speed() -> bool:
	"""Check if currently changing speed"""
	return abs(speed - target_speed) > 1.0

func get_movement_info() -> Dictionary:
	"""Get movement information for debugging"""
	return {
		"velocity": velocity,
		"target_velocity": target_velocity,
		"direction": direction,
		"target_direction": target_direction,
		"speed": speed,
		"target_speed": target_speed,
		"is_transitioning": is_transitioning,
		"transition_progress": transition_progress,
		"movement_mode": movement_mode,
		"is_moving": is_moving(),
		"is_changing_direction": is_changing_direction(),
		"is_changing_speed": is_changing_speed()
	}

func reset_to_defaults() -> void:
	"""Reset movement state to default values"""
	velocity = Vector2.ZERO
	target_velocity = Vector2.ZERO
	direction = Vector2.RIGHT
	target_direction = Vector2.RIGHT
	speed = 80.0
	target_speed = 80.0
	is_transitioning = false
	transition_progress = 0.0
	movement_mode = "patrol"