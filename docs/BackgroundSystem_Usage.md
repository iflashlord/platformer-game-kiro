# Background System Usage Guide

The background system provides two main components for creating looping backgrounds with parallax effects and dimension layer support.

## Components

### 1. LoopingBackground
A simple component for single-layer backgrounds that loop seamlessly.

### 2. ParallaxBackgroundSystem
An advanced system that manages multiple background layers with different parallax speeds.

## Quick Start

### Simple Background
```gdscript
# Add to your scene
var bg = preload("res://actors/LoopingBackground.tscn").instantiate()
bg.texture = load("res://content/Graphics/Vector/Backgrounds/background_solid_sky.svg")
bg.scroll_speed = Vector2(-50, 0)
bg.parallax_factor = Vector2(0.3, 0.3)
add_child(bg)
```

### Multi-Layer Parallax
```gdscript
# Add to your scene
var parallax_system = preload("res://actors/ParallaxBackgroundSystem.tscn").instantiate()

# Create layer configurations
var far_layer = BackgroundLayerConfig.new()
far_layer.texture = load("res://path/to/sky_texture.png")
far_layer.scroll_speed = Vector2(-20, 0)
far_layer.parallax_factor = Vector2(0.1, 0.1)
far_layer.z_index = -30

var near_layer = BackgroundLayerConfig.new()
near_layer.texture = load("res://path/to/trees_texture.png")
near_layer.scroll_speed = Vector2(-60, 0)
near_layer.parallax_factor = Vector2(0.7, 0.7)
near_layer.z_index = -10

parallax_system.background_layers = [far_layer, near_layer]
add_child(parallax_system)
```

## Configuration Options

### LoopingBackground Properties

| Property | Type | Description |
|----------|------|-------------|
| `texture` | Texture2D | Main background texture |
| `scroll_speed` | Vector2 | Pixels per second scroll speed |
| `parallax_factor` | Vector2 | Camera movement multiplier (0.0-1.0) |
| `auto_scroll` | bool | Enable automatic scrolling |
| `loop_seamlessly` | bool | Enable seamless looping |
| `modulate_color` | Color | Tint color for the background |
| `z_index` | int | Rendering layer (-10 default) |
| `scale_factor` | Vector2 | Scale multiplier for texture |

### Dimension Layer Support

Both components support different textures per dimension layer:

```gdscript
bg.use_different_textures_per_layer = true
bg.layer_a_texture = load("res://backgrounds/layer_a_bg.png")
bg.layer_b_texture = load("res://backgrounds/layer_b_bg.png")
```

## Parallax Factor Guide

The parallax factor determines how much the background moves relative to the camera:

- `0.0` - Background doesn't move (fixed)
- `0.1` - Very slow movement (far background)
- `0.5` - Half camera speed (mid background)
- `0.8` - Fast movement (near background)
- `1.0` - Same as camera speed (no parallax effect)

## Common Patterns

### Three-Layer Parallax Setup
```gdscript
# Far background (sky/mountains)
var far_config = BackgroundLayerConfig.new()
far_config.scroll_speed = Vector2(-15, 0)
far_config.parallax_factor = Vector2(0.1, 0.1)
far_config.z_index = -30

# Mid background (trees/buildings)
var mid_config = BackgroundLayerConfig.new()
mid_config.scroll_speed = Vector2(-30, 0)
far_config.parallax_factor = Vector2(0.3, 0.3)
mid_config.z_index = -20

# Near background (foreground elements)
var near_config = BackgroundLayerConfig.new()
near_config.scroll_speed = Vector2(-45, 0)
near_config.parallax_factor = Vector2(0.6, 0.6)
near_config.z_index = -10
```

### Vertical Scrolling
```gdscript
bg.scroll_speed = Vector2(0, -30)  # Scroll upward
bg.parallax_factor = Vector2(0.0, 0.2)  # Only vertical parallax
```

### Static Background with Parallax
```gdscript
bg.scroll_speed = Vector2.ZERO  # No auto-scroll
bg.parallax_factor = Vector2(0.3, 0.3)  # Only moves with camera
```

## Runtime Control

### LoopingBackground Methods
```gdscript
bg.set_scroll_speed(Vector2(-100, 0))  # Change speed
bg.set_parallax_factor(Vector2(0.5, 0.5))  # Change parallax
bg.pause_scrolling()  # Stop scrolling
bg.resume_scrolling()  # Resume scrolling
bg.reset_position()  # Reset to start position
```

### ParallaxBackgroundSystem Methods
```gdscript
system.pause_all_scrolling()  # Pause all layers
system.resume_all_scrolling()  # Resume all layers
system.set_global_scroll_speed_multiplier(0.5)  # Slow down all layers
system.get_background_layer(0)  # Get specific layer
```

## Performance Tips

1. **Texture Size**: Use power-of-2 textures when possible
2. **Layer Count**: Limit to 3-5 layers for optimal performance
3. **Z-Index**: Use appropriate z-index values to avoid sorting issues
4. **Sprite Count**: The system automatically calculates needed sprites

## Integration with Dimension System

The background system automatically integrates with the DimensionManager:

1. Backgrounds respond to layer changes automatically
2. Different textures can be shown per dimension layer
3. No additional setup required - just assign textures

## Troubleshooting

### Background Not Moving
- Check that `auto_scroll` is enabled
- Verify `scroll_speed` is not zero
- Ensure camera is properly set up

### Parallax Not Working
- Confirm camera exists and is active
- Check `parallax_factor` values
- Verify camera is in the "cameras" group or is the main camera

### Texture Not Loading
- Check file paths are correct
- Ensure textures are imported properly
- Verify texture format is supported

### Performance Issues
- Reduce number of background layers
- Use smaller texture sizes
- Check z-index values for proper layering

## Example Scene

See `examples/BackgroundExample.tscn` for a complete working example with:
- Simple looping background
- Multi-layer parallax system
- Camera controls for testing
- Dimension layer switching

Run the example scene to test the background system functionality.