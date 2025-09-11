# Explosion System - Production Ready

## Overview
The Explosion system (Bomb class) is a comprehensive, production-ready component for handling explosive projectiles in the game. It features advanced collision detection, particle effects, chain reactions, and robust error handling.

## Key Features

### 1. Smart Collision Detection
- **Player Contact**: Explodes immediately when touching player
- **TNT Crate Contact**: Explodes when touching InteractiveCrate (TNT types)
- **Hard Impact**: Explodes on impact with objects (not during rolling phase)
- **Enemy/Boss Safe**: Will not explode when touching enemies or bosses

### 2. Radiation System
- **Player Damage**: Only damages player in radiation area, not enemies/bosses
- **TNT Chain Reaction**: Triggers TNT crates in radiation area
- **Performance Optimized**: Caches bodies in explosion area for efficient processing

### 3. Visual Effects
- **Particle Systems**: 
  - Explosion particles (fire/energy effect)
  - Smoke particles (lingering smoke effect)
  - Particles scale with bomb power (LOW/MEDIUM/HIGH)
- **Lighting**: Dynamic explosion light with flash effect
- **Visual Feedback**: Bomb flashes red as fuse timer approaches explosion

### 4. Audio Integration
- Power-based audio effects:
  - HIGH: "big_explosion"
  - MEDIUM: "explosion" 
  - LOW: "small_explosion"
- Screen shake effects scale with bomb power

### 5. Chain Reaction System
- **TNT Crate Triggering**: Automatically triggers nearby TNT crates
- **Bomb-to-Bomb**: Chain reactions between bombs with cascading delay
- **Safety Checks**: Prevents infinite loops and validates objects before triggering

### 6. Three Power Levels

#### LOW Power
- Radius: 60 units
- Damage: 1.0
- Fuse Time: 4.0 seconds
- Shake: 60 strength

#### MEDIUM Power  
- Radius: 100 units
- Damage: 1.0
- Fuse Time: 3.0 seconds
- Shake: 90 strength

#### HIGH Power
- Radius: 150 units  
- Damage: 2.0
- Fuse Time: 2.0 seconds
- Shake: 120 strength

### 7. Production-Ready Features
- **Error Handling**: Validates configuration on startup
- **Memory Management**: Proper cleanup in _exit_tree()
- **Performance**: Optimized collision detection and caching
- **Safety Checks**: Prevents crashes with null checking
- **Debug Logging**: Comprehensive logging for debugging
- **API**: get_explosion_info() for external systems

## Usage

### Basic Setup
```gdscript
var bomb = bomb_scene.instantiate()
get_parent().add_child(bomb)
bomb.setup(Bomb.BombPower.HIGH)
bomb.global_position = spawn_position
```

### Legacy Setup (Backward Compatible)
```gdscript
bomb.setup_legacy(radius, damage)
```

### Getting Bomb Info
```gdscript
var info = bomb.get_explosion_info()
print("Bomb power: ", info.power_name)
print("Time remaining: ", info.remaining_time)
```

## File Structure
- `Explosion.gd`: Main bomb logic and behavior
- `Explosion.tscn`: Scene with particles, lighting, and collision areas

## Integration Requirements
- FX system for screen shake and hit-stop effects
- Audio system for explosion sounds
- TNT crates must have `start_explosion_countdown()` method
- Player must have `take_damage()` method
- Objects should be in appropriate groups: "player", "crates", "enemy", "boss"

## Performance Considerations
- Uses collision caching to avoid repeated area queries
- Validates objects before processing to prevent errors
- Automatic cleanup prevents memory leaks
- Optimized particle counts based on power level

## Safety Features
- Collision disabling after explosion to prevent duplicate triggers
- Instance validation before calling methods on other objects
- Configuration validation with fallback defaults
- Proper error handling for missing dependencies

This explosion system is ready for production use and provides a solid foundation for explosive gameplay mechanics.
