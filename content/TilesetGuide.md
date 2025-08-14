# Tileset Guide

## Tile Sources

### Source 0: Solid Tiles
- **Tile 0**: Basic solid block (32x32 rectangle collision)
- **Usage**: Ground, walls, platforms

### Source 1: One-Way Platforms  
- **Tile 0**: One-way platform (32x16 rectangle, one_way_collision = true)
- **Usage**: Jump-through platforms

### Source 2: Slopes
- **Tile 0**: 45° slope up (left to right)
- **Tile 1**: 45° slope down (left to right)  
- **Tile 2**: Gentle slope up (16px rise over 32px)
- **Tile 3**: Gentle slope down (16px drop over 32px)
- **Tile 4**: Steep slope up (32px rise over 16px)
- **Tile 5**: Steep slope down (32px drop over 16px)

### Source 3: Hazards
- **Tile 0**: Spikes/damage tiles
- **Usage**: Instant death or damage zones

## Layer Setup

### Layer 0: Background
- Z-index: -1
- Decorative tiles, no collision

### Layer 1: Solid
- Z-index: 0  
- Main collision geometry

### Layer 2: One-Way
- Z-index: 1
- Jump-through platforms

### Layer 3: Hazards
- Z-index: 0
- Damage/death tiles

## Collision Shapes

All collision shapes are properly configured:
- **Solid**: Full 32x32 rectangle
- **One-way**: 32x16 rectangle with one_way_collision
- **Slopes**: ConvexPolygonShape2D with proper angles
- **Hazards**: Custom shapes for spikes/traps

## Usage in Levels

1. Paint solid tiles for main geometry
2. Add slopes for smooth transitions
3. Place one-way platforms for vertical navigation
4. Use hazard tiles sparingly for challenge
5. Add background tiles for visual appeal

## Performance Tips

- Use TileMap layers efficiently
- Group similar collision types
- Minimize overdraw with background layers
- Use collision layers/masks for complex interactions