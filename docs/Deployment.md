# Deployment (Deprecated)

This document is superseded by `docs/deployment-guide.md`.

Quick start for web:

```bash
godot --headless --export-release "Web" web-dist/index.html
cd web-dist
vercel --prod
```

For headers and caching, see the `vercel.json` in the project root. For optimization tips, see `docs/web-optimization.md`.
