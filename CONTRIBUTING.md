# Contributing

Thanks for your interest in improving Glitch Dimension! This guide helps you get productive quickly and make high‑quality changes.

## Setup

- Install Godot 4.4.
- Clone the repo and open `project.godot` in Godot.
- Optional: install Node.js if you plan to deploy with Vercel CLI or setup GitHub repo in the Vercel dashboard.

## Making Changes

- Keep changes focused and minimal; prefer small PRs.
- Follow Godot GDScript style and existing project conventions.
- Update or add documentation when introducing new features or behaviors.
- Test on both Desktop and Web exports when possible. There are some cases that the behavior may differ slightly for example for loading scenes and playing audio that happened on different platforms.

## Commit Messages

- Prefer Conventional Commits (e.g., `feat:`, `fix:`, `docs:`, `refactor:`).
- Include a brief rationale in the body if the change is non‑obvious.

## Pull Requests

- Title: concise summary (include scope where useful).
- Description: purpose, screenshots/GIFs for UI changes, testing notes.
- Checklist:
  - Project opens and runs without errors
  - Feature works on Main Menu → Level Select → Level
  - Saves/persistence remain intact (no data loss/regression)
  - Web export sanity: input, audio, pause, and results screens

## Adding Content

- Levels: prefer inheriting `levels/BaseLevel.gd` for consistent flow.
- Actors: follow existing patterns in `actors/` and make elements reusable and not linked to specific levels, this will help to easily create new levels by drag and drop to the editor view.
- Dimensions: use `DimensionManager` and `LayerObject` for layer‑specific behavior to make sure the dimension flip works correctly for new elements. All should have option to select layer A or B or Both.
- UI: reuse existing themes and patterns (see `ui/` and `docs/`).
- Audio: follow the conventions in `docs/audio-system.md`.
- Data: document any new fields in `docs/` and validate JSON.

## Reporting Issues

- Include Godot version, platform, reproduction steps, and logs (if any).
- Label bugs by area: `ui`, `audio`, `level`, `save`, `web`, `docs`.

## Code of Conduct

By participating, you agree to uphold the standards in `CODE_OF_CONDUCT.md`.
