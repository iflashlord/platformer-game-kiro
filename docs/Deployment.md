# Deployment Guide

## GitHub Actions CI/CD Pipeline

This project uses GitHub Actions to automatically build and deploy the HTML5 game to Vercel whenever code is pushed to the main branch.

### Required GitHub Secrets

You need to set up the following secrets in your GitHub repository settings:

#### 1. VERCEL_TOKEN
- **Purpose**: Authenticates with Vercel API for deployment
- **How to get**: 
  1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
  2. Click on your profile → Settings → Tokens
  3. Create a new token with appropriate scope
  4. Copy the token value

#### 2. VERCEL_ORG_ID
- **Purpose**: Identifies your Vercel organization/team
- **How to get**:
  1. Install Vercel CLI: `npm i -g vercel`
  2. Run `vercel login` and authenticate
  3. In your project directory, run `vercel link`
  4. Check `.vercel/project.json` for the `orgId` value

#### 3. VERCEL_PROJECT_ID
- **Purpose**: Identifies your specific Vercel project
- **How to get**:
  1. Same as above - run `vercel link` in your project
  2. Check `.vercel/project.json` for the `projectId` value

### Setting Up Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the exact names above

## Vercel Setup

### Initial Project Setup

1. **Create Vercel Account**
   - Sign up at [vercel.com](https://vercel.com)
   - Connect your GitHub account

2. **Import Project**
   - Click "New Project" in Vercel dashboard
   - Import your GitHub repository
   - Configure build settings (usually auto-detected)

3. **Configure Domain** (Optional)
   - Add custom domain in project settings
   - Update DNS records as instructed

### Project Configuration

The `vercel.json` file in the root directory configures:
- Static file serving
- CORS headers for Godot HTML5 export
- Caching policies
- Route handling

### Environment Variables

If your game needs environment variables:
1. Go to Vercel project settings
2. Add environment variables in the "Environment Variables" section
3. These will be available during build time

## Build Process

### Automated Workflow

The GitHub Action workflow (`deploy.yml`) performs these steps:

1. **Checkout Code**: Downloads repository content
2. **Setup Godot**: Uses `barichello/godot-ci:4.3` Docker image
3. **Export Game**: Builds HTML5 version using export presets
4. **Upload Artifacts**: Stores build files for download
5. **Deploy to Vercel**: Pushes build to Vercel using CLI

### Export Presets

The `export_presets.cfg` file defines build configurations for:
- **Web**: HTML5 export optimized for browsers
- **Windows**: Desktop executable
- **Linux**: Native Linux binary
- **macOS**: Mac application bundle

### Build Artifacts

Each successful build creates downloadable artifacts:
- `web-build`: HTML5 game files
- `windows-build`: Windows executable
- `linux-build`: Linux binary
- `mac-build`: macOS application

## Manual Deployment

### Local Build

```bash
# Install Godot (if not using Docker)
# Export the project
godot --headless --export-release "Web" build/web/index.html

# Deploy to Vercel
cd build/web
vercel --prod
```

### Using Vercel CLI

```bash
# Install Vercel CLI
npm i -g vercel

# Login to Vercel
vercel login

# Deploy from project root
vercel --prod
```

## Troubleshooting

### Common Issues

1. **Build Fails**
   - Check export presets are correctly configured
   - Ensure all required assets are included
   - Verify Godot version compatibility

2. **Deployment Fails**
   - Verify Vercel secrets are correctly set
   - Check Vercel project is properly linked
   - Ensure sufficient Vercel plan limits

3. **Game Won't Load**
   - Check browser console for errors
   - Verify CORS headers are set correctly
   - Ensure all game files are uploaded

4. **Performance Issues**
   - Enable gzip compression on Vercel
   - Optimize asset sizes
   - Use appropriate texture compression

### Debug Steps

1. **Check GitHub Actions Logs**
   - Go to Actions tab in GitHub repository
   - Click on failed workflow to see detailed logs

2. **Verify Vercel Deployment**
   - Check Vercel dashboard for deployment status
   - Review function logs if using serverless functions

3. **Test Locally**
   - Build and test HTML5 export locally
   - Use local web server to test: `python -m http.server`

## Performance Optimization

### Build Optimization

- Enable texture compression in export presets
- Minimize audio file sizes
- Use object pooling for frequently created objects
- Implement efficient asset loading

### Vercel Optimization

- Configure appropriate caching headers
- Use Vercel's Edge Network for global distribution
- Enable compression for static assets
- Monitor performance with Vercel Analytics

## Security Considerations

### Secrets Management

- Never commit secrets to repository
- Use GitHub's encrypted secrets feature
- Rotate tokens periodically
- Limit token permissions to minimum required

### CORS Configuration

- Set appropriate CORS headers for game assets
- Restrict origins if needed for security
- Use HTTPS for all external requests

## Monitoring and Analytics

### Vercel Analytics

- Enable Vercel Analytics in project settings
- Monitor page views, performance metrics
- Track user engagement and retention

### Error Tracking

- Implement error logging in game code
- Use Vercel's function logs for debugging
- Set up alerts for deployment failures

## Scaling Considerations

### Traffic Management

- Vercel automatically scales based on traffic
- Monitor bandwidth usage
- Consider CDN for large assets

### Cost Optimization

- Review Vercel pricing tiers
- Optimize build frequency
- Use appropriate caching strategies

## Support and Resources

- [Vercel Documentation](https://vercel.com/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Godot Export Documentation](https://docs.godotengine.org/en/stable/tutorials/export/index.html)
- [barichello/godot-ci](https://github.com/barichello/godot-ci)