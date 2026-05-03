# Troubleshooting

Codex Pet Overlay is a standalone macOS overlay app. It does not patch, inject
into, or modify Codex.app.

## App Does Not Appear

Run the standard verification command:

```bash
./script/build_and_run.sh --verify
```

Check these items:

- Look for `Codex Pet Overlay` in the Dock and app switcher.
- Open the app menu and use Settings if the overlay is off-screen.
- If the pet was dragged to another display, relaunching should recover the
  saved position to a visible screen when possible.
- Confirm the bundle exists at `dist/Codex Pet Overlay.app`.

If the process is not running, rebuild and relaunch with the command above.

## Lucy Is Too Large Or Blurry

The runtime prefers overlay high-resolution assets, but it can still fall back
to Codex-compatible `192x208` cells. Large display scales can make fallback
cells look blurry.

Try this:

- Lower the Settings scale.
- Check Settings and confirm the current asset kind is `Overlay high-res atlas`.
- Keep `sourceScale` and `displayScale` separate. A `2x` source drawn at `2.0x`
  display scale can become much larger than intended.

See `docs/overlay-high-resolution-assets.md` for the asset model.

## Click-Through Trapped Me

Click-through mode uses `NSWindow.ignoresMouseEvents`, so the pet may stop
receiving clicks.

Recovery options:

- Use the Dock app menu or Settings to turn click-through off.
- Relaunch the app if the menu path is not reachable.
- Keep click-through off while testing drag, scale, or right-click behavior.

There is no global recovery shortcut yet.

## Accessibility Permission Needed

Accessibility permission is optional. Without it:

- The overlay still works.
- Manual animation controls still work.
- Codex state detection is skipped.

With permission, the app reads public Codex window text and matches it against
`config/state-rules.json`. This is heuristic polling, not a full AXObserver.

If macOS reports permission is needed, grant permission in System Settings, then
quit and relaunch the app.

## Wrong Pet Folder

A Codex-compatible pet folder should contain a valid `spritesheet.webp` using
the compatibility atlas contract:

- Atlas: `1536x1872`
- Grid: `8 columns x 9 rows`
- Cell: `192x208`
- Background: transparent

If Settings points at the wrong folder, choose the pet package folder itself,
not a parent output directory. The bundled demo asset is under `Assets/lucy-v2/`.

After changing the path, use `Reload Pet` in Settings. If stale bundled
resources are suspected, rebuild and relaunch with `./script/build_and_run.sh
--verify`.

## Codex Not Running

Codex is optional. If Codex is not running:

- The overlay should continue animating.
- Manual animation selection remains available.
- Automatic state detection may stay idle or show no detected state.

Start Codex and relaunch Codex Pet Overlay if you need state detection.

## Green Background Or Chroma Key Artifacts

The app window is intended to be transparent. Overlay high-resolution manifests
can declare `chroma_key_rgb` and `chroma_threshold`; the runtime applies that
key before drawing. A visible green background usually means a stale build,
missing manifest metadata, or capture/compositing settings.

Check these items:

- Rebuild the app bundle if stale resources were copied into `dist/`.
- Check Settings and confirm the current asset kind is `Overlay high-res atlas`.
- Confirm the selected overlay manifest includes `chroma_key_rgb` and
  `chroma_threshold`.
- Disable conflicting chroma key filters in the recording or streaming tool.
- Capture the transparent window directly when possible.
