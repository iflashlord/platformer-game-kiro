# Asset Checklist - HTML5 Platformer

## Required Assets Status

### ✅ Completed Assets
- [x] Project configuration (project.godot)
- [x] Audio bus layout (default_bus_layout.tres)
- [x] Export presets (export_presets.cfg)
- [x] Web deployment configuration
- [x] CI/CD pipeline setup
- [x] All scene files (.tscn)
- [x] All script files (.gd)
- [x] Texture import configurations (.import)

### 🔄 Placeholder Assets (Need Replacement)

#### Graphics Assets
- [ ] **icon.svg** - Game icon (128x128 SVG)
  - Current: Basic placeholder SVG
  - Needed: Professional game logo/icon
  
- [ ] **content/splash.png** - Boot splash (1280x720 PNG)
  - Current: Text placeholder
  - Needed: Game logo with dark background
  
- [ ] **content/PlayerSprite.png** - Player character (32x32 PNG)
  - Current: Text placeholder
  - Needed: Pixel art player character sprite
  
- [ ] **content/EnemySprites.png** - Enemy sprites (64x32 PNG)
  - Current: Text placeholder
  - Needed: Patrol enemy (0,0,32,32) + Charger enemy (32,0,32,32)
  
- [ ] **content/CollectibleSprites.png** - Collectibles (80x32 PNG)
  - Current: Text placeholder
  - Needed: 5 fruits (top row) + 5 gems (bottom row), 16x16 each
  
- [ ] **content/HazardSprites.png** - Hazards (128x64 PNG)
  - Current: Text placeholder
  - Needed: 4 spike directions (top row) + 4 crate types (bottom row), 32x32 each
  
- [ ] **content/UISprites.png** - UI elements (128x64 PNG)
  - Current: Text placeholder
  - Needed: Button backgrounds, icons, progress bars

#### Web Assets
- [ ] **web/icon-144.png** - PWA icon (144x144 PNG)
- [ ] **web/icon-180.png** - PWA icon (180x180 PNG)  
- [ ] **web/icon-512.png** - PWA icon (512x512 PNG)
- [ ] **web/favicon.ico** - Browser favicon (16x16, 32x32, 48x48 ICO)
- [ ] **web/preview.png** - Social media preview (1200x630 PNG)

#### Audio Assets
- [ ] **audio/music/** - Background music tracks
  - menu_theme.ogg - Main menu music
  - tutorial_theme.ogg - Tutorial level music
  - level_theme.ogg - Standard level music
  - chase_theme.ogg - Chase level music
  
- [ ] **audio/sfx/** - Sound effects
  - jump.ogg - Player jump sound
  - land.ogg - Player land sound
  - heavy_land.ogg - Heavy landing sound
  - soft_land.ogg - Soft landing sound
  - collect_fruit.ogg - Fruit collection sound
  - collect_gem.ogg - Gem collection sound
  - gem_reveal.ogg - Hidden gem reveal sound
  - dimension_gate.ogg - Flip gate activation
  - checkpoint.ogg - Checkpoint reached
  - explosion.ogg - Standard explosion
  - big_explosion.ogg - TNT explosion
  - small_explosion.ogg - Minor explosion
  - bounce_crate.ogg - Bounce crate sound
  - shard_bounce.ogg - Debris bounce sound
  - speed_up.ogg - Chase level speed increase
  - test_beep.ogg - ✅ Already exists (placeholder)

## Asset Specifications

### Graphics Requirements

#### Sprite Textures
- **Format**: PNG with transparency
- **Color Mode**: RGBA (32-bit)
- **Style**: Pixel art recommended
- **Compression**: Lossless for pixel art

#### Player Sprite (32x32)
- Bright, contrasting colors (blue/green recommended)
- Clear silhouette for easy recognition
- Facing right by default (will be flipped in code)
- Simple but appealing design

#### Enemy Sprites (32x32 each)
- **Patrol Enemy**: Red/orange, walking pose
- **Charger Enemy**: Darker red, aggressive pose
- Distinct from player character
- Threatening but not too scary

#### Collectible Sprites (16x16 each)
- **Fruits**: Apple (red), Banana (yellow), Cherry (red), Orange (orange), Grape (purple)
- **Gems**: Ruby (red), Emerald (green), Sapphire (blue), Diamond (white), Amethyst (purple)
- Bright, appealing colors
- Easy to distinguish from background

#### Hazard Sprites (32x32 each)
- **Spikes**: Gray/metallic, clearly dangerous
- **Crates**: Wood texture with appropriate markings
  - Normal: Plain wood
  - Bounce: Springs/coils visible
  - TNT: Red with "TNT" text
  - Nitro: Green with warning symbols

### Audio Requirements

#### Music Tracks
- **Format**: OGG Vorbis
- **Quality**: 5-7 (balance of size/quality)
- **Length**: 1-3 minutes, seamlessly looping
- **Style**: Upbeat, energetic, game-appropriate

#### Sound Effects
- **Format**: OGG Vorbis
- **Quality**: 6-8 (higher quality for short sounds)
- **Length**: 0.1-2 seconds typically
- **Style**: Clear, punchy, not overwhelming

### Icon Requirements

#### Game Icon (SVG)
- **Size**: 128x128 base, scalable
- **Style**: Clean, recognizable at small sizes
- **Colors**: Match game theme
- **Content**: Game logo or representative symbol

#### PWA Icons (PNG)
- **Sizes**: 144x144, 180x180, 512x512
- **Style**: Consistent with main icon
- **Background**: Solid color or transparent
- **Quality**: High resolution, crisp edges

## Asset Creation Tools

### Recommended Software
- **Pixel Art**: Aseprite, Piskel, GIMP
- **Vector Graphics**: Inkscape, Adobe Illustrator
- **Audio Editing**: Audacity, Reaper, FL Studio
- **Icon Creation**: GIMP, Photoshop, online generators

### Online Resources
- **Pixel Art**: Lospec (palettes), Pixilart
- **Audio**: Freesound.org, Zapsplat, Adobe Audition
- **Icons**: Flaticon, Icons8, Font Awesome

## Integration Process

### Adding New Assets
1. **Replace placeholder files** with actual assets
2. **Verify import settings** in Godot editor
3. **Test in-game appearance** and functionality
4. **Check web export** for proper loading
5. **Update documentation** if needed

### Quality Check
- [ ] Assets display correctly in all scenes
- [ ] File sizes are optimized for web
- [ ] Audio plays without issues
- [ ] Icons appear properly in browsers
- [ ] Performance remains stable

## Priority Order

### High Priority (Core Gameplay)
1. Player sprite
2. Basic sound effects (jump, land, collect)
3. Enemy sprites
4. Collectible sprites

### Medium Priority (Polish)
1. Hazard sprites
2. Background music
3. UI sprites
4. Additional sound effects

### Low Priority (Branding)
1. Game icon and branding
2. PWA icons
3. Splash screen
4. Social media assets

## Notes
- All placeholder assets are functional for testing
- Game is fully playable with current placeholders
- Assets can be replaced incrementally
- Import settings are pre-configured for optimal performance
- Web deployment works with placeholder assets