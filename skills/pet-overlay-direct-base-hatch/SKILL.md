---
name: pet-overlay-direct-base-hatch
description: Create Codex Pet Overlay native high-resolution character assets from a user-supplied canonical base image, with optional Codex-compatible export. Use for repo-local direct-base character runs that must preserve identity, outfit details, proportions, and row consistency while using image generation for animation rows and deterministic scripts for overlay manifests, QA, and export output.
---

# Pet Overlay Direct Base Hatch

Use this skill when the character's main look is already approved and the user wants that exact image to become the canonical base. This is the repo-local asset pipeline for Codex Pet Overlay. It may retain forked deterministic scripts from earlier Codex-compatible work, but the active product direction is overlay-native high-resolution character assets first and Codex-compatible export second.

## Boundaries

- Do not invoke or overwrite the installed `${CODEX_HOME:-$HOME/.codex}/skills/hatch-pet` skill as this repo's governing workflow.
- Do not regenerate `base` with `$imagegen`.
- Do not mark row jobs complete from local edits, crops, composites, or post-processed files.
- Use `$imagegen` for every row-strip visual job.
- Parent owns `imagegen-jobs.json`, finalization, QA, and package writes.
- Record row outputs sequentially with `record_imagegen_result.py`; do not run manifest-writing record commands in parallel.
- Only `base` may use `source_provenance: user-supplied-base`.
- Do not promise large-overlay visual quality from the standard Codex atlas alone. The Codex package contract uses `192x208` cells; this overlay project should also produce a larger overlay-specific atlas when the pet will be shown as a desktop character.

## Direct-Base Workflow

1. Prepare the run with this repo-local script set:

```bash
SKILL_DIR="/absolute/path/to/skills/pet-overlay-direct-base-hatch"
python "$SKILL_DIR/scripts/prepare_pet_run.py" \
  --pet-name "<Name>" \
  --description "<one sentence>" \
  --reference /absolute/path/to/user-base.png \
  --output-dir /absolute/path/to/run \
  --pet-notes "<identity lock>" \
  --style-notes "<direct-base style lock>" \
  --force
```

2. Seed the approved user base instead of generating it:

```bash
python "$SKILL_DIR/scripts/seed_user_base.py" \
  --run-dir /absolute/path/to/run \
  --source /absolute/path/to/user-base.png \
  --force
```

This copies the source to `decoded/base.png` and `references/canonical-base.png`, records SHA-256 hashes, updates `pet_request.json`, and marks only the `base` job as `user-supplied-base`.

3. Check ready jobs:

```bash
python "$SKILL_DIR/scripts/pet_job_status.py" --run-dir /absolute/path/to/run
```

4. Generate rows with `$imagegen`, always attaching the prompt file and all input images listed for that row in `imagegen-jobs.json`.

Start with `idle` and `running-right` as the identity and gait gate. Inspect them against `references/canonical-base.png` before generating the remaining rows.

5. Record selected row outputs one at a time:

```bash
python "$SKILL_DIR/scripts/record_imagegen_result.py" \
  --run-dir /absolute/path/to/run \
  --job-id <row-id> \
  --source "${CODEX_HOME:-$HOME/.codex}/generated_images/.../ig_*.png"
```

6. Finalize the compatibility export and QA artifacts:

```bash
python "$SKILL_DIR/scripts/finalize_pet_run.py" --run-dir /absolute/path/to/run
```

7. Build the primary high-resolution overlay asset from the original generated row strips:

```bash
python "$SKILL_DIR/scripts/build_overlay_highres_atlas.py" \
  --run-dir /absolute/path/to/run \
  --scale 2
```

This writes `overlay-highres/2x/spritesheet.png`, `spritesheet.webp`, and `manifest.json` using `384x416` cells. Use `--scale 3` for `576x624` cells when the overlay needs to appear much larger. This output is the primary overlay app asset; the Codex-compatible package is the secondary export.

## Identity And Style Lock

For direct-base runs, the supplied base is the highest-priority identity source. Row prompts and visual QA must preserve:

- face shape, expression family, eye style, and hair silhouette
- body proportions chosen by the user, including non-chibi/tall humanoid proportions when requested
- outfit structure, straps, belt, buckle, pouch side, boots, and key accessories
- palette zones and rim-light style
- chroma-key background, no scenery, no logos, no text, no UI marks

If a row has valid geometry but visibly changes identity, outfit structure, pouch side/count, proportions, or rendering style, treat it as failed and regenerate that row before final packaging.

## Overlay High-Resolution Output

The direct-base character workflow has two output targets:

- **Overlay high-res atlas:** primary app asset generated from `decoded/<row>.png` source strips, saved under `run/overlay-highres/<scale>x/`.
- **Codex-compatible export:** optional fixed `1536x1872` atlas with `192x208` cells, saved under `${CODEX_HOME:-$HOME/.codex}/pets/<pet-id>/` or `output/<pet>/pet-package/` when compatibility is needed.

Do not use a simple upscale of `final/spritesheet.webp` as the primary high-res path; that only magnifies already-downsampled frames. Build the overlay atlas from the original row strips in `decoded/` so it keeps as much generated detail as possible.

For Lucy-style tall humanoid pets, default to `--scale 2` first. Move to `--scale 3` only if the overlay app is intended to show a large desktop character and memory/rendering cost is acceptable.

## Subagent Use

When the user asks for subagents or the run is long:

1. Parent prepares the run and seeds `base`.
2. Delegate one row per subagent.
3. Give each subagent the exact row id, prompt file, required input images, and identity lock.
4. Subagents return only generated image paths and notes; they do not edit the manifest.
5. Parent records accepted outputs sequentially.
6. Wait patiently under `codex-long-running-workflow`; do not duplicate a silent row worker unless it failed or exceeded the patience window.

## Repair Policy

If a row drifts:

1. Regenerate only that row.
2. Keep the same base and accepted rows.
3. Record the replacement with `record_imagegen_result.py --force`.
4. Re-run `finalize_pet_run.py`.
5. Re-check `qa/contact-sheet.png`, `qa/review.json`, and `final/validation.json`.

`final/validation.json` and `qa/review.json` passing is required but not enough. The contact sheet must still look like the same pet in every row.
