# Design Document

## Overview

The Flying Enemy AI Enhancement system will transform the current basic flying enemy behavior into an intelligent, dynamic system that can navigate around obstacles and engage with players more effectively. The design builds upon the existing FlyingEnemy class while adding new AI components for pathfinding, obstacle detection, and enhanced chase mechanics.

## Architecture

### Core Components

#### 1. AIController Component
A new modular AI system that manages different behavior states:
- **PatrolState**: Default movement patterns (horizontal, sine wave, circular, vertical)
- **ChaseState**: Active pursuit of detected players
- **AvoidanceState**: Obstacle navigation and pathfinding
- **IdleState**: Low-activity mode for performance optimization

#### 2. ObstacleDetector Component
Handles collision detection and pathfinding:
- **RaycastSystem**: 4-ray detection pattern for obstacle sensing
- **PathfindingLogic**: Simple A* alternative route calculation
- **CollisionCache**: Performance optimization for repeated checks

#### 3. ChaseDetector Component
Manages player detection and engagement:
- **DetectionZone**: Configurable radius-based player sensing
- **LineOfSight**: Optional raycast verification for realistic detection
- **EngagementTimer**: Manages chase duration and cooldowns

#### 4. MovementController Component
Unified movement system with smooth transitions:
- **VelocityBlending**: Interpolated speed and direction changes
- **StateTransitions**: Smooth switching between AI states
- **CollisionAvoidance**: Real-time obstacle response

## Components and Interfaces

### Enhanced FlyingEnemy Class Structure

```gdscript
extends CharacterBody2D
class_name FlyingEnemy

# New AI Components
@onready var ai_controller: AIController = $AIController
@onready var obstacle_detector: ObstacleDetector = $ObstacleDetector
@onready var chase_detector: ChaseDetector = $ChaseDetector
@onready var movement_controller: MovementController = $MovementController

# Enhanced Configuration
@export_group("AI Behavior")
@export var ai_mode: AIMode = AIMode.PATROL_AND_CHASE
@export var chase_detection_radius_multiplier: float = 5.0
@export var obstacle_avoidance_sensitivity: float = 32.0
@export var pathfinding_attempts: int = 3

@export_group("Movement Settings")
@export var patrol_speed: float = 80.0
@export var chase_speed: float = 120.0
@export var speed_transition_time: float = 0.5
@export var direction_change_smoothing: float = 0.3

@export_group("Performance")
@export var update_frequency: UpdateFrequency = UpdateFrequency.NORMAL
@export var off_screen_optimization: bool = true
```

### AIController Interface

```gdscript
class_name AIController
extends Node

enum AIState { PATROL, CHASE, AVOIDANCE, IDLE }
enum AIMode { PATROL_ONLY, CHASE_ONLY, PATROL_AND_CHASE }

signal state_changed(old_state: AIState, new_state: AIState)
signal target_acquired(target: Node2D)
signal target_lost(target: Node2D)

var current_state: AIState = AIState.PATROL
var ai_mode: AIMode = AIMode.PATROL_AND_CHASE
var state_machine: Dictionary = {}

func transition_to_state(new_state: AIState) -> void
func update_ai(delta: float) -> void
func can_chase() -> bool
func should_avoid_obstacles() -> bool
```

### ObstacleDetector Interface

```gdscript
class_name ObstacleDetector
extends Node2D

signal obstacle_detected(direction: Vector2, distance: float)
signal path_found(waypoints: Array[Vector2])
signal path_blocked()

@export var detection_range: float = 32.0
@export var raycast_count: int = 4
@export var collision_layers: int = 1  # World geometry

var raycast_pool: Array[RaycastNode] = []
var obstacle_cache: Dictionary = {}
var last_detection_time: float = 0.0

func detect_obstacles() -> Array[Vector2]
func find_alternative_path(blocked_direction: Vector2) -> Array[Vector2]
func is_path_clear(from: Vector2, to: Vector2) -> bool
func get_avoidance_direction(obstacle_direction: Vector2) -> Vector2
```

### ChaseDetector Interface

```gdscript
class_name ChaseDetector
extends Area2D

signal player_entered_range(player: Node2D)
signal player_exited_range(player: Node2D)
signal chase_timeout()

@export var detection_radius: float = 150.0
@export var chase_timeout_duration: float = 2.0
@export var line_of_sight_check: bool = false

var detected_players: Array[Node2D] = []
var chase_timer: float = 0.0
var is_chasing: bool = false

func setup_detection_area(radius: float) -> void
func get_closest_player() -> Node2D
func has_line_of_sight(target: Node2D) -> bool
func start_chase(target: Node2D) -> void
func stop_chase() -> void
```

## Data Models

### AIBehaviorConfig Resource

```gdscript
class_name AIBehaviorConfig
extends Resource

@export var ai_mode: AIController.AIMode = AIController.AIMode.PATROL_AND_CHASE
@export var patrol_pattern: String = "Horizontal"
@export var patrol_speed: float = 80.0
@export var chase_speed: float = 120.0
@export var detection_radius_multiplier: float = 5.0
@export var obstacle_sensitivity: float = 32.0
@export var pathfinding_attempts: int = 3
@export var speed_transition_time: float = 0.5
@export var direction_smoothing: float = 0.3
```

### MovementState Data Structure

```gdscript
class_name MovementState
extends RefCounted

var velocity: Vector2 = Vector2.ZERO
var target_velocity: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var speed: float = 80.0
var target_speed: float = 80.0
var is_transitioning: bool = false
var transition_progress: float = 0.0
```

### ObstacleInfo Data Structure

```gdscript
class_name ObstacleInfo
extends RefCounted

var position: Vector2
var direction: Vector2
var distance: float
var surface_normal: Vector2
var detection_time: float
var is_cached: bool = false
```

## Error Handling

### Obstacle Detection Failures
- **Raycast Failures**: Fallback to simple direction reversal
- **Pathfinding Timeout**: Return to patrol mode after 3 failed attempts
- **Invalid Collision Data**: Use cached obstacle information

### Chase System Failures
- **Target Lost**: Implement timeout system with gradual return to patrol
- **Invalid Player Reference**: Clear target and reset to patrol mode
- **Detection Area Errors**: Disable chase mode and log warning

### Performance Degradation
- **Frame Rate Drops**: Automatically reduce AI update frequency
- **Memory Pressure**: Clear obstacle cache and reduce raycast count
- **Off-Screen Optimization**: Switch to simplified update mode

## Testing Strategy

### Unit Tests
1. **AIController State Transitions**
   - Test all valid state transitions
   - Verify invalid transitions are rejected
   - Confirm state change signals are emitted

2. **ObstacleDetector Accuracy**
   - Test raycast collision detection
   - Verify pathfinding algorithm correctness
   - Validate obstacle cache performance

3. **ChaseDetector Range Calculation**
   - Test detection radius calculations
   - Verify line-of-sight raycast accuracy
   - Confirm timeout behavior

### Integration Tests
1. **AI Behavior Scenarios**
   - Enemy encounters wall and finds alternative path
   - Player enters detection range and chase begins
   - Multiple obstacles require complex pathfinding

2. **Performance Tests**
   - 10+ flying enemies with full AI active
   - Frame rate stability during intensive AI operations
   - Memory usage during extended gameplay

3. **Edge Case Handling**
   - Enemy stuck in corner with no escape routes
   - Player teleports outside detection range
   - Rapid state transitions during complex scenarios

### Gameplay Tests
1. **Player Experience Validation**
   - Enemies feel intelligent and challenging
   - Pathfinding appears natural and believable
   - Chase behavior enhances gameplay tension

2. **Level Design Compatibility**
   - AI works correctly in existing levels
   - New behavior doesn't break level progression
   - Performance remains stable across all level types

## Implementation Phases

### Phase 1: Core AI Framework
- Implement AIController base class
- Create state machine architecture
- Add basic state transitions

### Phase 2: Obstacle Detection
- Implement ObstacleDetector component
- Add raycast-based collision detection
- Create simple pathfinding algorithm

### Phase 3: Chase Enhancement
- Upgrade ChaseDetector with configurable radius
- Implement smooth speed transitions
- Add line-of-sight verification

### Phase 4: Performance Optimization
- Implement staggered update system
- Add off-screen optimization
- Create obstacle caching system

### Phase 5: Integration and Polish
- Integrate all components into FlyingEnemy
- Add configuration exports for level designers
- Implement comprehensive error handling

## Performance Considerations

### Update Frequency Management
- **On-Screen Enemies**: 60 FPS updates for smooth behavior
- **Off-Screen Enemies**: 20 FPS updates for performance
- **Inactive Enemies**: 5 FPS updates for basic state maintenance

### Memory Optimization
- **Obstacle Cache**: Maximum 50 cached obstacles per enemy
- **Raycast Pooling**: Reuse RaycastNode instances
- **State Data**: Use lightweight RefCounted classes

### CPU Optimization
- **Squared Distance**: Avoid expensive square root calculations
- **Staggered Updates**: Distribute AI calculations across frames
- **Early Exits**: Skip unnecessary calculations when possible

## Configuration Examples

### Aggressive Chaser Configuration
```gdscript
ai_mode = AIMode.PATROL_AND_CHASE
chase_detection_radius_multiplier = 7.0
chase_speed = 150.0
obstacle_avoidance_sensitivity = 24.0
speed_transition_time = 0.2
```

### Cautious Patroller Configuration
```gdscript
ai_mode = AIMode.PATROL_ONLY
patrol_speed = 60.0
obstacle_avoidance_sensitivity = 48.0
direction_change_smoothing = 0.8
pathfinding_attempts = 5
```

### Performance-Optimized Configuration
```gdscript
update_frequency = UpdateFrequency.LOW
off_screen_optimization = true
obstacle_avoidance_sensitivity = 40.0
pathfinding_attempts = 2
```