# Giant Boss Setup Guide

## Quick Setup

The Giant Boss is ready to use in the project. Use the bundled boss level to verify behavior, or integrate the boss into other levels.

### 1. Files Created
- ✅ `actors/GiantBoss.gd` / `actors/GiantBoss.tscn` — Main boss
- ✅ `actors/InteractiveCrate.gd` / `actors/InteractiveCrate.tscn` — TNT crates via `crate_type = "tnt"`
- ✅ `actors/Explosion.gd` / `actors/Explosion.tscn` — Explosion effects
- ✅ `ui/BossHealthUI.gd` / `ui/BossHealthUI.tscn` — Boss health display
- ✅ `levels/Level_GiantBoss.gd` / `levels/Level_GiantBoss.tscn` — Boss level (wired and ready)

### 2. Testing the Boss

#### Option A: From Main Menu
- Run the game and use Level Select to open “The Giant’s Last Stand”.

#### Option B: Direct Scene
```bash
godot --path . --main-scene res://levels/Level_GiantBoss.tscn
```

#### Option C: Editor
1. Open `levels/Level_GiantBoss.tscn`
2. Click Play Scene (F6)

### 3. If You Get Scene Reference Errors

If UIDs/resources were changed, re-instance the boss/UI references:

#### Method 1: Re-instance Scenes
1. Open `levels/Level_GiantBoss.tscn` in Godot
2. Delete the GiantBoss and Player nodes
3. Re-add them by dragging from FileSystem:
   - `actors/GiantBoss.tscn` → position at (640, 550)
   - `actors/Player.tscn` → position at (200, 600)
4. Save the scene

#### Method 2: Minimal Test
- Create a new scene with ground, Player, and GiantBoss; add `ui/BossHealthUI.tscn` under a CanvasLayer.

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
- TNT is provided by `actors/InteractiveCrate.tscn` with `crate_type = "tnt"`.
- Check crate masks and ensure the fuse timer/animation are active.
- Verify nearby explosions trigger chain reactions (see `actors/Explosion.gd`).

### 6. Customization

#### Adjust Boss Difficulty
```gdscript
# In GiantBoss.gd, modify export variables (examples):
@export var max_health: int = 5
@export var walk_speed: float = 50.0
@export var tnt_drop_interval: float = 3.0
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
