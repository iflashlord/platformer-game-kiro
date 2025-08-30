extends Node2D
class_name ObstacleDetector

# Signals for obstacle detection events
signal obstacle_detected(direction: Vector2, distance: float)
signal path_found(waypoints: Array[Vector2])
signal path_blocked()

# Detection configuration
@export var detection_range: float = 32.0
@export var raycast_count: int = 4
@export var collision_layers: int = 1  # World geometry layer
@export var min_obstacle_distance: float = 16.0

# Raycast system
var raycast_pool: Array[RaycastNode] = []
var raycast_directions: Array[Vector2] = []
var active_raycasts: int = 0

# Obstacle caching for performance
var obstacle_cache: Dictionary = {}
var cache_max_size: int = 50
var cache_lifetime: float = 1.0
var last_detection_time: float = 0.0

# Performance optimization
var detection_frequency: float = 1.0 / 30.0  # 30 FPS default
var detection_timer: float = 0.0
var is_detection_active: bool = true

# Parent reference
var flying_enemy: FlyingEnemy

# Obstacle information structure
class ObstacleInfo:
	var position: Vector2
	var direction: Vector2
	var distance: float
	var surface_normal: Vector2
	var detection_time: float
	var is_cached: bool = false
	
	func _init(pos: Vector2, dir: Vector2, dist: float, normal: Vector2 = Vector2.ZERO):
		position = pos
		direction = dir.normalized()
		distance = dist
		surface_normal = normal.normalized()
		detection_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second

func _ready():
	# Get parent reference
	flying_enemy = get_parent() as FlyingEnemy
	if not flying_enemy:
		push_error("ObstacleDetector must be child of FlyingEnemy")
		return
	
	# Setup raycast system
	_setup_raycast_system()
	
	# Initialize detection directions (4-ray pattern)
	_setup_detection_directions()

func _setup_raycast_system():
	"""Initialize the raycast pool for obstacle detection"""
	raycast_pool.clear()
	
	for i in range(raycast_count):
		var raycast = RaycastNode.new()
		raycast.collision_mask = collision_layers
		raycast.enabled = true
		raycast.exclude_parent = true
		add_child(raycast)
		raycast_pool.append(raycast)

func _setup_detection_directions():
	"""Setup the 4-ray detection pattern"""
	raycast_directions = [
		Vector2.RIGHT,   # Forward (relative to movement)
		Vector2.LEFT,    # Backward
		Vector2.UP,      # Up
		Vector2.DOWN     # Down
	]

func _physics_process(delta):
	"""Main detection update loop"""
	if not is_detection_active:
		return
	
	detection_timer += delta
	
	# Check if it's time for detection update
	if detection_timer >= detection_frequency:
		detection_timer = 0.0
		_perform_obstacle_detection()
		_cleanup_obstacle_cache()

func _perform_obstacle_detection():
	"""Perform obstacle detection using raycast system"""
	var detected_obstacles: Array[Vector2] = []
	var current_velocity = flying_enemy.velocity if flying_enemy else Vector2.RIGHT
	var movement_direction = current_velocity.normalized() if current_velocity.length() > 0 else Vector2.RIGHT
	
	# Update raycast directions based on current movement
	var detection_dirs = _get_adjusted_detection_directions(movement_direction)
	
	for i in range(min(raycast_count, detection_dirs.size())):
		var raycast = raycast_pool[i]
		var direction = detection_dirs[i]
		
		# Set raycast parameters
		raycast.target_position = direction * detection_range
		raycast.force_raycast_update()
		
		# Check for collision
		if raycast.is_colliding():
			var collision_point = raycast.get_collision_point()
			var collision_normal = raycast.get_collision_normal()
			var distance = global_position.distance_to(collision_point)
			
			# Only consider obstacles within minimum distance
			if distance <= detection_range:
				detected_obstacles.append(direction)
				
				# Create obstacle info
				var obstacle_info = ObstacleInfo.new(collision_point, direction, distance, collision_normal)
				_cache_obstacle(direction, obstacle_info)
				
				# Emit obstacle detected signal
				obstacle_detected.emit(direction, distance)
	
	# Update last detection time
	last_detection_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second

func _get_adjusted_detection_directions(movement_direction: Vector2) -> Array[Vector2]:
	"""Get detection directions adjusted for current movement"""
	var adjusted_directions: Array[Vector2] = []
	
	# Primary direction: forward movement
	adjusted_directions.append(movement_direction)
	
	# Secondary directions: perpendicular to movement
	var perpendicular_right = Vector2(movement_direction.y, -movement_direction.x)
	var perpendicular_left = Vector2(-movement_direction.y, movement_direction.x)
	adjusted_directions.append(perpendicular_right)
	adjusted_directions.append(perpendicular_left)
	
	# Tertiary direction: backward (for escape routes)
	adjusted_directions.append(-movement_direction)
	
	return adjusted_directions

func detect_obstacles() -> Array[Vector2]:
	"""Get currently detected obstacle directions"""
	var obstacles: Array[Vector2] = []
	
	# Check cached obstacles first
	for direction in obstacle_cache.keys():
		var obstacle_info = obstacle_cache[direction] as ObstacleInfo
		if obstacle_info and _is_obstacle_still_valid(obstacle_info):
			obstacles.append(direction)
	
	return obstacles

func find_alternative_path(blocked_direction: Vector2) -> Array[Vector2]:
	"""Find alternative path around obstacles using intelligent pathfinding"""
	var waypoints: Array[Vector2] = []
	var current_pos = global_position
	var attempts = 0
	var max_attempts = flying_enemy.pathfinding_attempts if flying_enemy else 3
	
	# Get current movement context
	var current_velocity = flying_enemy.velocity if flying_enemy else Vector2.RIGHT
	var movement_direction = current_velocity.normalized() if current_velocity.length() > 0 else Vector2.RIGHT
	
	# Try different pathfinding strategies
	while attempts < max_attempts and waypoints.is_empty():
		attempts += 1
		
		match attempts:
			1:
				# Strategy 1: Vertical bypass (Requirements 1.3)
				waypoints = _try_vertical_bypass(current_pos, blocked_direction, movement_direction)
			2:
				# Strategy 2: Horizontal bypass (Requirements 1.4)
				waypoints = _try_horizontal_bypass(current_pos, blocked_direction, movement_direction)
			3:
				# Strategy 3: Diagonal bypass (advanced pathfinding)
				waypoints = _try_diagonal_bypass(current_pos, blocked_direction, movement_direction)
	
	# If no path found after all attempts, use fallback (Requirements 1.5)
	if waypoints.is_empty():
		waypoints = _get_fallback_path(current_pos, blocked_direction)
		path_blocked.emit()
	else:
		path_found.emit(waypoints)
	
	return waypoints

func _try_vertical_bypass(current_pos: Vector2, blocked_direction: Vector2, movement_direction: Vector2) -> Array[Vector2]:
	"""Try vertical bypass strategy (up/down by 64 pixels)"""
	var waypoints: Array[Vector2] = []
	var bypass_distance = 64.0
	
	# Prioritize bypass direction based on current movement and obstacles
	var vertical_options = _get_prioritized_vertical_options(movement_direction)
	
	for vertical_offset in vertical_options:
		var bypass_position = current_pos + vertical_offset * bypass_distance
		
		# Check if bypass position is clear
		if is_path_clear(current_pos, bypass_position):
			waypoints.append(bypass_position)
			
			# Check if we can continue in original direction after bypass
			var continue_position = bypass_position + blocked_direction.normalized() * bypass_distance
			if is_path_clear(bypass_position, continue_position):
				waypoints.append(continue_position)
				return waypoints
			else:
				# Try shorter continuation
				var short_continue = bypass_position + blocked_direction.normalized() * (bypass_distance * 0.5)
				if is_path_clear(bypass_position, short_continue):
					waypoints.append(short_continue)
					return waypoints
		
		# Clear waypoints if this option didn't work
		waypoints.clear()
	
	return waypoints

func _try_horizontal_bypass(current_pos: Vector2, blocked_direction: Vector2, movement_direction: Vector2) -> Array[Vector2]:
	"""Try horizontal bypass strategy (left/right by 64 pixels)"""
	var waypoints: Array[Vector2] = []
	var bypass_distance = 64.0
	
	# Prioritize bypass direction based on current movement and obstacles
	var horizontal_options = _get_prioritized_horizontal_options(movement_direction, blocked_direction)
	
	for horizontal_offset in horizontal_options:
		var bypass_position = current_pos + horizontal_offset * bypass_distance
		
		# Check if bypass position is clear
		if is_path_clear(current_pos, bypass_position):
			waypoints.append(bypass_position)
			
			# Check if we can continue in original direction after bypass
			var continue_position = bypass_position + blocked_direction.normalized() * bypass_distance
			if is_path_clear(bypass_position, continue_position):
				waypoints.append(continue_position)
				return waypoints
			else:
				# Try angled continuation
				var angled_continue = bypass_position + (blocked_direction.normalized() + horizontal_offset).normalized() * bypass_distance
				if is_path_clear(bypass_position, angled_continue):
					waypoints.append(angled_continue)
					return waypoints
		
		# Clear waypoints if this option didn't work
		waypoints.clear()
	
	return waypoints

func _try_diagonal_bypass(current_pos: Vector2, blocked_direction: Vector2, movement_direction: Vector2) -> Array[Vector2]:
	"""Try diagonal bypass strategy (combination of vertical and horizontal)"""
	var waypoints: Array[Vector2] = []
	var bypass_distance = 45.0  # Shorter distance for diagonal
	
	# Generate diagonal bypass options
	var diagonal_options = [
		Vector2(1, 1).normalized(),   # Up-right
		Vector2(-1, 1).normalized(),  # Up-left
		Vector2(1, -1).normalized(),  # Down-right
		Vector2(-1, -1).normalized()  # Down-left
	]
	
	# Prioritize diagonals based on movement direction
	diagonal_options.sort_custom(func(a, b): 
		return movement_direction.dot(a) > movement_direction.dot(b)
	)
	
	for diagonal_dir in diagonal_options:
		var bypass_position = current_pos + diagonal_dir * bypass_distance
		
		if is_path_clear(current_pos, bypass_position):
			waypoints.append(bypass_position)
			
			# Try to continue toward original goal
			var continue_position = bypass_position + blocked_direction.normalized() * bypass_distance
			if is_path_clear(bypass_position, continue_position):
				waypoints.append(continue_position)
				return waypoints
		
		waypoints.clear()
	
	return waypoints

func _get_fallback_path(current_pos: Vector2, blocked_direction: Vector2) -> Array[Vector2]:
	"""Get fallback path when all pathfinding attempts fail (Requirements 1.5)"""
	var waypoints: Array[Vector2] = []
	
	# Fallback strategy: reverse direction and continue original behavior
	var reverse_direction = -blocked_direction.normalized()
	var fallback_position = current_pos + reverse_direction * 32.0
	
	# Ensure fallback position is safe
	if is_path_clear(current_pos, fallback_position):
		waypoints.append(fallback_position)
	else:
		# If even reverse is blocked, try perpendicular escape
		var perpendicular = Vector2(-blocked_direction.y, blocked_direction.x).normalized()
		var escape_position = current_pos + perpendicular * 32.0
		if is_path_clear(current_pos, escape_position):
			waypoints.append(escape_position)
	
	return waypoints

func _get_prioritized_vertical_options(movement_direction: Vector2) -> Array[Vector2]:
	"""Get vertical bypass options prioritized by movement direction"""
	var options: Array[Vector2] = []
	
	# If moving mostly horizontally, prefer up first (less likely to hit ground)
	if abs(movement_direction.x) > abs(movement_direction.y):
		options = [Vector2.UP, Vector2.DOWN]
	else:
		# If moving vertically, prefer direction that continues movement
		if movement_direction.y < 0:  # Moving up
			options = [Vector2.UP, Vector2.DOWN]
		else:  # Moving down
			options = [Vector2.DOWN, Vector2.UP]
	
	return options

func _get_prioritized_horizontal_options(movement_direction: Vector2, blocked_direction: Vector2) -> Array[Vector2]:
	"""Get horizontal bypass options prioritized by movement and obstacle direction"""
	var options: Array[Vector2] = []
	
	# Calculate perpendicular directions to blocked direction
	var perpendicular_right = Vector2(blocked_direction.y, -blocked_direction.x).normalized()
	var perpendicular_left = Vector2(-blocked_direction.y, blocked_direction.x).normalized()
	
	# Prioritize based on current movement direction
	if movement_direction.dot(perpendicular_right) > movement_direction.dot(perpendicular_left):
		options = [perpendicular_right, perpendicular_left]
	else:
		options = [perpendicular_left, perpendicular_right]
	
	return options

func is_path_clear(from: Vector2, to: Vector2) -> bool:
	"""Check if path between two points is clear with advanced validation"""
	# Use a temporary raycast to check path
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = collision_layers
	query.exclude = [flying_enemy]  # Exclude self
	
	var result = space_state.intersect_ray(query)
	
	# If no collision, path is clear
	if result.is_empty():
		return true
	
	# Additional validation for edge cases
	var collision_point = result.position
	var distance_to_collision = from.distance_to(collision_point)
	
	# If collision is very close to start point, might be false positive
	if distance_to_collision < min_obstacle_distance * 0.5:
		return true
	
	# Check if collision is with a temporary or moving object
	var collider = result.collider
	if collider and collider.has_method("is_temporary_obstacle"):
		if collider.is_temporary_obstacle():
			return true
	
	return false

func validate_collision_data(collision_point: Vector2, collision_normal: Vector2, collider: Node) -> bool:
	"""Validate collision data for accuracy and relevance"""
	# Check if collision point is within reasonable range
	var distance = global_position.distance_to(collision_point)
	if distance > detection_range * 1.5:  # Allow some tolerance
		return false
	
	# Check if collision normal makes sense
	if collision_normal.length() < 0.1:
		return false  # Invalid normal
	
	# Check if collider is a valid obstacle
	if not collider:
		return false
	
	# Exclude certain types of objects that shouldn't be obstacles
	if collider.is_in_group("players") or collider.is_in_group("enemies"):
		return false
	
	# Check if collider is on the correct collision layer
	if collider.has_method("get_collision_layer"):
		var collider_layer = collider.get_collision_layer()
		if (collider_layer & collision_layers) == 0:
			return false
	
	return true

func get_obstacle_priority(obstacle_info: ObstacleInfo, current_movement: Vector2) -> float:
	"""Calculate priority of obstacle for pathfinding decisions"""
	var priority = 0.0
	
	# Distance factor (closer obstacles have higher priority)
	var distance_factor = 1.0 - (obstacle_info.distance / detection_range)
	priority += distance_factor * 0.4
	
	# Movement alignment factor (obstacles in movement path have higher priority)
	var movement_alignment = current_movement.normalized().dot(obstacle_info.direction)
	priority += max(movement_alignment, 0.0) * 0.3
	
	# Surface normal factor (walls vs floors/ceilings)
	var normal_factor = abs(obstacle_info.surface_normal.dot(Vector2.UP))
	priority += normal_factor * 0.2  # Horizontal surfaces are more important
	
	# Confidence factor
	priority += obstacle_info.confidence * 0.1
	
	return clamp(priority, 0.0, 1.0)

func find_best_avoidance_path(obstacles: Array[ObstacleInfo], target_direction: Vector2) -> Array[Vector2]:
	"""Find the best avoidance path considering multiple obstacles"""
	var waypoints: Array[Vector2] = []
	var current_pos = global_position
	
	if obstacles.is_empty():
		return waypoints
	
	# Sort obstacles by priority
	obstacles.sort_custom(func(a, b): 
		return get_obstacle_priority(a, target_direction) > get_obstacle_priority(b, target_direction)
	)
	
	# Start with the highest priority obstacle
	var primary_obstacle = obstacles[0]
	
	# Get potential bypass positions from the primary obstacle
	var bypass_positions = primary_obstacle.get_bypass_positions()
	
	# Evaluate each bypass position
	var best_position = Vector2.ZERO
	var best_score = -1.0
	
	for bypass_pos in bypass_positions:
		var score = _evaluate_bypass_position(bypass_pos, obstacles, target_direction)
		if score > best_score:
			best_score = score
			best_position = bypass_pos
	
	# If we found a good bypass position, create waypoints
	if best_score > 0.0:
		waypoints.append(best_position)
		
		# Try to add a continuation waypoint
		var continue_pos = best_position + target_direction.normalized() * 64.0
		if _is_position_safe(continue_pos, obstacles):
			waypoints.append(continue_pos)
	
	return waypoints

func _evaluate_bypass_position(position: Vector2, obstacles: Array[ObstacleInfo], target_direction: Vector2) -> float:
	"""Evaluate how good a bypass position is"""
	var score = 0.0
	
	# Check if position is reachable
	if not is_path_clear(global_position, position):
		return 0.0
	
	# Distance from obstacles (farther is better)
	var min_obstacle_distance = INF
	for obstacle in obstacles:
		var distance = position.distance_to(obstacle.position)
		min_obstacle_distance = min(min_obstacle_distance, distance)
	
	if min_obstacle_distance > min_obstacle_distance:
		score += 0.4
	
	# Alignment with target direction (closer to target is better)
	var direction_to_position = (position - global_position).normalized()
	var alignment = direction_to_position.dot(target_direction.normalized())
	score += max(alignment, 0.0) * 0.3
	
	# Check if we can continue from this position
	var continue_pos = position + target_direction.normalized() * 32.0
	if is_path_clear(position, continue_pos):
		score += 0.3
	
	return score

func _is_position_safe(position: Vector2, obstacles: Array[ObstacleInfo]) -> bool:
	"""Check if a position is safe from known obstacles"""
	for obstacle in obstacles:
		var distance = position.distance_to(obstacle.position)
		if distance < min_obstacle_distance:
			return false
	
	return true

func get_avoidance_direction(obstacle_direction: Vector2) -> Vector2:
	"""Get direction to avoid obstacle"""
	# Find the best perpendicular direction to avoid obstacle
	var perpendicular_right = Vector2(obstacle_direction.y, -obstacle_direction.x)
	var perpendicular_left = Vector2(-obstacle_direction.y, obstacle_direction.x)
	
	# Check which perpendicular direction is clearer
	var right_clear = is_path_clear(global_position, global_position + perpendicular_right * detection_range)
	var left_clear = is_path_clear(global_position, global_position + perpendicular_left * detection_range)
	
	if right_clear and not left_clear:
		return perpendicular_right
	elif left_clear and not right_clear:
		return perpendicular_left
	elif right_clear and left_clear:
		# Both clear, choose based on current movement preference
		var current_velocity = flying_enemy.velocity if flying_enemy else Vector2.RIGHT
		if current_velocity.dot(perpendicular_right) > current_velocity.dot(perpendicular_left):
			return perpendicular_right
		else:
			return perpendicular_left
	else:
		# Both blocked, reverse direction
		return -obstacle_direction

func _cache_obstacle(direction: Vector2, obstacle_info: ObstacleInfo):
	"""Cache obstacle information for performance"""
	# Remove oldest entries if cache is full
	if obstacle_cache.size() >= cache_max_size:
		_cleanup_obstacle_cache(true)
	
	obstacle_info.is_cached = true
	obstacle_cache[direction] = obstacle_info

func _cleanup_obstacle_cache(force_cleanup: bool = false):
	"""Clean up expired obstacle cache entries"""
	var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	var keys_to_remove: Array = []
	
	for direction in obstacle_cache.keys():
		var obstacle_info = obstacle_cache[direction] as ObstacleInfo
		if obstacle_info:
			var age = current_time - obstacle_info.detection_time
			if age > cache_lifetime or force_cleanup:
				keys_to_remove.append(direction)
	
	# Remove expired entries
	for key in keys_to_remove:
		obstacle_cache.erase(key)
	
	# If force cleanup and still too many, remove oldest
	if force_cleanup and obstacle_cache.size() >= cache_max_size:
		var oldest_key = null
		var oldest_time = current_time
		
		for direction in obstacle_cache.keys():
			var obstacle_info = obstacle_cache[direction] as ObstacleInfo
			if obstacle_info and obstacle_info.detection_time < oldest_time:
				oldest_time = obstacle_info.detection_time
				oldest_key = direction
		
		if oldest_key:
			obstacle_cache.erase(oldest_key)

func _is_obstacle_still_valid(obstacle_info: ObstacleInfo) -> bool:
	"""Check if cached obstacle is still valid"""
	var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	var age = current_time - obstacle_info.detection_time
	
	# Check age
	if age > cache_lifetime:
		return false
	
	# Check if obstacle is still within detection range
	var distance_to_obstacle = global_position.distance_to(obstacle_info.position)
	return distance_to_obstacle <= detection_range

# Configuration and utility functions
func set_detection_range(range: float):
	"""Set obstacle detection range"""
	detection_range = max(range, 16.0)  # Minimum 16 pixels

func set_detection_frequency(frequency: float):
	"""Set detection update frequency"""
	detection_frequency = 1.0 / max(frequency, 1.0)  # Minimum 1 FPS

func set_collision_layers(layers: int):
	"""Set collision layers to detect"""
	collision_layers = layers
	
	# Update existing raycasts
	for raycast in raycast_pool:
		if raycast:
			raycast.collision_mask = collision_layers

func enable_detection(enabled: bool):
	"""Enable or disable obstacle detection"""
	is_detection_active = enabled

func get_obstacle_count() -> int:
	"""Get number of currently detected obstacles"""
	return detect_obstacles().size()

func get_cached_obstacle_count() -> int:
	"""Get number of cached obstacles"""
	return obstacle_cache.size()

func clear_obstacle_cache():
	"""Clear all cached obstacles"""
	obstacle_cache.clear()

func get_debug_info() -> Dictionary:
	"""Get debug information about obstacle detection"""
	return {
		"detection_range": detection_range,
		"raycast_count": raycast_count,
		"active_obstacles": get_obstacle_count(),
		"cached_obstacles": get_cached_obstacle_count(),
		"detection_frequency": 1.0 / detection_frequency,
		"is_active": is_detection_active,
		"last_detection_time": last_detection_time
	}

# Custom RaycastNode class for pooling
class RaycastNode extends RayCast2D:
	func _init():
		enabled = true
		exclude_parent = true