# Flying Enemy System Guide

## Overview

The `FlyingEnemy` is a new enemy type that adds aerial threats to your levels. Unlike ground-based `PatrolEnemy`, flying enemies ignore gravity and can move in complex patterns through the air.

## Features

### 🎯 **Flight Patterns**
- **Horizontal**: Simple left-right patrol
- **Sine Wave**: Wavy horizontal movement
- **Circular**: Elliptical flight path
- **Chase Player**: Actively pursues the player when detected
- **Vertical**: Up-down patrol movement

### 🐝 **Enemy Types**
- **Bee**: Yellow, moderate speed, sine wave pattern (200 pts)
- **Fly**: White, fast horizontal patrol (150 pts)
- **Ladybug Fly**: Red, circular pattern, 2 HP (250 pts)
- **Bat**: Dark gray, chases player (300 pts)
- **Wasp**: Orange, vertical patrol, 2 damage (350 pts)

### 🎮 **Gameplay Mechanics**
- **No Gravity**: Flies freely through the air
- **Stompable**: Can be defeated by jumping on them
- **Damage Dealing**: Hurts player on contact with pushback
- **Detection**: Larger detection range than ground enemies
- **Visual Effects**: Unique defeat animations (spinning fall)

## Usage in Levels

### Basic Setup
1. Add `FlyingEnemy.tscn` to your level
2. Set the `enemy_type` property in the inspector
3. Choose a `flight_pattern`
4. Adjust `pattern_amplitude` and `pattern_frequency` for custom behavior

### Code Configuration
```gdscript
# Setup a bee with sine wave pattern
flying_enemy.set_enemy_stats("bee", 1, 80.0)
flying_enemy.set_flight_pattern("Sine Wave", 60.0, 1.5)

# Setup a chasing bat
flying_enemy.set_enemy_stats("bat", 1, 100.0)
flying_enemy.set_chase_behavior(true, 120.0)

# Setup patrol area
flying_enemy.set_patrol_area(Vector2(500, 200), 150.0)
```

### Inspector Properties
- **Enemy Type**: "bee", "fly", "ladybug_fly", "bat", "wasp"
- **Flight Speed**: Base movement speed (50-150 recommended)
- **Flight Pattern**: Movement behavior type
- **Pattern Amplitude**: Size of pattern (for sine/circular)
- **Pattern Frequency**: Speed of pattern oscillation
- **Patrol Distance**: How far to travel before turning
- **Detection Range**: Player detection radius
- **Damage Amount**: Damage dealt to player
- **Points Value**: Score awarded when defeated
- **Health**: HP (1-3 recommended)

## Level Design Tips

### 🎯 **Placement Strategy**
- Place flying enemies in open areas where their patterns can be seen
- Use different heights to create layered threats
- Combine with platforms for interesting jump challenges
- Place near collectibles to create risk/reward scenarios

### 🎨 **Pattern Combinations**
- **Horizontal + Vertical**: Create crossing patrol routes
- **Sine Wave**: Great for narrow corridors
- **Circular**: Perfect for open areas with central platforms
- **Chase**: Use sparingly for intense moments
- **Mixed Types**: Combine different enemies for varied challenges

### ⚖️ **Difficulty Balancing**
- **Easy**: Single horizontal/sine wave enemies
- **Medium**: Multiple patterns, some with 2 HP
- **Hard**: Chase enemies, high damage wasps, complex patterns

## Technical Details

### Collision Layers
- **Enemy Layer**: 4 (same as ground enemies)
- **Detection Mask**: 2 (player layer)
- **Damage Mask**: 2 (player layer)

### Performance
- Flying enemies use `CharacterBody2D` for consistent physics
- No gravity calculations improve performance
- Efficient pattern calculations using sine/cosine
- Proper cleanup on defeat prevents memory leaks

### Signals
```gdscript
signal enemy_defeated(enemy: FlyingEnemy, points: int)
signal enemy_stomped(enemy: FlyingEnemy, player: Node2D, points: int)
signal player_detected(enemy: FlyingEnemy, player: Node2D)
signal player_damaged(enemy: FlyingEnemy, player: Node2D, damage: int)
```

## Testing

Practical testing steps:
- Add `actors/FlyingEnemy.tscn` to any level and set `flight_pattern` in the inspector.
- Use a large open section to observe sine/circular patterns.
- Set `flight_pattern = "Chase Player"` and verify detection range and pursue behavior.
- Combine with hazards and platforms to tune difficulty.

## Integration with Existing Systems

### ✅ **Compatible Systems**
- **Game Scoring**: Awards points on defeat
- **HealthSystem**: Damages player properly
- **Audio System**: Plays defeat sounds
- **FX System**: Screen shake and flash effects
- **Analytics**: Tracks enemy interactions
- **ErrorHandler**: Proper logging and debugging

### 🎮 **Player Interactions**
- **Stomping**: Jump on enemies to defeat them
- **Damage**: Contact damages player with pushback
- **Detection**: Enemies react to player presence
- **Chase**: Some enemies actively pursue player

## Future Enhancements

Potential improvements for the flying enemy system:
- **Projectile Attacks**: Some enemies could shoot
- **Formation Flying**: Multiple enemies in sync
- **Environmental Reactions**: React to dimension shifts
- **Advanced AI**: More complex chase behaviors
- **Custom Sprites**: Dedicated flying enemy artwork

---

The flying enemy system adds a new dimension to level design, creating aerial challenges that complement the existing ground-based threats. Use them strategically to create engaging and varied gameplay experiences! 🐝✨
