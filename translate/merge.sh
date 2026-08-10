#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd -- "${DIR}/.." && pwd)"
TRANSLATE_DIR="${DIR}"
METADATA="${PACKAGE_ROOT}/metadata.json"

PLUGIN_ID="$(grep -oP '"Id"\s*:\s*"\K[^"]+' "${METADATA}" | head -n 1 || true)"

if [[ -z "${PLUGIN_ID}" ]]; then
    echo "[merge] Error: Could not read KPlugin.Id from metadata.json."
    exit 1
fi

echo "[merge] Plugin ID: ${PLUGIN_ID}"

SOURCE_LIST="${TRANSLATE_DIR}/infiles.list"
cd "${PACKAGE_ROOT}"
find contents \
    -type f \( -name '*.qml' -o -name '*.js' \) \
    ! -name 'Translations.js' \
    -print | sort > "${SOURCE_LIST}"

if [[ ! -s "${SOURCE_LIST}" ]]; then
    echo "[merge] Error: No QML/JS source files found."
    rm -f "${SOURCE_LIST}"
    exit 1
fi

echo "[merge] Extracting messages..."

xgettext \
    --language=C \
    --from-code=UTF-8 \
    --width=400 \
    --add-location=file \
    --package-name="wOOti Win11 Menu" \
    --package-version="1.0.5" \
    --msgid-bugs-address="https://github.com/wOOtiTv/tv.wooti.win11menu/issues" \
    --keyword=i18n:1 \
    --keyword=i18nc:2 \
    --keyword=i18np:1,2 \
    --keyword=i18ncp:2,3 \
    --files-from="${SOURCE_LIST}" \
    --output="${TRANSLATE_DIR}/template.pot.new"

sed -i \
    's/"Content-Type: text\/plain; charset=CHARSET\\n"/"Content-Type: text\/plain; charset=UTF-8\\n"/' \
    "${TRANSLATE_DIR}/template.pot.new"

if [[ -f "${TRANSLATE_DIR}/template.pot" ]]; then
    old_normalized="$(mktemp)"
    new_normalized="$(mktemp)"
    trap 'rm -f "${old_normalized}" "${new_normalized}" "${SOURCE_LIST}"' EXIT

    sed '/^"POT-Creation-Date:/d' "${TRANSLATE_DIR}/template.pot" > "${old_normalized}"
    sed '/^"POT-Creation-Date:/d' "${TRANSLATE_DIR}/template.pot.new" > "${new_normalized}"

    if cmp -s "${old_normalized}" "${new_normalized}"; then
        rm -f "${TRANSLATE_DIR}/template.pot.new"
        echo "[merge] No changes to template.pot."
    else
        mv "${TRANSLATE_DIR}/template.pot.new" "${TRANSLATE_DIR}/template.pot"
        echo "[merge] template.pot updated."
    fi

    rm -f "${old_normalized}" "${new_normalized}"
    trap - EXIT
else
    mv "${TRANSLATE_DIR}/template.pot.new" "${TRANSLATE_DIR}/template.pot"
    echo "[merge] template.pot created."
fi

echo "[merge] Updating translation catalogs..."

shopt -s nullglob
for catalog in "${TRANSLATE_DIR}"/*.po; do
    locale="$(basename "${catalog}" .po)"
    echo "[merge] ${locale}.po"

    msgmerge \
        --update \
        --backup=none \
        --no-fuzzy-matching \
        --add-location=file \
        --width=400 \
        "${catalog}" \
        "${TRANSLATE_DIR}/template.pot"
done
shopt -u nullglob

rm -f "${SOURCE_LIST}"
echo "[merge] Done."
