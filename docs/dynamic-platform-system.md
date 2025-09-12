# Dynamic Platform System

A flexible platform component that uses 9-slice/6-slice rendering for scalable platforms with proper corner and edge preservation, supporting breakable mechanics and dimension switching.

## Features

- **9-Slice Rendering**: Proper corner and edge preservation with scalable centers
- **Multiple Slice Modes**: 9-slice, 6-slice (horizontal), and 3-slice options
- **Auto-Margin Detection**: Automatically detects optimal slice margins from texture
- **Multiple Platform Types**: Yellow, Green, and Empty block variants
- **Breakable Mechanics**: Platforms can break and fall after player interaction
- **Dimension System Integration**: Compatible with existing layer switching system
- **Particle Effects**: Breaking platforms create debris particles
- **Audio Integration**: Connects to EventBus for sound effects
- **Runtime Configuration**: Can be modified during gameplay

## Usage

### Basic Setup

1. Add the `DynamicPlatform.tscn` scene to your level
2. Configure the exported properties in the inspector:
   - `platform_type`: Choose between YELLOW, GREEN, or EMPTY
   - `platform_size`: Set width and height in tiles (Vector2i)
   - `is_breakable`: Enable/disable breaking mechanics
   - `break_delay`: Time before platform breaks after first touch
   - `shake_duration`: Time platform shakes before breaking
   - `target_layer`: For dimension system compatibility

### Platform Types

```gdscript
enum PlatformType {
    YELLOW,  # Standard yellow blocks
    GREEN,   # Green variant blocks  
    EMPTY    # Empty/transparent blocks
}
```

### Breakable Platform Behavior

When `is_breakable` is enabled:

1. **STABLE**: Platform is solid and functional
2. **TOUCHED**: Player touches platform, break timer starts
3. **SHAKING**: Platform shakes for `shake_duration` seconds
4. **BROKEN**: Platform becomes non-solid, particles play, then destroys itself

### Runtime Creation

```gdscript
# Create a platform programmatically
var platform_scene = preload("res://actors/DynamicPlatform.tscn")
var platform = platform_scene.instantiate() as DynamicPlatform

# Configure properties
platform.platform_type = DynamicPlatform.PlatformType.GREEN
platform.platform_size = Vector2i(4, 2)
platform.is_breakable = true
platform.break_delay = 3.0

# Add to scene
add_child(platform)
platform.global_position = Vector2(400, 300)

# Apply configuration
platform._setup_platform()
if platform.is_breakable:
    platform._setup_breakable_mechanics()
```

### Runtime Modification

```gdscript
# Change platform type
platform.set_platform_type(DynamicPlatform.PlatformType.YELLOW)

# Resize platform
platform.set_platform_size(Vector2i(6, 1))

# Enable/disable breakable behavior
platform.set_breakable(true)
```

## Integration with Existing Systems

### EventBus Integration

The platform system emits the following events:
- `sfx_requested`: For sound effects (touch, shake, break)
- `screen_shake_requested`: When platform breaks

### Dimension System

Platforms respect the `target_layer` property and will:
- Hide/show based on current dimension layer
- Disable collision when not in active layer
- Maintain break state across layer switches

### Audio Events

- `"platform_touched"`: When player first touches breakable platform
- `"platform_shaking"`: When platform starts shaking
- `"platform_break"`: When platform breaks apart

## Performance Considerations

- Tilemap collision is automatically generated
- Particles are pooled and cleaned up after lifetime
- Broken platforms self-destruct to prevent memory leaks
- Uses signals instead of polling for better performance

## Customization

### Adding New Platform Types

1. Add new enum value to `PlatformType`
2. Add texture to `platform_textures` dictionary
3. Update particle colors in `_setup_break_particles()` if needed

### Custom Break Behavior

Override `_break_platform()` method to implement custom breaking effects:

```gdscript
func _break_platform():
    super._break_platform()  # Call original behavior
    # Add custom effects here
```

## Example Scenes

- `examples/DynamicPlatformTest.tscn`: Basic platform showcase
- `examples/DynamicPlatformDemo.gd`: Runtime creation examples

## Technical Details

### File Structure
- `actors/DynamicPlatform.gd`: Main platform script
- `actors/DynamicPlatform.tscn`: Platform scene template
- `examples/`: Demo scenes and scripts
- `docs/dynamic-platform-system.md`: This documentation

### Dependencies
- EventBus (for audio/effects)
- DimensionManager (for layer switching)
- Platform textures in `content/Graphics/Sprites/Tiles/Default/`

### Collision Layers
- Uses standard physics layers (Layer 1: World)
- Automatically disables collision when broken or in wrong dimension layer
