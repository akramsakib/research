"""Local-only handoff packs for reviewing a workspace with an Arena assistant.

This command deliberately does not run a scan, contact a target, invoke Docker,
or require an LLM. It records a bounded inventory of a local source directory so
a user can ask an Arena assistant to review the files in the shared workspace.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from datetime import UTC, datetime
from pathlib import Path

from rich.console import Console


_IGNORED_DIRECTORIES = frozenset(
    {
        ".git",
        ".hg",
        ".svn",
        ".venv",
        "__pycache__",
        "node_modules",
        ".next",
        ".cache",
        "build",
        "coverage",
        "dist",
        "target",
    },
)
_MAX_FILES = 500
_MAX_FILE_BYTES = 5 * 1024 * 1024


def _workspace_root() -> Path:
    """Return the directory from which the command was launched."""
    return Path.cwd().resolve()


def _local_directory(value: str, *, workspace: Path) -> Path:
    """Resolve and validate a target as a directory inside the local workspace."""
    candidate = Path(value).expanduser().resolve()
    if not candidate.exists():
        raise ValueError(f"Target does not exist: {candidate}")
    if not candidate.is_dir():
        raise ValueError("Arena review accepts a local directory, not a URL or file.")
    if not candidate.is_relative_to(workspace):
        raise ValueError(
            f"Target must be inside the current workspace ({workspace}), not {candidate}."
        )
    return candidate


def _inventory(root: Path, *, excluded: Path | None = None) -> tuple[list[dict[str, object]], bool]:
    """Return a bounded metadata-only inventory without following directory links."""
    files: list[dict[str, object]] = []
    truncated = False
    for directory, dirnames, filenames in os.walk(root, followlinks=False):
        directory_path = Path(directory)
        dirnames[:] = sorted(
            name
            for name in dirnames
            if name not in _IGNORED_DIRECTORIES
            and (excluded is None or (directory_path / name).resolve() != excluded)
        )
        for name in sorted(filenames):
            path = directory_path / name
            if path.is_symlink():
                continue
            try:
                stat = path.stat()
            except OSError:
                continue
            if not path.is_file() or stat.st_size > _MAX_FILE_BYTES:
                continue
            relative = path.relative_to(root).as_posix()
            files.append(
                {
                    "path": relative,
                    "bytes": stat.st_size,
                    "sha256": _sha256(path),
                },
            )
            if len(files) >= _MAX_FILES:
                truncated = True
                return files, truncated
    return files, truncated


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    try:
        with path.open("rb") as handle:
            while chunk := handle.read(64 * 1024):
                digest.update(chunk)
    except OSError:
        return "unavailable"
    return digest.hexdigest()


def _write_markdown(path: Path, *, target: Path, manifest: dict[str, object]) -> None:
    inventory = manifest["files"]
    assert isinstance(inventory, list)
    file_lines = "\n".join(f"- `{item['path']}` ({item['bytes']} bytes)" for item in inventory)
    if manifest["truncated"]:
        file_lines += f"\n- _Inventory truncated after {_MAX_FILES} files._"
    path.write_text(
        "# Arena review handoff\n\n"
        "This is a local, metadata-only handoff pack. It does not represent a security scan "
        "and it did not contact any network target.\n\n"
        "## Scope\n\n"
        f"- **Source directory:** `{target}`\n"
        f"- **Generated:** {manifest['generated_at']}\n"
        f"- **Files inventoried:** {len(inventory)}\n"
        "- **Authorization reminder:** review only software that you own or are explicitly "
        "authorized to assess.\n\n"
        "## Ask the Arena assistant\n\n"
        "In this chat, ask the assistant to review this local source directory and the "
        "accompanying `arena-review.json`. The assistant can read the shared workspace, "
        "reason about the source, and suggest remediation. This bridge cannot invoke the "
        "assistant automatically or turn the chat into an LLM API.\n\n"
        "## Inventory\n\n"
        f"{file_lines or '_No eligible files found._'}\n",
        encoding="utf-8",
    )


def run_arena_review(argv: list[str]) -> int:
    """Create an Arena handoff pack and return a process-style exit code."""
    parser = argparse.ArgumentParser(
        prog="strix arena-review",
        description="Create a local-only review handoff for the Arena shared workspace.",
    )
    parser.add_argument(
        "--target",
        required=True,
        help="Local source directory inside the current workspace.",
    )
    parser.add_argument(
        "--output",
        default="strix_arena_review",
        help="Directory for REVIEW_REQUEST.md and arena-review.json (default: ./strix_arena_review).",
    )
    args = parser.parse_args(argv)
    console = Console()
    workspace = _workspace_root()
    try:
        target = _local_directory(args.target, workspace=workspace)
        output = Path(args.output).expanduser().resolve()
        if not output.is_relative_to(workspace):
            raise ValueError(f"Output must be inside the current workspace ({workspace}).")
        if output == target or target.is_relative_to(output):
            raise ValueError("Output directory cannot be the target directory or its parent.")
    except ValueError as exc:
        console.print(f"[red]Arena review setup failed:[/] {exc}")
        return 2

    output.mkdir(parents=True, exist_ok=True)
    files, truncated = _inventory(target, excluded=output)
    manifest: dict[str, object] = {
        "format": "strix-arena-review-v1",
        "generated_at": datetime.now(UTC).isoformat(),
        "target": str(target),
        "workspace": str(workspace),
        "file_limit": _MAX_FILES,
        "truncated": truncated,
        "files": files,
    }
    manifest_path = output / "arena-review.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    request_path = output / "REVIEW_REQUEST.md"
    _write_markdown(request_path, target=target, manifest=manifest)

    console.print("[green]Arena review handoff created.[/]")
    console.print(f"  Request:  {request_path}")
    console.print(f"  Manifest: {manifest_path}")
    console.print("[dim]No LLM, Docker container, or network target was used.[/]")
    return 0


if __name__ == "__main__":
    sys.exit(run_arena_review(sys.argv[1:]))
