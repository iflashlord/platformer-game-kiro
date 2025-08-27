# 9-Slice Platform System - Quick Reference

## 🎯 Slice Modes

### 9-Slice (Full)
- **Use Case**: Platforms that scale in both directions
- **Features**: Preserves all corners and edges
- **Best For**: Large rectangular platforms, UI elements

### 6-Slice (Horizontal)
- **Use Case**: Horizontal platforms that don't scale vertically
- **Features**: Preserves left/right edges, stretches center horizontally
- **Best For**: Traditional platformer platforms, bridges

### 3-Slice (Minimal)
- **Use Case**: Simple horizontal stretching
- **Features**: Basic left-center-right stretching
- **Best For**: Simple platforms, performance-critical scenarios

## ⚙️ Configuration

```gdscript
# Set slice mode
platform.slice_mode = DynamicPlatform.SliceMode.NINE_SLICE  # or SIX_SLICE, THREE_SLICE

# Auto-detect margins (recommended)
platform.auto_detect_margins = true

# Manual margins (left, top, right, bottom)
platform.set_custom_margins(8, 8, 8, 8)

# Change slice mode at runtime
platform.set_slice_mode(DynamicPlatform.SliceMode.SIX_SLICE)
```

## 🎨 Texture Requirements

### Optimal Texture Layout
```
┌─────┬─────────┬─────┐
│ TL  │   TOP   │ TR  │  ← Top row (corners + edge)
├─────┼─────────┼─────┤
│LEFT │ CENTER  │RIGHT│  ← Middle row (edges + center)
├─────┼─────────┼─────┤
│ BL  │ BOTTOM  │ BR  │  ← Bottom row (corners + edge)
└─────┴─────────┴─────┘
```

### Margin Guidelines
- **32x32 texture**: Use 8px margins (1/4 of size)
- **64x64 texture**: Use 16px margins
- **Custom**: Adjust based on your texture's border design

## 🚀 Quick Setup

1. **Inspector Setup**:
   ```
   Platform Type: YELLOW/GREEN/EMPTY
   Platform Size: Vector2i(width, height)
   Slice Mode: NINE_SLICE/SIX_SLICE/THREE_SLICE
   Auto Detect Margins: ✓ (recommended)
   ```

2. **Runtime Creation**:
   ```gdscript
   var platform = platform_scene.instantiate()
   platform.platform_size = Vector2i(5, 2)
   platform.slice_mode = DynamicPlatform.SliceMode.SIX_SLICE
   platform._setup_platform()
   ```

## 🎮 Demo Controls

In `SliceModeDemo.tscn`:
- **1-3**: Switch between slice modes
- **SPACE**: Create platform at mouse
- **R**: Reset platforms
- **ENTER**: Toggle auto-margins

## 🔧 Advanced Usage

### Custom Margin Configurations
```gdscript
# Asymmetric margins for special effects
platform.set_custom_margins(16, 4, 16, 4)  # Wide horizontal borders

# Different margins per platform type
match platform.platform_type:
    DynamicPlatform.PlatformType.YELLOW:
        platform.set_custom_margins(8, 8, 8, 8)
    DynamicPlatform.PlatformType.GREEN:
        platform.set_custom_margins(12, 6, 12, 6)
```

### Performance Optimization
```gdscript
# Use 3-slice for simple horizontal platforms
platform.slice_mode = DynamicPlatform.SliceMode.THREE_SLICE

# Disable auto-detection for better performance
platform.auto_detect_margins = false
platform.slice_margins = Vector4i(8, 8, 8, 8)
```

## 📊 Comparison

| Mode | Corners | Edges | Performance | Use Case |
|------|---------|-------|-------------|----------|
| 9-Slice | ✓ | ✓ | Good | Complex platforms |
| 6-Slice | Partial | Horizontal | Better | Standard platforms |
| 3-Slice | None | Horizontal | Best | Simple platforms |

## 🎯 Best Practices

1. **Use 6-slice for most platformer platforms** - optimal balance
2. **Enable auto-margin detection** - handles different texture sizes
3. **Use 9-slice for UI elements** - preserves all visual details
4. **Use 3-slice for performance-critical areas** - minimal processing
5. **Test with different sizes** - ensure margins work at all scales

## 🐛 Troubleshooting

**Platform looks stretched/distorted:**
- Check slice margins are appropriate for texture size
- Enable auto-margin detection
- Verify texture has proper border design

**Performance issues:**
- Switch to 6-slice or 3-slice mode
- Disable auto-margin detection
- Use smaller platform sizes where possible

**Corners not preserved:**
- Use 9-slice mode instead of 6-slice
- Increase corner margins
- Check texture has distinct corner regions