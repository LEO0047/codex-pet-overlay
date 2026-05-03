# Release Packaging

This repo does not have notarization yet. Release artifacts are local zip files
created from the built `.app` bundle.

## Build

Build the app bundle without launching it:

```bash
./script/make_app_bundle.sh
```

The bundle is written to:

```text
dist/Codex Pet Overlay.app
```

For the standard build, launch, and process verification path, run:

```bash
./script/build_and_run.sh --verify
```

## Package Zip

Create a zip under `dist/`:

```bash
./script/package_release.sh
```

The script:

- Calls `script/make_app_bundle.sh`.
- Reads the version from `dist/Codex Pet Overlay.app/Contents/Info.plist`.
- Creates a timestamped zip under `dist/`.
- Uses quoted paths so the iCloud workspace path and app name with spaces are
  handled safely.
- Does not notarize.

Manual equivalent:

```bash
./script/make_app_bundle.sh
ditto -c -k --norsrc --keepParent \
  "dist/Codex Pet Overlay.app" \
  "dist/Codex Pet Overlay.zip"
```

## Verify Version

After building, verify the version from the app bundle:

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  "dist/Codex Pet Overlay.app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' \
  "dist/Codex Pet Overlay.app/Contents/Info.plist"
```

Current checked-in bundle metadata is `CFBundleShortVersionString=0.1.0` and
`CFBundleVersion=1`.

## Notarization Status

No notarization flow exists yet. Do not claim that local zips are notarized or
ready for Gatekeeper-smooth distribution.

Future notarization work should add signing identity selection, hardened runtime
settings, notarization submission, stapling, and verification as a separate
release phase.
