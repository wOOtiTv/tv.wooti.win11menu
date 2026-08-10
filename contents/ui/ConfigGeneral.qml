import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property string cfg_language: "system"

    Item {
        implicitHeight: Kirigami.Units.gridUnit
    }

    onCfg_languageChanged: {
        const index = languageCombo.indexOfValue(cfg_language)
        if (index >= 0 && languageCombo.currentIndex !== index) {
            languageCombo.currentIndex = index
        }
    }

    Controls.ComboBox {
        id: languageCombo

        Kirigami.FormData.label: i18n("Language:")

        model: [
            { text: i18n("System default"), value: "system" },
            { text: "English", value: "en" },
            { text: "Deutsch", value: "de" },
            { text: "Français", value: "fr" },
            { text: "Italiano", value: "it" },
            { text: "Nederlands", value: "nl" }
        ]

        textRole: "text"
        valueRole: "value"

        Component.onCompleted: {
            const index = indexOfValue(page.cfg_language)
            currentIndex = index >= 0 ? index : 0
        }

        onActivated: page.cfg_language = currentValue
    }
}
