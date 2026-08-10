import QtQuick
import QtCore
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.kitemmodels
import org.kde.plasma.private.sessions 2.0
import "Translations.js" as Translations

PlasmoidItem {
    id: root

    Plasmoid.icon: "start-here"
    property string searchText: ""
    signal closeContextMenus()

    // Per-widget translation override.
    // "system" follows the current system locale; any other configured
    // language applies only to this plasmoid instance.
    function i18n(sourceText) {
        return Translations.translate(
            sourceText,
            plasmoid.configuration.language,
            Qt.locale().name
        )
    }

    onExpandedChanged: function() {
        if (!plasmoid.expanded) {
            searchText = ""
            closeContextMenus()
        }
    }

    // ─────────────────────────────────────────────
    // Launcher – Hauptfenster
    // ─────────────────────────────────────────────

    fullRepresentation: Item {
        id: launcher

        // ─────────────────────────────────────────
        // Dynamische Popup-Größe
        // ─────────────────────────────────────────

        readonly property var appletInterface: Plasmoid

        // 8 Spalten wie bei unserem aktuellen Layout.
        // Die Zellgröße bestimmt die tatsächliche Breite des Menüs.
        readonly property int columnCount: 8
        readonly property int cellWidth: 132
        readonly property int cellHeight: 88

        // Alphabetisch gruppiertes KDE-Modell für "Alle".
        // modelForRow(0) ist das "Alle Anwendungen"-Modell;
        // dessen Einträge sind die Buchstabengruppen (#, A, B, C ...).
        property var allAppsModel: null

        // Ansicht für "Alle": Raster oder Liste.
        // Standard bleibt das bisherige Raster.
        property bool allAppsListView: false

        readonly property int allAppsColumnCount:
            allAppsListView ? 1 : columnCount

        readonly property int allAppsCellHeight:
            allAppsListView ? 58 : cellHeight

        readonly property int sectionHeaderHeight: 34
        readonly property int sectionSpacing: 8

        Timer {
            id: allAppsModelInitTimer
            interval: 150
            repeat: false
            running: true
            onTriggered: launcher.refreshAllAppsModel()
        }

        function refreshAllAppsModel() {
            var model = rootModel.modelForRow(0)
            if (model) {
                allAppsModel = model
            }
        }

        function allAppsContentHeight() {
            if (!allAppsModel) {
                return cellHeight * appRows
            }

            var total = 0

            for (var i = 0; i < allAppsModel.count; ++i) {
                var groupModel = allAppsModel.modelForRow(i)

                if (!groupModel) {
                    continue
                }

                total += sectionHeaderHeight
                total += Math.ceil(
                    groupModel.count / allAppsColumnCount
                ) * allAppsCellHeight
                total += sectionSpacing
            }

            return Math.max(total, cellHeight * appRows)
        }

        // Sichtbare App-Zeilen im Bereich "Alle".
        // Das Menü wächst zusätzlich automatisch, wenn mehrere
        // Reihen angehefteter Apps vorhanden sind.
        readonly property int appRows: 7
        readonly property int pinnedRows: Math.max(1, Math.ceil((rootModel.favoritesModel ? rootModel.favoritesModel.count : 0) / columnCount))

        readonly property int contentWidth:
            (cellWidth * columnCount) + 64

        // Bewusst kompakte Grundhöhe:
        // "Alle" bekommt seinen eigenen Scrollbereich.
        readonly property int allAppsVisibleHeight: 520

        // ─────────────────────────────────────────
        // FESTE MENÜHÖHE
        // ─────────────────────────────────────────
        //
        // Diese Höhe entspricht exakt dem aktuellen Layout
        // mit EINER Pinned-Zeile (8 Apps).
        //
        // Wichtig:
        // pinnedRows wird hier NICHT mehr verwendet.
        // Eine 9. App darf deshalb niemals die Außenhöhe
        // des Menüs verändern.
        readonly property int fixedMenuHeight:
            24 + 46 + 35 +
            88 +
            25 + 35 + 40 +
            allAppsVisibleHeight +
            78

        readonly property rect screenRect: root.availableScreenRect

        readonly property int popupHeight: Math.min(
            fixedMenuHeight,
            screenRect.height - (Kirigami.Units.gridUnit * 2)
        )

        readonly property int popupWidth: Math.min(
            contentWidth,
            screenRect.width - (Kirigami.Units.gridUnit * 2)
        )

        Layout.minimumWidth: popupWidth
        Layout.maximumWidth: popupWidth
        Layout.preferredWidth: popupWidth

        Layout.minimumHeight: popupHeight
        Layout.maximumHeight: popupHeight
        Layout.preferredHeight: popupHeight

        height: popupHeight
        width: popupWidth
        clip: true

        Rectangle {
            id: launcherBackground

            anchors.fill: parent

            color: "#18191f"
            radius: 18
            clip: true

        // ─────────────────────────────────────────
        // Hintergrund
        // ─────────────────────────────────────────

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#20232b"
            opacity: 0.92
        }

        // ─────────────────────────────────────────
        // Suchfeld
        // ─────────────────────────────────────────

        Rectangle {
            id: searchBox

            x: 32
            y: 24
            height: 46
            width: parent.width - 64

            radius: 23
            color: "#17191f"
            border.color: "#30343d"
            border.width: 1

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter

                text: "⌕"
                color: "#4da3ff"
                font.pixelSize: 25
            }

            PlasmaComponents.TextField {
                id: searchField

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                leftPadding: 52
                rightPadding: 16

                placeholderText: i18n("Search for apps, files and settings")

                background: null

                font.pixelSize: 15

                text: root.searchText

                onTextEdited: {
                    root.searchText = text
                }
            }
        }

        // Ctrl+F bringt den Fokus jederzeit direkt zurück ins Suchfeld.
        Shortcut {
            sequence: "Ctrl+F"
            enabled: plasmoid.expanded

            onActivated: {
                searchField.forceActiveFocus()
            }
        }

        // ─────────────────────────────────────────────
        // ANGEHEFTETE ANWENDUNGEN
        // ─────────────────────────────────────────────

        PlasmaComponents.Label {
            id: pinnedLabel

            x: 32
            y: 105

            text: i18n("Pinned")

            font.pixelSize: 16
            font.bold: true

            visible: root.searchText.length === 0
        }

        Grid {
            id: pinnedApps

            x: 32
            y: 145

            columns: 8
            rowSpacing: 0
            columnSpacing: 0

            visible: root.searchText.length === 0

            Repeater {
                model: pinnedFavoritesModel

                delegate: Item {
                    id: favoriteItem

                    height: launcher.cellHeight
                    width: launcher.cellWidth

                    Rectangle {
                        id: favoriteHover

                        anchors.fill: parent
                        anchors.margins: 2

                        radius: 12

                        color: "#30343d"

                        opacity: favoriteMouseArea.containsMouse ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                            }
                        }
                    }

                    Kirigami.Icon {
                        id: favoriteIcon

                        height: 36
                        width: 36

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 8

                        source: model.decoration
                    }

                    PlasmaComponents.Label {
                        anchors.left: parent.left
                        anchors.right: parent.right

                        anchors.top: favoriteIcon.bottom
                        anchors.topMargin: 4

                        anchors.leftMargin: 4
                        anchors.rightMargin: 4

                        text: model.display

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        maximumLineCount: 1
                        elide: Text.ElideRight

                        font.pixelSize: 13
                    }

                    Controls.Menu {
                        id: favoriteContextMenu

                        Connections {
                            target: root

                            function onCloseContextMenus() {
                                favoriteContextMenu.close()
                            }
                        }

                        Controls.MenuItem {
                            text: i18n("Unpin")
                            icon.name: "list-remove"

                            onTriggered: {
                                rootModel.favoritesModel.removeFavorite(
                                    model.favoriteId
                                )
                            }
                        }
                    }

                    MouseArea {
                        id: favoriteMouseArea

                        anchors.fill: parent

                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        cursorShape: Qt.PointingHandCursor

                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                favoriteContextMenu.popup(
                                    favoriteMouseArea,
                                    mouse.x,
                                    mouse.y
                                )
                                return
                            }

                            console.log("🦊 PINNED CLICK:", model.display, model.favoriteId)
                            Qt.callLater(function() {
                                var sourceIndex = pinnedFavoritesModel.mapToSource(
                                    pinnedFavoritesModel.index(index, 0)
                                )

                                if (sourceIndex.valid) {
                                    rootModel.favoritesModel.trigger(
                                        sourceIndex.row,
                                        "",
                                        null
                                    )
                                }
                            })
                        }
                    }
                }
            }
        }

        // ─────────────────────────────────────────────
        // ALLE ANWENDUNGEN
        // ─────────────────────────────────────────────

        PlasmaComponents.Label {
            id: allAppsLabel

            x: 32

            y: pinnedApps.y + pinnedApps.height + 25

            text: i18n("All")

            font.pixelSize: 16
            font.bold: true

            visible: root.searchText.length === 0
        }

        PlasmaComponents.Label {
            id: viewLabel

            x: parent.width - 140

            y: allAppsLabel.y

            text: launcher.allAppsListView
                ? i18n("View: List  ▾")
                : i18n("View: Grid  ▾")

            font.pixelSize: 14
            opacity: viewToggleMouseArea.containsMouse ? 1.0 : 0.85

            visible: root.searchText.length === 0

            MouseArea {
                id: viewToggleMouseArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    launcher.allAppsListView = !launcher.allAppsListView
                }
            }
        }

        // ─────────────────────────────────────────
        // ALLE APPS – ALPHABETISCH
        // ─────────────────────────────────────────

        Flickable {
            id: allAppsScroll

            x: 32
            y: allAppsLabel.y + 40

            width: parent.width - 64
            height: Math.max(
                0,
                Math.min(
                    launcher.allAppsVisibleHeight,
                    parent.height - y - 100
                )
            )

            clip: true

            contentWidth: width
            contentHeight: launcher.allAppsContentHeight()

            boundsBehavior: Flickable.StopAtBounds

            // Dezente, dauerhaft sichtbare Scrollbar wie bei KDE/Windows 11.
            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AlwaysOn

                width: 6

                contentItem: Rectangle {
                    implicitWidth: 5
                    radius: width / 2
                    color: "#555a66"
                    opacity: parent.pressed ? 0.9 : 0.65
                }

                background: Rectangle {
                    color: "transparent"
                }
            }

            visible: root.searchText.length === 0

            Column {
                id: allAppsColumn

                width: allAppsScroll.width
                spacing: 0

                Repeater {
                    model: launcher.allAppsModel
                        ? launcher.allAppsModel.count
                        : 0

                    delegate: Item {
                        id: appSection

                        width: allAppsColumn.width

                        property var sectionModel: launcher.allAppsModel
                            ? launcher.allAppsModel.modelForRow(index)
                            : null

                        height: launcher.sectionHeaderHeight +
                                (sectionModel
                                 ? Math.ceil(
                                       sectionModel.count /
                                       launcher.allAppsColumnCount
                                   ) * launcher.allAppsCellHeight
                                 : 0) +
                                launcher.sectionSpacing

                        PlasmaComponents.Label {
                            id: sectionLabel

                            x: 0
                            y: 0

                            width: parent.width
                            height: launcher.sectionHeaderHeight

                            text: appSection.sectionModel
                                ? (appSection.sectionModel.description === "0-9"
                                   ? "#"
                                   : appSection.sectionModel.description)
                                : ""

                            font.pixelSize: 15
                            font.bold: true

                            verticalAlignment: Text.AlignVCenter
                        }

                        GridView {
                            id: sectionGrid

                            x: 0
                            y: sectionLabel.height

                            width: parent.width
                            height: appSection.sectionModel
                                ? Math.ceil(
                                      appSection.sectionModel.count /
                                      launcher.allAppsColumnCount
                                  ) * launcher.allAppsCellHeight
                                : 0

                            cellWidth: width / launcher.allAppsColumnCount
                            cellHeight: launcher.allAppsCellHeight

                            interactive: false
                            clip: false

                            model: appSection.sectionModel

                            delegate: Item {
                                id: appItem

                                width: sectionGrid.cellWidth
                                height: sectionGrid.cellHeight

                                Rectangle {
                                    id: hoverBackground

                                    anchors.fill: parent
                                    anchors.margins: 2

                                    radius: 12

                                    color: "#30343d"

                                    opacity: mouseArea.containsMouse ? 1 : 0

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 120
                                        }
                                    }
                                }

                                Kirigami.Icon {
                                    id: appIcon

                                    width: 36
                                    height: 36

                                    x: launcher.allAppsListView
                                        ? 16
                                        : (parent.width - width) / 2

                                    y: launcher.allAppsListView
                                        ? (parent.height - height) / 2
                                        : 8

                                    source: model.decoration
                                }

                                PlasmaComponents.Label {
                                    x: launcher.allAppsListView
                                        ? appIcon.x + appIcon.width + 12
                                        : 4

                                    y: launcher.allAppsListView
                                        ? (parent.height - height) / 2
                                        : appIcon.y + appIcon.height + 4

                                    width: launcher.allAppsListView
                                        ? parent.width - appIcon.x - appIcon.width - 28
                                        : parent.width - 8

                                    height: launcher.allAppsListView
                                        ? 28
                                        : parent.height - appIcon.height - appIcon.y - 4

                                    text: model.display

                                    horizontalAlignment: launcher.allAppsListView
                                        ? Text.AlignLeft                                        : Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter

                                    maximumLineCount: 1
                                    elide: Text.ElideRight

                                    font.pixelSize: 13
                                }

                                Controls.Menu {
                                    id: appContextMenu

                                    Connections {
                                        target: root

                                        function onCloseContextMenus() {
                                            appContextMenu.close()
                                        }
                                    }

                                    Controls.MenuItem {
                                        text: i18n("Pin")
                                        icon.name: "list-add"

                                        onTriggered: {
                                            var favoriteId = model.favoriteId

                                            if (favoriteId) {
                                                rootModel.favoritesModel.addFavorite(
                                                    favoriteId
                                                )
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: mouseArea

                                    anchors.fill: parent

                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            appContextMenu.popup(
                                                mouseArea,
                                                mouse.x,
                                                mouse.y
                                            )
                                            return
                                        }

                                        console.log("🦊 ALL APPS CLICK:", model.display, model.favoriteId)
                                        Qt.callLater(function() {
                                            appSection.sectionModel.trigger(index, "", null)
                                        })
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ─────────────────────────────────────────
        // SUCHERGEBNISSE
        // Apps + Dateien + Systemeinstellungen
        // Ein gemeinsamer Scrollbereich für die komplette Suche.
        // ─────────────────────────────────────────

        Flickable {
            id: searchResultsScroll

            x: 0
            y: 100
            width: parent.width
            height: parent.height - y - 78

            clip: true

            visible: root.searchText.length > 0   // ✅ NUR diese Zeile hinzufügen!

            contentWidth: width
            contentHeight: Math.max(
                settingsSearchGrid.visible
                    ? settingsSearchGrid.y + settingsSearchGrid.height + 30
                    : fileSearchGrid.visible
                        ? fileSearchGrid.y + fileSearchGrid.height + 30
                        : appSearchGrid.visible
                            ? appSearchGrid.y + appSearchGrid.height + 30
                            : noSearchResultsLabel.y + noSearchResultsLabel.height + 30,
                height
            )

            boundsBehavior: Flickable.StopAtBounds

            // Ein einziger dezenter Scrollbalken für die komplette Suche.
            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AlwaysOn

                width: 6

                contentItem: Rectangle {
                    implicitWidth: 5
                    radius: width / 2
                    color: "#555a66"
                    opacity: parent.pressed ? 0.9 : 0.65
                }

                background: Rectangle {
                    color: "transparent"
                }
            }

            PlasmaComponents.Label {
                id: searchResultsLabel

                x: 32
                y: 5

                text: i18n("Search results")

                font.pixelSize: 16
                font.bold: true

                visible: root.searchText.length > 0
            }

            PlasmaComponents.Label {
                id: appsResultsLabel

                x: 32
                y: 45

                text: "Apps"

                font.pixelSize: 14
                font.bold: true
                opacity: 0.85

                visible: root.searchText.length > 0 && appSearchGrid.count > 0
            }

            GridView {
                id: appSearchGrid

                x: 32
                y: 75

                height: appSearchGrid.count > 0
                    ? Math.ceil(appSearchGrid.count / launcher.columnCount) * appSearchGrid.cellHeight
                    : 0
                width: parent.width - 64

                clip: true

                cellHeight: 80
                cellWidth: width / launcher.columnCount

                visible: root.searchText.length > 0 && appSearchGrid.count > 0

                interactive: false

                model: appRunnerModel.count > 0 ? appRunnerModel.modelForRow(0) : null

                delegate: Item {
                    id: searchAppItem

                    height: appSearchGrid.cellHeight
                    width: appSearchGrid.cellWidth

                    Rectangle {
                        id: searchAppHover

                        anchors.fill: parent
                        anchors.margins: 2

                        radius: 12
                        color: "#30343d"

                        opacity: searchAppMouseArea.containsMouse ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: 120 }
                        }
                    }

                    Kirigami.Icon {
                        id: searchAppIcon

                        width: 36
                        height: 36

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 8

                        source: model.decoration
                    }

                    PlasmaComponents.Label {
                        anchors.left: parent.left
                        anchors.right: parent.right

                        anchors.top: searchAppIcon.bottom
                        anchors.topMargin: 5

                        anchors.leftMargin: 4
                        anchors.rightMargin: 4

                        text: model.display

                        horizontalAlignment: Text.AlignHCenter

                        maximumLineCount: 2
                        elide: Text.ElideRight

                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: searchAppMouseArea

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            appSearchGrid.model.trigger(index, "", null)
                            root.searchText = ""
                            plasmoid.expanded = false
                        }
                    }
                }
            }

            PlasmaComponents.Label {
                id: filesResultsLabel

                x: 32

                // Wenn Apps fehlen, rutscht "Dateien" direkt unter
                // "Suchergebnisse", statt eine leere App-Fläche zu lassen.
                y: appSearchGrid.count > 0
                    ? appSearchGrid.y + appSearchGrid.height + 18
                    : 45

                text: i18n("Files")

                font.pixelSize: 14
                font.bold: true
                opacity: 0.85

                visible: root.searchText.length > 0 && fileSearchGrid.count > 0
            }

            GridView {
                id: fileSearchGrid

                x: 32

                y: filesResultsLabel.y + 30

                height: fileSearchGrid.count > 0
                    ? Math.ceil(fileSearchGrid.count / launcher.columnCount) * fileSearchGrid.cellHeight
                    : 0
                width: parent.width - 64

                clip: true

                cellHeight: 80
                cellWidth: width / launcher.columnCount

                visible: root.searchText.length > 0 && fileSearchGrid.count > 0

                interactive: false

                // Native KDE/KRunner-Dateisuche über den Baloo-Runner.
                model: fileSearchResultsModel

                delegate: Item {
                    id: searchFileItem

                    height: fileSearchGrid.cellHeight
                    width: fileSearchGrid.cellWidth

                    Rectangle {
                        id: searchFileHover

                        anchors.fill: parent
                        anchors.margins: 2

                        radius: 12
                        color: "#30343d"

                        opacity: searchFileMouseArea.containsMouse ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: 120 }
                        }
                    }

                    Kirigami.Icon {
                        id: searchFileIcon

                        width: 36
                        height: 36

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 8

                        source: model.decoration || "text-x-generic"
                    }

                    PlasmaComponents.Label {
                        anchors.left: parent.left
                        anchors.right: parent.right

                        anchors.top: searchFileIcon.bottom
                        anchors.topMargin: 5

                        anchors.leftMargin: 4
                        anchors.rightMargin: 4

                        text: model.display

                        horizontalAlignment: Text.AlignHCenter

                        maximumLineCount: 2
                        elide: Text.ElideRight

                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: searchFileMouseArea

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (fileSearchGrid.model) {
                                fileSearchGrid.model.trigger(index, "", null)
                            }
                            root.searchText = ""
                            plasmoid.expanded = false
                        }
                    }
                }
            }

            PlasmaComponents.Label {
                id: settingsResultsLabel

                x: 32

                // Einstellungen folgen immer direkt auf den letzten
                // tatsächlich sichtbaren Bereich.
                y: fileSearchGrid.count > 0
                    ? fileSearchGrid.y + fileSearchGrid.height + 18
                    : appSearchGrid.count > 0
                        ? appSearchGrid.y + appSearchGrid.height + 18
                        : 45

                text: i18n("Settings")

                font.pixelSize: 14
                font.bold: true
                opacity: 0.85

                visible: root.searchText.length > 0 && settingsSearchGrid.count > 0
            }

            GridView {
                id: settingsSearchGrid

                x: 32

                y: settingsResultsLabel.y + 30

                height: settingsSearchGrid.count > 0
                    ? Math.ceil(settingsSearchGrid.count / launcher.columnCount) * settingsSearchGrid.cellHeight
                    : 0
                width: parent.width - 64

                clip: true

                cellHeight: 80
                cellWidth: width / launcher.columnCount

                visible: root.searchText.length > 0 && settingsSearchGrid.count > 0

                interactive: false

                model: settingsRunnerModel.count > 0 ? settingsRunnerModel.modelForRow(0) : null

                delegate: Item {
                    id: searchSettingsItem

                    height: settingsSearchGrid.cellHeight
                    width: settingsSearchGrid.cellWidth

                    Rectangle {
                        id: searchSettingsHover

                        anchors.fill: parent
                        anchors.margins: 2

                        radius: 12
                        color: "#30343d"

                        opacity: searchSettingsMouseArea.containsMouse ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: 120 }
                        }
                    }

                    Kirigami.Icon {
                        id: searchSettingsIcon

                        width: 36
                        height: 36

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 8

                        source: model.decoration
                    }

                    PlasmaComponents.Label {
                        anchors.left: parent.left
                        anchors.right: parent.right

                        anchors.top: searchSettingsIcon.bottom
                        anchors.topMargin: 5

                        anchors.leftMargin: 4
                        anchors.rightMargin: 4

                        text: model.display

                        horizontalAlignment: Text.AlignHCenter

                        maximumLineCount: 2
                        elide: Text.ElideRight

                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: searchSettingsMouseArea

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            settingsSearchGrid.model.trigger(index, "", null)
                            root.searchText = ""
                            plasmoid.expanded = false
                        }
                    }
                }
            }

            PlasmaComponents.Label {
                id: noSearchResultsLabel

                anchors.left: parent.left
                anchors.right: parent.right

                y: 75
                height: 150

                text: root.searchText.length >= 3
                    && fileSearchResultsModel
                    && fileSearchResultsModel.count === 0
                    ? i18n("No results found\n\n💡 Baloo only searches indexed folders.\nCheck file search under System Settings → Search → File Search.")
                    : i18n("No results found")

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                font.pixelSize: 16
                opacity: 0.7

                visible: root.searchText.length > 0
                    && appSearchGrid.count === 0
                    && fileSearchGrid.count === 0
                    && settingsSearchGrid.count === 0
            }
        }

        // Unterer Bereich
        // ─────────────────────────────────────────

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: 78
            radius: 18

            color: "#15171d"
        }

        // ─────────────────────────────────────────
        // Aktueller Benutzer
        // ─────────────────────────────────────────

        KCoreAddons.KUser {
            id: currentUser
        }

        Item {
            id: userInfo

            anchors.left: parent.left
            anchors.leftMargin: 24

            anchors.verticalCenter: parent.bottom
            anchors.verticalCenterOffset: -39

            width: 250
            height: 48

            // ─────────────────────────────────────
            // Benutzer-Avatar
            // ─────────────────────────────────────

            Rectangle {
                id: avatarFrame

                width: 32
                height: 32

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                radius: width / 2
                color: "#30343d"

                clip: true

                Image {
                    id: userAvatar

                    anchors.fill: parent

                    source: currentUser.faceIconUrl

                    fillMode: Image.PreserveAspectCrop

                    asynchronous: true
                    cache: false
                }

                // Macht das Benutzerbild tatsächlich kreisrund.
                // Das runde Rectangle allein würde das Bild nur
                // innerhalb eines rechteckigen Clipping-Bereichs halten.
                OpacityMask {
                    anchors.fill: userAvatar

                    source: userAvatar
                    maskSource: avatarMask

                    visible: userAvatar.status === Image.Ready
                }

                Rectangle {
                    id: avatarMask

                    anchors.fill: parent
                    radius: width / 2
                    color: "white"

                    visible: false
                }

                // Falls kein Avatar vorhanden ist oder das Bild
                // nicht geladen werden kann, wird ein neutrales
                // Benutzer-Symbol angezeigt.
                Kirigami.Icon {
                    anchors.centerIn: parent

                    width: 24
                    height: 24

                    source: "user"

                    visible: userAvatar.status !== Image.Ready
                }
            }

            // ─────────────────────────────────────
            // Benutzername
            // ─────────────────────────────────────

            PlasmaComponents.Label {
                anchors.left: avatarFrame.right
                anchors.leftMargin: 12

                anchors.right: parent.right
                anchors.verticalCenter: avatarFrame.verticalCenter

                text: currentUser.fullName

                font.pixelSize: 15
                font.bold: true

                maximumLineCount: 1
                elide: Text.ElideRight
            }
        }

        // ─────────────────────────────────────────
        // Sitzungs- und Energieaktionen
        // ─────────────────────────────────────────

        Row {
            id: sessionActions

            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.bottom
            anchors.verticalCenterOffset: -39

            spacing: 8

            Rectangle {
                id: logoutButton

                width: 118
                height: 42
                radius: 12

                color: logoutMouse.containsMouse
                    ? "#30343d"
                    : "transparent"

                opacity: sessionManagement.canLogout ? 1 : 0.45

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                Kirigami.Icon {
                    width: 20
                    height: 20

                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter

                    source: "system-log-out"
                }

                PlasmaComponents.Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 42
                    anchors.verticalCenter: parent.verticalCenter

                    text: i18n("Log Out")
                    font.pixelSize: 13
                }

                MouseArea {
                    id: logoutMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: sessionManagement.canLogout
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                    onClicked: {
                        sessionManagement.requestLogout(1)
                    }
                }
            }

            Rectangle {
                id: rebootButton

                width: 112
                height: 42
                radius: 12

                color: rebootMouse.containsMouse
                    ? "#30343d"
                    : "transparent"

                opacity: sessionManagement.canReboot ? 1 : 0.45

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                Kirigami.Icon {
                    width: 20
                    height: 20

                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter

                    source: "system-reboot"
                }

                PlasmaComponents.Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 42
                    anchors.verticalCenter: parent.verticalCenter

                    text: i18n("Restart")
                    font.pixelSize: 13
                }

                MouseArea {
                    id: rebootMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: sessionManagement.canReboot
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                    onClicked: {
                        sessionManagement.requestReboot(1)
                    }
                }
            }

            Rectangle {
                id: shutdownButton

                width: 108
                height: 42
                radius: 12

                color: shutdownMouse.containsMouse
                    ? "#30343d"
                    : "transparent"

                opacity: sessionManagement.canShutdown ? 1 : 0.45

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                Kirigami.Icon {
                    width: 20
                    height: 20

                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter

                    source: "system-shutdown"
                }

                PlasmaComponents.Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 42
                    anchors.verticalCenter: parent.verticalCenter

                    text: i18n("Shut Down")
                    font.pixelSize: 13
                }

                MouseArea {
                    id: shutdownMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: sessionManagement.canShutdown
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                    onClicked: {
                        sessionManagement.requestShutdown(1)
                    }
                }
            }
        }
        }
    }

    // ─────────────────────────────────────────────
    // KDE Session Management
    // ─────────────────────────────────────────────

    SessionManagement {
        id: sessionManagement
    }

    // ─────────────────────────────────────────────
    // KDE Kicker – Anwendungsdaten
    // ─────────────────────────────────────────────

    property QtObject globalFavorites: rootModel.favoritesModel
    property QtObject systemFavorites: rootModel.systemFavoritesModel

    // ─────────────────────────────────────────────
    // Angeheftete Anwendungen – alphabetische Anzeige
    // ─────────────────────────────────────────────
    //
    // Das originale KDE-Favoritenmodell bleibt unverändert.
    // Nur die Darstellung wird alphabetisch nach `display` sortiert.
    //
    KSortFilterProxyModel {
        id: pinnedFavoritesModel

        sourceModel: rootModel.favoritesModel
        sortRoleName: "display"
        sortOrder: Qt.AscendingOrder
    }

    // ─────────────────────────────────────────────
    // KRunner Suche
    // Apps und Systemeinstellungen getrennt
    // ─────────────────────────────────────────────

    Kicker.RunnerModel {
        id: appRunnerModel

        appletInterface: plasmoid

        favoritesModel: rootModel.favoritesModel

        query: root.searchText

        runners: [
            "krunner_services"
        ]
    }

    // ─────────────────────────────────────────────
    // KDE/KRunner – Dateisuche über den nativen Baloo-Runner
    // ─────────────────────────────────────────────
    //
    // Wir durchsuchen Home NICHT selbst.
    // KRunner/Baloo übernimmt Suche UND Aktivierung der Treffer.
    // Das entspricht dem Mechanismus des KDE/Kicker-Menüs.
    //

    Kicker.RunnerModel {
        id: fileRunnerModel

        appletInterface: plasmoid
        favoritesModel: rootModel.favoritesModel

        query: root.searchText

        runners: [
            "baloosearch"
        ]

        // Baloo kann nur Treffer liefern, die tatsächlich indiziert
        // und nicht explizit aus der Dateisuche ausgeschlossen sind.
        // Bei einer leeren Suche geben wir einen hilfreichen Hinweis
        // in die Plasma/QML-Konsole aus – ohne zusätzliche Scans.
        onCountChanged: {
            if (count === 0 && root.searchText.length >= 3) {
                console.log(
                    "💡 Keine Dateitreffer: Baloo prüft nur indizierte Ordner. " +
                    "Dateisuche konfigurieren unter Systemeinstellungen → Suche → Dateisuche."
                )
            }
        }
    }

    readonly property var fileSearchResultsModel:
        fileRunnerModel.count > 0
            ? fileRunnerModel.modelForRow(0)
            : null

    Kicker.RunnerModel {
        id: settingsRunnerModel

        appletInterface: plasmoid

        favoritesModel: rootModel.favoritesModel

        query: root.searchText

        runners: [
            "krunner_systemsettings"
        ]
    }

    // ─────────────────────────────────────────────
    // KDE Kicker – Root Model
    // ─────────────────────────────────────────────

    Kicker.RootModel {
        id: rootModel

        showAllApps: true
        showAllAppsCategorized: true
        showRecentApps: false
        showRecentDocs: false

        appletInterface: plasmoid

        Component.onCompleted: {
            if (globalFavorites) {
                globalFavorites.initForClient("org.kde.plasma.kicker")
            }

            // Warten, bis fullRepresentation initialisiert wurde
            Qt.callLater(function() {
                if (fullRepresentation && fullRepresentation.refreshAllAppsModel) {
                    fullRepresentation.refreshAllAppsModel()
                }
            })
        }
    }

    Connections {
        target: rootModel

        function onRefreshed() {
            Qt.callLater(function() {
                if (fullRepresentation && fullRepresentation.refreshAllAppsModel) {
                    fullRepresentation.refreshAllAppsModel()
                }
            })
        }
    }
}
