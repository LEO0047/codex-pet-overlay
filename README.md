# Codex Pet Overlay

Codex Pet Overlay is an unofficial macOS desktop character overlay that can
coordinate with the Codex app.
It does not modify, inject into, or patch Codex.app.
It only observes public window/accessibility state when permission is granted.

The project is moving toward its own overlay-native high-resolution character
asset system. Codex-compatible pet atlases remain useful as a bridge and
fallback, but they are no longer the main product model.

## Screenshot / GIF Placeholders

Release media is not checked in yet. When screenshots or short demos are ready,
place them under `docs/media/` and link them here:

- `docs/media/overlay-screenshot.png` for the desktop overlay.
- `docs/media/settings-screenshot.png` for Settings.
- `docs/media/codex-sync-demo.gif` for heuristic Codex state changes.
- `docs/media/click-through-recovery.gif` for recovery from click-through mode.

## Quick Start

```bash
git clone https://github.com/LEO0047/codex-pet-overlay.git
cd codex-pet-overlay
./script/build_and_run.sh --verify
```

The app launches as a normal macOS Dock app and creates
`dist/Codex Pet Overlay.app`. The bundled Lucy v2 demo asset is used by default.

Accessibility permission is optional. Without it, the overlay still opens and
manual animation controls remain available. With it, the app can read public
Codex window text and choose an animation state using configurable heuristic
rules.

## Features

- Native Swift macOS Dock app.
- Transparent always-on-top desktop overlay.
- Drag to reposition, with multi-display position recovery.
- Scale from `1.0x` to `4.0x`; default is `2.0x`.
- Right-click menu for settings, animation switching, and click-through recovery.
- Optional click-through mode using `NSWindow.ignoresMouseEvents`.
- Settings window with pet folder, scale, window level, status bubble, and state detection controls.
- Read-only Accessibility observation of the Codex window.
- Configurable state rules in `config/state-rules.json`.

## Build And Run

```bash
./script/build_and_run.sh --verify
```

The script builds the SwiftPM executable, creates a real `.app` bundle at
`dist/Codex Pet Overlay.app`, launches it, and verifies the bundle/process.
If the local Command Line Tools installation has a broken SwiftPM manifest API,
the script falls back to direct `swiftc` compilation while keeping the package
layout intact.

To build the bundle without launching it, run:

```bash
./script/make_app_bundle.sh
```

To create a local release zip without notarization, run:

```bash
./script/package_release.sh
```

See `docs/release.md` for the release packaging checklist.

## Asset Model

The product has two asset layers:

- **Overlay-native high-resolution assets:** the intended primary desktop
  display path, described by this repo's high-resolution manifest and runtime
  loader. These assets keep `sourceScale` separate from the on-screen
  `displayScale`.
- **Codex-compatible exports:** optional compatibility artifacts using the Codex
  pet atlas contract. They remain useful for fallback rendering, deterministic
  QA, and compatibility exports.

The compatibility contract is:

- Atlas: `1536x1872`
- Grid: `8 columns x 9 rows`
- Cell: `192x208`
- Background: transparent

If a selected compatibility folder does not match this contract, the app shows a
clear error instead of silently failing.

The desktop overlay direction is different from the Codex compatibility
contract: large on-screen characters should use overlay-native high-resolution
assets when available, with the Codex atlas kept as a compatibility fallback.
See `docs/overlay-high-resolution-assets.md`.

The runtime now prefers an overlay-specific manifest when available, then falls
back to the standard Codex-compatible `spritesheet.webp` only when no overlay
asset exists. Settings shows which asset kind is currently loaded.

## Lucy v2 Artifacts

The bundled Lucy v2 demo asset is mirrored in a few repo artifacts so future
contributors can inspect the package and QA trail without rerunning the pet
generation pipeline:

- `output/lucy-v2/pet-package/` contains the distributable pet folder shape:
  `spritesheet.webp` plus `pet.json`.
- `output/lucy-v2/run/final/validation.json` records atlas validation results
  for the final spritesheet.
- `output/lucy-v2/run/qa/review.json` records per-row and per-frame QA metadata.
- `output/lucy-v2/run/overlay-highres/2x/` contains the current experimental
  overlay-specific high-resolution atlas and manifest.
- `skills/codex-pet-overlay-runtime/` documents the app maintenance workflow
  for Settings, click-through recovery, Accessibility, rendering, memory, build,
  and launch work.
- `skills/pet-overlay-direct-base-hatch/` documents the controlled direct-base workflow
  used when creating or repairing a pet from an already-approved base image.

## Accessibility

Codex UI detection is heuristic and configurable. It is not a full AXObserver
implementation. If Codex changes its window text, update
`config/state-rules.json` and rebuild/relaunch the app bundle.

The app does not read secrets and does not modify Codex. If Accessibility
permission is unavailable or revoked, it falls back to manual animation control.

See `docs/accessibility.md` for the permission model.

## Troubleshooting

See `docs/troubleshooting.md` for common issues:

- The app launches but no overlay appears.
- Lucy looks too large, too small, or blurry.
- Click-through mode makes the overlay hard to recover.
- Accessibility permission is needed or was denied.
- The selected pet folder is invalid or stale.
- Codex is not running, or heuristic state detection does not change.
- Green background / chroma key artifacts in capture workflows.

## License

Code is licensed under MIT. The bundled Lucy v2 asset is governed separately by
`ASSET_LICENSE`; it is not automatically covered by the MIT license.
