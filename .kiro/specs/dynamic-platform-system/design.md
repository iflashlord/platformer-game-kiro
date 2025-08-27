# Design Document

## Overview

The Dynamic Platform System enhancement will transform the current complex DynamicPlatform implementation into a streamlined, editor-friendly system with standard width/height properties, perfect physics matching, and responsive breakable mechanics. The design focuses on simplicity, performance, and intuitive editor workflow while maintaining all existing functionality.

## Architecture

### Core Components

#### 1. DynamicPlatform Node Structure
```
DynamicPlatform (StaticBody2D)
├── PlatformSprite (Sprite2D) - Main visual representation
├── CollisionShape2D - Physics collision matching sprite exactly
├── BreakableComponent (Node) - Optional breakable behavior
│   ├── PlayerDetector (Area2D) - Detects player landing
│   ├── BreakTimer (Timer) - Countdown to shake phase
│   ├── ShakeTimer (Timer) - Shake duration before break
│   └── BreakParticles (GPUParticles2D) - Break effect
└── DimensionComponent (Node) - Layer switching behavior
```

#### 2. Simplified Property System
- **width**: float (in pixels, directly controls sprite and collision)
- **height**: float (in pixels, directly controls sprite and collision)  
- **platform_type**: enum (YELLOW, GREEN, EMPTY) - determines texture
- **is_breakable**: bool - enables/disables breakable behavior
- **break_delay**: float - time before shaking starts
- **shake_duration**: float - how long platform shakes before breaking
- **target_layer**: String - which dimension layer this platform exists in

### Design Patterns

#### 1. Component-Based Architecture
Instead of monolithic script, break functionality into focused components:
- **BreakableComponent**: Handles all breakable logic
- **DimensionComponent**: Manages layer visibility and collision
- **Core Platform**: Handles basic visual and physics setup

#### 2. Direct Property Mapping
- Width/Height properties directly control Sprite2D scale and CollisionShape2D size
- No complex nine-slice system - use simple sprite scaling for better performance
- Collision shape automatically updates when dimensions change

#### 3. State Machine for Breakable Platforms
```
STABLE → TOUCHED → SHAKING → BROKEN → DESTROYED
```

## Components and Interfaces

### 1. Core Platform System

#### DynamicPlatform.gd (Main Script)
```gdscript
@tool
extends StaticBody2D
class_name DynamicPlatform

# Inspector Properties
@export var width: float = 96.0: set = _set_width
@export var height: float = 32.0: set = _set_height
@export var platform_type: PlatformType = PlatformType.YELLOW: set = _set_platform_type
@export var is_breakable: bool = false: set = _set_breakable
@export var break_delay: float = 3.0
@export var shake_duration: float = 2.0
@export var target_layer: String = "A"

# Core methods
func _set_width(value: float)
func _set_height(value: float)
func _update_visual_and_collision()
func _setup_components()
```

#### Platform Textures
- Use simple Sprite2D with texture scaling instead of NinePatchRect
- Maintain texture quality with proper import settings
- Support for different platform types with texture swapping

### 2. Breakable Component System

#### BreakableComponent.gd
```gdscript
extends Node
class_name BreakableComponent

signal break_started
signal break_completed

enum BreakState { STABLE, TOUCHED, SHAKING, BROKEN }

var break_state: BreakState = BreakState.STABLE
var platform: DynamicPlatform
var original_position: Vector2

func setup(platform_node: DynamicPlatform)
func _on_player_detected(body: Node2D)
func start_break_sequence()
func start_shaking()
func break_platform()
```

#### Player Detection System
- Use Area2D positioned slightly above platform surface
- Detect CharacterBody2D nodes (player) landing on platform
- Trigger break sequence immediately on first contact
- Ignore detection while platform is already breaking

### 3. Visual and Audio Feedback

#### Shake System
- Smooth sine-wave based shaking with increasing intensity
- Shake affects only visual position, not collision
- Clear visual warning before platform becomes non-solid

#### Particle Effects
- Color-matched particles based on platform type
- Debris falls with realistic physics
- Particle count scales with platform size

#### Audio Integration
- EventBus integration for sound effects
- Positional audio for 3D sound placement
- Different sounds for touch, shake, and break phases

## Data Models

### Platform Configuration
```gdscript
class_name PlatformConfig
extends Resource

@export var width: float = 96.0
@export var height: float = 32.0
@export var platform_type: PlatformType = PlatformType.YELLOW
@export var is_breakable: bool = false
@export var break_delay: float = 3.0
@export var shake_duration: float = 2.0
@export var target_layer: String = "A"
```

### Platform Textures Resource
```gdscript
class_name PlatformTextures
extends Resource

@export var yellow_texture: Texture2D
@export var green_texture: Texture2D
@export var empty_texture: Texture2D

func get_texture(type: PlatformType) -> Texture2D
```

## Error Handling

### Validation System
- Ensure width and height are positive values
- Validate break_delay and shake_duration are reasonable
- Check for required node references before operations
- Graceful fallbacks for missing textures or components

### Editor Safety
- All property setters work safely in editor mode
- No runtime-only code execution in editor
- Proper cleanup when nodes are removed
- Configuration warnings for invalid setups

### Runtime Error Recovery
- Handle missing EventBus gracefully
- Fallback behavior when audio system unavailable
- Safe cleanup when platform is freed during break sequence
- Prevent multiple break sequences on same platform

## Testing Strategy

### Unit Tests
- Property setter validation
- Collision shape size matching
- Component initialization and cleanup
- State machine transitions

### Integration Tests
- Player interaction with breakable platforms
- Dimension system integration
- Audio system integration through EventBus
- Performance with multiple platforms

### Editor Tests
- Real-time property updates in editor
- Visual feedback during property changes
- Scene saving and loading with custom properties
- Undo/redo functionality with platform modifications

### Performance Tests
- Multiple platforms breaking simultaneously
- Memory usage during particle effects
- Frame rate impact with many platforms
- Garbage collection during platform cleanup

## Implementation Phases

### Phase 1: Core Platform System
1. Simplify DynamicPlatform to use Sprite2D instead of NinePatchRect
2. Implement direct width/height property control
3. Create automatic collision shape updating
4. Add platform type texture switching

### Phase 2: Breakable Component
1. Extract breakable logic into separate component
2. Implement state machine for break sequence
3. Add player detection system
4. Create shake animation system

### Phase 3: Visual and Audio Polish
1. Implement particle effects system
2. Add audio integration through EventBus
3. Create smooth visual transitions
4. Add editor visual feedback

### Phase 4: Integration and Optimization
1. Integrate with dimension system
2. Performance optimization and testing
3. Error handling and validation
4. Documentation and examples

## Performance Considerations

### Memory Management
- Object pooling for particle effects
- Proper cleanup of timers and signals
- Efficient texture sharing between platforms
- Minimal memory allocation during runtime

### Rendering Optimization
- Batch similar platforms for rendering
- Use texture atlasing where possible
- Minimize shader switches
- Efficient particle system configuration

### Physics Optimization
- Simple rectangular collision shapes
- Disable collision immediately when platform breaks
- Efficient Area2D detection zones
- Minimal physics calculations during shake

## Migration Strategy

### Backward Compatibility
- Automatic conversion of existing NinePatchRect-based platforms
- Property mapping from old system to new system
- Fallback behavior for unsupported configurations
- Clear migration warnings and guidance

### Conversion Tools
- Editor plugin for batch conversion of existing platforms
- Validation tools for checking converted platforms
- Backup and restore functionality
- Migration progress tracking