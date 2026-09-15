import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property bool cfg_enablePinnedGroups: true

    Item {
        implicitHeight: Kirigami.Units.gridUnit
    }

    Controls.CheckBox {
        Kirigami.FormData.label: i18n("Pinned apps:")
        text: i18n("Enable groups")
        checked: page.cfg_enablePinnedGroups
        onToggled: page.cfg_enablePinnedGroups = checked
    }
}
