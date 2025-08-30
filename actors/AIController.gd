extends Node
class_name AIController

# AI State enumeration
enum AIState { 
	PATROL, 
	CHASE, 
	AVOIDANCE, 
	IDLE 
}

# AI Mode enumeration for configuration
enum AIMode { 
	PATROL_ONLY, 
	CHASE_ONLY, 
	PATROL_AND_CHASE 
}

# Signals for state changes and events
signal state_changed(old_state: AIState, new_state: AIState)
signal target_acquired(target: Node2D)
signal target_lost(target: Node2D)

# Current AI state and configuration
var current_state: AIState = AIState.PATROL
var ai_mode: AIMode = AIMode.PATROL_AND_CHASE
var previous_state: AIState = AIState.PATROL

# State machine configuration
var state_machine: Dictionary = {}
var state_transition_cooldown: float = 0.1
var last_transition_time: float = 0.0

# References to parent and components
var flying_enemy: FlyingEnemy
var obstacle_detector: ObstacleDetector
var chase_detector: ChaseDetector
var movement_controller: MovementController

# State timing and performance
var state_duration: float = 0.0
var update_timer: float = 0.0
var update_frequency: float = 1.0 / 60.0  # 60 FPS default

func _ready():
	# Initialize state machine with valid transitions
	_setup_state_machine()
	
	# Get reference to parent FlyingEnemy
	flying_enemy = get_parent() as FlyingEnemy
	if not flying_enemy:
		push_error("AIController must be child of FlyingEnemy")
		return
	
	# Connect to component signals when they're ready
	call_deferred("_connect_component_signals")

func _setup_state_machine():
	"""Setup valid state transitions for the AI state machine"""
	state_machine = {
		AIState.PATROL: [AIState.CHASE, AIState.AVOIDANCE, AIState.IDLE],
		AIState.CHASE: [AIState.PATROL, AIState.AVOIDANCE, AIState.IDLE],
		AIState.AVOIDANCE: [AIState.PATROL, AIState.CHASE, AIState.IDLE],
		AIState.IDLE: [AIState.PATROL, AIState.CHASE, AIState.AVOIDANCE]
	}

func _connect_component_signals():
	"""Connect to component signals for AI coordination"""
	# Get component references
	obstacle_detector = flying_enemy.get_node_or_null("ObstacleDetector")
	chase_detector = flying_enemy.get_node_or_null("ChaseDetector")
	movement_controller = flying_enemy.get_node_or_null("MovementController")
	
	# Connect obstacle detector signals
	if obstacle_detector:
		obstacle_detector.obstacle_detected.connect(_on_obstacle_detected)
		obstacle_detector.path_blocked.connect(_on_path_blocked)
	
	# Connect chase detector signals
	if chase_detector:
		chase_detector.player_entered_range.connect(_on_player_entered_range)
		chase_detector.player_exited_range.connect(_on_player_exited_range)
		chase_detector.chase_timeout.connect(_on_chase_timeout)

func update_ai(delta: float) -> void:
	"""Main AI update function called by FlyingEnemy"""
	# Update state duration
	state_duration += delta
	update_timer += delta
	
	# Check if it's time for an AI update (for performance optimization)
	if update_timer < update_frequency:
		return
	
	update_timer = 0.0
	
	# Update current state behavior
	match current_state:
		AIState.PATROL:
			_update_patrol_state(delta)
		AIState.CHASE:
			_update_chase_state(delta)
		AIState.AVOIDANCE:
			_update_avoidance_state(delta)
		AIState.IDLE:
			_update_idle_state(delta)

func _update_patrol_state(delta: float) -> void:
	"""Update patrol behavior"""
	# Check if we should transition to chase (if allowed)
	if can_chase() and chase_detector and chase_detector.get_closest_player():
		transition_to_state(AIState.CHASE)
		return
	
	# Check if we need to avoid obstacles
	if should_avoid_obstacles() and obstacle_detector and obstacle_detector.detect_obstacles().size() > 0:
		transition_to_state(AIState.AVOIDANCE)
		return
	
	# Continue normal patrol behavior (handled by FlyingEnemy movement methods)

func _update_chase_state(delta: float) -> void:
	"""Update chase behavior"""
	# Check if we still have a valid target
	if not chase_detector or not chase_detector.get_closest_player():
		transition_to_state(AIState.PATROL)
		return
	
	# Check if we need to avoid obstacles while chasing
	if should_avoid_obstacles() and obstacle_detector and obstacle_detector.detect_obstacles().size() > 0:
		transition_to_state(AIState.AVOIDANCE)
		return
	
	# Continue chase behavior (handled by chase detector and movement controller)

func _update_avoidance_state(delta: float) -> void:
	"""Update obstacle avoidance behavior"""
	# Check if obstacles are cleared
	if not obstacle_detector or obstacle_detector.detect_obstacles().size() == 0:
		# Return to previous state (chase or patrol)
		if previous_state == AIState.CHASE and can_chase() and chase_detector and chase_detector.get_closest_player():
			transition_to_state(AIState.CHASE)
		else:
			transition_to_state(AIState.PATROL)
		return
	
	# Continue avoidance behavior (handled by obstacle detector)

func _update_idle_state(delta: float) -> void:
	"""Update idle behavior for performance optimization"""
	# Check periodically if we should become active again
	if state_duration > 1.0:  # Check every second in idle
		if can_chase() and chase_detector and chase_detector.get_closest_player():
			transition_to_state(AIState.CHASE)
		elif should_avoid_obstacles() and obstacle_detector and obstacle_detector.detect_obstacles().size() > 0:
			transition_to_state(AIState.AVOIDANCE)
		else:
			transition_to_state(AIState.PATROL)

func transition_to_state(new_state: AIState) -> void:
	"""Transition to a new AI state with validation"""
	# Check if transition is valid
	if not _is_valid_transition(current_state, new_state):
		push_warning("Invalid AI state transition from " + str(current_state) + " to " + str(new_state))
		return
	
	# Check transition cooldown to prevent rapid state changes
	var current_time = Time.get_time_dict_from_system()
	var time_since_last = (current_time.hour * 3600 + current_time.minute * 60 + current_time.second) - last_transition_time
	if time_since_last < state_transition_cooldown:
		return
	
	# Perform state transition
	var old_state = current_state
	previous_state = current_state
	current_state = new_state
	state_duration = 0.0
	last_transition_time = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
	
	# Emit state change signal
	state_changed.emit(old_state, new_state)
	
	# Handle state entry logic
	_on_state_entered(new_state, old_state)

func _is_valid_transition(from_state: AIState, to_state: AIState) -> bool:
	"""Check if a state transition is valid"""
	if from_state == to_state:
		return false  # No transition needed
	
	return to_state in state_machine.get(from_state, [])

func _on_state_entered(new_state: AIState, old_state: AIState) -> void:
	"""Handle logic when entering a new state"""
	match new_state:
		AIState.PATROL:
			# Reset to normal patrol behavior
			if movement_controller:
				movement_controller.set_target_speed(flying_enemy.patrol_speed if flying_enemy else 80.0)
		
		AIState.CHASE:
			# Increase speed for chase
			if movement_controller:
				var chase_speed = flying_enemy.chase_speed if flying_enemy else 120.0
				movement_controller.set_target_speed(chase_speed)
		
		AIState.AVOIDANCE:
			# Maintain current speed but focus on obstacle avoidance
			pass
		
		AIState.IDLE:
			# Reduce update frequency for performance
			update_frequency = 1.0 / 5.0  # 5 FPS for idle

func can_chase() -> bool:
	"""Check if the AI is allowed to chase based on current mode"""
	return ai_mode == AIMode.CHASE_ONLY or ai_mode == AIMode.PATROL_AND_CHASE

func should_avoid_obstacles() -> bool:
	"""Check if the AI should perform obstacle avoidance"""
	# Always avoid obstacles unless in idle state
	return current_state != AIState.IDLE

func set_ai_mode(new_mode: AIMode) -> void:
	"""Set the AI mode and adjust behavior accordingly"""
	ai_mode = new_mode
	
	# Force state transition based on new mode
	match ai_mode:
		AIMode.PATROL_ONLY:
			if current_state == AIState.CHASE:
				transition_to_state(AIState.PATROL)
		AIMode.CHASE_ONLY:
			if current_state == AIState.PATROL:
				if chase_detector and chase_detector.get_closest_player():
					transition_to_state(AIState.CHASE)

func set_update_frequency(frequency: float) -> void:
	"""Set the AI update frequency for performance optimization"""
	update_frequency = 1.0 / max(frequency, 1.0)  # Minimum 1 FPS

func get_current_state() -> AIState:
	"""Get the current AI state"""
	return current_state

func get_state_duration() -> float:
	"""Get how long the AI has been in the current state"""
	return state_duration

# Signal callbacks from components
func _on_obstacle_detected(direction: Vector2, distance: float) -> void:
	"""Handle obstacle detection signal"""
	if should_avoid_obstacles() and current_state != AIState.AVOIDANCE:
		transition_to_state(AIState.AVOIDANCE)

func _on_path_blocked() -> void:
	"""Handle path blocked signal"""
	if current_state != AIState.AVOIDANCE:
		transition_to_state(AIState.AVOIDANCE)

func _on_player_entered_range(player: Node2D) -> void:
	"""Handle player entering detection range"""
	if can_chase():
		target_acquired.emit(player)
		transition_to_state(AIState.CHASE)

func _on_player_exited_range(player: Node2D) -> void:
	"""Handle player exiting detection range"""
	target_lost.emit(player)
	# Don't immediately transition - let chase timeout handle it

func _on_chase_timeout() -> void:
	"""Handle chase timeout"""
	if current_state == AIState.CHASE:
		transition_to_state(AIState.PATROL)

# Debug and utility functions
func get_state_name(state: AIState) -> String:
	"""Get human-readable state name for debugging"""
	match state:
		AIState.PATROL: return "PATROL"
		AIState.CHASE: return "CHASE"
		AIState.AVOIDANCE: return "AVOIDANCE"
		AIState.IDLE: return "IDLE"
		_: return "UNKNOWN"

func get_debug_info() -> Dictionary:
	"""Get debug information about the AI state"""
	return {
		"current_state": get_state_name(current_state),
		"previous_state": get_state_name(previous_state),
		"state_duration": state_duration,
		"ai_mode": ai_mode,
		"update_frequency": 1.0 / update_frequency,
		"can_chase": can_chase(),
		"should_avoid_obstacles": should_avoid_obstacles()
	}
