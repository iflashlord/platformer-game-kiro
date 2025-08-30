extends RefCounted
class_name ObstacleInfo

# Obstacle position and direction information
var position: Vector2
var direction: Vector2
var distance: float
var surface_normal: Vector2
var detection_time: float
var is_cached: bool = false

# Additional obstacle properties
var obstacle_type: String = "unknown"
var is_temporary: bool = false
var confidence: float = 1.0  # How confident we are in this detection

func _init(pos: Vector2, dir: Vector2, dist: float, normal: Vector2 = Vector2.ZERO):
	"""Initialize obstacle information"""
	position = pos
	direction = dir.normalized() if dir.length() > 0 else Vector2.ZERO
	distance = dist
	surface_normal = normal.normalized() if normal.length() > 0 else Vector2.ZERO
	detection_time = _get_current_time()

func _get_current_time() -> float:
	"""Get current time as float for comparison"""
	var time_dict = Time.get_time_dict_from_system()
	return time_dict.hour * 3600.0 + time_dict.minute * 60.0 + time_dict.second

func get_age() -> float:
	"""Get age of this obstacle detection in seconds"""
	return _get_current_time() - detection_time

func is_expired(max_age: float) -> bool:
	"""Check if obstacle detection has expired"""
	return get_age() > max_age

func update_position(new_pos: Vector2, new_distance: float):
	"""Update obstacle position (for moving obstacles)"""
	position = new_pos
	distance = new_distance
	detection_time = _get_current_time()

func get_avoidance_vector(from_position: Vector2) -> Vector2:
	"""Get vector to avoid this obstacle from given position"""
	var to_obstacle = (position - from_position).normalized()
	
	# Use surface normal if available, otherwise use perpendicular
	if surface_normal.length() > 0:
		return surface_normal
	else:
		# Return perpendicular vector (90 degrees from obstacle direction)
		return Vector2(-to_obstacle.y, to_obstacle.x)

func get_bypass_positions(bypass_distance: float = 64.0) -> Array[Vector2]:
	"""Get potential positions to bypass this obstacle"""
	var bypass_positions: Array[Vector2] = []
	
	# Calculate perpendicular directions for bypass
	var perpendicular_1 = Vector2(-direction.y, direction.x) * bypass_distance
	var perpendicular_2 = Vector2(direction.y, -direction.x) * bypass_distance
	
	# Add bypass positions
	bypass_positions.append(position + perpendicular_1)
	bypass_positions.append(position + perpendicular_2)
	
	# Add vertical bypass options if surface normal suggests it
	if abs(surface_normal.y) > 0.5:  # Horizontal surface
		bypass_positions.append(position + Vector2(0, -bypass_distance))  # Above
		bypass_positions.append(position + Vector2(0, bypass_distance))   # Below
	
	return bypass_positions

func is_similar_to(other: ObstacleInfo, position_threshold: float = 32.0, direction_threshold: float = 0.8) -> bool:
	"""Check if this obstacle is similar to another (for deduplication)"""
	if not other:
		return false
	
	# Check position similarity
	var position_distance = position.distance_to(other.position)
	if position_distance > position_threshold:
		return false
	
	# Check direction similarity
	var direction_similarity = direction.dot(other.direction)
	if direction_similarity < direction_threshold:
		return false
	
	return true

func merge_with(other: ObstacleInfo):
	"""Merge this obstacle info with another similar one"""
	if not other or not is_similar_to(other):
		return
	
	# Average positions and distances
	position = (position + other.position) * 0.5
	distance = (distance + other.distance) * 0.5
	
	# Use more recent detection time
	detection_time = max(detection_time, other.detection_time)
	
	# Average confidence
	confidence = (confidence + other.confidence) * 0.5
	
	# Prefer non-temporary obstacles
	if other.is_temporary and not is_temporary:
		is_temporary = false

func get_threat_level(from_position: Vector2, movement_direction: Vector2) -> float:
	"""Calculate threat level of this obstacle (0.0 to 1.0)"""
	var threat = 0.0
	
	# Distance factor (closer = more threatening)
	var distance_factor = 1.0 - (distance / 100.0)  # Assume 100 pixels as max threat distance
	distance_factor = clamp(distance_factor, 0.0, 1.0)
	threat += distance_factor * 0.4
	
	# Direction factor (in movement path = more threatening)
	var direction_to_obstacle = (position - from_position).normalized()
	var alignment = movement_direction.dot(direction_to_obstacle)
	var direction_factor = max(alignment, 0.0)  # Only positive alignment matters
	threat += direction_factor * 0.4
	
	# Confidence factor
	threat += confidence * 0.2
	
	return clamp(threat, 0.0, 1.0)

func to_dictionary() -> Dictionary:
	"""Convert obstacle info to dictionary for serialization/debugging"""
	return {
		"position": {"x": position.x, "y": position.y},
		"direction": {"x": direction.x, "y": direction.y},
		"distance": distance,
		"surface_normal": {"x": surface_normal.x, "y": surface_normal.y},
		"detection_time": detection_time,
		"age": get_age(),
		"is_cached": is_cached,
		"obstacle_type": obstacle_type,
		"is_temporary": is_temporary,
		"confidence": confidence
	}

func from_dictionary(data: Dictionary):
	"""Load obstacle info from dictionary"""
	if data.has("position"):
		position = Vector2(data.position.x, data.position.y)
	if data.has("direction"):
		direction = Vector2(data.direction.x, data.direction.y)
	if data.has("distance"):
		distance = data.distance
	if data.has("surface_normal"):
		surface_normal = Vector2(data.surface_normal.x, data.surface_normal.y)
	if data.has("detection_time"):
		detection_time = data.detection_time
	if data.has("is_cached"):
		is_cached = data.is_cached
	if data.has("obstacle_type"):
		obstacle_type = data.obstacle_type
	if data.has("is_temporary"):
		is_temporary = data.is_temporary
	if data.has("confidence"):
		confidence = data.confidence