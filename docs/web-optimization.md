# Web Optimization Guide

## Project Settings

### Display Settings
- **Window Size**: 1280x720 (16:9 aspect ratio)
- **Stretch Mode**: `canvas_items` (maintains pixel-perfect scaling)
- **Stretch Aspect**: `keep` (prevents distortion)

### Rendering Settings
- **Renderer**: GL Compatibility (best web support)
- **Anti-aliasing**: MSAA 2x (balance of quality/performance)
- **V-Sync**: Enabled (prevents screen tearing)

## Asset Import Settings

### Textures
```
Filter: Off (for pixel art) / On (for smooth art)
Mipmaps: Off (saves memory for 2D games)
Format: VRAM Compressed (automatic compression)
```

### Audio
```
Format: Ogg Vorbis (best compression for web)
Quality: 5-7 (balance of size/quality)
Loop: Enable for music, disable for SFX
```

### Scenes
```
Compression: Lossless (maintains quality)
Bundle Resources: On (reduces file count)
```

## Performance Optimizations
 

### Object Pooling
- Pool frequently created/destroyed objects
- Shards, fruits, explosions, particles
- Prevents garbage collection spikes

### Signal-Based Architecture
- Replace `_process()` polling with signals
- Use `EventBus` for decoupled communication
- Reduces per-frame calculations

## HTML5 Export Settings

### Features
```
Threads: Disabled (not supported in browsers)
GDScript: Enabled
```

### Resources
```
Export Mode: Export selected resources
Filters: Include only necessary files
```

### Advanced
```
Head Include: Custom HTML for web integration
Custom HTML Shell: For branded deployment
```

## File Size Optimization

### Audio Compression
- Use Ogg Vorbis at quality 5-6
- Mono for SFX, stereo for music
- Keep music tracks under 2MB each

### Texture Compression
- Use VRAM compression for most textures
- PNG for UI elements with transparency
- JPEG for backgrounds without transparency

### Code Optimization
- Remove debug prints in release builds
- Use object pooling for temporary objects
- Minimize string operations in hot paths

## Loading Performance

### Preloading
```gdscript
# Preload critical resources
const PLAYER_SCENE = preload("res://actors/Player.tscn")
const AUDIO_CLIPS = preload("res://audio/AudioClips.tres")
```

### Async Loading
```gdscript
# Load non-critical resources asynchronously
ResourceLoader.load_threaded_request("res://levels/Level01.tscn")
```

### Progressive Loading
- Load menu assets first
- Stream level assets as needed
- Show loading progress to user

## Browser Compatibility

### Supported Features
- WebGL 2.0 (fallback to WebGL 1.0)
- Web Audio API
- Gamepad API
- Touch events

### Limitations
- No threading support
- Limited file system access
- Memory constraints (2-4GB typical)
- No native file dialogs

## Deployment Checklist

1. **Test in multiple browsers**
   - Chrome, Firefox, Safari, Edge
   - Mobile browsers (iOS Safari, Chrome Mobile)

2. **Verify asset loading**
   - All textures display correctly
   - Audio plays without issues
   - No missing resource errors

3. **Performance testing**
   - Maintain 60 FPS on target devices
   - Memory usage under 1GB
   - Loading times under 10 seconds

4. **HTTPS requirement**
   - Many browser features require HTTPS
   - Use secure hosting for production

## Common Issues & Solutions

### Audio Not Playing
- Browsers require user interaction before audio
- Implement "Click to Start" screen
- Use Web Audio API compatible formats

### Slow Loading
- Enable gzip compression on server
- Use CDN for asset delivery
- Implement asset preloading

### Memory Issues
- Use object pooling extensively
- Unload unused resources
- Monitor memory usage in browser dev tools

### Input Lag
- Disable V-Sync if causing issues
- Use `Input.is_action_just_pressed()` for responsive controls
- Minimize input processing overhead