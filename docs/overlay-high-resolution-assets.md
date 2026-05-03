# Overlay High-Resolution Assets

Codex Pet Overlay should not depend on scaling the standard Codex pet atlas for large desktop characters. The primary direction is an overlay-native high-resolution character asset system that can still coordinate with Codex.

## Why

The standard Codex pet package uses `192x208` cells. That is good for Codex-compatible pet folders, but it becomes visibly low-resolution when a detailed humanoid character such as Lucy is shown as a large desktop overlay.

## Target Model

Maintain two outputs, with overlay-native assets as the primary runtime path:

1. **Overlay high-resolution character asset**
   - Project-specific asset for this app.
   - Declares its own cell size, dimensions, and state mapping in a manifest.
   - Built from original generated row strips or dedicated high-resolution character images.
   - Used by the overlay app when available.

2. **Codex-compatible export**
   - Fixed `1536x1872` atlas.
   - Fixed `192x208` cells.
   - Useful for Codex compatibility, deterministic QA, and fallback rendering.

## Current Example

The current Lucy v2 2x overlay artifact is:

```text
output/lucy-v2/run/overlay-highres/2x/
  manifest.json
  spritesheet.png
  spritesheet.webp
```

It uses:

- Atlas size: `3072x3744`
- Cell size: `384x416`
- Grid: `8 columns x 9 rows`

This is better than the standard atlas, but it is still an intermediate path. For a large desktop character, a future dedicated overlay renderer may use higher-resolution per-state strips, independent frame sizes, or even separate still/animation assets instead of a strict Codex-style grid.

## Runtime Direction

Future runtime implementation should:

1. Look for an overlay high-resolution manifest first.
2. Load `spritesheet.webp` from that manifest.
3. Use manifest-declared cell dimensions rather than hard-coded `192x208`.
4. Fall back to the standard Codex pet package only when no overlay asset exists.
5. Keep Settings and validation messages explicit about whether the loaded asset is `Codex package` or `Overlay high-res`.

Keep these terms separate:

- `sourceScale`: how much larger the asset source is compared with the Codex
  `192x208` cells.
- `displayScale`: how much the app draws that already-high-resolution source on
  screen.

A `2x` source with `displayScale = 1.0` should draw at `384x416` per frame. A
`2x` source with `displayScale = 2.0` draws at `768x832`, which may be larger
than intended.

The overlay manifest should include a state-to-row mapping. This is important
because current runtime docs and hatch outputs have had row-order drift. Do not
use remembered row order as the source of truth.

## Generation Direction

Use `skills/pet-overlay-direct-base-hatch/` for generation work. The important rule is:

Do not upscale `final/spritesheet.webp` as the source of truth. Build overlay high-resolution assets from `decoded/<state>.png` row strips or from newly generated high-resolution overlay character images.

Do not invoke the original user/global `hatch-pet` skill as the governing workflow for this repo. Use the repo-local `skills/pet-overlay-direct-base-hatch/` workflow and evolve it toward overlay-native assets first, with Codex-compatible export second.
