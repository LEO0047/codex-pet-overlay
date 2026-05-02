# Accessibility

Codex Pet Overlay can observe Codex window text through macOS Accessibility.
This is read-only and optional.

The app uses the observed text with `config/state-rules.json` to choose an
animation state. The rules are intentionally configurable because Codex UI text
can change across app releases.

If permission is not granted, the app still works:

- The overlay remains visible.
- Right-click and settings controls still work.
- Animation state can be selected manually.
- Codex state detection is skipped.

The app does not patch, inject into, or modify Codex.app.
