import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import "Translations.js" as Translations

Kirigami.FormLayout {
    id: page

    property string cfg_language: "system"
    property alias cfg_icon: menuIcon.value
    property bool cfg_showUserInfo: true
    property string cfg_sessionButtonAlignment: "right"

    function translatedText(sourceText) {
        return Translations.translate(
            sourceText,
            page.cfg_language,
            Qt.locale().name
        )
    }

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

    ConfigIcon {
        id: menuIcon

        Kirigami.FormData.label: i18n("Menu icon:")
        defaultValue: "start-here"
    }

    Controls.Label {
        Kirigami.FormData.label: i18n("Current icon:")
        text: menuIcon.value
    }

    Item {
        implicitHeight: Kirigami.Units.smallSpacing * 2
    }

    Controls.CheckBox {
        Kirigami.FormData.label: page.translatedText("User information:")
        text: page.translatedText("Show name and avatar")
        checked: page.cfg_showUserInfo
        enabled: page.cfg_sessionButtonAlignment !== "left"
        onToggled: page.cfg_showUserInfo = checked
    }
}
