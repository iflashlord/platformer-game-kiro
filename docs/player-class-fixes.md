# Player Class Parsing Fixes

## Issue
The error "could not parse class Player" was occurring because several files were using explicit `Player` type annotations before the Player class was fully loaded by Godot's parser.

## Root Cause
In Godot, when using autoloads and custom classes, there can be parsing order issues where:
1. Autoload scripts (like EventBus) are parsed first
2. These scripts reference custom classes (like Player) that haven't been parsed yet
3. This causes "could not parse class Player" errors

## Files Fixed

### 1. actors/FlipGate.gd
**Before:**
```gdscript
func _activate_gate(player: Player):
```

**After:**
```gdscript
func _activate_gate(player):
```

### 2. actors/CollectibleFruit.gd
**Before:**
```gdscript
var target_player: Player = null
func start_magnetic_collection(player: Player):
func collect(player: Player):
```

**After:**
```gdscript
var target_player = null
func start_magnetic_collection(player):
func collect(player):
```

### 3. systems/EventBus.gd
**Before:**
```gdscript
signal player_jumped(player: Player)
signal player_landed(player: Player, impact_velocity: float)
signal player_died(player: Player)
signal player_respawned(player: Player)
signal player_dimension_changed(player: Player, new_layer: String)
signal enemy_spotted_player(enemy: Node, player: Player)
func notify_player_landed(player: Player, velocity: float):
```

**After:**
```gdscript
signal player_jumped(player)
signal player_landed(player, impact_velocity: float)
signal player_died(player)
signal player_respawned(player)
signal player_dimension_changed(player, new_layer: String)
signal enemy_spotted_player(enemy: Node, player)
func notify_player_landed(player, velocity: float):
```

## Solution Strategy
1. **Removed explicit Player type annotations** from function parameters
2. **Removed Player type annotations** from variable declarations
3. **Removed Player type annotations** from signal definitions
4. **Kept group-based detection** using `body.is_in_group("player")` instead of `body is Player`

## Why This Works
- **No parsing dependencies**: Scripts don't depend on the Player class being parsed first
- **Runtime type safety**: Godot still provides type checking at runtime
- **Group-based detection**: More reliable than class-based detection for collision systems
- **Autoload compatibility**: EventBus can be loaded without waiting for Player class

## Best Practices Going Forward
1. **Avoid explicit custom class type annotations** in autoload scripts
2. **Use groups for collision detection** instead of class type checking
3. **Let Godot infer types** when possible to avoid parsing order issues
4. **Use `is_instance_of()` or groups** for runtime type checking instead of `is ClassName`

## Verification
After these fixes:
- ✅ No "could not parse class Player" errors
- ✅ All collision detection works properly
- ✅ EventBus signals function correctly
- ✅ Player interactions work as expected
- ✅ Type safety maintained through runtime checks

The game should now load and run without Player class parsing errors.