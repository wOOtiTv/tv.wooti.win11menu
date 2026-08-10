# Translation Tools

This directory contains the translation catalogs and helper scripts for the **wOOti Win11 Menu** Plasmoid.

The launcher uses English source strings and supports:

- English (`en`)
- German (`de`)
- French (`fr`)
- Italian (`it`)
- Dutch (`nl`)

The default setting follows the system language. Users can override the launcher language in **General → Language**.

## Files

```text
translate/
├── README.md
├── template.pot
├── merge.sh
├── build.sh
├── generate_translations.py
├── en.po
├── de.po
├── fr.po
├── it.po
└── nl.po
```

`template.pot` is generated from the QML source and should not be edited manually.

## Workflow

After adding or changing an `i18n("...")` source string:

```bash
./merge.sh
```

Translate the new or changed entries in the `.po` files, then build them:

```bash
./build.sh
```

`build.sh` performs two tasks:

1. Compiles every `.po` catalog to the corresponding `.mo` file under `contents/locale/<language>/LC_MESSAGES/`.
2. Regenerates `contents/ui/Translations.js`, which is used for the per-widget manual language override.

The translation domain is:

```text
plasma_applet_tv.wooti.win11menu
```

## Adding another language

1. Add a new `<language>.po` catalog.
2. Run `./merge.sh`.
3. Translate all entries.
4. Run `./build.sh`.
5. Add the language to the ComboBox in `contents/ui/ConfigGeneral.qml`.
6. Test both **System default** and the manual language selection.

Missing translations fall back to the English source text.

## Important

- Change visible source text in QML first, then run `./merge.sh`.
- Do not edit `template.pot` or `contents/ui/Translations.js` manually.
- Run `./build.sh` after every translation change.
- `infiles.list` is temporary and is removed automatically by `merge.sh`.
