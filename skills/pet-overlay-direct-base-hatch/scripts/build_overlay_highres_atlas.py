#!/usr/bin/env python3
"""Build a larger overlay-specific atlas from generated row strips."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

from PIL import Image

BASE_CELL_WIDTH = 192
BASE_CELL_HEIGHT = 208
ATLAS_COLUMNS = 8
ATLAS_ROWS = 9
ROWS = [
    ("idle", 6),
    ("running-right", 8),
    ("running-left", 8),
    ("waving", 4),
    ("jumping", 5),
    ("failed", 8),
    ("waiting", 6),
    ("running", 6),
    ("review", 6),
]


def load_json(path: Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def chroma_from_request(run_dir: Path) -> tuple[int, int, int]:
    request_path = run_dir / "pet_request.json"
    if request_path.exists():
        request = load_json(request_path)
        chroma = request.get("chroma_key")
        if isinstance(chroma, dict) and isinstance(chroma.get("rgb"), list):
            rgb = chroma["rgb"]
            if len(rgb) == 3 and all(isinstance(value, int) for value in rgb):
                return int(rgb[0]), int(rgb[1]), int(rgb[2])
    return 0, 255, 0


def remove_chroma(image: Image.Image, chroma: tuple[int, int, int], threshold: int) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    cr, cg, cb = chroma
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            distance = math.sqrt((r - cr) ** 2 + (g - cg) ** 2 + (b - cb) ** 2)
            if distance <= threshold:
                pixels[x, y] = (r, g, b, 0)
            elif a == 0:
                pixels[x, y] = (r, g, b, 0)
    return rgba


def nontransparent_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    return alpha.getbbox()


def extract_slot(strip: Image.Image, frame_index: int, frame_count: int) -> Image.Image:
    left = round(strip.width * frame_index / frame_count)
    right = round(strip.width * (frame_index + 1) / frame_count)
    return strip.crop((left, 0, right, strip.height))


def fit_into_cell(
    sprite: Image.Image,
    *,
    cell_width: int,
    cell_height: int,
    margin_x: int,
    margin_y: int,
    allow_upscale: bool,
) -> Image.Image:
    output = Image.new("RGBA", (cell_width, cell_height), (0, 0, 0, 0))
    bbox = nontransparent_bbox(sprite)
    if bbox is None:
        return output

    crop = sprite.crop(bbox)
    max_width = max(1, cell_width - margin_x * 2)
    max_height = max(1, cell_height - margin_y * 2)
    ratio = min(max_width / crop.width, max_height / crop.height)
    if not allow_upscale:
        ratio = min(1.0, ratio)

    resized = crop.resize(
        (max(1, round(crop.width * ratio)), max(1, round(crop.height * ratio))),
        Image.Resampling.LANCZOS,
    )
    x = (cell_width - resized.width) // 2
    y = (cell_height - resized.height) // 2
    output.alpha_composite(resized, (x, y))
    return output


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--scale", type=int, default=2)
    parser.add_argument("--default-display-scale", type=float, default=1.0)
    parser.add_argument("--chroma-threshold", type=int, default=42)
    parser.add_argument("--allow-upscale", action="store_true")
    parser.add_argument("--output-dir")
    args = parser.parse_args()

    if args.scale < 2:
        raise SystemExit("--scale must be 2 or greater for overlay high-res output")

    run_dir = Path(args.run_dir).expanduser().resolve()
    decoded_dir = run_dir / "decoded"
    if not decoded_dir.is_dir():
        raise SystemExit(f"decoded directory not found: {decoded_dir}")

    cell_width = BASE_CELL_WIDTH * args.scale
    cell_height = BASE_CELL_HEIGHT * args.scale
    margin_x = 18 * args.scale
    margin_y = 16 * args.scale
    output_dir = (
        Path(args.output_dir).expanduser().resolve()
        if args.output_dir
        else run_dir / "overlay-highres" / f"{args.scale}x"
    )
    output_dir.mkdir(parents=True, exist_ok=True)

    chroma = chroma_from_request(run_dir)
    atlas = Image.new(
        "RGBA",
        (ATLAS_COLUMNS * cell_width, ATLAS_ROWS * cell_height),
        (0, 0, 0, 0),
    )
    manifest_rows: list[dict[str, object]] = []

    for row_index, (state, frame_count) in enumerate(ROWS):
        strip_path = decoded_dir / f"{state}.png"
        if not strip_path.is_file():
            raise SystemExit(f"missing decoded row strip: {strip_path}")
        with Image.open(strip_path) as raw_strip:
            strip = remove_chroma(raw_strip, chroma, args.chroma_threshold)
            row_frames: list[dict[str, object]] = []
            for frame_index in range(frame_count):
                slot = extract_slot(strip, frame_index, frame_count)
                frame = fit_into_cell(
                    slot,
                    cell_width=cell_width,
                    cell_height=cell_height,
                    margin_x=margin_x,
                    margin_y=margin_y,
                    allow_upscale=args.allow_upscale,
                )
                atlas.alpha_composite(frame, (frame_index * cell_width, row_index * cell_height))
                bbox = nontransparent_bbox(frame)
                row_frames.append(
                    {
                        "index": frame_index,
                        "nonempty": bbox is not None,
                        "bbox": list(bbox) if bbox else None,
                    }
                )
        manifest_rows.append(
            {
                "state": state,
                "row": row_index,
                "frames": frame_count,
                "source": str(strip_path),
                "frames_detail": row_frames,
            }
        )

    png_path = output_dir / "spritesheet.png"
    webp_path = output_dir / "spritesheet.webp"
    manifest_path = output_dir / "manifest.json"
    atlas.save(png_path)
    atlas.save(webp_path, "WEBP", lossless=True, quality=100, method=6)
    manifest = {
        "schema_version": 1,
        "kind": "codex-pet-overlay-highres-atlas",
        "source_run_dir": str(run_dir),
        "sourceScale": args.scale,
        "defaultDisplayScale": args.default_display_scale,
        "columns": ATLAS_COLUMNS,
        "rows": ATLAS_ROWS,
        "cellWidth": cell_width,
        "cellHeight": cell_height,
        "width": atlas.width,
        "height": atlas.height,
        "stateRowMap": {state: row_index for row_index, (state, _frame_count) in enumerate(ROWS)},
        "chroma_key_rgb": list(chroma),
        "chroma_threshold": args.chroma_threshold,
        "allow_upscale": bool(args.allow_upscale),
        "outputs": {
            "png": str(png_path),
            "webp": str(webp_path),
        },
        "rows_detail": manifest_rows,
    }
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    print(f"wrote {png_path}")
    print(f"wrote {webp_path}")
    print(f"wrote {manifest_path}")


if __name__ == "__main__":
    main()
