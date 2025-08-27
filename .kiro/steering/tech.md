# Technology Stack

## Engine & Framework
- **Godot Engine**: 4.4+ (GL Compatibility renderer for web support)
- **Language**: GDScript (primary), with class_name declarations for type safety
- **Target Resolution**: 1280x720 (16:9 aspect ratio)
- **Rendering**: GL Compatibility mode for optimal web performance

## Build System & Deployment

### Export Presets
- **Web**: Primary target with HTML5 export, PWA support
- **Windows Desktop**: Secondary target (.exe)
- **Linux/X11**: Secondary target (.x86_64)
- **macOS**: Secondary target (.zip with universal binary)

### CI/CD Pipeline
```bash
# Automated via GitHub Actions (.github/workflows/deploy.yml)
# Uses barichello/godot-ci:4.3 Docker container

# Manual export commands:
godot --headless --export-release "Web" build/web/index.html
godot --headless --export-release "Windows Desktop" build/windows/html5-platformer.exe
godot --headless --export-release "Linux/X11" build/linux/html5-platformer.x86_64
```

### Deployment
- **Primary**: Vercel (automated via GitHub Actions)
- **Local Testing**: `godot --main-scene res://ui/MainMenu.tscn`
- **Web Testing**: Serve build/web/ directory locally

## Architecture Patterns

### Autoload Singletons (Global Systems)
All core systems are autoloaded in project.godot:
- `Game` - Main game state management
- `LevelLoader` - Async level loading
- `Audio` - 3-bus audio system with pooling
- `Persistence` - Cross-platform save system
- `FX` - Visual effects (shake, hit-stop, particles)
- `EventBus` - Signal-based communication hub
- `DimensionManager` - Layer switching mechanics
- `ObjectPool` - Performance optimization

### Signal-Based Architecture
- Use EventBus for cross-system communication
- Avoid polling in _process() - use signals instead
- Connect signals in _ready(), disconnect in _exit_tree()

### Component System
- Use composition over inheritance
- LayerObject.gd for dimension-aware objects
- HealthSystem.gd for damage/health management
- Modular actor components

## Performance Requirements
- **Target FPS**: 60 FPS on web browsers
- **Memory**: Under 1GB RAM usage
- **Load Time**: Under 10 seconds initial web load
- **File Size**: Under 50MB total download

## Development Commands

### Platform-Specific Godot Paths
- **macOS**: `/Applications/Godot.app/Contents/MacOS/Godot`
- **Windows**: `godot.exe` (if in PATH)
- **Linux**: `godot` (if in PATH)

### Local Development
```bash
# Open project in Godot editor
godot project.godot
# macOS: /Applications/Godot.app/Contents/MacOS/Godot project.godot

# Run specific scene
godot --main-scene res://levels/Level01.tscn
# macOS: /Applications/Godot.app/Contents/MacOS/Godot --main-scene res://levels/Level01.tscn

# Run with debug
godot --debug --main-scene res://ui/MainMenu.tscn
# macOS: /Applications/Godot.app/Contents/MacOS/Godot --debug --main-scene res://ui/MainMenu.tscn
```

### Testing
```bash
# Performance testing
godot --main-scene res://systems/PerformanceTest.tscn
# macOS: /Applications/Godot.app/Contents/MacOS/Godot --main-scene res://systems/PerformanceTest.tscn

# Audio testing  
godot --main-scene res://systems/AudioTest.tscn
# macOS: /Applications/Godot.app/Contents/MacOS/Godot --main-scene res://systems/AudioTest.tscn

# VFX testing
godot --main-scene res://systems/VFXTest.tscn
# macOS: /Applications/Godot.app/Contents/MacOS/Godot --main-scene res://systems/VFXTest.tscn

# Test DynamicPlatform system
godot --main-scene res://examples/Level_DynamicPlatforms.tscn
# macOS: /Applications/Godot.app/Contents/MacOS/Godot --main-scene res://examples/Level_DynamicPlatforms.tscn

# Test simple DynamicPlatform (for debugging)
godot --main-scene res://examples/Level_DynamicPlatforms_Simple.tscn
# macOS: /Applications/Godot.app/Contents/MacOS/Godot --main-scene res://examples/Level_DynamicPlatforms_Simple.tscn
```

### Web Deployment
```bash
# Export for web
godot --headless --export-release "Web" build/web/index.html
# macOS: /Applications/Godot.app/Contents/MacOS/Godot --headless --export-release "Web" build/web/index.html

# Deploy to Vercel (requires setup)
cd build/web
vercel --prod
```

## Libraries & Dependencies
- **Built-in Godot Systems**: No external dependencies
- **CI/CD**: GitHub Actions with barichello/godot-ci Docker image
- **Deployment**: Vercel CLI for automated deployment
- **Audio**: Godot's built-in audio system with 3-bus architecture