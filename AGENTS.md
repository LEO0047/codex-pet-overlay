# Codex Pet Overlay Agent Instructions

## Scope

These instructions apply to this repository:

`/Users/leo/Library/Mobile Documents/com~apple~CloudDocs/Coding/Projects/codex-pet-overlay`

This repo builds an unofficial standalone macOS overlay app that can coordinate with Codex. It must not patch, inject into, modify, or automate private internals of `/Applications/Codex.app`.

## Product Identity

This project is no longer just a wrapper around the original Codex custom pet system. Treat it as an independent overlay-native character system.

Codex integration is still important, but it is a bridge:

- Codex provides optional read-only state signals through macOS Accessibility.
- Codex-compatible pet export can remain as an optional compatibility artifact.
- The primary runtime, asset format, generation workflow, and QA rules belong to this repo.

Do not use the built-in or user-installed `~/.codex/skills/hatch-pet` workflow as the authority for this project unless the user explicitly asks for Codex custom pet compatibility work. Use the repo-local skills and docs here as the source of truth.

## Core Direction

The product direction is now:

1. Build a standalone overlay character runtime with its own asset contract.
2. Use overlay-specific high-resolution character assets as the primary display path.
3. Keep a Codex-compatible package only as a compatibility/export layer when useful.
4. Do not rely on enlarging the standard `192x208` Codex pet cells for large on-screen characters.

The Codex custom pet atlas contract remains useful as a bridge, but it is not the product's main contract. Future work should make the app prefer overlay-specific high-resolution assets when available, and fall back to the standard Codex atlas only when no overlay asset exists.

## App Data Flow

Current runtime flow:

```text
AppSettings/UserDefaults
  -> PetFolderLoader
  -> SpriteAtlas validates and crops the selected spritesheet
  -> SpriteOverlayView draws the current frame
  -> OverlayPanelController hosts the transparent NSPanel

SpriteAnimator timer
  -> frameIndex
  -> SpriteOverlayView redraw

CodexAccessibilityObserver
  -> observed Codex UI text
  -> CodexStateDetector rules
  -> AppDelegate.applyAnimationState
  -> SpriteOverlayView.animationState + statusText
```

This data flow is still standard-atlas oriented today. The intended next runtime change is to add an overlay asset descriptor/manifest before `SpriteAtlas` so the renderer can load project-native high-resolution assets.

## Repository Areas

- `Sources/CodexPetOverlay/App/`
  App entrypoint, `AppDelegate`, menu setup, settings window, overlay launch, Accessibility observer lifecycle.
- `Sources/CodexPetOverlay/Overlay/`
  Borderless `NSPanel`, sprite drawing, drag behavior, right-click menu, click-through recovery.
- `Sources/CodexPetOverlay/Animation/`
  Animation state names, frame timer, atlas frame access.
- `Sources/CodexPetOverlay/Pet/`
  Pet folder loading and atlas validation.
- `Sources/CodexPetOverlay/Accessibility/`
  Read-only AX permission check, Codex UI text polling, state rule matching.
- `Sources/CodexPetOverlay/Settings/`
  User defaults, scale, click-through, manual state, SwiftUI settings UI.
- `Assets/lucy-v2/`
  Bundled demo asset used by the app.
- `output/lucy-v2/`
  Auditable Lucy v2 generation outputs, QA files, source images, package, and overlay high-res artifacts.
- `skills/codex-pet-overlay-runtime/`
  Repo-local skill for app runtime work.
- `skills/pet-overlay-direct-base-hatch/`
  Repo-local skill for approved-base pet generation and overlay high-resolution asset generation.

## Asset Contracts

There are two asset layers. Keep them separate.

### Overlay-Native Asset

Purpose: high-quality desktop overlay rendering. This is the primary product asset.

- Uses this repo's manifest/descriptor, not the original Codex pet assumptions.
- May use larger cells, per-state strips, high-resolution atlases, or a future non-grid format.
- Must declare state-to-frame mapping explicitly.
- Must keep `sourceScale` separate from `displayScale`.
- Current generated example:
  - `output/lucy-v2/run/overlay-highres/2x/spritesheet.webp`
  - `output/lucy-v2/run/overlay-highres/2x/manifest.json`

### Codex-Compatible Export

Purpose: optional compatibility with Codex custom pet folders and deterministic QA.

- Atlas size: `1536x1872`
- Grid: `8 columns x 9 rows`
- Cell: `192x208`
- Main output example: `output/lucy-v2/pet-package/spritesheet.webp`
- Validation examples:
  - `output/lucy-v2/run/final/validation.json`
  - `output/lucy-v2/run/qa/review.json`

If implementing runtime support, the preferred behavior is:

1. Load an overlay-specific manifest/spritesheet when present.
2. Use that asset's declared cell size and row/frame metadata.
3. Fall back to the standard Codex `spritesheet.webp` only if no overlay asset exists.
4. Keep user-facing validation errors clear about which contract failed.

Keep terminology strict:

- `sourceScale` means asset resolution relative to the Codex `192x208` cell.
- `displayScale` means the app's on-screen drawing scale.
- Do not reuse one `scale` setting for both concepts.

Overlay-first manifests should eventually include a `stateRowMap` or equivalent row descriptor. Do not trust hard-coded row order when loading overlay-specific assets.

## Skills

Use the repo-local skills intentionally:

- Use `skills/codex-pet-overlay-runtime/` for macOS app behavior, Settings, click-through, Accessibility, rendering, memory, build, and launch work.
- Use `skills/pet-overlay-direct-base-hatch/` for repo-local overlay character asset generation, direct-base seeding, Lucy asset repair, high-resolution overlay output, and optional Codex-compatible export.

Do not confuse these with built-in Codex skills. They are project-specific. If wording in an older script says `hatch-pet`, treat it as inherited implementation detail, not as the governing workflow.

## Accessibility

`AX permission needed` is a macOS Accessibility permission/status signal, not a pet generation failure.

Rules:

- The app must keep working without Accessibility permission.
- Manual animation and Settings must remain reachable.
- Do not block the overlay just because AX permission is missing.
- Keep Codex observation read-only.

## Build And Verification

Start most implementation tasks with:

```bash
git status --short --branch
```

For app/runtime changes, run:

```bash
./script/build_and_run.sh --verify
git diff --check
```

This repo may live under an iCloud path containing spaces. Always quote paths in shell commands. When passing file lists in Bash scripts, use arrays; do not use unquoted command substitution such as `$(find ...)`.

Known local behavior: `swift build` may fail on this machine because of Command Line Tools / SwiftPM manifest issues. `script/make_app_bundle.sh` has a direct `swiftc` fallback. Do not remove that fallback unless SwiftPM is verified on the target machine.

For pet-generation artifacts, run focused checks such as:

```bash
python3 skills/pet-overlay-direct-base-hatch/scripts/pet_job_status.py --run-dir output/lucy-v2/run
ruby -rjson -e 'ARGV.each { |f| JSON.parse(File.read(f)); puts "ok #{f}" }' \
  output/lucy-v2/run/final/validation.json \
  output/lucy-v2/run/qa/review.json
```

For overlay high-resolution assets, verify manifest JSON and image dimensions:

```bash
ruby -rjson -e 'JSON.parse(File.read("output/lucy-v2/run/overlay-highres/2x/manifest.json")); puts "ok"'
```

For future overlay manifests, also verify that `stateRowMap` or equivalent state descriptors match the renderer's `AnimationState` mapping before accepting runtime changes.

## Working Rules

- Do not commit, push, create PRs, publish, or deploy unless the user explicitly asks.
- Preserve unrelated user changes. This repo may have active uncommitted work.
- Do not delete generated assets unless the user explicitly asks or the replacement is clearly part of the requested asset workflow.
- Keep `Lucy v2` asset licensing separate from MIT code licensing unless the owner explicitly changes that policy.
- When a task involves long-running work or subagents, use the `codex-long-running-workflow` patience rules: do not duplicate silent subagent work, and ask once for progress before replacing a slow worker.
- Prefer smallest coherent changes. Do not redesign runtime and asset pipeline in the same patch unless requested.

## Current Architectural Risks

- Settings changes are not fully live-applied; `petFolderPath` likely still requires restart.
- Accessibility observation is shallow polling, not a robust AX observer.
- Runtime support for overlay-specific high-resolution assets is not complete yet. The next implementation should add a loader/manifest path instead of only drawing the standard Codex atlas.
- Row ordering currently has drift risk. Runtime/docs historically used `idle, running-right, running-left, running, waiting, waving, jumping, failed, review`, while the hatch/Lucy v2 output uses `idle, running-right, running-left, waving, jumping, failed, waiting, running, review`. Future runtime work should make manifest `stateRowMap` the authority and then align code, docs, validation, and generated assets.
