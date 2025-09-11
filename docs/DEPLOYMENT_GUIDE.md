# Production Deployment Guide

## 🚀 Glitch Dimension - Production Deployment

This guide covers deploying Glitch Dimension to production environments with all the professional systems in place.

## 📋 Prerequisites

### Development Environment
- Godot 4.4+ installed
- Git for version control
- Node.js (optional, for Vercel CLI)

### Production Systems
- Vercel account (for web hosting)
- CDN (optional)

## 🔧 Build Configuration

### 1. Export Presets Setup

Ensure the following export presets are configured in Godot:

#### Web Export
```
Name: Web
Platform: Web
Features: GL Compatibility
Export Path: web-dist/index.html
```

#### Desktop Exports
```
Windows Desktop: build/windows/glitch-dimension.exe
Linux/X11: build/linux/glitch-dimension.x86_64
macOS: build/macos/glitch-dimension.zip
```

### 2. Project Settings Validation

Verify these critical settings:

```gdscript
# Application
application/config/name = "Glitch Dimension"
application/config/version = "1.0.0"
application/run/main_scene = "res://ui/MainMenu.tscn"

# Rendering
rendering/renderer/rendering_method = "gl_compatibility"
rendering/textures/canvas_textures/default_texture_filter = 0

# Audio
audio/buses/default_bus_layout = "res://audio/sfx/default_bus_layout.tres"
```

## 🏗️ Build Process

### Automated Build (Optional)

The `tools/BuildManager.gd` script can assist with repeatable exports. For simple web hosting, a manual export is sufficient.

### Manual Build

For manual builds:

```bash
# Web build
godot --headless --export-release "Web" web-dist/index.html

# Windows build
godot --headless --export-release "Windows Desktop" build/windows/glitch-dimension.exe

# Linux build
godot --headless --export-release "Linux/X11" build/linux/glitch-dimension.x86_64

# macOS build
godot --headless --export-release "macOS" build/macos/glitch-dimension.zip
```

## 🌐 Web Deployment

### Vercel Deployment (Primary)

1. **Setup Vercel Project**
   ```bash
   npm install -g vercel
   cd web-dist
   vercel --prod
   ```

2. **Headers**
   This repo ships a `vercel.json` configured for Godot Web exports (COOP/COEP, CORS, correct MIME types for wasm/pck, and caching). No additional Vercel config is required.

3. **Environment Variables**
   Set these in Vercel dashboard:
   ```
   GAME_VERSION=1.0.0
   ANALYTICS_ENABLED=true
   ERROR_REPORTING_ENABLED=true
   ```

### Alternative Web Hosting

For other hosting providers:

1. **Static File Hosting**
   - Upload the `web-dist/` directory
   - Ensure proper MIME types for `.wasm` and `.pck` files
   - Configure CORS headers if needed

2. **CDN Configuration**
   - Enable gzip compression
   - Set appropriate cache headers
   - Configure SSL/TLS

## 🖥️ Desktop Deployment

### Windows
```bash
# Build
godot --headless --export-release "Windows Desktop" build/windows/glitch-dimension.exe

# Package (optional)
zip -r glitch-dimension-windows.zip build/windows/
```

### Linux
```bash
# Build
godot --headless --export-release "Linux/X11" build/linux/glitch-dimension.x86_64

# Make executable
chmod +x build/linux/glitch-dimension.x86_64

# Package
tar -czf glitch-dimension-linux.tar.gz -C build/linux .
```

### macOS
```bash
# Build
godot --headless --export-release "macOS" build/macos/glitch-dimension.zip

# The output is already a zip file ready for distribution
```

## 📊 Production Configuration

Analytics in this project is local-only (no network). See `docs/Analytics.md` for details.

### 3. Performance Monitoring

Ensure performance monitoring is active:

```gdscript
# In systems/PerformanceMonitor.gd
const PERFORMANCE_MONITORING_ENABLED = true
const PERFORMANCE_THRESHOLDS = {
    "fps_warning": 30.0,
    "fps_critical": 15.0,
    "memory_warning": 512 * 1024 * 1024  # 512MB
}
```

## 🔒 Security Configuration

### 1. Content Security Policy (Web)

Add to your web server configuration:

```
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-eval'; worker-src 'self' blob:; connect-src 'self' https:;
```

### 2. HTTPS Configuration

Ensure all production deployments use HTTPS:
- Vercel provides automatic HTTPS
- For custom hosting, configure SSL certificates

### 3. Data Privacy

Ensure compliance with privacy regulations:
- Analytics data anonymization
- User consent for data collection
- Data retention policies

## 📈 Monitoring & Maintenance

### 1. Health Checks
For static hosting, health checks are typically handled at the CDN/hosting layer.

### 2. Log Monitoring

Monitor application logs:
- Error rates and patterns
- Performance metrics
- User behavior analytics
- System resource usage

### 3. Update Deployment

For updates:

1. **Version Bump**
   ```gdscript
   # Update in project.godot
   application/config/version="1.0.1"
   ```

2. **Build and Test**
   ```bash
   godot --script tools/BuildManager.gd -- --build-all
   ```

3. **Deploy**
   ```bash
   cd web-dist
   vercel --prod
   ```

## 🚨 Rollback Procedures

### Web Rollback (Vercel)
```bash
# List deployments
vercel ls

# Rollback to previous deployment
vercel rollback [deployment-url]
```

### Desktop Rollback
- Maintain previous build artifacts
- Provide download links to stable versions
- Implement auto-update rollback mechanism

## 📋 Pre-Launch Checklist

### Technical Validation
- [ ] All export presets configured
- [ ] Builds complete successfully
- [ ] Performance targets met (60 FPS, <1GB RAM)
- [ ] Error handling tested
- [ ] Analytics tracking verified
- [ ] Cross-platform compatibility confirmed

### Content Validation
- [ ] All levels playable and completable
- [ ] UI navigation works correctly
- [ ] Audio/music plays properly
- [ ] Save/load functionality works
- [ ] Settings persist correctly

### Production Readiness
- [ ] Monitoring systems active
- [ ] Error reporting configured
- [ ] Analytics collecting data
- [ ] Performance metrics baseline established
- [ ] Rollback procedures tested

## 🎯 Launch Day Procedures

### 1. Final Build
```bash
# Clean build for launch
godot --script tools/BuildManager.gd -- --clean
godot --script tools/BuildManager.gd -- --build-all
```

### 2. Deployment
```bash
# Deploy to production
cd web-dist
vercel --prod
```

### 3. Verification
- [ ] Game loads correctly
- [ ] All features functional
- [ ] Performance within targets
- [ ] Analytics receiving data
- [ ] Error reporting active

### 4. Monitoring
- Monitor error rates
- Track performance metrics
- Watch user engagement
- Respond to issues quickly

## 🔧 Troubleshooting

### Common Issues

1. **Build Failures**
   - Check export preset configuration
   - Verify all required files exist
   - Check Godot version compatibility

2. **Performance Issues**
   - Monitor PerformanceMonitor alerts
   - Check memory usage patterns
   - Optimize asset loading

3. **Loading Issues**
   - Verify CORS headers
   - Check file permissions
   - Validate MIME types

### Support Resources
- Check ErrorHandler logs
- Review Analytics data
- Monitor PerformanceMonitor metrics
- Use ConfigManager diagnostics

---

## 🎉 Production Deployment Complete!

Your Glitch Dimension game is now ready for production with:

- **Professional build system**
- **Comprehensive monitoring**
- **Error tracking and analytics**
- **Multi-platform support**
- **Scalable architecture**

The game is production-ready and enterprise-grade! 🚀
