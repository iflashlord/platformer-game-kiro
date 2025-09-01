# Giant Boss Setup Guide

## Quick Setup

The Giant Boss system has been created with all necessary components. Here's how to get it working:

### 1. Files Created
- ✅ `actors/GiantBoss.gd` & `.tscn` - Main boss
- ✅ `actors/TNTCrate.gd` & `.tscn` - Explosive crates  
- ✅ `actors/Explosion.tscn` - Explosion effects
- ✅ `ui/BossHealthUI.gd` & `.tscn` - Health display
- ✅ `examples/Level_GiantBoss.gd` & `.tscn` - Test level
- ✅ `examples/Level_GiantBoss_Simple.tscn` - Fallback test level

### 2. Testing the Boss

#### Option A: Run Test Script
```bash
./test_boss.sh
```

#### Option B: Manual Testing
```bash
# macOS
/Applications/Godot.app/Contents/MacOS/Godot --main-scene res://examples/Level_GiantBoss.tscn

# Linux/Windows
godot --main-scene res://examples/Level_GiantBoss.tscn
```

#### Option C: Open in Godot Editor
1. Open Godot
2. Navigate to `examples/Level_GiantBoss.tscn`
3. Click "Play Scene" (F6)

### 3. If You Get Scene Reference Errors

The autofix may have changed some UIDs. Here's how to fix:

#### Method 1: Re-instance Scenes
1. Open `examples/Level_GiantBoss.tscn` in Godot
2. Delete the GiantBoss and Player nodes
3. Re-add them by dragging from FileSystem:
   - `actors/GiantBoss.tscn` → position at (640, 550)
   - `actors/Player.tscn` → position at (200, 600)
4. Save the scene

#### Method 2: Use Simple Level
1. Open `examples/Level_GiantBoss_Simple.tscn`
2. Manually add the boss and player scenes
3. Test from there

### 4. Manual Integration Steps

To add the boss to your own level:

#### Step 1: Add Boss to Scene
```gdscript
# In your level scene, add as child:
var boss = preload("res://actors/GiantBoss.tscn").instantiate()
add_child(boss)
boss.position = Vector2(640, 550)  # Adjust as needed
```

#### Step 2: Add Health UI
```gdscript
# Add to a CanvasLayer:
var health_ui = preload("res://ui/BossHealthUI.tscn").instantiate()
ui_layer.add_child(health_ui)
health_ui.show_boss_ui("GIANT BOSS")
```

#### Step 3: Connect Signals
```gdscript
# In your level script:
func _ready():
    boss.boss_defeated.connect(_on_boss_defeated)
    boss.boss_damaged.connect(_on_boss_damaged)
    boss.tnt_placed.connect(_on_tnt_placed)

func _on_boss_defeated():
    print("Boss defeated!")
    # Add victory logic

func _on_boss_damaged(health: int, max_health: int):
    print("Boss health: ", health, "/", max_health)

func _on_tnt_placed(position: Vector2):
    print("TNT placed at: ", position)
```

### 5. Troubleshooting

#### Boss Not Moving
- Check collision layers (boss should be on layer 4)
- Ensure ground collision is on layer 1
- Verify RayCast2D nodes are enabled

#### Player Can't Damage Boss
- Check stomp detector Area2D collision mask (should detect layer 2)
- Ensure player is in "player" group
- Verify player has `bounce()` method

#### Health UI Not Showing
- Check EventBus connections
- Ensure BossHealthUI is child of CanvasLayer
- Verify `show_boss_ui()` is called

#### TNT Not Exploding
- Check TNT collision layers and masks
- Ensure explosion area is properly configured
- Verify timer connections

### 6. Customization

#### Adjust Boss Difficulty
```gdscript
# In GiantBoss.gd, modify export variables:
@export var max_health: int = 3  # Easier (default: 5)
@export var walk_speed: float = 30.0  # Slower (default: 50.0)
@export var tnt_drop_interval: float = 5.0  # Less frequent (default: 3.0)
```

#### Change Boss Appearance
1. Open `actors/GiantBoss.tscn`
2. Select the Sprite node
3. Modify the SpriteFrames resource
4. Replace textures with your own sprites

#### Modify Health UI
1. Open `ui/BossHealthUI.tscn`
2. Adjust colors, fonts, and layout
3. Modify positioning and styling

### 7. Integration with Existing Systems

The boss system integrates with:
- ✅ **EventBus** - For global communication
- ✅ **Audio System** - For sound effects
- ✅ **FX System** - For screen shake and effects
- ✅ **Game System** - For scoring and state management

### 8. Performance Notes

- Boss uses efficient collision detection
- TNT crates are physics-based but optimized
- Particle effects are GPU-accelerated
- Signal-based communication reduces polling

### 9. Next Steps

Once the boss is working:
1. Adjust difficulty and timing
2. Add more visual polish
3. Create multiple boss variants
4. Integrate with your level progression system
5. Add boss-specific audio and music

## Need Help?

If you encounter issues:
1. Check the Godot debugger output
2. Verify all scene references are correct
3. Ensure collision layers match the documentation
4. Test individual components separately

The boss system is designed to be modular and easy to integrate with your existing game architecture!