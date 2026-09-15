import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import "Translations.js" as Translations

Kirigami.FormLayout {
    id: page

    property string cfg_language: "system"
    property bool cfg_showUserInfo: true
    property bool cfg_showSessionButtonLabels: true
    property string cfg_sessionButtonAlignment: "right"
    property bool cfg_showLockButton: true
    property bool cfg_showLogoutButton: true
    property bool cfg_showRestartButton: true
    property bool cfg_showShutdownButton: true

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

    onCfg_sessionButtonAlignmentChanged: {
        const index = sessionButtonPositionCombo.indexOfValue(
            cfg_sessionButtonAlignment
        )

        if (index >= 0 && sessionButtonPositionCombo.currentIndex !== index) {
            sessionButtonPositionCombo.currentIndex = index
        }

        if (cfg_sessionButtonAlignment === "left" && cfg_showUserInfo) {
            cfg_showUserInfo = false
        }
    }

    Controls.CheckBox {
        Kirigami.FormData.label: page.translatedText("Session buttons:")
        text: page.translatedText("Show button labels")
        checked: page.cfg_showSessionButtonLabels
        onToggled: page.cfg_showSessionButtonLabels = checked
    }

    Controls.ComboBox {
        id: sessionButtonPositionCombo

        Kirigami.FormData.label: page.translatedText("Button position:")

        model: [
            { text: page.translatedText("Left"), value: "left" },
            { text: page.translatedText("Center"), value: "center" },
            { text: page.translatedText("Right"), value: "right" }
        ]

        textRole: "text"
        valueRole: "value"

        Component.onCompleted: {
            const index = indexOfValue(page.cfg_sessionButtonAlignment)
            currentIndex = index >= 0 ? index : 2
        }

        onActivated: page.cfg_sessionButtonAlignment = currentValue
    }

    Controls.CheckBox {
        text: page.translatedText("Show Lock Screen")
        checked: page.cfg_showLockButton
        onToggled: page.cfg_showLockButton = checked
    }

    Controls.CheckBox {
        text: page.translatedText("Show Log Out")
        checked: page.cfg_showLogoutButton
        onToggled: page.cfg_showLogoutButton = checked
    }

    Controls.CheckBox {
        text: page.translatedText("Show Restart")
        checked: page.cfg_showRestartButton
        onToggled: page.cfg_showRestartButton = checked
    }

    Controls.CheckBox {
        text: page.translatedText("Show Shut Down")
        checked: page.cfg_showShutdownButton
        onToggled: page.cfg_showShutdownButton = checked
    }
}
