# Dynamic Platform - Editor Integration

## 🎨 Editor Preview

The Dynamic Platform system now provides full editor integration with real-time preview and property updates.

### Visual Preview in Editor
- **Immediate Visibility**: Platforms are visible in the 2D editor with proper textures
- **Real-time Updates**: Changes to properties instantly update the visual preview
- **Size Handles**: Resize platforms directly in the editor using NinePatchRect handles
- **Type Preview**: Different platform types show different textures immediately

### Inspector Property Updates
All exported properties now update the platform in real-time:

```gdscript
@export var platform_type: PlatformType = PlatformType.YELLOW: set = _set_platform_type
@export var platform_size: Vector2 = Vector2(96, 32): set = _set_platform_size
@export var slice_mode: SliceMode = SliceMode.NINE_SLICE: set = _set_slice_mode
@export var slice_margins: Vector4i = Vector4i(8, 8, 8, 8): set = _set_slice_margins
@export var auto_detect_margins: bool = true: set = _set_auto_detect_margins
@export var is_breakable: bool = false: set = _set_breakable
```

## 🔧 Editor Workflow

### 1. Adding Platforms
1. Drag `actors/DynamicPlatform.tscn` into your scene
2. Platform appears immediately with default yellow texture
3. Adjust properties in inspector - changes apply instantly

### 2. Resizing Platforms
**Method 1: Inspector**
- Change `Platform Size` values in inspector
- Platform updates immediately

**Method 2: Visual Handles**
- Select the platform in the scene
- Expand the NinePatchRect node
- Drag the corner/edge handles to resize
- Size automatically syncs with collision

### 3. Changing Appearance
- **Platform Type**: Switch between YELLOW, GREEN, EMPTY
- **Slice Mode**: Choose 9-slice, 6-slice, or 3-slice
- **Margins**: Adjust slice margins or enable auto-detection

### 4. Configuring Breakable Behavior
- Enable `Is Breakable` in inspector
- Set `Break Delay` and `Shake Duration`
- Breakable setup only occurs at runtime (not in editor)

## 🎯 Editor Features

### Real-time Property Updates
```gdscript
# When you change platform_type in inspector:
func _set_platform_type(value: PlatformType):
    platform_type = value
    _update_platform_appearance()  # Immediate visual update

# When you change platform_size in inspector:
func _set_platform_size(value: Vector2):
    platform_size = value
    _update_platform_size()  # Updates size and collision
```

### Editor Safety
- **Tool Script**: Uses `@tool` annotation for editor functionality
- **Runtime Separation**: Breakable mechanics only setup at runtime
- **Safe Operations**: All editor operations are safe and non-destructive
- **Error Handling**: Validates configuration and provides warnings

### Visual Feedback
- **Texture Preview**: Shows actual block textures in editor
- **Size Accuracy**: Visual size matches collision size exactly
- **Slice Preview**: 9-slice margins visible in editor
- **Type Switching**: Instant texture updates when changing types

## 📋 Best Practices

### Level Design Workflow
1. **Place Platforms**: Drag platforms into scene
2. **Set Types**: Choose appropriate platform types for visual variety
3. **Size Platforms**: Use inspector or visual handles to size platforms
4. **Configure Slicing**: Adjust slice modes for optimal appearance
5. **Add Breakables**: Enable breakable behavior where needed
6. **Test Runtime**: Play scene to test breakable functionality

### Performance Considerations
- **Editor Mode**: Minimal processing in editor mode
- **Runtime Setup**: Full functionality only initialized at runtime
- **Property Caching**: Efficient property updates without redundant operations

### Troubleshooting

**Platform not visible in editor:**
- Check that NinePatchRect has a texture assigned
- Verify platform_size is not zero
- Ensure the platform node is selected in scene tree

**Properties not updating:**
- Make sure you're changing values in the inspector
- Check that the platform is properly added to the scene
- Verify the script is attached and working

**Size not matching collision:**
- Use `refresh_platform()` method to force update
- Check that platform_size values are positive
- Ensure collision shape is properly configured

## 🔍 Debug Methods

```gdscript
# Force refresh all platform components
platform.refresh_platform()

# Validate platform configuration
platform._validate_configuration()

# Sync size from visual component
platform.sync_size_from_nine_patch()
```

## 📁 Example Scenes

- `examples/EditorPreviewTest.tscn` - Demonstrates editor preview functionality
- `examples/PlatformSizeTest.tscn` - Shows different sizes and configurations
- `examples/SliceModeDemo.tscn` - Interactive slice mode demonstration

## 🎮 Runtime vs Editor

| Feature | Editor | Runtime |
|---------|--------|---------|
| Visual Preview | ✓ | ✓ |
| Property Updates | ✓ | ✓ |
| Collision Setup | ✓ | ✓ |
| Breakable Mechanics | ✗ | ✓ |
| Player Detection | ✗ | ✓ |
| Particle Effects | ✗ | ✓ |
| Dimension System | ✗ | ✓ |

The editor integration provides a seamless design experience while maintaining full runtime functionality.