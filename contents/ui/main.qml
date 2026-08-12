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

    Plasmoid.icon: plasmoid.configuration.icon || "start-here"
    property string searchText: ""
    signal closeContextMenus()

    // Pinned groups are stored as JSON in the plasmoid configuration.
    // KDE's favorites model itself remains untouched; groups only control
    // how pinned applications are presented inside this launcher.
    property var pinnedGroups: []
    property bool pinnedGroupsEnabled: plasmoid.configuration.enablePinnedGroups
    readonly property int maxPinnedGroupApps: 12

    function loadPinnedGroups() {
        var raw = plasmoid.configuration.pinnedGroups || "[]"

        try {
            var parsed = JSON.parse(raw)
            pinnedGroups = Array.isArray(parsed) ? parsed : []
        } catch (error) {
            console.warn("🦊 Could not load pinned groups:", error)
            pinnedGroups = []
        }
    }

    function savePinnedGroups(groups) {
        pinnedGroups = groups
        plasmoid.configuration.pinnedGroups = JSON.stringify(groups)
    }

    function copyPinnedGroups() {
        return JSON.parse(JSON.stringify(pinnedGroups || []))
    }

    function groupIndex(groupId) {
        for (var i = 0; i < pinnedGroups.length; ++i) {
            if (String(pinnedGroups[i].id) === String(groupId)) {
                return i
            }
        }

        return -1
    }

    function isFavoriteGrouped(favoriteId) {
        var id = String(favoriteId || "")

        if (!id) {
            return false
        }

        for (var i = 0; i < pinnedGroups.length; ++i) {
            var apps = pinnedGroups[i].apps || []

            if (apps.indexOf(id) >= 0) {
                return true
            }
        }

        return false
    }

    function favoriteBelongsToGroup(favoriteId, groupId) {
        var id = String(favoriteId || "")
        var index = groupIndex(groupId)

        if (!id || index < 0) {
            return false
        }

        return (pinnedGroups[index].apps || []).indexOf(id) >= 0
    }

    function addFavoriteToGroup(favoriteId, groupId) {
        var id = String(favoriteId || "")
        var groups = copyPinnedGroups()
        var targetIndex = -1

        if (!id) {
            return false
        }

        // Find the destination first. This prevents an app from being
        // removed from another group if the target group is already full.
        for (var i = 0; i < groups.length; ++i) {
            if (String(groups[i].id) === String(groupId)) {
                targetIndex = i
                break
            }
        }

        if (targetIndex < 0) {
            return false
        }

        var targetApps = groups[targetIndex].apps || []

        if (targetApps.indexOf(id) >= 0) {
            return true
        }

        if (targetApps.length >= maxPinnedGroupApps) {
            return false
        }

        // A pinned app can belong to only one group at a time.
        for (var groupIndexValue = groups.length - 1; groupIndexValue >= 0; --groupIndexValue) {
            var apps = groups[groupIndexValue].apps || []
            var appIndex = apps.indexOf(id)

            if (appIndex >= 0) {
                apps.splice(appIndex, 1)

                if (apps.length === 0
                        && String(groups[groupIndexValue].id) !== String(groupId)) {
                    groups.splice(groupIndexValue, 1)
                } else {
                    groups[groupIndexValue].apps = apps
                }
            }
        }

        // Re-resolve the target after editing the copied groups.
        for (var targetSearch = 0; targetSearch < groups.length; ++targetSearch) {
            if (String(groups[targetSearch].id) === String(groupId)) {
                targetIndex = targetSearch
                break
            }
        }

        groups[targetIndex].apps.push(id)
        savePinnedGroups(groups)
        return true
    }

    function createGroupAndAdd(name, favoriteId) {
        var cleanName = String(name || "").trim()
        var id = String(favoriteId || "")

        if (!cleanName || !id) {
            return false
        }

        var groups = copyPinnedGroups()
        var groupId = "group-" + Date.now().toString(36) + "-" + Math.floor(Math.random() * 1000000).toString(36)

        groups.push({
            id: groupId,
            name: cleanName,
            apps: [id]
        })

        savePinnedGroups(groups)
        return true
    }

    function removeFavoriteFromGroup(favoriteId, groupId) {
        var id = String(favoriteId || "")
        var groups = copyPinnedGroups()

        for (var i = groups.length - 1; i >= 0; --i) {
            if (String(groups[i].id) !== String(groupId)) {
                continue
            }

            var apps = groups[i].apps || []
            var appIndex = apps.indexOf(id)

            if (appIndex >= 0) {
                apps.splice(appIndex, 1)
            }

            // Empty groups disappear automatically.
            if (apps.length === 0) {
                groups.splice(i, 1)
            } else {
                groups[i].apps = apps
            }

            break
        }

        savePinnedGroups(groups)
    }

    function removeFavoriteFromAllGroups(favoriteId) {
        var id = String(favoriteId || "")
        var groups = copyPinnedGroups()

        for (var i = groups.length - 1; i >= 0; --i) {
            var apps = groups[i].apps || []
            var appIndex = apps.indexOf(id)

            if (appIndex >= 0) {
                apps.splice(appIndex, 1)
            }

            if (apps.length === 0) {
                groups.splice(i, 1)
            } else {
                groups[i].apps = apps
            }
        }

        savePinnedGroups(groups)
    }

    function dissolveGroup(groupId) {
        var groups = copyPinnedGroups()

        for (var i = groups.length - 1; i >= 0; --i) {
            if (String(groups[i].id) === String(groupId)) {
                groups.splice(i, 1)
                break
            }
        }

        savePinnedGroups(groups)
    }

    function renameGroup(groupId, name) {
        var cleanName = String(name || "").trim()
        var groups = copyPinnedGroups()

        if (!cleanName) {
            return false
        }

        for (var i = 0; i < groups.length; ++i) {
            if (String(groups[i].id) === String(groupId)) {
                groups[i].name = cleanName
                savePinnedGroups(groups)
                return true
            }
        }

        return false
    }

    Component.onCompleted: loadPinnedGroups()

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
        // modelForRow() erzeugt in QML selbst keine Abhängigkeit. Deshalb
        // hängt die Bindung bewusst an allAppsModelRow und wird bei jedem
        // RootModel-Refresh wie im KDE-Kickoff manuell neu ausgewertet.
        property int allAppsModelRow: 0
        readonly property var allAppsModel: rootModel.modelForRow(allAppsModelRow)

        // Ansicht für "Alle": Raster oder Liste.
        // Standard bleibt das bisherige Raster.
        property bool allAppsListView: false

        // Gemeinsame alphabetische Anzeige für normale Pins und Gruppen.
        // Die KDE-Favoriten selbst bleiben unverändert; wir bauen lediglich
        // eine kleine Darstellungs-Liste für den Pinned-Bereich.
        property var pinnedDisplayEntries: []

        function comparePinnedEntries(leftEntry, rightEntry) {
            var leftName = String(leftEntry.sortName || "").toLowerCase()
            var rightName = String(rightEntry.sortName || "").toLowerCase()

            if (leftName < rightName) {
                return -1
            }

            if (leftName > rightName) {
                return 1
            }

            return 0
        }

        function schedulePinnedDisplayRebuild() {
            pinnedDisplayRebuildTimer.restart()
        }

        function rebuildPinnedDisplayEntries() {
            var entries = []
            var groupsEnabled = root.pinnedGroupsEnabled

            if (groupsEnabled) {
                for (var groupIndex = 0; groupIndex < root.pinnedGroups.length; ++groupIndex) {
                    var group = root.pinnedGroups[groupIndex]
                    var groupApps = group.apps || []
                    var previewIcons = []

                    // Show up to four small app icons as a quick preview.
                    for (var appIndex = 0; appIndex < groupApps.length && previewIcons.length < 4; ++appIndex) {
                        var groupFavoriteId = String(groupApps[appIndex] || "")

                        for (var favoriteLookup = 0; favoriteLookup < pinnedFavoriteData.count; ++favoriteLookup) {
                            var previewFavorite = pinnedFavoriteData.itemAt(favoriteLookup)

                            if (previewFavorite
                                    && previewFavorite.favoriteIdValue === groupFavoriteId) {
                                previewIcons.push(previewFavorite.decorationValue)
                                break
                            }
                        }
                    }

                    entries.push({
                        entryType: "group",
                        sortName: String(group.name || ""),
                        groupId: String(group.id || ""),
                        groupName: String(group.name || ""),
                        previewIcons: previewIcons
                    })
                }
            }

            for (var favoriteIndex = 0; favoriteIndex < pinnedFavoriteData.count; ++favoriteIndex) {
                var favorite = pinnedFavoriteData.itemAt(favoriteIndex)

                if (!favorite || !favorite.favoriteIdValue) {
                    continue
                }

                if (groupsEnabled && root.isFavoriteGrouped(favorite.favoriteIdValue)) {
                    continue
                }

                entries.push({
                    entryType: "app",
                    sortName: favorite.displayName,
                    favoriteId: favorite.favoriteIdValue,
                    displayName: favorite.displayName,
                    decoration: favorite.decorationValue
                })
            }

            entries.sort(comparePinnedEntries)
            pinnedDisplayEntries = entries
        }

        function favoriteProxyRow(favoriteId) {
            var id = String(favoriteId || "")

            for (var i = 0; i < pinnedFavoriteData.count; ++i) {
                var favorite = pinnedFavoriteData.itemAt(i)

                if (favorite && favorite.favoriteIdValue === id) {
                    return i
                }
            }

            return -1
        }

        function triggerPinnedFavorite(favoriteId) {
            var proxyRow = favoriteProxyRow(favoriteId)

            if (proxyRow < 0) {
                return
            }

            var sourceIndex = pinnedFavoritesModel.mapToSource(
                pinnedFavoritesModel.index(proxyRow, 0)
            )

            if (sourceIndex.valid) {
                rootModel.favoritesModel.trigger(sourceIndex.row, "", null)
            }
        }

        // Trigger a native Kicker action directly on the favorite's source row.
        // We intentionally do NOT read or copy model.actionList here; the
        // launcher only invokes the native actions exposed in this menu.
        function triggerPinnedFavoriteAction(favoriteId, actionId) {
            var proxyRow = favoriteProxyRow(favoriteId)

            if (proxyRow < 0) {
                return
            }

            var sourceIndex = pinnedFavoritesModel.mapToSource(
                pinnedFavoritesModel.index(proxyRow, 0)
            )

            if (!sourceIndex.valid) {
                return
            }

            var closeRequested = rootModel.favoritesModel.trigger(
                sourceIndex.row,
                String(actionId || ""),
                null
            )

            if (closeRequested) {
                plasmoid.expanded = false
            }
        }

        Timer {
            id: pinnedDisplayRebuildTimer
            interval: 1
            repeat: false
            onTriggered: launcher.rebuildPinnedDisplayEntries()
        }

        Connections {
            target: root

            function onPinnedGroupsChanged() {
                launcher.schedulePinnedDisplayRebuild()

                if (groupPopup.visible) {
                    groupPopup.rebuildApps()
                }
            }

            function onPinnedGroupsEnabledChanged() {
                launcher.schedulePinnedDisplayRebuild()

                if (!root.pinnedGroupsEnabled && groupPopup.visible) {
                    groupPopup.close()
                }
            }
        }

        Connections {
            target: rootModel

            function onRefreshed() {
                // modelForRow() is a method call and therefore does not create
                // its own QML dependency. Re-emit the dependency signal so the
                // allAppsModel binding resolves the newly-created KDE child model.
                launcher.allAppsModelRowChanged()
            }
        }

        // Breite des Launcher-Inhalts.
        readonly property int contentWidth:
            (cellWidth * columnCount) + 64

        // Maximale sichtbare Höhe des Bereichs "Alle Anwendungen".
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

            SearchBar {
                id: searchBar

                x: 32
                y: 24
                width: parent.width - 64

                searchText: root.searchText
                placeholderText: i18n("Search for apps, files and settings")

                onSearchTextEdited: function(text) {
                    root.searchText = text
                }
            }

            // Ctrl+F bringt den Fokus jederzeit direkt zurück ins Suchfeld.
            Shortcut {
                sequence: "Ctrl+F"
                enabled: plasmoid.expanded

                onActivated: {
                    searchBar.focusSearchField()
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

            // Unsichtbarer Daten-Spiegel des bereits alphabetisch sortierten
            // KDE-Favoritenmodells. Er liefert Rollen wie Name, ID und Icon an
            // unsere gemeinsame Pinned-Darstellung.
            Item {
                id: pinnedFavoriteDataHost
                width: 0
                height: 0
                visible: false

                Repeater {
                    id: pinnedFavoriteData
                    model: pinnedFavoritesModel
                    onCountChanged: launcher.schedulePinnedDisplayRebuild()

                    delegate: Item {
                        width: 0
                        height: 0

                        property string favoriteIdValue: String(model.favoriteId || "")
                        property string displayName: String(model.display || "")
                        property var decorationValue: model.decoration

                        Component.onCompleted: launcher.schedulePinnedDisplayRebuild()
                        onFavoriteIdValueChanged: launcher.schedulePinnedDisplayRebuild()
                        onDisplayNameChanged: launcher.schedulePinnedDisplayRebuild()
                        onDecorationValueChanged: launcher.schedulePinnedDisplayRebuild()
                    }
                }
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
                    model: launcher.pinnedDisplayEntries

                    delegate: Item {
                        id: pinnedEntry

                        property var entryData: modelData
                        property bool isGroup: entryData && entryData.entryType === "group"

                        height: launcher.cellHeight
                        width: launcher.cellWidth

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 12
                            color: "#30343d"
                            opacity: pinnedEntryMouseArea.containsMouse ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: 120 }
                            }
                        }

                        Rectangle {
                            id: pinnedGroupPreview
                            visible: pinnedEntry.isGroup

                            width: 46
                            height: 46
                            radius: 10

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 4

                            color: "#272b33"
                            border.color: "#454b56"
                            border.width: 1
                            clip: true

                            Grid {
                                anchors.centerIn: parent
                                columns: 2
                                spacing: 2

                                Repeater {
                                    model: pinnedEntry.entryData
                                        ? (pinnedEntry.entryData.previewIcons || [])
                                        : []

                                    delegate: Item {
                                        width: 18
                                        height: 18

                                        Kirigami.Icon {
                                            anchors.fill: parent
                                            source: modelData
                                        }
                                    }
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            visible: pinnedEntry.isGroup

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: pinnedGroupPreview.bottom
                            anchors.topMargin: 4
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4

                            text: pinnedEntry.entryData
                                ? String(pinnedEntry.entryData.groupName || "")
                                : ""

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            font.pixelSize: 13
                        }

                        Kirigami.Icon {
                            id: pinnedEntryIcon
                            visible: !pinnedEntry.isGroup

                            height: 36
                            width: 36

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 8

                            source: pinnedEntry.entryData
                                ? pinnedEntry.entryData.decoration
                                : ""
                        }

                        PlasmaComponents.Label {
                            visible: !pinnedEntry.isGroup

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: pinnedEntryIcon.bottom
                            anchors.topMargin: 4
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4

                            text: pinnedEntry.entryData
                                ? String(pinnedEntry.entryData.displayName || "")
                                : ""

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            font.pixelSize: 13
                        }

                        Controls.Menu {
                            id: pinnedGroupContextMenu

                            Connections {
                                target: root

                                function onCloseContextMenus() {
                                    pinnedGroupContextMenu.close()
                                }
                            }

                            Controls.MenuItem {
                                text: i18n("Rename group…")
                                icon.name: "edit-rename"

                                onTriggered: {
                                    renameGroupDialog.groupId = String(pinnedEntry.entryData.groupId)
                                    renameGroupDialog.groupName = String(pinnedEntry.entryData.groupName)
                                    renameGroupField.text = String(pinnedEntry.entryData.groupName)
                                    renameGroupDialog.open()
                                    renameGroupField.forceActiveFocus()
                                    renameGroupField.selectAll()
                                }
                            }

                            Controls.MenuItem {
                                text: i18n("Dissolve group")
                                icon.name: "folder-remove"

                                onTriggered: {
                                    if (groupPopup.groupId === String(pinnedEntry.entryData.groupId)) {
                                        groupPopup.close()
                                    }

                                    root.dissolveGroup(String(pinnedEntry.entryData.groupId))
                                }
                            }
                        }

                        Controls.Menu {
                            id: pinnedFavoriteContextMenu

                            Connections {
                                target: root

                                function onCloseContextMenus() {
                                    pinnedFavoriteContextMenu.close()
                                }
                            }

                            Controls.MenuItem {
                                visible: root.pinnedGroupsEnabled
                                text: i18n("Add to group…")
                                icon.name: "folder-new"

                                onTriggered: {
                                    addToGroupDialog.favoriteId = String(pinnedEntry.entryData.favoriteId)
                                    addToGroupDialog.favoriteName = String(pinnedEntry.entryData.displayName)
                                    addToGroupDialog.rebuildChoices()
                                    addToGroupDialog.open()
                                }
                            }

                            Controls.MenuSeparator { }

                            Controls.MenuItem {
                                text: i18n("Pin to Task Manager")
                                icon.name: "pin"

                                onTriggered: launcher.triggerPinnedFavoriteAction(
                                    pinnedEntry.entryData.favoriteId,
                                    "addToTaskManager"
                                )
                            }

                            Controls.MenuItem {
                                text: i18n("Edit Application…")
                                icon.name: "kmenuedit"

                                onTriggered: launcher.triggerPinnedFavoriteAction(
                                    pinnedEntry.entryData.favoriteId,
                                    "editApplication"
                                )
                            }

                            Controls.MenuSeparator { }

                            Controls.MenuItem {
                                text: i18n("Unpin")
                                icon.name: "list-remove"

                                onTriggered: {
                                    root.removeFavoriteFromAllGroups(pinnedEntry.entryData.favoriteId)
                                    rootModel.favoritesModel.removeFavorite(
                                        pinnedEntry.entryData.favoriteId
                                    )
                                }
                            }
                        }

                        MouseArea {
                            id: pinnedEntryMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor

                            onClicked: function(mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    if (pinnedEntry.isGroup) {
                                        pinnedGroupContextMenu.popup(
                                            pinnedEntryMouseArea,
                                            mouse.x,
                                            mouse.y
                                        )
                                    } else {
                                        pinnedFavoriteContextMenu.popup(
                                            pinnedEntryMouseArea,
                                            mouse.x,
                                            mouse.y
                                        )
                                    }
                                    return
                                }

                                if (pinnedEntry.isGroup) {
                                    groupPopup.groupId = String(pinnedEntry.entryData.groupId)
                                    groupPopup.groupName = String(pinnedEntry.entryData.groupName)
                                    groupPopup.rebuildApps()
                                    groupPopup.openFor(pinnedEntry)
                                    return
                                }

                                launcher.triggerPinnedFavorite(
                                    pinnedEntry.entryData.favoriteId
                                )
                            }
                        }
                    }
                }
            }

            // ─────────────────────────────────────────────
            // PINNED-GRUPPEN – Dialoge und Gruppenansicht
            // ─────────────────────────────────────────────

            ListModel {
                id: groupChoiceModel
            }

            Controls.Dialog {
                id: addToGroupDialog

                parent: launcher
                x: Math.round((launcher.width - width) / 2)
                y: Math.round((launcher.height - height) / 2)
                width: 420
                modal: true
                focus: true
                title: i18n("Add to group")
                standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel

                property string favoriteId: ""
                property string favoriteName: ""

                function rebuildChoices() {
                    groupChoiceModel.clear()

                    for (var i = 0; i < root.pinnedGroups.length; ++i) {
                        var groupApps = root.pinnedGroups[i].apps || []

                        // Full groups are intentionally omitted from the target list.
                        if (groupApps.length >= root.maxPinnedGroupApps) {
                            continue
                        }

                        groupChoiceModel.append({
                            label: String(root.pinnedGroups[i].name),
                            groupId: String(root.pinnedGroups[i].id),
                            createNew: false
                        })
                    }

                    groupChoiceModel.append({
                        label: i18n("New group…"),
                        groupId: "",
                        createNew: true
                    })

                    groupChoice.currentIndex = groupChoiceModel.count > 0 ? 0 : -1
                    newGroupField.text = ""
                }

                contentItem: Column {
                    spacing: 12

                    Controls.Label {
                        width: 360
                        wrapMode: Text.WordWrap
                        text: i18n("Add %1 to:").replace("%1", addToGroupDialog.favoriteName)
                    }

                    Controls.ComboBox {
                        id: groupChoice
                        width: 360
                        model: groupChoiceModel
                        textRole: "label"
                    }

                    Controls.TextField {
                        id: newGroupField
                        width: 360
                        visible: groupChoice.currentIndex >= 0
                                && groupChoiceModel.get(groupChoice.currentIndex).createNew
                        placeholderText: i18n("Group name")
                        onAccepted: addToGroupDialog.accept()
                    }
                }

                onAccepted: {
                    if (groupChoice.currentIndex < 0) {
                        return
                    }

                    var choice = groupChoiceModel.get(groupChoice.currentIndex)

                    if (choice.createNew) {
                        root.createGroupAndAdd(newGroupField.text, favoriteId)
                    } else {
                        root.addFavoriteToGroup(favoriteId, choice.groupId)
                    }
                }
            }

            Controls.Dialog {
                id: renameGroupDialog

                parent: launcher
                x: Math.round((launcher.width - width) / 2)
                y: Math.round((launcher.height - height) / 2)
                width: 420
                modal: true
                focus: true
                title: i18n("Rename group")
                standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel

                property string groupId: ""
                property string groupName: ""

                contentItem: Controls.TextField {
                    id: renameGroupField
                    width: 360
                    placeholderText: i18n("Group name")
                    onAccepted: renameGroupDialog.accept()
                }

                onAccepted: {
                    root.renameGroup(groupId, renameGroupField.text)
                }
            }

            Controls.Popup {
                id: groupPopup

                parent: launcher
                x: Math.round((launcher.width - width) / 2)
                y: 120
                width: Math.min(620, launcher.width - 80)
                padding: 18
                modal: false
                focus: true
                closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside

                property string groupId: ""
                property string groupName: ""
                property var appEntries: []

                // Groups are limited to 12 apps (4 columns × 3 rows), so the
                // complete group is shown at once without scrolling.
                property int visibleRows: Math.min(3, Math.max(1, Math.ceil(appEntries.length / 4)))
                property int appsAreaHeight: visibleRows * 86 + Math.max(0, visibleRows - 1) * 4
                height: 28 + 12 + appsAreaHeight + padding * 2

                function openFor(anchorItem) {
                    var point = anchorItem.mapToItem(launcher, 0, 0)
                    var desiredX = point.x + Math.round((anchorItem.width - width) / 2)
                    var desiredY = point.y + anchorItem.height + 8

                    x = Math.max(20, Math.min(desiredX, launcher.width - width - 20))

                    if (desiredY + height > launcher.height - 20) {
                        desiredY = point.y - height - 8
                    }

                    y = Math.max(20, Math.min(desiredY, launcher.height - height - 20))
                    open()
                }

                function rebuildApps() {
                    var entries = []

                    for (var i = 0; i < pinnedFavoriteData.count; ++i) {
                        var favorite = pinnedFavoriteData.itemAt(i)

                        if (!favorite || !favorite.favoriteIdValue) {
                            continue
                        }

                        if (!root.favoriteBelongsToGroup(favorite.favoriteIdValue, groupId)) {
                            continue
                        }

                        entries.push({
                            sortName: favorite.displayName,
                            favoriteId: favorite.favoriteIdValue,
                            displayName: favorite.displayName,
                            decoration: favorite.decorationValue
                        })
                    }

                    entries.sort(launcher.comparePinnedEntries)
                    appEntries = entries
                }

                background: Rectangle {
                    color: "#20232b"
                    radius: 16
                    border.color: "#3b414c"
                    border.width: 1
                }

                contentItem: Column {
                    spacing: 12

                    Item {
                        width: parent.width
                        height: 28

                        PlasmaComponents.Label {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 38
                            anchors.rightMargin: 38
                            text: groupPopup.groupName
                            font.pixelSize: 18
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        Controls.ToolButton {
                            width: 28
                            height: 28
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            icon.name: "dialog-close"
                            onClicked: groupPopup.close()
                        }
                    }

                    Flickable {
                        width: parent.width
                        height: groupPopup.appsAreaHeight
                        contentWidth: width
                        contentHeight: groupAppsGrid.implicitHeight
                        clip: true
                        interactive: false

                        Grid {
                            id: groupAppsGrid
                            width: parent.width
                            columns: 4
                            rowSpacing: 4
                            columnSpacing: 4

                            Repeater {
                                model: groupPopup.appEntries

                                delegate: Item {
                                    id: groupAppItem
                                    property var appData: modelData

                                    width: Math.floor((groupAppsGrid.width - 12) / 4)
                                    height: 86

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 10
                                        color: "#30343d"
                                        opacity: groupAppMouse.containsMouse ? 1 : 0

                                        Behavior on opacity {
                                            NumberAnimation { duration: 120 }
                                        }
                                    }

                                    Kirigami.Icon {
                                        id: groupAppIcon

                                        width: 36
                                        height: 36
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.top
                                        anchors.topMargin: 8
                                        source: groupAppItem.appData
                                            ? groupAppItem.appData.decoration
                                            : ""
                                    }

                                    PlasmaComponents.Label {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: groupAppIcon.bottom
                                        anchors.topMargin: 4
                                        anchors.leftMargin: 4
                                        anchors.rightMargin: 4
                                        text: groupAppItem.appData
                                            ? String(groupAppItem.appData.displayName || "")
                                            : ""
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                        font.pixelSize: 13
                                    }

                                    Controls.Menu {
                                        id: groupAppContextMenu

                                        Controls.MenuItem {
                                            text: i18n("Remove from group")
                                            icon.name: "go-up"

                                            onTriggered: {
                                                root.removeFavoriteFromGroup(
                                                    groupAppItem.appData.favoriteId,
                                                    groupPopup.groupId
                                                )

                                                if (root.groupIndex(groupPopup.groupId) < 0) {
                                                    groupPopup.close()
                                                } else {
                                                    groupPopup.rebuildApps()
                                                }
                                            }
                                        }

                                        Controls.MenuItem {
                                            text: i18n("Unpin")
                                            icon.name: "list-remove"

                                            onTriggered: {
                                                root.removeFavoriteFromAllGroups(
                                                    groupAppItem.appData.favoriteId
                                                )
                                                rootModel.favoritesModel.removeFavorite(
                                                    groupAppItem.appData.favoriteId
                                                )

                                                if (root.groupIndex(groupPopup.groupId) < 0) {
                                                    groupPopup.close()
                                                } else {
                                                    groupPopup.rebuildApps()
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: groupAppMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked: function(mouse) {
                                            if (mouse.button === Qt.RightButton) {
                                                groupAppContextMenu.popup(
                                                    groupAppMouse,
                                                    mouse.x,
                                                    mouse.y
                                                )
                                                return
                                            }

                                            groupPopup.close()
                                            launcher.triggerPinnedFavorite(
                                                groupAppItem.appData.favoriteId
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ─────────────────────────────────────────────
            // ALLE ANWENDUNGEN
            // ─────────────────────────────────────────────

            AllAppsView {
                id: allAppsView

                x: 0
                y: pinnedApps.y + pinnedApps.height + 25

                width: parent.width
                height: Math.max(0, parent.height - y)

                allAppsModel: launcher.allAppsModel
                favoritesModel: rootModel.favoritesModel
                contextMenuController: root

                searchText: root.searchText
                listView: launcher.allAppsListView

                columnCount: launcher.columnCount
                gridCellHeight: launcher.cellHeight
                visibleHeight: launcher.allAppsVisibleHeight

                allText: i18n("All")
                viewListText: i18n("View: List  ▾")
                viewGridText: i18n("View: Grid  ▾")
                pinText: i18n("Pin")

                onListViewToggleRequested: {
                    launcher.allAppsListView = !launcher.allAppsListView
                }
            }

            // ─────────────────────────────────────────
            // SUCHERGEBNISSE
            // Apps + Dateien + Systemeinstellungen
            // ─────────────────────────────────────────

            SearchResultsView {
                id: searchResultsView

                x: 0
                y: 100
                width: parent.width
                height: parent.height - y - 78

                searchText: root.searchText

                appsRunner: appRunnerModel
                filesResultsModel: fileSearchResultsModel
                settingsRunner: settingsRunnerModel

                favorites: rootModel.favoritesModel
                contextController: root

                columnCount: launcher.columnCount

                searchResultsText: i18n("Search results")
                appsText: "Apps"
                filesText: i18n("Files")
                settingsText: i18n("Settings")

                pinText: i18n("Pin")
                unpinText: i18n("Unpin")

                noResultsText: i18n("No results found")

                balooNoResultsText: i18n(
                    "No results found\n\n💡 Baloo only searches indexed folders.\nCheck file search under System Settings → Search → File Search."
                )

                onRemoveFavoriteFromGroupsRequested: function(favoriteId) {
                    root.removeFavoriteFromAllGroups(favoriteId)
                }

                onCloseLauncherRequested: {
                    root.searchText = ""
                    plasmoid.expanded = false
                }
            }

            // ─────────────────────────────────────────
            // Unterer Bereich
            // ─────────────────────────────────────────

            LauncherFooter {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                sessionManager: sessionManagement

                showLockButton: plasmoid.configuration.showLockButton
                showLogoutButton: plasmoid.configuration.showLogoutButton
                showRestartButton: plasmoid.configuration.showRestartButton
                showShutdownButton: plasmoid.configuration.showShutdownButton

                lockText: i18n("Lock Screen")
                logoutText: i18n("Log Out")
                restartText: i18n("Restart")
                shutdownText: i18n("Shut Down")

                onCloseLauncherRequested: {
                    plasmoid.expanded = false
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
    // ────────────────────────────────────────────
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

        appletInterface: root

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

        appletInterface: root
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

        appletInterface: root

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

        appletInterface: root

        Component.onCompleted: {
            if (globalFavorites) {
                globalFavorites.initForClient("org.kde.plasma.kicker.favorites.instance-" + Plasmoid.id)
            }

        }
    }
}
