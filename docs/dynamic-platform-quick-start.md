# Dynamic Platform Quick Start Guide

## 🚀 Quick Setup (30 seconds)

1. **Add to Scene**: Drag `actors/DynamicPlatform.tscn` into your level
2. **Configure**: Set properties in inspector
3. **Done**: Platform automatically generates 9-slice visual and collision

## 🎛️ Inspector Properties

```
Platform Type: YELLOW | GREEN | EMPTY
Platform Size: Vector2(width, height) in pixels
Slice Mode: NINE_SLICE | SIX_SLICE | THREE_SLICE
Auto Detect Margins: true (recommended)
Is Breakable: true/false
Break Delay: 3.0 seconds (time before breaking)
Shake Duration: 2.0 seconds (shake before break)
Target Layer: "A" (for dimension system)
```

## 💻 Runtime Creation

```gdscript
# Basic creation
var platform_scene = preload("res://actors/DynamicPlatform.tscn")
var platform = platform_scene.instantiate()
add_child(platform)

# Configure
platform.global_position = Vector2(400, 300)
platform.platform_type = DynamicPlatform.PlatformType.GREEN
platform.platform_size = Vector2(128, 32)  # Width x Height in pixels
platform.slice_mode = DynamicPlatform.SliceMode.SIX_SLICE
platform.is_breakable = true

# Apply (required for runtime creation)
platform._setup_platform()
if platform.is_breakable:
    platform._setup_breakable_mechanics()
```

## 🎮 Platform Types

- **YELLOW**: Standard solid blocks
- **GREEN**: Alternative solid blocks  
- **EMPTY**: Transparent/ghost blocks

## ⚡ Breakable Behavior

1. Player touches → Timer starts
2. Platform shakes for `shake_duration`
3. Platform breaks with particles
4. Collision disabled, platform destroyed

## 🔧 Runtime Modification

```gdscript
# Change appearance
platform.set_platform_type(DynamicPlatform.PlatformType.YELLOW)

# Resize (in pixels)
platform.set_platform_size(Vector2(192, 64))

# Change slice mode
platform.set_slice_mode(DynamicPlatform.SliceMode.NINE_SLICE)

# Enable breaking
platform.set_breakable(true)

# Sync size from NinePatchRect (if resized in editor)
platform.sync_size_from_nine_patch()
```

## 🎵 Audio Events

Automatically emits to EventBus:
- `"platform_touched"` - First player contact
- `"platform_shaking"` - Starts shaking
- `"platform_break"` - Platform breaks

## 🌀 Dimension Integration

Works with existing layer system:
- Set `target_layer` to "A" or "B"
- Platform hides/shows based on current dimension
- Maintains break state across layer switches

## 📁 Files

- `actors/DynamicPlatform.tscn` - Main scene
- `actors/DynamicPlatform.gd` - Script
- `examples/Level_DynamicPlatforms.tscn` - Demo level
- `docs/dynamic-platform-system.md` - Full documentation

## 🎯 Common Use Cases

```gdscript
# Temporary platform
func create_temp_platform(pos: Vector2, duration: float):
    var platform = create_platform(pos, YELLOW, Vector2i(2,1), false)
    await get_tree().create_timer(duration).timeout
    platform.queue_free()

# Challenge sequence
func create_breakable_sequence():
    for i in range(5):
        var pos = Vector2(200 + i * 100, 300)
        create_platform(pos, GREEN, Vector2i(2,1), true, 2.0, 1.0)

# Safe checkpoint platform
func create_checkpoint_platform(pos: Vector2):
    create_platform(pos, YELLOW, Vector2i(4,1), false)
```

## ⚠️ Important Notes

- Call `_setup_platform()` after runtime configuration
- Breakable platforms self-destruct when broken
- Uses Layer 1 for physics collision
- Requires EventBus for audio integration
