# Giant Boss System Guide

## Overview

The Giant Boss is a multi-phase enemy that provides an escalating challenge as the player damages it. The boss requires 5 hits to defeat and changes its behavior pattern with each hit taken.

## Features

### Progressive Damage System
- **Health**: 5 hits to defeat
- **Visual Health Bar**: Shows current health and damage taken
- **Phase Indicator**: Displays current movement pattern
- **Damage Immunity**: 1-second invincibility after each hit

### Movement Phases

#### Phase 1: Walking (5/5 Health)
- Simple left-right movement
- Changes direction when hitting walls or edges
- Moderate speed movement
- **Color**: White indicator

#### Phase 2: Jumping (4/5 Health)  
- Continues walking movement
- Adds periodic jumping behavior
- Slightly increased movement speed
- **Color**: Yellow indicator

#### Phase 3: Charging (3/5 Health)
- Fast charging movement
- Creates screen shake when hitting walls
- Significantly increased speed
- **Color**: Orange indicator

#### Phase 4: Flying (2/5 & 1/5 Health)
- Disables gravity - boss can fly
- Actively follows the player
- Increased aggression at 1 health
- **Color**: Red indicator

### TNT Dropping System
- **Drop Interval**: Starts at 3 seconds, decreases as health drops
- **Fuse Time**: 3 seconds before explosion
- **Visual Warning**: Yellow warning light with pulsing effect
- **Explosion Radius**: 100 pixels
- **Player Damage**: 1 damage per explosion

### Player Interaction
- **Stomping**: Player must jump on boss's head to damage it
- **Bounce Effect**: Player bounces up after successful stomp
- **Damage Detection**: Only top area of boss can be stomped
- **Hazard Avoidance**: Boss body damages player on contact

## Technical Implementation

### Core Components

#### GiantBoss.gd
- Main boss logic and state management
- Movement pattern implementations
- Health and damage system
- TNT dropping mechanics

#### BossHealthUI.gd
- Health bar visualization
- Phase indicator updates
- Damage counter display
- Animated feedback effects

#### TNTCrate.gd
- Explosive crate behavior
- Fuse timer and warning system
- Explosion damage and effects
- Physics-based dropping

### Godot Features Used

#### Advanced Physics
- **CharacterBody2D**: For boss movement and collision
- **RigidBody2D**: For TNT crate physics
- **Area2D**: For damage detection and explosion radius
- **RayCast2D**: For wall and ground detection

#### Visual Effects
- **GPUParticles2D**: Hit effects and dust clouds
- **AnimatedSprite2D**: Multi-frame sprite animations
- **Tween**: Smooth animations and screen shake
- **Modulation**: Color changes and flash effects

#### Audio Integration
- **AudioStreamPlayer2D**: Positional sound effects
- **Multiple Audio Streams**: Fuse sounds and explosions

#### Signal-Based Architecture
- **EventBus Integration**: Global event communication
- **Custom Signals**: Boss-specific events
- **UI Updates**: Real-time health and phase updates

### Performance Optimizations
- **Object Pooling**: Reuse explosion effects
- **Conditional Updates**: Only update active systems
- **Efficient Collision**: Optimized collision shapes
- **Smart Timers**: Event-driven rather than polling

## Usage Instructions

### Adding to a Level
1. Instance `GiantBoss.tscn` in your level
2. Add `BossHealthUI.tscn` to a CanvasLayer
3. Connect boss signals to level management
4. Ensure proper collision layers are set

### Testing
- From the game: open “The Giant’s Last Stand” via Level Select.
- Direct scene: `godot --path . --main-scene res://levels/Level_GiantBoss.tscn`

### Customization Options

#### Boss Stats (Export Variables)
- `max_health`: Number of hits to defeat (default: 5)
- `walk_speed`: Base movement speed (default: 50.0)
- `fly_speed`: Flying phase speed (default: 80.0)
- `jump_force`: Jump velocity (default: -400.0)

#### TNT System
- `tnt_drop_interval`: Time between TNT drops (default: 3.0)
- `explosion_radius`: TNT explosion range (configured on `InteractiveCrate`)
- `fuse_time`: TNT fuse duration (configured on `InteractiveCrate`)

#### Visual Customization
- Replace sprite animations in `GiantBoss.tscn`
- Modify particle effects for different themes
- Customize health bar colors and styling

## Integration with Game Systems

### EventBus Signals
- `boss_health_changed(health, max_health)`
- `boss_defeated`
- `boss_phase_changed(phase)`
- `boss_tnt_placed(position)`

### Audio System
- Connects to global Audio singleton
- Plays positional sound effects
- Supports different audio buses

### FX System
- Screen shake on damage and wall hits
- Hit-stop effects for impact feedback
- Particle systems for visual polish

### Level Flow
- `levels/Level_GiantBoss.gd` hides the exit portal until `boss_defeated`.
- On defeat, the portal animates in and allows level completion.

## Best Practices

### Level Design
- Provide adequate vertical space for jumping phases
- Include platforms for player positioning
- Consider TNT explosion radius in layout
- Add visual cues for stomp zones

### Balancing
- Test all movement phases thoroughly
- Adjust TNT drop rates for difficulty
- Ensure player has escape routes
- Balance boss size vs. level constraints

### Performance
- Monitor particle effect counts
- Limit simultaneous TNT crates
- Use appropriate collision layer masks
- Profile boss behavior in complex levels

## Troubleshooting

### Common Issues
- **Boss falls through floor**: Check collision layers
- **Player can't damage boss**: Verify stomp detector setup
- **TNT doesn't explode**: InteractiveCrate must be `crate_type = "tnt"`; check fuse/animations
- **Health UI not updating**: Ensure EventBus connections

### Debug Features
- Enable collision shape visibility
- Use print statements for phase transitions
- Monitor signal emissions in debugger
- Check physics layer interactions

## Future Enhancements

### Potential Additions
- Multiple boss variants with different sprites
- Special attack patterns (projectiles, ground slam)
- Environmental interactions (destructible terrain)
- Boss dialogue and story integration
- Achievement system for different defeat methods
