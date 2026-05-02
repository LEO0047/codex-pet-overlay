# Codex Pet Overlay

Codex Pet Overlay is an unofficial macOS companion app for the Codex app.
It does not modify, inject into, or patch Codex.app.
It only observes public window/accessibility state when permission is granted.

The app displays a larger desktop overlay pet using the same Codex pet atlas
shape. It ships with a Lucy v2 demo asset and can also load a local pet folder
such as `~/.codex/pets/lucy`.

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

## Pet Contract

Custom pet folders must contain `spritesheet.webp` using the Codex pet atlas
contract:

- Atlas: `1536x1872`
- Grid: `8 columns x 9 rows`
- Cell: `192x208`
- Background: transparent

If a selected folder does not match this contract, the app shows a clear error
instead of silently failing.

## Accessibility

Codex UI detection is heuristic and configurable. If Codex changes its window
text, update `config/state-rules.json` and rebuild/relaunch the app bundle.

The app does not read secrets and does not modify Codex. If Accessibility
permission is unavailable or revoked, it falls back to manual animation control.

## License

Code is licensed under MIT. The bundled Lucy v2 asset has separate terms in
`ASSET_LICENSE`.
