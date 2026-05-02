# Codex Pet Overlay Handoff

## Current State

This repo is a first-pass MVP, not a polished product.

Public repo:

- GitHub: https://github.com/LEO0047/codex-pet-overlay
- Local iCloud path: `/Users/leo/Library/Mobile Documents/com~apple~CloudDocs/Coding/Projects/codex-pet-overlay`
- Original scratch path: `/Users/leo/Documents/Codex/2026-05-03/files-mentioned-by-the-user-2026/codex-pet-overlay`
- Current commit: `14f0cc6c8ef03f1916c3be527ac97d7b70bd0764`

What exists:

- Native Swift/AppKit macOS Dock app entrypoint.
- Transparent always-on-top overlay window.
- Lucy v2 bundled asset under `Assets/lucy-v2/`.
- Basic sprite animation from the Codex pet atlas.
- Basic Settings window.
- Right-click menu on the pet when click-through is off.
- Click-through toggle using `NSWindow.ignoresMouseEvents`.
- Accessibility polling skeleton for Codex window text.
- Configurable heuristic rules in `config/state-rules.json`.
- Bundle build scripts under `script/`.
- README, MIT license, asset license, and basic docs.

## Important Reality Check

The app is intentionally functional but rough. The initial goal was to prove the path:

1. Do not patch Codex.app.
2. Build a separate desktop overlay.
3. Bundle it as a real `.app`.
4. Publish a public repo.

It does not yet feel like a delightful desktop pet. The interaction model, animation behavior, and Codex state sync need product work.

## Build And Run

Primary command:

```bash
./script/build_and_run.sh --verify
```

Expected behavior:

- Builds the executable.
- Creates `dist/Codex Pet Overlay.app`.
- Launches the app.
- Verifies the process and bundle metadata.

Known local toolchain issue:

- On this machine, plain `swift build` currently fails because Command Line Tools has a broken SwiftPM `PackageDescription` manifest link path.
- `script/make_app_bundle.sh` catches that failure and falls back to direct `swiftc` compilation.
- Do not remove the fallback unless SwiftPM is verified on the target machine.

## Architecture

Main areas:

- `Sources/CodexPetOverlay/App/`
  App entrypoint, `AppDelegate`, app menu, settings window, overlay boot.
- `Sources/CodexPetOverlay/Overlay/`
  `NSPanel` / `NSView` overlay behavior, drawing, drag, context menu.
- `Sources/CodexPetOverlay/Animation/`
  Codex pet atlas row/frame model and frame timer.
- `Sources/CodexPetOverlay/Pet/`
  Pet folder loading and fixed atlas validation.
- `Sources/CodexPetOverlay/Accessibility/`
  AX permission helper, Codex app polling, heuristic state detector.
- `Sources/CodexPetOverlay/Settings/`
  Settings model and SwiftUI settings view.

The app currently copies `Assets/` and `config/` into `Contents/Resources/` during bundle creation. Runtime asset loading assumes the `.app` bundle path, not raw executable launch.

## Known Limitations

High-priority issues:

- Changing `petFolderPath` in Settings does not hot-reload the sprite. It likely requires restart right now.
- Manual animation selection can be overridden by Accessibility detection when detection is enabled.
- Accessibility sync is shallow polling, not a robust observer.
- The app does not yet have a first-run permission flow good enough for normal users.
- There is no global shortcut to recover from click-through mode.
- The Dock menu recovery path exists, but it is basic.
- No CI, no automated UI tests, no notarization, no release artifact.
- No real app icon design; current icon was generated from the spritesheet.
- `swift build` failure is documented but still ugly for contributors who expect pure SwiftPM.
- Settings UI is utilitarian and not product-polished.

Medium-priority issues:

- Multi-display recovery exists but needs real-world testing.
- Space/fullscreen behavior needs testing.
- Retina/pixel rendering should be visually checked and probably made configurable.
- Status bubble is very basic.
- Window level options are rough.
- Animation frame timing is fixed.
- No support for multiple named pets beyond manually setting a folder path.
- `pet.json` is not fully used yet.

## Recommended Next Work

Do these before adding more novelty:

1. Make Settings actually apply changes live.
   - Hot-reload `petFolderPath`.
   - Reload atlas validation errors into the UI instead of only alerting on launch.
   - Make manual state selection disable or temporarily pause auto detection.

2. Improve click-through recovery.
   - Add a Dock menu item that reliably opens Settings and disables click-through.
   - Consider a global hotkey only after the menu path is solid.

3. Make Codex state detection less fake.
   - Replace shallow full-tree polling with a more targeted AX observer if possible.
   - Display current detected state in Settings.
   - Add a debug panel showing matched rule and matched text.

4. Productize the overlay behavior.
   - Better scale controls.
   - Better drag affordance.
   - Better bubble styling.
   - Pause/play animation control.
   - Optional "snap to screen edge" or "stay above Dock" behavior.

5. Clean up build story.
   - Test on a machine with full Xcode or healthy SwiftPM.
   - Decide whether to keep direct `swiftc` fallback permanently.
   - Add GitHub Actions only once the SwiftPM path is known to work in CI.

6. Add release packaging.
   - Create zipped `.app` artifact.
   - Add versioning.
   - Decide whether to notarize later.

## Verification Checklist For Next Agent

Run:

```bash
git status --short --branch
./script/build_and_run.sh --verify
```

Then manually verify:

- App appears in Dock.
- Settings window opens from app menu.
- Lucy overlay appears and animates.
- Dragging works when click-through is off.
- Right-click menu works when click-through is off.
- Click-through can be disabled from app menu or Settings.
- Wrong pet folder shows a clear validation error.
- Codex not running does not crash the app.
- Accessibility permission denial does not crash the app.

## Constraints

- Do not patch, inject into, or modify `/Applications/Codex.app`.
- Keep Codex integration read-only.
- Keep `Lucy v2` asset licensing separate from MIT code licensing unless the owner explicitly changes that policy.
- Do not push new changes without explicit user approval.

