import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property bool cfg_enablePinnedGroups: true
    property string cfg_pinnedGroups: "[]"
    property bool cfg_pinnedOrderCustomized: false
    property string cfg_pinnedOrder: "[]"

    Item {
        implicitHeight: Kirigami.Units.gridUnit
    }

    Controls.CheckBox {
        Kirigami.FormData.label: i18n("Pinned apps:")
        text: i18n("Enable groups")
        checked: page.cfg_enablePinnedGroups
        onToggled: page.cfg_enablePinnedGroups = checked
    }

    Controls.Button {
        text: i18n("Reset to default")
        enabled: page.cfg_pinnedGroups !== "[]"
            || page.cfg_pinnedOrderCustomized
            || page.cfg_pinnedOrder !== "[]"
        onClicked: resetPinnedDialog.open()
    }

    Controls.Label {
        text: i18n("Removes all groups and restores the default alphabetical order. Pinned apps are kept.")
        wrapMode: Text.WordWrap
        opacity: 0.7
        Layout.fillWidth: true
    }

    Controls.Dialog {
        id: resetPinnedDialog

        title: i18n("Reset pinned apps?")
        modal: true
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel
        width: Math.min(460, page.width - 40)
        x: Math.round((page.width - width) / 2)
        y: Math.max(20, Math.round((page.height - height) / 2))

        contentItem: Controls.Label {
            width: parent ? parent.width : 360
            text: i18n("All groups and the custom pinned order will be removed. Your pinned apps themselves will stay pinned.")
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            page.cfg_pinnedGroups = "[]"
            page.cfg_pinnedOrder = "[]"
            page.cfg_pinnedOrderCustomized = false
        }
    }
}
