# Asset Requirements for Web Deployment

## Web Export Assets

The exported web game is placed in `web-dist/` (index.html/js/wasm/pck). If you use a custom HTML shell, include:

### Favicon
- **Path**: `web-dist/favicon.ico`
- **Size**: 16x16, 32x32, 48x48
- **Format**: ICO

### Preview Image (optional)
- **Path**: `web-dist/preview.png`
- **Size**: 1200x630 (Open Graph)
- **Format**: PNG

### App Icons (optional PWA)
- **144x144**: `web-dist/icon-144.png`
- **180x180**: `web-dist/icon-180.png`
- **512x512**: `web-dist/icon-512.png`

## Creating Assets

### Favicon Generation
```bash
# Using ImageMagick to create favicon from PNG
convert icon.png -resize 16x16 favicon-16.png
convert icon.png -resize 32x32 favicon-32.png
convert icon.png -resize 48x48 favicon-48.png
convert favicon-16.png favicon-32.png favicon-48.png favicon.ico
```

### Preview Image
- Use game screenshot or promotional art
- Include game title and key visual elements
- Ensure text is readable at small sizes
- Test on various social platforms

### Optimization
- Use PNG for images with transparency
- Use JPEG for photographic content
- Compress images without quality loss
- Consider WebP format for modern browsers

## Asset Integration

### HTML Meta Tags (if using a custom shell)
```html
<link rel="icon" type="image/x-icon" href="/favicon.ico">
<link rel="apple-touch-icon" sizes="180x180" href="/icon-180.png">
<meta property="og:image" content="/preview.png">
```

### Vercel Configuration
`vercel.json` configures headers/MIME/caching for Godot’s web export.

## Asset Checklist

- [ ] Favicon created and optimized
- [ ] Preview image designed and tested
- [ ] App icons generated for PWA
- [ ] All images compressed
- [ ] Meta tags updated in HTML
- [ ] Assets tested in browser
- [ ] Social sharing preview verified
