# Project Structure & Organization

## Folder Hierarchy

```
├── actors/          # Game entities (Player, enemies, collectibles, interactive objects)
├── systems/         # Core game systems (autoloaded singletons)
├── ui/             # User interface scenes and scripts
├── levels/         # Game levels and test scenes
├── content/        # Assets (sprites, textures, resources)
├── audio/          # Music and sound effects
├── data/           # Configuration files (JSON, game data)
├── docs/           # Documentation and guides
├── tools/          # Development utilities and generators
├── web/            # Web deployment assets (PWA icons, HTML)
├── examples/       # Code examples and tutorials
└── .github/        # CI/CD workflows
```

## Naming Conventions

### Files & Scenes
- **Scene files**: PascalCase (e.g., `Player.tscn`, `MainMenu.tscn`)
- **Script files**: Match scene name (e.g., `Player.gd`, `MainMenu.gd`)
- **Resource files**: PascalCase (e.g., `GameAtlas.tres`, `Enemy.tres`)
- **Asset files**: snake_case (e.g., `player_sprite.png`, `sfx_jump.ogg`)

### Code Conventions
- **Classes**: PascalCase with `class_name` declaration
- **Variables**: snake_case (e.g., `current_health`, `is_jumping`)
- **Functions**: snake_case (e.g., `_on_player_died()`, `setup_enemy_appearance()`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `MAX_SPEED`, `JUMP_VELOCITY`)
- **Signals**: snake_case with descriptive names (e.g., `player_died`, `level_completed`)

## Core Directories

### `/actors/` - Game Entities
**Purpose**: All interactive game objects with behavior
- **Player.tscn/gd** - Main character with movement, health, abilities
- **PatrolEnemy.tscn/gd** - AI enemies with patrol behavior
- **EnemyCharger.tscn/gd** - Charging enemy AI
- **CollectibleFruit.tscn/gd** - Point-based collectibles
- **HiddenGem.tscn/gd** - Secret collectibles with unlock requirements
- **Crate.tscn/gd** - Interactive destructible objects
- **FlipGate.tscn/gd** - Dimension switching triggers
- **Portal.tscn/gd** - Level transition objects

### `/systems/` - Core Architecture
**Purpose**: Autoloaded singletons managing global game state
- **Game.gd** - Main game state, scoring, pause management
- **EventBus.gd** - Signal hub for cross-system communication
- **LevelLoader.gd** - Async level loading with progress tracking
- **Audio.gd** - 3-bus audio system with pooling
- **Persistence.gd** - Save/load system with cross-platform support
- **DimensionManager.gd** - Layer switching mechanics
- **ObjectPool.gd** - Performance optimization for temporary objects

### `/ui/` - User Interface
**Purpose**: All menu and HUD systems
- **MainMenu.tscn/gd** - Entry point with navigation
- **LevelSelect.tscn/gd** - Level selection with unlock status
- **GameUI.tscn/gd** - In-game HUD management
- **PauseMenu.tscn/gd** - Pause overlay with options
- **Results.tscn/gd** - Level completion screen with scoring
- **TouchControls.tscn/gd** - Mobile touch input system

### `/levels/` - Game Content
**Purpose**: Playable levels and test scenes
- **Level##.tscn/gd** - Main campaign levels
- **Tutorial.tscn/gd** - Teaching basic mechanics
- **Test scenes** - Development and debugging levels
- **Chase##.tscn/gd** - Special high-speed levels

### `/content/` - Assets & Resources
**Purpose**: Visual and audio assets
- **Sprites**: PNG textures organized by type
- **Resources**: .tres files for shared configurations
- **SpriteAtlas.gd** - Texture atlas management
- **Tileset.tres** - Level geometry tileset

## Architecture Patterns

### Scene Organization
```
ActorScene.tscn
├── RootNode (CharacterBody2D/StaticBody2D/Area2D)
│   ├── VisualComponents (Sprite2D/ColorRect/AnimatedSprite2D)
│   ├── CollisionShape2D
│   ├── Areas (for detection/damage)
│   └── Effects (particles, audio)
```

### Script Structure
```gdscript
extends NodeType
class_name ClassName

# Signals first
signal signal_name(param: Type)

# Exports for inspector
@export var property_name: Type = default_value

# Public variables
var public_var: Type

# Private variables (underscore prefix)
var _private_var: Type

# Node references
@onready var node_ref: NodeType = $NodePath

# Godot lifecycle methods
func _ready():
func _process(delta):
func _physics_process(delta):

# Public methods
func public_method():

# Private methods (underscore prefix)
func _private_method():

# Signal callbacks (underscore + on prefix)
func _on_signal_callback():
```

### Layer System (Physics Layers)
```
Layer 1: World (static geometry)
Layer 2: Player
Layer 3: Enemies  
Layer 4: Debris (temporary objects)
Layer 5: Collectibles
Layer 6: FlipGates (dimension triggers)
Layer 7: SectionMarkers (progression tracking)
Layer 8: Hazards (damage zones)
```

## File Dependencies

### Scene Dependencies
- Actors depend on systems (via autoloads)
- UI scenes depend on Game and EventBus
- Levels compose actors and UI elements
- No circular dependencies between actors

### Resource Management
- Shared resources in `/content/`
- Level-specific assets in level folders
- Preload critical resources
- Use ResourceLoader for dynamic loading

## Development Guidelines

### Adding New Actors
1. Create scene in `/actors/` folder
2. Use appropriate physics body type
3. Add `class_name` declaration in script
4. Connect to EventBus for communication
5. Follow established naming conventions

### Adding New Systems
1. Create script in `/systems/` folder
2. Add to autoload in project settings
3. Use signals for external communication
4. Document public API in comments
5. Consider performance implications

### Adding New Levels
1. Create scene in `/levels/` folder
2. Inherit from base level script if available
3. Add entry to `/data/levels.json`
4. Test unlock progression
5. Document special mechanics