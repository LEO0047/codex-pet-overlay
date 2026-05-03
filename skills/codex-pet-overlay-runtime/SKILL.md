---
name: codex-pet-overlay-runtime
description: Maintain and debug the Codex Pet Overlay macOS app runtime. Use for Settings, Dock/app menu recovery, click-through, Accessibility permission state, overlay scale/window behavior, memory/performance, Swift/AppKit/SwiftUI code, and build/run verification. Do not use for pet generation or Lucy asset repair.
---

# Codex Pet Overlay Runtime

Use this skill when working on the macOS app itself:

- Settings window behavior
- Dock menu, app menu, right-click menu, and click-through recovery
- Accessibility permission prompts, state detection, and `AX permission needed`
- overlay scale, status bubble, position, window level, and rendering
- low-resolution, pixelated, blurry, or over-scaled pet rendering
- memory, crash, build, launch, and runtime verification

Do not use this skill to generate, repair, or repackage pet assets. For approved-base pet generation work, use `skills/pet-overlay-direct-base-hatch/` instead.

## Boundaries

- Do not patch, inject into, or modify `/Applications/Codex.app`.
- Keep Codex integration read-only.
- Do not change the Lucy v2 asset license policy.
- Do not commit, push, create PRs, or deploy unless explicitly approved.
- Preserve the SwiftPM plus `.app` bundle script workflow.
- The repo may live under an iCloud path with spaces; quote paths and use shell arrays in scripts.

## First Checks

Before changing code:

```bash
git status --short --branch
./script/build_and_run.sh --verify
```

If the report is about the app being unclickable, also check:

```bash
defaults read com.leo0047.codex-pet-overlay clickThrough 2>/dev/null || true
defaults read com.leo0047.codex-pet-overlay scale 2>/dev/null || true
pgrep -fl CodexPetOverlay || true
```

## Common Runtime Triage

For `Settings...` cannot be clicked:

- Check whether `clickThrough` is enabled.
- Ensure Settings is available from the app menu and Dock right-click menu, not only from the overlay right-click menu.
- Menu items that call `AppDelegate` actions should set `target = self`.
- `Disable Click-through` must remain reachable without clicking the overlay.

For `AX permission needed`:

- Treat this as a macOS Accessibility permission state, not a pet generation issue.
- The bubble means Codex state detection cannot read AX state yet; it does not mean the pet atlas is broken.
- The app must not crash or block manual animation when permission is missing.
- Keep the fallback path clear: manual animation and Settings must still work.

For low-resolution, pixelated, or blurry pet rendering:

- First identify whether the app is enlarging a Codex pet atlas frame beyond its native `192x208` cell size. A large overlay at `3x` or `4x` will expose the atlas resolution limit.
- Do not rerun pet generation unless the source atlas itself is wrong. For overlay display quality, the runtime choices are scale, interpolation, Retina/backing behavior, or an overlay-specific high-resolution asset path.
- For detailed non-pixel-art pets like Lucy v2, prefer smooth scaling (`CGContext.interpolationQuality = .high`) over hard nearest-neighbor scaling.
- For true pixel-art pets, nearest-neighbor may still be appropriate, so a future rendering-quality setting is better than a one-size-fits-all policy.
- If the user wants a large desktop character, treat that as a separate high-resolution overlay asset requirement, not as the standard Codex `1536x1872` pet package contract.

For excessive scale or huge overlay:

- Prefer safe defaults such as `scale = 2.0`.
- Keep slider bounds conservative and avoid writing a `@Published` property to itself inside `didSet`.
- If the current user defaults are broken, reset only the affected app defaults.

For memory or renderer problems:

- Inspect the drawing path before changing assets.
- Prefer caching decoded/cropped frames once at startup over repeatedly decoding or scaling the full atlas every animation tick.
- After launch, sample RSS with:

```bash
ps -axo pid,rss,vsz,comm | rg 'CodexPetOverlay'
```

## Verification

Use the smallest checks that prove the fix:

```bash
./script/build_and_run.sh --verify
git diff --check
```

For JSON metadata edits:

```bash
ruby -rjson -e 'ARGV.each { |f| JSON.parse(File.read(f)); puts "ok #{f}" }' <files>
```

Manual verification should include:

- app appears in Dock
- Settings opens from app menu or `Cmd+,`
- Settings opens from Dock right-click menu
- click-through can be disabled without clicking the overlay
- scale changes do not crash
- detailed pets do not render with obvious hard pixel enlargement at the intended default scale
- `AX permission needed` does not crash the app
