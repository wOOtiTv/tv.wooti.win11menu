import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import "Translations.js" as Translations

Kirigami.FormLayout {
    id: page

    property string cfg_language: "system"
    property alias cfg_iconSize: iconSizeSpin.value
    property alias cfg_menuHeight: menuHeightSpin.value
    property alias cfg_menuWidth: menuWidthSpin.value
    property bool cfg_showSectionTitles: true
    property string cfg_allAppsViewMode: "legacy"
    property bool cfg_allAppsListView: false

    function translatedText(sourceText) {
        return Translations.translate(
            sourceText,
            page.cfg_language,
            Qt.locale().name
        )
    }

    function resolvedAllAppsViewMode() {
        var configuredMode = String(page.cfg_allAppsViewMode || "legacy")

        if (configuredMode === "grid"
                || configuredMode === "list"
                || configuredMode === "pinned") {
            return configuredMode
        }

        return page.cfg_allAppsListView ? "list" : "grid"
    }

    function syncViewModeCombo() {
        const index = allAppsViewModeCombo.indexOfValue(
            page.resolvedAllAppsViewMode()
        )

        if (index >= 0 && allAppsViewModeCombo.currentIndex !== index) {
            allAppsViewModeCombo.currentIndex = index
        }
    }

    Item {
        implicitHeight: Kirigami.Units.gridUnit
    }

    onCfg_allAppsViewModeChanged: syncViewModeCombo()
    onCfg_allAppsListViewChanged: syncViewModeCombo()

    Controls.SpinBox {
        id: iconSizeSpin

        Kirigami.FormData.label: i18n("Icon size:")
        from: 24
        to: 64
        stepSize: 4
        editable: true
    }

    Controls.Label {
        text: i18n("Min. 24 px · Max. 64 px · Default: 36 px")
        opacity: 0.7
    }

    Item {
        implicitHeight: Kirigami.Units.smallSpacing * 2
    }

    Controls.SpinBox {
        id: menuHeightSpin

        Kirigami.FormData.label: i18n("Menu height:")
        from: 600
        to: 1200
        stepSize: 16
        editable: true
    }

    Controls.Label {
        text: i18n("Min. 600 px · Max. 1200 px · Default: 800 px")
        opacity: 0.7
    }

    Item {
        implicitHeight: Kirigami.Units.smallSpacing * 2
    }

    Controls.SpinBox {
        id: menuWidthSpin

        Kirigami.FormData.label: i18n("Menu width:")
        from: 800
        to: 1600
        stepSize: 16
        editable: true
    }

    Controls.Label {
        text: i18n("Min. 800 px · Max. 1600 px · Default: 1000 px")
        opacity: 0.7
    }

    Item {
        implicitHeight: Kirigami.Units.smallSpacing * 2
    }

    Controls.CheckBox {
        Kirigami.FormData.label: page.translatedText("Sections:")
        text: page.translatedText("Show Pinned and All headings")
        checked: page.cfg_showSectionTitles
        onToggled: page.cfg_showSectionTitles = checked
    }

    Controls.ComboBox {
        id: allAppsViewModeCombo

        Kirigami.FormData.label: page.translatedText("All Applications view:")

        model: [
            { text: page.translatedText("Grid"), value: "grid" },
            { text: page.translatedText("List"), value: "list" },
            { text: page.translatedText("Pinned style"), value: "pinned" }
        ]

        textRole: "text"
        valueRole: "value"

        Component.onCompleted: page.syncViewModeCombo()

        onActivated: {
            page.cfg_allAppsViewMode = currentValue
            page.cfg_allAppsListView = currentValue === "list"
        }
    }
}
