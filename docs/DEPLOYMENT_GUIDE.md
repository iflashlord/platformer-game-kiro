# Production Deployment Guide

## 🚀 Glitch Dimension - Production Deployment

This guide covers deploying Glitch Dimension to production environments with all the professional systems in place.

## 📋 Prerequisites

### Development Environment
- Godot 4.4+ installed
- Git for version control
- Node.js (for web deployment tools)
- Platform-specific SDKs (if targeting native platforms)

### Production Systems
- Vercel account (for web deployment)
- Analytics service (optional)
- Error tracking service (optional)
- CDN for assets (optional)

## 🔧 Build Configuration

### 1. Export Presets Setup

Ensure the following export presets are configured in Godot:

#### Web Export
```
Name: Web
Platform: Web
Features: gl_compatibility
Export Path: build/web/index.html
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

### Automated Build (Recommended)

Use the BuildManager tool for consistent builds:

```bash
# Build for web
godot --script tools/BuildManager.gd -- --build-web

# Build for all platforms
godot --script tools/BuildManager.gd -- --build-all

# Clean build directory
godot --script tools/BuildManager.gd -- --clean
```

### Manual Build

For manual builds:

```bash
# Web build
godot --headless --export-release "Web" build/web/index.html

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
   cd build/web
   vercel --prod
   ```

2. **Configure vercel.json**
   ```json
   {
     "version": 2,
     "builds": [
       {
         "src": "**/*",
         "use": "@vercel/static"
       }
     ],
     "routes": [
       {
         "src": "/(.*)",
         "dest": "/$1"
       }
     ],
     "headers": [
       {
         "source": "/(.*)",
         "headers": [
           {
             "key": "Cross-Origin-Embedder-Policy",
             "value": "require-corp"
           },
           {
             "key": "Cross-Origin-Opener-Policy",
             "value": "same-origin"
           }
         ]
       }
     ]
   }
   ```

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
   - Upload entire `build/web/` directory
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

### 1. Analytics Setup

Configure analytics in `systems/Analytics.gd`:

```gdscript
# Enable analytics for production
const ANALYTICS_ENABLED = true

# Configure your analytics endpoint
const ANALYTICS_ENDPOINT = "https://your-analytics-service.com/api/events"
```

### 2. Error Reporting

Configure error reporting in `systems/ErrorHandler.gd`:

```gdscript
# Enable error reporting for production
const ERROR_REPORTING_ENABLED = true

# Configure your error reporting service
const ERROR_ENDPOINT = "https://your-error-service.com/api/errors"
```

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

Implement health check endpoints:

```gdscript
# In your web build, add health check functionality
func health_check() -> Dictionary:
    return {
        "status": "healthy",
        "version": ProjectSettings.get_setting("application/config/version"),
        "timestamp": Time.get_datetime_string_from_system(),
        "performance": PerformanceMonitor.get_performance_data()
    }
```

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
   cd build/web
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
cd build/web
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