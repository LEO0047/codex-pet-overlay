# Lucy v2 Direct-Base Runbook

Use this reference when recreating the Lucy v2 workflow.

## Canonical Base

- Source: `/Users/leo/Downloads/產生的圖片 2.png`
- SHA-256: `aaee071d68917d66421aa22a908af022b27e330adfc6246fd3be086362cb3bfb`
- Provenance: `user-supplied-base`

## Output Locations

- Run: `/Users/leo/Documents/Codex/2026-05-02/pet/output/hatch-pet/lucy-v2`
- Package: `/Users/leo/.codex/pets/lucy-v2`
- Copied overlay archive: `/Users/leo/Library/Mobile Documents/com~apple~CloudDocs/Coding/Projects/codex-pet-overlay/output/lucy-v2`

## Important Lessons

- The original `hatch-pet` workflow assumes `base` is generated or recorded from an imagegen output. For Lucy v2, `base` was intentionally seeded from the user-supplied image.
- `finalize_pet_run.py` must accept `user-supplied-base` only for `job_id == "base"` and still validate hashes.
- Row jobs remain normal `$imagegen` jobs.
- Parent must record row outputs sequentially. Parallel `record_imagegen_result.py` calls can race and lose manifest updates.
- Geometry validation can pass even when style identity drifts. Always inspect `qa/contact-sheet.png`.
- The `failed` row was regenerated once after visual feedback because the first accepted row looked less consistent with the supplied base.

