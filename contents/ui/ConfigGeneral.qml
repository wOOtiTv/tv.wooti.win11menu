import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property string cfg_language: "system"
    property alias cfg_icon: menuIcon.value
    property bool cfg_showLockButton: true
    property bool cfg_showLogoutButton: true
    property bool cfg_showRestartButton: true
    property bool cfg_showShutdownButton: true
    property bool cfg_enablePinnedGroups: true

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

    Controls.CheckBox {
        Kirigami.FormData.label: i18n("Pinned apps:")
        text: i18n("Enable groups")
        checked: page.cfg_enablePinnedGroups
        onToggled: page.cfg_enablePinnedGroups = checked
    }

    Controls.CheckBox {
        Kirigami.FormData.label: i18n("Session buttons:")
        text: i18n("Show Lock Screen")
        checked: page.cfg_showLockButton
        onToggled: page.cfg_showLockButton = checked
    }

    Controls.CheckBox {
        text: i18n("Show Log Out")
        checked: page.cfg_showLogoutButton
        onToggled: page.cfg_showLogoutButton = checked
    }

    Controls.CheckBox {
        text: i18n("Show Restart")
        checked: page.cfg_showRestartButton
        onToggled: page.cfg_showRestartButton = checked
    }

    Controls.CheckBox {
        text: i18n("Show Shut Down")
        checked: page.cfg_showShutdownButton
        onToggled: page.cfg_showShutdownButton = checked
    }
}
