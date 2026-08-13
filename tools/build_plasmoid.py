#!/usr/bin/env python3
"""Build a clean KDE Plasma .plasmoid package from the repository.

The generated archive contains only the files required for distribution:
- metadata.json
- LICENSE
- contents/

Development files such as screenshots, README, changelog and translation
source/build helpers are intentionally excluded.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys
import zipfile


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
METADATA_PATH = REPO_ROOT / "metadata.json"
CONTENTS_DIR = REPO_ROOT / "contents"
LICENSE_PATH = REPO_ROOT / "LICENSE"
DIST_DIR = REPO_ROOT / "dist"


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def validate_package(metadata: dict) -> tuple[str, str]:
    plugin = metadata.get("KPlugin", {})
    package_id = str(plugin.get("Id", "")).strip()
    version = str(plugin.get("Version", "")).strip()

    if metadata.get("KPackageStructure") != "Plasma/Applet":
        fail('metadata.json must contain "KPackageStructure": "Plasma/Applet"')

    if metadata.get("X-Plasma-API-Minimum-Version") != "6.0":
        fail('metadata.json must contain "X-Plasma-API-Minimum-Version": "6.0"')

    if not package_id:
        fail("KPlugin.Id is missing in metadata.json")

    if not version:
        fail("KPlugin.Version is missing in metadata.json")

    if not CONTENTS_DIR.is_dir():
        fail("contents/ directory is missing")

    if not (CONTENTS_DIR / "ui" / "main.qml").is_file():
        fail("contents/ui/main.qml is missing")

    if not LICENSE_PATH.is_file():
        fail("LICENSE is missing")

    return package_id, version


def add_file(archive: zipfile.ZipFile, source: Path, archive_name: str) -> None:
    archive.write(source, archive_name)


def main() -> None:
    if not METADATA_PATH.is_file():
        fail("metadata.json is missing")

    try:
        metadata = json.loads(METADATA_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"Could not read metadata.json: {error}")

    package_id, version = validate_package(metadata)

    DIST_DIR.mkdir(exist_ok=True)
    output_path = DIST_DIR / f"{package_id}-{version}.plasmoid"
    checksum_path = output_path.with_suffix(output_path.suffix + ".sha256")

    if output_path.exists():
        output_path.unlink()

    with zipfile.ZipFile(
        output_path,
        mode="w",
        compression=zipfile.ZIP_DEFLATED,
        compresslevel=9,
    ) as archive:
        add_file(archive, METADATA_PATH, "metadata.json")
        add_file(archive, LICENSE_PATH, "LICENSE")

        for source in sorted(path for path in CONTENTS_DIR.rglob("*") if path.is_file()):
            archive_name = source.relative_to(REPO_ROOT).as_posix()
            add_file(archive, source, archive_name)

    with zipfile.ZipFile(output_path, mode="r") as archive:
        names = set(archive.namelist())
        required = {
            "metadata.json",
            "LICENSE",
            "contents/ui/main.qml",
            "contents/config/main.xml",
        }
        missing = sorted(required - names)

        if missing:
            output_path.unlink(missing_ok=True)
            fail("Package verification failed; missing: " + ", ".join(missing))

        file_count = len(archive.namelist())

    digest = hashlib.sha256(output_path.read_bytes()).hexdigest()
    checksum_path.write_text(
        f"{digest}  {output_path.name}\n",
        encoding="utf-8",
    )

    print("KDE Plasma package built successfully")
    print(f"Package:  {output_path}")
    print(f"Files:    {file_count}")
    print(f"SHA-256:  {digest}")
    print(f"Checksum: {checksum_path}")


if __name__ == "__main__":
    main()
