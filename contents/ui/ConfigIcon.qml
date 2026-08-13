import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.iconthemes as KIconThemes

Controls.Button {
    id: root

    property string defaultValue: "start-here"
    property string value: defaultValue

    implicitWidth: Kirigami.Units.gridUnit * 4
    implicitHeight: Kirigami.Units.gridUnit * 4

    display: Controls.AbstractButton.IconOnly
    icon.name: (value && value !== defaultValue) ? value : ""
    icon.source: (!value || value === defaultValue) ? Qt.resolvedUrl("icons/start-here.svg") : ""
    icon.width: Kirigami.Units.iconSizes.large
    icon.height: Kirigami.Units.iconSizes.large

    onClicked: iconMenu.open()

    KIconThemes.IconDialog {
        id: iconDialog
        iconSize: Kirigami.Units.iconSizes.medium

        onIconNameChanged: {
            if (iconName) {
                root.value = iconName
            }
        }
    }

    Controls.Menu {
        id: iconMenu
        y: root.height

        Controls.MenuItem {
            text: i18n("Choose...")
            icon.name: "document-open-folder"
            onTriggered: iconDialog.open()
        }

        Controls.MenuItem {
            text: i18n("Reset to default")
            icon.name: "edit-clear"
            enabled: root.value !== root.defaultValue
            onTriggered: root.value = root.defaultValue
        }
    }
}
