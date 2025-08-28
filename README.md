# Glitch Dimension

A fast-paced 2D platformer built with Godot 4.4, featuring dimension-shifting mechanics, challenging levels, and smooth web deployment.

## 🎮 Play Online

**[Play Now on Vercel](https://glitch-dimension.vercel.app/)**

## ✨ Features

- **Dimension Shifting**: Switch between layers to navigate complex puzzles
- **Responsive Controls**: Coyote time, jump buffering, and variable jump height
- **Progressive Levels**: From tutorial to expert chase sequences
- **Hidden Secrets**: Collectible gems and unlockable content
- **Touch Support**: Mobile-friendly controls for web play
- **Visual Effects**: Particle systems, screen shake, and hit-stop feedback
- **Audio System**: Dynamic music and sound effects with volume controls
- **Performance Optimized**: Object pooling, sprite atlases, and efficient rendering

## 🎯 Game Mechanics

### Core Movement
- **WASD/Arrow Keys**: Movement and jumping
- **Space**: Primary jump button
- **S**: Dimension flip between layers A and B
- **ESC**: Pause menu
- **R**: Restart current level

### Advanced Techniques
- **Coyote Time**: Jump briefly after leaving platforms
- **Jump Buffering**: Press jump before landing for instant response
- **Variable Jump**: Hold jump for higher jumps, release for shorter hops
- **Mid-Air Flipping**: Use flip gates to change dimensions while jumping

## 🏗️ Development Setup

### Prerequisites
- [Godot 4.3+](https://godotengine.org/download)
- Git for version control
- Node.js (for Vercel deployment)

### Local Development
```bash
# Clone the repository
git clone https://github.com/yourusername/glitch-dimension.git
cd glitch-dimension

# Open in Godot
godot project.godot

# Or run directly
godot --main-scene res://ui/MainMenu.tscn
```

### Project Structure
```
├── actors/          # Player, enemies, collectibles
├── systems/         # Core game systems (Audio, FX, etc.)
├── ui/             # Menus and interface
├── levels/         # Game levels and scenes
├── data/           # Configuration files
├── content/        # Sprites and assets
├── audio/          # Music and sound effects
├── docs/           # Documentation
└── .github/        # CI/CD workflows
```

## 🚀 Deployment

### Automatic Deployment
This project uses GitHub Actions for automatic deployment to Vercel:

1. **Fork this repository**
2. **Set up Vercel project** and get your tokens
3. **Add GitHub Secrets**:
   - `VERCEL_TOKEN`: Your Vercel API token
   - `VERCEL_ORG_ID`: Your Vercel organization ID
   - `VERCEL_PROJECT_ID`: Your Vercel project ID
4. **Push to main branch** - deployment happens automatically!

### Manual Deployment
```bash
# Export HTML5 build
godot --headless --export-release "Web" build/web/index.html

# Deploy to Vercel
cd build/web
vercel --prod
```

See [Deployment Guide](docs/Deployment.md) for detailed instructions.

## 🎨 Game Design

### Level Progression
1. **Level00**: Tutorial - Basic movement and mechanics
2. **Level01**: First Steps - Introduction to dimension gates
3. **Level02**: Forest Canopy - Multi-layer platforming with enemies
4. **Level03**: Crystal Caves - Complex hazards and precise timing
5. **Chase01**: The Great Escape - High-speed chase with pursuing wall

### Scoring System
- **Base Score**: Completion bonus per level
- **Time Bonus**: Faster completion = higher score
- **Collectibles**: Hidden gems provide significant bonuses
- **Relics**: Bronze/Silver/Gold rankings based on completion time

### Hidden Content
Each level contains one hidden gem:
- **Emerald** (Level01): 150 points
- **Sapphire** (Level02): 200 points  
- **Diamond** (Level03): 300 points
- **Amethyst** (Chase01): 250 points

## 🛠️ Technical Details

### Performance Optimizations
- **Object Pooling**: Reuses particles, projectiles, and temporary objects
- **Sprite Atlases**: Batches rendering calls for better performance
- **Signal-Based Events**: Eliminates per-frame polling overhead
- **Efficient Collision**: Layer-based collision detection

### Web Optimization
- **Canvas Items Stretch**: Maintains pixel-perfect scaling
- **Compressed Assets**: Optimized textures and audio
- **Progressive Loading**: Loads critical assets first
- **CORS Headers**: Proper configuration for web deployment

### Browser Compatibility
- **WebGL 2.0** support (fallback to WebGL 1.0)
- **Web Audio API** for sound
- **Touch Events** for mobile devices
- **Gamepad API** for controller support

## 📊 Analytics and Monitoring

The game includes built-in analytics for:
- Level completion rates
- Average completion times
- Death locations and causes
- Collectible discovery rates
- Performance metrics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Godot's GDScript style guide
- Add comments for complex mechanics
- Test on multiple browsers before submitting
- Update documentation for new features

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Behrouz Pooladrak**: Game Developer - [www.behrouz.nl](https://www.behrouz.nl)
- **Kiro IDE**: Development environment for Vibe coding and development
- **Godot Engine**: Amazing open-source game engine
- **barichello/godot-ci**: Docker images for CI/CD
- **Vercel**: Excellent hosting platform
- **GitHub Actions**: Automated deployment pipeline

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/glitch-dimension/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/glitch-dimension/discussions)
- **Documentation**: [docs/](docs/) folder

## 🎯 Roadmap

- [ ] Additional levels and worlds
- [ ] Multiplayer support
- [ ] Level editor
- [ ] Steam integration
- [ ] Mobile app versions
- [ ] Speedrun leaderboards

---

**Built with ❤️ by Behrouz Pooladrak using Godot Engine and Kiro IDE**