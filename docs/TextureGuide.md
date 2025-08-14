# Texture Guide for HTML5 Platformer

## Texture Files Overview

The game uses multiple texture files organized by category for optimal performance and organization.

### Texture Files

1. **PlayerSprite.png** (32x32 pixels)
   - Contains player character sprites
   - Region: (0,0,32,32) for idle/main sprite
   - Used in: Player.tscn, particle systems

2. **EnemySprites.png** (64x32 pixels)
   - Contains enemy character sprites
   - Region: (0,0,32,32) for EnemyPatrol
   - Region: (32,0,32,32) for EnemyCharger
   - Used in: EnemyPatrol.tscn, EnemyCharger.tscn

3. **CollectibleSprites.png** (80x16 pixels)
   - Contains fruit and gem sprites
   - Fruits: (0,0,16,16) to (64,0,16,16)
   - Gems: (0,16,16,16) to (64,16,16,16)
   - Used in: CollectibleFruit.tscn, HiddenGem.tscn

4. **HazardSprites.png** (128x64 pixels)
   - Contains hazards, crates, and tiles
   - Spikes: (0,0,32,32) to (96,0,32,32)
   - Crates: (0,32,32,32) to (96,32,32,32)
   - Used in: Spike.tscn, Crate.tscn, level tiles

5. **UISprites.png** (128x64 pixels)
   - Contains UI elements and buttons
   - Icons, buttons, and interface elements
   - Used in: UI scenes and menus

6. **TileTexture.png** (32x32 pixels)
   - Basic tile texture for particles and effects
   - Used in: Particle systems, basic sprites

## Sprite Atlas System

The `SpriteAtlas.gd` class manages texture regions and provides:

- Automatic texture selection based on sprite name
- Region mapping for efficient sprite batching
- Easy sprite creation with `create_atlas_sprite()`
- Texture application with `apply_to_sprite()`

### Usage Example

```gdscript
# Create a sprite using the atlas
var atlas = SpriteAtlas.new()
var player_sprite = atlas.create_atlas_sprite("player_idle")
add_child(player_sprite)

# Apply atlas texture to existing sprite
atlas.apply_to_sprite(existing_sprite, "enemy_patrol")
```

## Texture Regions

### Player Sprites (PlayerSprite.png)
- `player_idle`: (0,0,32,32)
- `player_run1`: (32,0,32,32) - if animated
- `player_run2`: (64,0,32,32) - if animated
- `player_jump`: (96,0,32,32) - if animated
- `player_fall`: (128,0,32,32) - if animated

### Enemy Sprites (EnemySprites.png)
- `enemy_patrol`: (0,0,32,32)
- `enemy_charger`: (32,0,32,32)

### Collectible Sprites (CollectibleSprites.png)
- `fruit_apple`: (0,0,16,16)
- `fruit_banana`: (16,0,16,16)
- `fruit_cherry`: (32,0,16,16)
- `fruit_orange`: (48,0,16,16)
- `fruit_grape`: (64,0,16,16)
- `gem_ruby`: (0,16,16,16)
- `gem_emerald`: (16,16,16,16)
- `gem_sapphire`: (32,16,16,16)
- `gem_diamond`: (48,16,16,16)
- `gem_amethyst`: (64,16,16,16)

### Hazard Sprites (HazardSprites.png)
- `spike_up`: (0,0,32,32)
- `spike_down`: (32,0,32,32)
- `spike_left`: (64,0,32,32)
- `spike_right`: (96,0,32,32)
- `crate_normal`: (0,32,32,32)
- `crate_bounce`: (32,32,32,32)
- `crate_tnt`: (64,32,32,32)
- `crate_nitro`: (96,32,32,32)

## Creating Actual Textures

To replace the placeholder textures with actual artwork:

### 1. Create PNG Files
Create the following PNG files with the specified dimensions:

```
content/PlayerSprite.png (32x32)
content/EnemySprites.png (64x32)
content/CollectibleSprites.png (80x32)
content/HazardSprites.png (128x64)
content/UISprites.png (128x64)
```

### 2. Sprite Layout
Arrange sprites according to the region mappings above. For example:

**PlayerSprite.png Layout:**
```
[Player Idle - 32x32]
```

**EnemySprites.png Layout:**
```
[Patrol Enemy - 32x32][Charger Enemy - 32x32]
```

**CollectibleSprites.png Layout:**
```
[Apple][Banana][Cherry][Orange][Grape]
[Ruby ][Emerald][Sapphire][Diamond][Amethyst]
```

### 3. Art Style Guidelines
- **Pixel Art**: 32x32 for characters, 16x16 for collectibles
- **Color Palette**: Bright, contrasting colors for visibility
- **Consistency**: Maintain consistent lighting and style
- **Transparency**: Use alpha channel for non-rectangular sprites

### 4. Optimization
- Use PNG format with transparency
- Keep file sizes small for web deployment
- Consider using indexed color mode for pixel art
- Test compression settings in Godot import tab

## Import Settings

Each texture file has an `.import` file that configures:
- Compression mode (0 = lossless for pixel art)
- Mipmaps (disabled for 2D sprites)
- Filter (off for pixel-perfect rendering)
- Format (CompressedTexture2D for performance)

## Performance Considerations

- **Texture Atlasing**: Multiple sprites per texture reduces draw calls
- **Power of 2 Sizes**: Use 32x32, 64x64, 128x128 for optimal GPU performance
- **Compression**: Balance quality vs file size for web deployment
- **Batching**: Group similar sprites in same texture for rendering efficiency

## Testing Textures

1. Load any scene with sprites (e.g., Player.tscn)
2. Check that textures display correctly
3. Verify region rectangles show correct sprite parts
4. Test in-game to ensure proper scaling and visibility
5. Check web export for loading performance

## Troubleshooting

**Sprites appear blank:**
- Check that PNG files exist in content/ folder
- Verify import settings are correct
- Ensure region rectangles match sprite positions

**Wrong sprite parts showing:**
- Check region_rect values in scene files
- Verify sprite layout matches region mappings
- Update atlas regions if sprites moved

**Performance issues:**
- Reduce texture sizes if too large
- Enable compression in import settings
- Check that sprites are properly batched