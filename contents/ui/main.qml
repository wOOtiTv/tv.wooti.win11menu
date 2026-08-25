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

    readonly property string bundledDefaultIcon: Qt.resolvedUrl("icons/start-here.svg").toString()
    Plasmoid.icon: (!plasmoid.configuration.icon || plasmoid.configuration.icon === "start-here") ? bundledDefaultIcon : plasmoid.configuration.icon
    property string searchText: ""
    signal closeContextMenus()

    // Pinned groups are stored as JSON in the plasmoid configuration.
    // KDE's favorites model itself remains untouched; groups only control
    // how pinned applications are presented inside this launcher.
    property var pinnedGroups: []
    property bool pinnedGroupsEnabled: plasmoid.configuration.enablePinnedGroups
    readonly property int maxPinnedGroupApps: 16

    function sanitizePinnedGroups(groups) {
        var sourceGroups = Array.isArray(groups) ? groups : []
        var sanitizedGroups = []

        for (var i = 0; i < sourceGroups.length; ++i) {
            var group = sourceGroups[i]

            if (!group) {
                continue
            }

            var sourceApps = Array.isArray(group.apps) ? group.apps : []
            var apps = []

            for (var appIndex = 0;
                    appIndex < sourceApps.length
                        && apps.length < root.maxPinnedGroupApps;
                    ++appIndex) {
                var appId = String(sourceApps[appIndex] || "")

                if (appId && apps.indexOf(appId) < 0) {
                    apps.push(appId)
                }
            }

            sanitizedGroups.push({
                id: String(group.id || ""),
                name: String(group.name || ""),
                apps: apps
            })
        }

        return sanitizedGroups
    }

    function loadPinnedGroups() {
        var raw = plasmoid.configuration.pinnedGroups || "[]"

        try {
            var parsed = JSON.parse(raw)
            var sourceGroups = Array.isArray(parsed) ? parsed : []
            var sanitizedGroups = sanitizePinnedGroups(sourceGroups)
            var sanitizedRaw = JSON.stringify(sanitizedGroups)

            pinnedGroups = sanitizedGroups

            // Repair oversized or otherwise malformed stored groups once when
            // loading so hidden entries beyond the supported limit cannot remain.
            if (sanitizedRaw !== JSON.stringify(sourceGroups)) {
                plasmoid.configuration.pinnedGroups = sanitizedRaw
            }
        } catch (error) {
            console.warn("🦊 Could not load pinned groups:", error)
            pinnedGroups = []
        }
    }

    function savePinnedGroups(groups) {
        var sanitizedGroups = sanitizePinnedGroups(groups)
        pinnedGroups = sanitizedGroups
        plasmoid.configuration.pinnedGroups = JSON.stringify(sanitizedGroups)
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

        if (targetApps.length >= root.maxPinnedGroupApps) {
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

        if (targetIndex < 0) {
            return false
        }

        var currentTargetApps = groups[targetIndex].apps || []

        if (currentTargetApps.length >= root.maxPinnedGroupApps) {
            return false
        }

        currentTargetApps.push(id)
        groups[targetIndex].apps = currentTargetApps
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
        // Die Zellbreite folgt der tatsächlich verfügbaren Popup-Breite.
        readonly property int columnCount: 8
        readonly property int cellWidth: Math.max(
            1,
            Math.floor((popupWidth - 64) / columnCount)
        )
        readonly property int cellHeight: 88

        // Alphabetisch gruppiertes KDE-Modell für "Alle".
        // modelForRow() erzeugt in QML selbst keine Abhängigkeit. Deshalb
        // hängt die Bindung bewusst an allAppsModelRow und wird bei jedem
        // RootModel-Refresh wie im KDE-Kickoff manuell neu ausgewertet.
        property int allAppsModelRow: 0
        readonly property var allAppsModel: rootModel.modelForRow(allAppsModelRow)

        // Ansicht für "Alle": Raster oder Liste.
        // Die Auswahl wird pro Plasmoid-Instanz dauerhaft gespeichert.
        readonly property bool allAppsListView: plasmoid.configuration.allAppsListView

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
                    var previewEntries = []
                    var previewIcons = []

                    // Collect all grouped apps with their display names so the
                    // preview follows the same alphabetical order as the launcher.
                    for (var appIndex = 0; appIndex < groupApps.length; ++appIndex) {
                        var groupFavoriteId = String(groupApps[appIndex] || "")

                        for (var favoriteLookup = 0; favoriteLookup < pinnedFavoriteData.count; ++favoriteLookup) {
                            var previewFavorite = pinnedFavoriteData.itemAt(favoriteLookup)

                            if (previewFavorite
                                    && previewFavorite.favoriteIdValue === groupFavoriteId) {
                                previewEntries.push({
                                    sortName: previewFavorite.displayName,
                                    decoration: previewFavorite.decorationValue
                                })
                                break
                            }
                        }
                    }

                    previewEntries.sort(comparePinnedEntries)

                    // Show up to four alphabetically sorted app icons as a quick preview.
                    for (var previewIndex = 0;
                            previewIndex < previewEntries.length && previewIndex < 4;
                            ++previewIndex) {
                        previewIcons.push(previewEntries[previewIndex].decoration)
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

        // Breite des Launcher-Inhalts. 1120 px entspricht exakt v1.1.1.
        readonly property int contentWidth: Math.max(
            800,
            Math.min(1600, plasmoid.configuration.menuWidth || 1120)
        )

        // Höhe des Launcher-Inhalts. 891 px entspricht exakt v1.1.1.
        readonly property int contentHeight: Math.max(
            600,
            Math.min(1200, plasmoid.configuration.menuHeight || 891)
        )

        readonly property rect screenRect: root.availableScreenRect

        readonly property int popupHeight: Math.min(
            contentHeight,
            screenRect.height - (Kirigami.Units.gridUnit * 2)
        )

        // "Alle Anwendungen" darf die zusätzlich verfügbare Höhe nutzen.
        // Die Ansicht begrenzt sich intern weiterhin selbst auf den Platz
        // zwischen ihrem Kopfbereich und dem Footer.
        readonly property int allAppsVisibleHeight: popupHeight

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
            PinnedSection {
                id: pinnedSection

                x: 0
                y: 105
                width: parent.width

                searchText: root.searchText
                entriesModel: launcher.pinnedDisplayEntries

                columnCount: launcher.columnCount
                cellWidth: launcher.cellWidth
                cellHeight: launcher.cellHeight

                groupsEnabled: root.pinnedGroupsEnabled

                groupController: root
                favoritesModel: rootModel.favoritesModel
                launcherController: launcher
                groupDialogsController: pinnedGroupDialogs
                groupPopupController: groupPopup
                contextMenuController: root

                pinnedText: i18n("Pinned")
                renameGroupText: i18n("Rename group…")
                dissolveGroupText: i18n("Dissolve group")
                addToGroupText: i18n("Add to group…")
                pinToTaskManagerText: i18n("Pin to Task Manager")
                editApplicationText: i18n("Edit Application…")
                unpinText: i18n("Unpin")
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

            // ─────────────────────────────────────────────
            // PINNED-GRUPPEN – Dialoge und Gruppenansicht
            // ─────────────────────────────────────────────
            PinnedGroupDialogs {
                id: pinnedGroupDialogs

                popupParent: launcher

                pinnedGroups: root.pinnedGroups
                maxGroupApps: root.maxPinnedGroupApps

                addToGroupTitle: i18n("Add to group")
                addToGroupText: i18n("Add %1 to:")
                newGroupText: i18n("New group…")
                groupNamePlaceholder: i18n("Group name")
                renameGroupTitle: i18n("Rename group")

                onCreateGroupRequested: function(name, favoriteId) {
                    root.createGroupAndAdd(name, favoriteId)
                }

                onAddFavoriteToGroupRequested: function(favoriteId, groupId) {
                    root.addFavoriteToGroup(favoriteId, groupId)
                }

                onRenameGroupRequested: function(groupId, name) {
                    root.renameGroup(groupId, name)
                }
            }

            MouseArea {
                id: groupPopupDismissArea

                anchors.fill: parent
                z: 1000

                visible: groupPopup.visible
                enabled: visible

                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onPressed: function(mouse) {
                    root.closeContextMenus()
                    groupPopup.close()
                    mouse.accepted = true
                }
            }

            PinnedGroupPopup {
                id: groupPopup

                popupParent: launcher

                favoriteDataSource: pinnedFavoriteData
                groupController: root
                launcherController: launcher
                contextMenuController: root
                maxGroupApps: root.maxPinnedGroupApps

                removeFromGroupText: i18n("Remove from group")
            }

            // ─────────────────────────────────────────────
            // ALLE ANWENDUNGEN
            // ─────────────────────────────────────────────

            AllAppsView {
                id: allAppsView

                x: 0
                y: pinnedSection.y + pinnedSection.height + 25

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
                pinToTaskManagerText: i18n("Pin to Task Manager")
                editApplicationText: i18n("Edit Application…")

                onListViewToggleRequested: {
                    plasmoid.configuration.allAppsListView = !plasmoid.configuration.allAppsListView
                }

                onCloseLauncherRequested: {
                    plasmoid.expanded = false
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
                pinToTaskManagerText: i18n("Pin to Task Manager")
                editApplicationText: i18n("Edit Application…")

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
