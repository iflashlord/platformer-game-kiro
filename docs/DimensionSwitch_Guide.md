# Dimension Switch Component Guide

## Overview

The `DimensionSwitch` is an interactive component that allows players to switch between dimension layers A and B by walking into the switch area. It provides visual feedback and respects the dimension manager's cooldown system.

## Features

- **Visual Feedback**: Shows current layer (A or B) with color coding
- **Cooldown System**: Respects both global dimension manager cooldown and local switch cooldown
- **Blinking Effect**: Blinks when dimension switching is temporarily unavailable
- **Two Modes**: Toggle mode (A↔B) or specific target layer mode
- **Audio/Visual Effects**: Plays sounds and creates visual effects on activation

## Usage

### Basic Setup

1. Add the `DimensionSwitch.tscn` scene to your level
2. Position it where you want players to interact with it
3. The switch will automatically work in toggle mode (A↔B)

### Configuration

#### Toggle Mode (Default)
```gdscript
# Switch toggles between A and B
switch.set_toggle_mode()
```

#### Specific Target Mode
```gdscript
# Switch always goes to layer B
switch.set_target_layer("B")
```

### Properties

- `switch_type`: "toggle" or "specific"
- `target_layer`: Target layer for specific mode (empty for toggle)
- `cooldown_time`: Local cooldown after activation (default: 0.5s)
- `blink_duration`: How long to blink when blocked (default: 2.0s)

## Visual States

### Layer A (Cyan)
- Switch background: Cyan
- Label: "A" in dark blue
- Indicates current dimension is A

### Layer B (Magenta)
- Switch background: Magenta  
- Label: "B" in dark red
- Indicates current dimension is B

### Inactive State
- Slightly transparent when no player nearby
- Full opacity when player is in range

### Cooldown State
- Grayed out appearance
- Red cooldown indicator bar
- Cannot be activated

### Blinking State
- Rapid alpha blinking
- Occurs when dimension manager cooldown is active
- Indicates switching is temporarily blocked

## Integration

### With Existing Systems

The DimensionSwitch works seamlessly with:
- Existing F key dimension switching
- DimensionManager cooldown system
- LayerPlatform and other layer-aware objects
- Audio and FX systems

### Signals

```gdscript
signal dimension_switched(switch: DimensionSwitch, new_layer: String)
```

Connect to this signal to respond to switch activations:

```gdscript
func _on_dimension_switch_activated(switch: DimensionSwitch, new_layer: String):
    print("Switch activated, now in layer: ", new_layer)
```

## API Reference

### Public Methods

```gdscript
# Configuration
set_target_layer(layer: String)  # Set specific target layer
set_toggle_mode()                # Set to toggle between A/B

# State queries
can_activate() -> bool           # Check if switch can be activated
```

### Collision Layers

- **Collision Layer**: 16 (Interactive layer)
- **Collision Mask**: 2 (Player layer)

## Example Levels

- `examples/Level_DimensionSwitch_Test.tscn` - Basic functionality test
- `examples/Level_DimensionSwitch_Demo.tscn` - Full demo with layer platforms

## Tips

1. **Placement**: Position switches at strategic points where dimension changes make sense
2. **Visual Clarity**: The color coding helps players understand the current state
3. **Cooldown Management**: The blinking effect clearly communicates when switching is blocked
4. **Accessibility**: Works with both touch interaction and keyboard (F key) switching
5. **Performance**: Uses efficient Area2D detection with proper cleanup

## Troubleshooting

### Switch Not Working
- Ensure DimensionManager autoload is properly configured
- Check collision layers (switch: layer 16, player: mask 2)
- Verify player is in "player" group

### No Visual Feedback
- Check that ColorRect and Label nodes exist in scene
- Ensure proper node references in script

### Audio Not Playing
- Verify Audio autoload exists and has "dimension" sound effect
- Check audio bus configuration

## Future Enhancements

Potential improvements for future versions:
- Animated sprites instead of ColorRect
- Particle effects on activation
- Different switch types (pressure plates, levers, etc.)
- Multi-layer support (A, B, C, etc.)
- Conditional activation requirements