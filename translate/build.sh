#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="${DIR}/.."
METADATA="${PACKAGE_ROOT}/metadata.json"

PLUGIN_ID="$(grep -oP '"Id"\s*:\s*"\K[^"]+' "${METADATA}" | head -n 1 || true)"

if [[ -z "${PLUGIN_ID}" ]]; then
    echo "[build] Error: Could not read KPlugin.Id from metadata.json."
    exit 1
fi

PROJECT_NAME="plasma_applet_${PLUGIN_ID}"

echo "[build] Translation domain: ${PROJECT_NAME}"
echo "[build] Compiling .po files..."

shopt -s nullglob
catalogs=("${DIR}"/*.po)

if [[ ${#catalogs[@]} -eq 0 ]]; then
    echo "[build] Error: No .po files found."
    exit 1
fi

for catalog in "${catalogs[@]}"; do
    locale="$(basename "${catalog}" .po)"
    [[ "${locale}" == "_template" ]] && continue

    output_dir="${PACKAGE_ROOT}/contents/locale/${locale}/LC_MESSAGES"
    output_file="${output_dir}/${PROJECT_NAME}.mo"

    echo "[build] ${locale}.po -> ${output_file}"
    mkdir -p "${output_dir}"
    msgfmt --check -o "${output_file}" "${catalog}"
done
shopt -u nullglob

echo "[build] Generating runtime translation catalog..."
python3 "${DIR}/generate_translations.py"

echo "[build] Done."
