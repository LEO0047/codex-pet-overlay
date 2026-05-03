#!/usr/bin/env python3
"""Seed a user-supplied canonical base image into a hatch-pet run."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image

CANONICAL_BASE_PATH = "references/canonical-base.png"


def load_json(path: Path) -> dict[str, object]:
    if not path.exists():
        raise SystemExit(f"file not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: dict[str, object]) -> None:
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def job_list(manifest: dict[str, object]) -> list[dict[str, object]]:
    jobs = manifest.get("jobs")
    if not isinstance(jobs, list):
        raise SystemExit("invalid imagegen-jobs.json: jobs must be a list")
    return [job for job in jobs if isinstance(job, dict)]


def find_job(manifest: dict[str, object], job_id: str) -> dict[str, object]:
    for job in job_list(manifest):
        if job.get("id") == job_id:
            return job
    raise SystemExit(f"unknown job id: {job_id}")


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def image_metadata(path: Path) -> dict[str, object]:
    with Image.open(path) as image:
        image.verify()
    with Image.open(path) as image:
        return {
            "width": image.width,
            "height": image.height,
            "mode": image.mode,
            "format": image.format,
        }


def manifest_relative(path: Path, run_dir: Path) -> str:
    return str(path.resolve().relative_to(run_dir.resolve()))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--source", required=True)
    parser.add_argument("--job-id", default="base")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    run_dir = Path(args.run_dir).expanduser().resolve()
    source = Path(args.source).expanduser().resolve()
    if args.job_id != "base":
        raise SystemExit("user-supplied-base provenance is allowed only for job-id base")
    if not source.is_file():
        raise SystemExit(f"source image not found: {source}")

    manifest_path = run_dir / "imagegen-jobs.json"
    manifest = load_json(manifest_path)
    job = find_job(manifest, "base")

    output_raw = job.get("output_path")
    if not isinstance(output_raw, str):
        raise SystemExit("base job has no output_path")
    output = run_dir / output_raw
    canonical = run_dir / CANONICAL_BASE_PATH
    for path in [output, canonical]:
        if path.exists() and not args.force:
            raise SystemExit(f"{path} already exists; pass --force to replace it")

    output.parent.mkdir(parents=True, exist_ok=True)
    canonical.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, output)
    shutil.copy2(source, canonical)

    metadata = image_metadata(output)
    source_sha = file_sha256(source)
    output_sha = file_sha256(output)
    canonical_sha = file_sha256(canonical)
    if output_sha != canonical_sha:
        raise SystemExit("base output and canonical reference hashes differ after copy")

    reference = {
        "path": manifest_relative(canonical, run_dir),
        "source_job": "base",
        "source_provenance": "user-supplied-base",
        "source_path": str(source),
        "sha256": canonical_sha,
        "metadata": metadata,
    }

    job["status"] = "complete"
    job["source_path"] = str(source)
    job["source_provenance"] = "user-supplied-base"
    job["source_sha256"] = source_sha
    job["output_sha256"] = output_sha
    job["completed_at"] = datetime.now(timezone.utc).isoformat()
    job["metadata"] = metadata
    job["canonical_reference_path"] = reference["path"]
    for key in [
        "last_error",
        "secondary_fallback",
        "secondary_provider",
        "synthetic_test_source",
    ]:
        job.pop(key, None)

    manifest["canonical_identity_reference"] = reference
    write_json(manifest_path, manifest)

    request_path = run_dir / "pet_request.json"
    if request_path.exists():
        request = load_json(request_path)
        request["canonical_identity_reference"] = reference
        write_json(request_path, request)

    print(f"seeded user base: {source}")
    print(f"decoded base: {output}")
    print(f"canonical reference: {canonical}")
    print(f"sha256: {source_sha}")


if __name__ == "__main__":
    main()

