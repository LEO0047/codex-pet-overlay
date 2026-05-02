# Pet Contract

Codex Pet Overlay expects the same atlas shape used by Codex custom pets.

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
