---
name: hatch-pet-direct-base
description: Create Codex-compatible animated pet packages from a user-supplied canonical base image without regenerating the base. Use for direct-base hatch-pet runs that must preserve identity, outfit details, proportions, and row consistency while still using $imagegen for all animation rows and deterministic scripts for atlas/package output.
---

# Hatch Pet Direct Base

Use this skill when the pet's main look is already approved and the user wants that exact image to become the canonical base. This is a controlled variant of `$hatch-pet`: it keeps the original deterministic atlas/package pipeline, but replaces only the base-generation step with a verified user-supplied base seed.

## Boundaries

- Do not overwrite the installed `${CODEX_HOME:-$HOME/.codex}/skills/hatch-pet` skill.
- Do not regenerate `base` with `$imagegen`.
- Do not mark row jobs complete from local edits, crops, composites, or post-processed files.
- Use `$imagegen` for every row-strip visual job.
- Parent owns `imagegen-jobs.json`, finalization, QA, and package writes.
- Record row outputs sequentially with `record_imagegen_result.py`; do not run manifest-writing record commands in parallel.
- Only `base` may use `source_provenance: user-supplied-base`.

## Direct-Base Workflow

1. Prepare the run with the original hatch-pet script set:

```bash
SKILL_DIR="/absolute/path/to/skills/hatch-pet-direct-base"
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

6. Finalize and package:

```bash
python "$SKILL_DIR/scripts/finalize_pet_run.py" --run-dir /absolute/path/to/run
```

## Identity And Style Lock

For direct-base runs, the supplied base is the highest-priority identity source. Row prompts and visual QA must preserve:

- face shape, expression family, eye style, and hair silhouette
- body proportions chosen by the user, including non-chibi/tall humanoid proportions when requested
- outfit structure, straps, belt, buckle, pouch side, boots, and key accessories
- palette zones and rim-light style
- chroma-key background, no scenery, no logos, no text, no UI marks

If a row has valid geometry but visibly changes identity, outfit structure, pouch side/count, proportions, or rendering style, treat it as failed and regenerate that row before final packaging.

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

