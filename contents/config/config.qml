import QtQuick 2.0

import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "kde"
        source: "ConfigGeneral.qml"
    }

    ConfigCategory {
        name: i18n("Menu")
        icon: "view-grid"
        source: "ConfigMenu.qml"
    }

    ConfigCategory {
        name: i18n("Pinned Apps")
        icon: "pin"
        source: "ConfigPinnedApps.qml"
    }

    ConfigCategory {
        name: i18n("Session Buttons")
        icon: "system-shutdown"
        source: "ConfigSessionButtons.qml"
    }
}
