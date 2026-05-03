# Pet Contract

Codex Pet Overlay currently supports the same atlas shape used by Codex custom
pets. This is the compatibility contract, not the desired long-term desktop
overlay art contract.

| Field | Value |
| --- | --- |
| Format | PNG or WebP |
| Atlas size | `1536x1872` |
| Columns | `8` |
| Rows | `9` |
| Cell size | `192x208` |
| Background | Transparent |

Rows are interpreted as:

1. `idle`
2. `running-right`
3. `running-left`
4. `running`
5. `waiting`
6. `waving`
7. `jumping`
8. `failed`
9. `review`

Each pet folder should contain:

```text
pet-folder/
  pet.json
  spritesheet.webp
```

The first version only requires `spritesheet.webp`; `pet.json` is useful for
human context but not required by the renderer.

## Overlay High-Resolution Contract

For large desktop characters, do not rely on scaling the standard `192x208`
cells. Use an overlay-specific asset manifest instead.

Recommended fields:

```json
{
  "kind": "codex-pet-overlay-highres-atlas",
  "spritesheetPath": "overlay-highres/2x/spritesheet.webp",
  "columns": 8,
  "rows": 9,
  "cellWidth": 384,
  "cellHeight": 416,
  "sourceScale": 2,
  "defaultDisplayScale": 1.0,
  "stateRowMap": {
    "idle": 0,
    "running-right": 1,
    "running-left": 2,
    "waving": 3,
    "jumping": 4,
    "failed": 5,
    "waiting": 6,
    "running": 7,
    "review": 8
  }
}
```

Important distinction:

- `sourceScale` describes the asset resolution relative to the Codex `192x208`
  cell contract.
- `defaultDisplayScale` describes how large the app should draw the asset on
  screen.

Do not merge those concepts into one `scale` field. A `2x` source drawn at
`2.0x` display scale becomes visually equivalent to `4x` relative to the Codex
cell size.
