import QtQuick
import QtQuick.Controls as Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "Translations.js" as Translations

Item {
    id: pinnedSection

    property string searchText: ""
    property var entriesModel: []
    property var visualEntries: []

    property int columnCount: 8
    property int cellWidth: 132
    property int cellHeight: 88
    readonly property int iconSize: Math.max(
        24,
        Math.min(48, Plasmoid.configuration.iconSize || 36)
    )
    readonly property int hoverPadding: 4
    readonly property int hoverWidth: iconSize + 80

    readonly property int effectiveColumnCount: Math.max(
        columnCount,
        Math.floor((width - 64) / 132)
    )
    readonly property int effectiveCellWidth: Math.max(
        1,
        Math.floor((width - 64) / effectiveColumnCount)
    )

    property bool groupsEnabled: true

    property var groupController
    property var favoritesModel
    property var launcherController
    property var groupDialogsController
    property var groupPopupController
    property var contextMenuController

    property string pinnedText: ""
    property string renameGroupText: ""
    property string dissolveGroupText: ""
    property string addToGroupText: ""
    property string pinToTaskManagerText: ""
    property string editApplicationText: ""
    readonly property string manageApplicationText: Translations.translate(
        "Uninstall or Manage Add-Ons…",
        Plasmoid.configuration.language,
        Qt.locale().name
    )
    property string unpinText: ""

    property bool layoutReady: false
    readonly property real contentBottom: pinnedApps.y + pinnedApps.height

    function entryOrderKey(entry) {
        if (!entry) {
            return ""
        }

        if (entry.entryType === "group") {
            var groupId = String(entry.groupId || "")
            return groupId ? "group:" + groupId : ""
        }

        var favoriteId = String(entry.favoriteId || "")
        return favoriteId ? "app:" + favoriteId : ""
    }

    function loadPinnedOrder() {
        var raw = String(Plasmoid.configuration.pinnedOrder || "[]")

        try {
            var parsed = JSON.parse(raw)
            return Array.isArray(parsed) ? parsed : []
        } catch (error) {
            console.warn("🦊 Could not load pinned order:", error)
            return []
        }
    }

    function savePinnedOrder(order) {
        var source = Array.isArray(order) ? order : []
        var sanitized = []

        for (var i = 0; i < source.length; ++i) {
            var key = String(source[i] || "")

            if (key && sanitized.indexOf(key) < 0) {
                sanitized.push(key)
            }
        }

        Plasmoid.configuration.pinnedOrder = JSON.stringify(sanitized)
    }

    function rebuildVisualEntries() {
        var source = []
        var model = pinnedSection.entriesModel || []

        for (var i = 0; i < model.length; ++i) {
            source.push(model[i])
        }

        if (!Plasmoid.configuration.pinnedOrderCustomized) {
            pinnedSection.visualEntries = source
            return
        }

        var order = loadPinnedOrder()
        var result = []
        var usedKeys = []
        var orderChanged = false

        for (var orderIndex = 0; orderIndex < order.length; ++orderIndex) {
            var orderedKey = String(order[orderIndex] || "")

            if (!orderedKey || usedKeys.indexOf(orderedKey) >= 0) {
                continue
            }

            for (var entryIndex = 0; entryIndex < source.length; ++entryIndex) {
                var orderedEntry = source[entryIndex]

                if (entryOrderKey(orderedEntry) === orderedKey) {
                    result.push(orderedEntry)
                    usedKeys.push(orderedKey)
                    break
                }
            }
        }

        // Newly pinned or newly ungrouped applications are appended to the
        // current custom order. Hidden/stale keys intentionally stay stored so
        // disabling and re-enabling groups does not destroy group positions.
        for (var sourceIndex = 0; sourceIndex < source.length; ++sourceIndex) {
            var sourceEntry = source[sourceIndex]
            var sourceKey = entryOrderKey(sourceEntry)

            if (!sourceKey || usedKeys.indexOf(sourceKey) >= 0) {
                continue
            }

            result.push(sourceEntry)
            usedKeys.push(sourceKey)

            if (order.indexOf(sourceKey) < 0) {
                order.push(sourceKey)
                orderChanged = true
            }
        }

        if (orderChanged) {
            savePinnedOrder(order)
        }

        pinnedSection.visualEntries = result
    }

    function movePinnedEntry(sourceKey, targetKey, insertAfter) {
        var source = String(sourceKey || "")
        var target = String(targetKey || "")

        if (!source || !target || source === target) {
            return false
        }

        var order = Plasmoid.configuration.pinnedOrderCustomized
            ? loadPinnedOrder()
            : []

        // The first manual reorder starts from exactly what the user currently
        // sees, preserving the previous alphabetical default until that moment.
        if (!Plasmoid.configuration.pinnedOrderCustomized) {
            for (var visibleIndex = 0;
                    visibleIndex < pinnedSection.visualEntries.length;
                    ++visibleIndex) {
                var initialKey = entryOrderKey(
                    pinnedSection.visualEntries[visibleIndex]
                )

                if (initialKey && order.indexOf(initialKey) < 0) {
                    order.push(initialKey)
                }
            }
        }

        if (order.indexOf(source) < 0) {
            order.push(source)
        }

        if (order.indexOf(target) < 0) {
            order.push(target)
        }

        var sourceIndex = order.indexOf(source)
        order.splice(sourceIndex, 1)

        var targetIndex = order.indexOf(target)

        if (targetIndex < 0) {
            return false
        }

        order.splice(targetIndex + (insertAfter ? 1 : 0), 0, source)

        Plasmoid.configuration.pinnedOrderCustomized = true
        savePinnedOrder(order)

        Qt.callLater(function() {
            pinnedSection.rebuildVisualEntries()
        })

        return true
    }

    function removePinnedOrderKey(key) {
        if (!Plasmoid.configuration.pinnedOrderCustomized) {
            return
        }

        var cleanKey = String(key || "")
        var order = loadPinnedOrder()
        var index = order.indexOf(cleanKey)

        if (index >= 0) {
            order.splice(index, 1)
            savePinnedOrder(order)
        }
    }

    function replaceAppsWithGroupOrder(sourceFavoriteId, targetFavoriteId, groupId) {
        if (!Plasmoid.configuration.pinnedOrderCustomized) {
            return
        }

        var sourceKey = "app:" + String(sourceFavoriteId || "")
        var targetKey = "app:" + String(targetFavoriteId || "")
        var groupKey = "group:" + String(groupId || "")
        var order = loadPinnedOrder()
        var targetIndex = order.indexOf(targetKey)

        if (targetIndex < 0) {
            targetIndex = order.length
        }

        var insertIndex = 0

        // Count the entries that were before the target while ignoring the
        // items that are about to be replaced by the new group.
        for (var beforeIndex = 0; beforeIndex < targetIndex; ++beforeIndex) {
            var beforeKey = order[beforeIndex]

            if (beforeKey !== sourceKey
                    && beforeKey !== targetKey
                    && beforeKey !== groupKey) {
                ++insertIndex
            }
        }

        var cleanedOrder = []

        for (var orderIndex = 0; orderIndex < order.length; ++orderIndex) {
            var key = order[orderIndex]

            if (key !== sourceKey && key !== targetKey && key !== groupKey) {
                cleanedOrder.push(key)
            }
        }

        cleanedOrder.splice(
            Math.min(insertIndex, cleanedOrder.length),
            0,
            groupKey
        )
        savePinnedOrder(cleanedOrder)
    }

    function actionForId(actionList, actionId) {
        if (!actionList) {
            return null
        }

        for (var i = 0; i < actionList.length; ++i) {
            var action = actionList[i]

            if (action && String(action.actionId || "") === String(actionId || "")) {
                return action
            }
        }

        return null
    }

    function actionsForId(actionList, actionId) {
        var actions = []

        if (!actionList) {
            return actions
        }

        for (var i = 0; i < actionList.length; ++i) {
            var action = actionList[i]

            if (action && String(action.actionId || "") === String(actionId || "")) {
                actions.push(action)
            }
        }

        return actions
    }

    function favoriteActionForId(favoriteId, actionId) {
        var id = String(favoriteId || "")

        for (var i = 0; i < pinnedFavoriteActions.count; ++i) {
            var favorite = pinnedFavoriteActions.itemAt(i)

            if (favorite && favorite.favoriteIdValue === id) {
                return actionForId(favorite.actionListValue, actionId)
            }
        }

        return null
    }

    function favoriteActionsForId(favoriteId, actionId) {
        var id = String(favoriteId || "")

        for (var i = 0; i < pinnedFavoriteActions.count; ++i) {
            var favorite = pinnedFavoriteActions.itemAt(i)

            if (favorite && favorite.favoriteIdValue === id) {
                return actionsForId(favorite.actionListValue, actionId)
            }
        }

        return []
    }

    function triggerFavoriteAction(favoriteId, actionId, actionArgument) {
        var id = String(favoriteId || "")

        if (!favoritesModel || !id) {
            return
        }

        for (var i = 0; i < pinnedFavoriteActions.count; ++i) {
            var favorite = pinnedFavoriteActions.itemAt(i)

            if (!favorite || favorite.favoriteIdValue !== id) {
                continue
            }

            var closeRequested = favoritesModel.trigger(
                favorite.sourceRow,
                String(actionId || ""),
                actionArgument === undefined ? null : actionArgument
            )

            if (closeRequested) {
                Plasmoid.expanded = false
            }

            return
        }
    }

    function defaultDraggedGroupName() {
        if (groupController && groupController.i18n) {
            var translatedName = String(
                groupController.i18n("New group…") || ""
            ).replace(/…$/, "").trim()

            if (translatedName) {
                return translatedName
            }
        }

        return "New group"
    }

    function createGroupFromDrop(sourceFavoriteId, targetFavoriteId) {
        var sourceId = String(sourceFavoriteId || "")
        var targetId = String(targetFavoriteId || "")

        if (!groupsEnabled
                || !groupController
                || !sourceId
                || !targetId
                || sourceId === targetId) {
            return false
        }

        if (groupController.isFavoriteGrouped
                && (groupController.isFavoriteGrouped(sourceId)
                    || groupController.isFavoriteGrouped(targetId))) {
            return false
        }

        if (!groupController.copyPinnedGroups
                || !groupController.savePinnedGroups) {
            return false
        }

        var groups = groupController.copyPinnedGroups()

        if (!Array.isArray(groups)) {
            groups = []
        }

        var groupId = "group-"
            + Date.now().toString(36)
            + "-"
            + Math.floor(Math.random() * 1000000).toString(36)

        groups.push({
            id: groupId,
            name: defaultDraggedGroupName(),
            apps: [targetId, sourceId]
        })

        replaceAppsWithGroupOrder(sourceId, targetId, groupId)
        groupController.savePinnedGroups(groups)
        return true
    }

    function groupCanAcceptDrop(groupId, favoriteId) {
        var id = String(groupId || "")
        var appId = String(favoriteId || "")

        if (!groupsEnabled || !groupController || !id || !appId) {
            return false
        }

        if (!groupController.groupIndex || !groupController.pinnedGroups) {
            return false
        }

        var index = groupController.groupIndex(id)

        if (index < 0 || index >= groupController.pinnedGroups.length) {
            return false
        }

        var apps = groupController.pinnedGroups[index].apps || []
        var maxApps = Number(groupController.maxPinnedGroupApps || 16)

        return apps.indexOf(appId) < 0 && apps.length < maxApps
    }

    onEntriesModelChanged: rebuildVisualEntries()
    onGroupsEnabledChanged: rebuildVisualEntries()

    height: contentBottom
    clip: true

    Behavior on height {
        enabled: pinnedSection.layoutReady

        NumberAnimation {
            duration: 170
            easing.type: Easing.OutCubic
        }
    }

    Component.onCompleted: {
        rebuildVisualEntries()

        Qt.callLater(function() {
            pinnedSection.layoutReady = true
        })
    }

    Item {
        width: 0
        height: 0
        visible: false

        Repeater {
            id: pinnedFavoriteActions
            model: pinnedSection.favoritesModel

            delegate: Item {
                width: 0
                height: 0

                property int sourceRow: index
                property string favoriteIdValue: String(model.favoriteId || "")
                property var actionListValue: model.actionList
            }
        }
    }

    PlasmaComponents.Label {
        id: pinnedLabel

        x: 32
        y: 0

        text: pinnedSection.pinnedText

        font.pixelSize: 16
        font.bold: true

        visible: pinnedSection.searchText.length === 0
    }

    Grid {
        id: pinnedApps

        x: 32
        y: 40

        columns: pinnedSection.effectiveColumnCount
        rowSpacing: 0
        columnSpacing: 0

        visible: pinnedSection.searchText.length === 0

        Repeater {
            model: pinnedSection.visualEntries

            delegate: Item {
                id: pinnedEntry

                property var entryData: modelData
                property bool isGroup:
                    entryData && entryData.entryType === "group"
                property string favoriteId: !isGroup && entryData
                    ? String(entryData.favoriteId || "")
                    : ""
                property string entryKey: pinnedSection.entryOrderKey(entryData)
                property bool dragActive: false
                property bool dragWasActive: false
                property bool validDropHover: false
                property int reorderDropSide: 0

                function calculateDropMode(drag) {
                    var source = drag ? drag.source : null
                    var sourceId = source
                        ? String(source.favoriteId || "")
                        : ""

                    if (!source
                            || source === pinnedEntry
                            || !sourceId
                            || !pinnedEntry.entryKey) {
                        return ""
                    }

                    var localX = drag.x

                    if (isNaN(localX)) {
                        localX = pinnedEntry.width / 2
                    }

                    // Without groups, the whole target is available for sorting.
                    if (!pinnedSection.groupsEnabled) {
                        return localX < pinnedEntry.width / 2
                            ? "before"
                            : "after"
                    }

                    // With groups enabled, the outer quarters sort while the
                    // center keeps the Windows-style drop-to-group behavior.
                    var edgeWidth = pinnedEntry.width * 0.25

                    if (localX < edgeWidth) {
                        return "before"
                    }

                    if (localX > pinnedEntry.width - edgeWidth) {
                        return "after"
                    }

                    if (pinnedEntry.isGroup) {
                        return pinnedSection.groupCanAcceptDrop(
                            pinnedEntry.entryData.groupId,
                            sourceId
                        ) ? "group" : ""
                    }

                    return sourceId !== pinnedEntry.favoriteId ? "group" : ""
                }

                function updateDropFeedback(drag) {
                    var mode = calculateDropMode(drag)

                    pinnedEntry.validDropHover = mode === "group"
                    pinnedEntry.reorderDropSide = mode === "before"
                        ? -1
                        : (mode === "after" ? 1 : 0)

                    if (drag) {
                        var source = drag.source
                        drag.accepted = Boolean(
                            source
                            && source !== pinnedEntry
                            && String(source.favoriteId || "").length > 0
                        )
                    }
                }

                function clearDropFeedback() {
                    pinnedEntry.validDropHover = false
                    pinnedEntry.reorderDropSide = 0
                }

                height: pinnedSection.cellHeight
                width: pinnedSection.effectiveCellWidth
                z: pinnedEntry.dragActive ? 2000 : 0

                Item {
                    id: pinnedDragProxy

                    x: 0
                    y: 0
                    width: pinnedEntry.width
                    height: pinnedEntry.height
                    opacity: pinnedEntry.dragActive
                        && pinnedEntry.x + pinnedDragProxy.x + width / 2 >= 0
                        && pinnedEntry.x + pinnedDragProxy.x + width / 2 <= pinnedApps.width
                        && pinnedEntry.y + pinnedDragProxy.y + height / 2 >= 0
                        && pinnedEntry.y + pinnedDragProxy.y + height / 2 <= pinnedApps.height
                            ? 0.92
                            : 0
                    z: 1000

                    Drag.active: pinnedEntry.dragActive
                    Drag.source: pinnedEntry
                    Drag.keys: ["wooti-pinned-app"]
                    Drag.supportedActions: Qt.MoveAction
                    Drag.proposedAction: Qt.MoveAction
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2

                    Rectangle {
                        width: pinnedSection.iconSize + 18
                        height: width
                        anchors.centerIn: parent
                        radius: 12
                        color: "#3a3f49"
                        border.width: 1
                        border.color: Kirigami.Theme.highlightColor

                        Kirigami.Icon {
                            width: pinnedSection.iconSize
                            height: pinnedSection.iconSize
                            anchors.centerIn: parent
                            source: pinnedEntry.entryData
                                ? pinnedEntry.entryData.decoration
                                : ""
                        }
                    }
                }

                DropArea {
                    id: pinnedAppDropArea

                    anchors.fill: parent
                    enabled: pinnedEntry.entryData
                        && (pinnedEntry.isGroup
                            ? String(pinnedEntry.entryData.groupId || "").length > 0
                            : pinnedEntry.favoriteId.length > 0)
                    keys: ["wooti-pinned-app"]

                    onEntered: function(drag) {
                        pinnedEntry.updateDropFeedback(drag)
                    }

                    onPositionChanged: function(drag) {
                        pinnedEntry.updateDropFeedback(drag)
                    }

                    onExited: {
                        pinnedEntry.clearDropFeedback()
                    }

                    onDropped: function(drop) {
                        var source = drop.source
                        var sourceId = source
                            ? String(source.favoriteId || "")
                            : ""
                        var sourceKey = source
                            ? String(source.entryKey || "")
                            : ""
                        var dropMode = pinnedEntry.calculateDropMode(drop)

                        pinnedEntry.clearDropFeedback()

                        if ((dropMode === "before" || dropMode === "after")
                                && sourceKey
                                && pinnedSection.movePinnedEntry(
                                    sourceKey,
                                    pinnedEntry.entryKey,
                                    dropMode === "after"
                                )) {
                            drop.acceptProposedAction()
                            return
                        }

                        if (dropMode !== "group") {
                            drop.accepted = false
                            return
                        }

                        if (pinnedEntry.isGroup) {
                            var groupId = String(
                                pinnedEntry.entryData.groupId || ""
                            )

                            if (sourceId
                                    && pinnedSection.groupCanAcceptDrop(
                                        groupId,
                                        sourceId
                                    )
                                    && pinnedSection.groupController
                                    && pinnedSection.groupController.addFavoriteToGroup
                                    && pinnedSection.groupController.addFavoriteToGroup(
                                        sourceId,
                                        groupId
                                    )) {
                                pinnedSection.removePinnedOrderKey(sourceKey)
                                drop.acceptProposedAction()
                                return
                            }

                            drop.accepted = false
                            return
                        }

                        var targetId = pinnedEntry.favoriteId

                        if (sourceId
                                && targetId
                                && sourceId !== targetId
                                && pinnedSection.createGroupFromDrop(
                                    sourceId,
                                    targetId
                                )) {
                            drop.acceptProposedAction()
                            return
                        }

                        drop.accepted = false
                    }
                }

                Rectangle {
                    id: pinnedEntryHover

                    readonly property Item contentIcon:
                        pinnedEntry.isGroup ? pinnedGroupPreview : pinnedEntryIcon
                    readonly property Item contentLabel:
                        pinnedEntry.isGroup ? pinnedGroupLabel : pinnedEntryLabel

                    width: Math.min(
                        parent.width - 4,
                        pinnedSection.hoverWidth
                    )
                    x: Math.round((parent.width - width) / 2)
                    y: Math.max(2, contentIcon.y - pinnedSection.hoverPadding)
                    height: Math.min(
                        parent.height - y - 2,
                        contentLabel.y + contentLabel.implicitHeight
                            + pinnedSection.hoverPadding - y
                    )

                    radius: 12
                    color: "#30343d"
                    opacity: pinnedEntryMouseArea.containsMouse
                        || pinnedEntry.validDropHover
                            ? 1
                            : 0
                    border.width: pinnedEntry.validDropHover ? 2 : 0
                    border.color: Kirigami.Theme.highlightColor

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }
                }

                Rectangle {
                    visible: pinnedEntry.reorderDropSide !== 0
                    width: 3
                    height: Math.min(64, parent.height - 12)
                    y: Math.round((parent.height - height) / 2)
                    x: pinnedEntry.reorderDropSide < 0
                        ? 1
                        : parent.width - width - 1
                    radius: width / 2
                    color: Kirigami.Theme.highlightColor
                    z: 1500
                }

                Rectangle {
                    id: pinnedGroupPreview
                    visible: pinnedEntry.isGroup

                    width: pinnedSection.iconSize + 10
                    height: pinnedSection.iconSize + 10
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
                                width: Math.max(10, Math.floor(pinnedSection.iconSize / 2))
                                height: width

                                Kirigami.Icon {
                                    anchors.fill: parent
                                    source: modelData
                                }
                            }
                        }
                    }
                }

                PlasmaComponents.Label {
                    id: pinnedGroupLabel
                    visible: pinnedEntry.isGroup

                    width: Math.max(1, pinnedEntryHover.width - pinnedSection.hoverPadding * 2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: pinnedGroupPreview.bottom
                    anchors.topMargin: 4

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

                    height: pinnedSection.iconSize
                    width: pinnedSection.iconSize

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 8

                    source: pinnedEntry.entryData
                        ? pinnedEntry.entryData.decoration
                        : ""
                }

                PlasmaComponents.Label {
                    id: pinnedEntryLabel
                    visible: !pinnedEntry.isGroup

                    width: Math.max(1, pinnedEntryHover.width - pinnedSection.hoverPadding * 2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: pinnedEntryIcon.bottom
                    anchors.topMargin: 4

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
                        target: pinnedSection.contextMenuController

                        function onCloseContextMenus() {
                            pinnedGroupContextMenu.close()
                        }
                    }

                    Controls.MenuItem {
                        text: pinnedSection.renameGroupText
                        icon.name: "edit-rename"

                        onTriggered: {
                            if (!pinnedSection.groupDialogsController) {
                                return
                            }

                            pinnedSection.groupDialogsController.openRenameGroup(
                                pinnedEntry.entryData.groupId,
                                pinnedEntry.entryData.groupName
                            )
                        }
                    }

                    Controls.MenuItem {
                        text: pinnedSection.dissolveGroupText
                        icon.name: "folder-remove"

                        onTriggered: {
                            if (pinnedSection.groupPopupController
                                    && pinnedSection.groupPopupController.groupId
                                        === String(pinnedEntry.entryData.groupId)) {
                                pinnedSection.groupPopupController.close()
                            }

                            if (pinnedSection.groupController) {
                                pinnedSection.groupController.dissolveGroup(
                                    String(pinnedEntry.entryData.groupId)
                                )
                            }
                        }
                    }
                }

                Controls.Menu {
                    id: pinnedFavoriteContextMenu

                    property var jumpListActions: pinnedEntry.isGroup
                        ? []
                        : pinnedSection.favoriteActionsForId(
                            pinnedEntry.entryData.favoriteId,
                            "_kicker_jumpListAction"
                        )
                    property var manageApplicationAction: pinnedEntry.isGroup
                        ? null
                        : pinnedSection.favoriteActionForId(
                            pinnedEntry.entryData.favoriteId,
                            "manageApplication"
                        )

                    Instantiator {
                        id: pinnedJumpActionsInstantiator
                        model: pinnedFavoriteContextMenu.jumpListActions

                        delegate: Controls.MenuItem {
                            required property var modelData

                            text: modelData && modelData.text
                                ? String(modelData.text)
                                : ""
                            icon.name: modelData && modelData.icon
                                ? String(modelData.icon)
                                : ""
                            enabled: !modelData || modelData.enabled === undefined
                                ? true
                                : Boolean(modelData.enabled)

                            onTriggered: {
                                pinnedSection.triggerFavoriteAction(
                                    pinnedEntry.entryData.favoriteId,
                                    modelData.actionId,
                                    modelData.actionArgument
                                )
                            }
                        }

                        onObjectAdded: function(index, object) {
                            pinnedFavoriteContextMenu.insertItem(index, object)
                        }

                        onObjectRemoved: function(index, object) {
                            pinnedFavoriteContextMenu.removeItem(object)
                        }
                    }

                    Controls.MenuSeparator {
                        visible: pinnedFavoriteContextMenu.jumpListActions.length > 0
                    }

                    Connections {
                        target: pinnedSection.contextMenuController

                        function onCloseContextMenus() {
                            pinnedFavoriteContextMenu.close()
                        }
                    }

                    Controls.MenuItem {
                        visible: pinnedSection.groupsEnabled
                        text: pinnedSection.addToGroupText
                        icon.name: "folder-new"

                        onTriggered: {
                            if (!pinnedSection.groupDialogsController) {
                                return
                            }

                            pinnedSection.groupDialogsController.openAddToGroup(
                                pinnedEntry.entryData.favoriteId,
                                pinnedEntry.entryData.displayName
                            )
                        }
                    }

                    Controls.MenuSeparator { }

                    Controls.MenuItem {
                        text: pinnedSection.pinToTaskManagerText
                        icon.name: "pin"

                        onTriggered: {
                            if (pinnedSection.launcherController) {
                                pinnedSection.launcherController.triggerPinnedFavoriteAction(
                                    pinnedEntry.entryData.favoriteId,
                                    "addToTaskManager"
                                )
                            }
                        }
                    }

                    Controls.MenuItem {
                        text: pinnedSection.editApplicationText
                        icon.name: "kmenuedit"

                        onTriggered: {
                            if (pinnedSection.launcherController) {
                                pinnedSection.launcherController.triggerPinnedFavoriteAction(
                                    pinnedEntry.entryData.favoriteId,
                                    "editApplication"
                                )
                            }
                        }
                    }

                    Controls.MenuItem {
                        visible: Boolean(pinnedFavoriteContextMenu.manageApplicationAction)
                        text: pinnedSection.manageApplicationText
                        icon.name: pinnedFavoriteContextMenu.manageApplicationAction
                            && pinnedFavoriteContextMenu.manageApplicationAction.icon
                                ? String(pinnedFavoriteContextMenu.manageApplicationAction.icon)
                                : "plasmadiscover"

                        onTriggered: {
                            if (pinnedSection.launcherController) {
                                pinnedSection.launcherController.triggerPinnedFavoriteAction(
                                    pinnedEntry.entryData.favoriteId,
                                    "manageApplication"
                                )
                            }
                        }
                    }

                    Controls.MenuSeparator { }

                    Controls.MenuItem {
                        text: pinnedSection.unpinText
                        icon.name: "window-unpin"

                        onTriggered: {
                            if (pinnedSection.groupController) {
                                pinnedSection.groupController.removeFavoriteFromAllGroups(
                                    pinnedEntry.entryData.favoriteId
                                )
                            }

                            pinnedSection.removePinnedOrderKey(pinnedEntry.entryKey)

                            if (pinnedSection.favoritesModel) {
                                pinnedSection.favoritesModel.removeFavorite(
                                    pinnedEntry.entryData.favoriteId
                                )
                            }
                        }
                    }
                }

                DragHandler {
                    id: pinnedEntryDragHandler

                    target: pinnedDragProxy
                    enabled: !pinnedEntry.isGroup
                        && pinnedEntry.favoriteId.length > 0
                    acceptedButtons: Qt.LeftButton

                    onActiveChanged: {
                        if (active) {
                            pinnedDragProxy.x = 0
                            pinnedDragProxy.y = 0
                            pinnedEntry.dragActive = true
                            pinnedEntry.dragWasActive = true

                            if (pinnedSection.contextMenuController) {
                                pinnedSection.contextMenuController.closeContextMenus()
                            }
                        } else if (pinnedEntry.dragActive) {
                            pinnedDragProxy.Drag.drop()
                            pinnedEntry.dragActive = false
                            pinnedDragProxy.x = 0
                            pinnedDragProxy.y = 0

                            Qt.callLater(function() {
                                pinnedEntry.dragWasActive = false
                            })
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

                        if (pinnedEntry.dragWasActive) {
                            return
                        }

                        if (pinnedEntry.isGroup) {
                            if (!pinnedSection.groupPopupController) {
                                return
                            }

                            pinnedSection.groupPopupController.groupId = String(
                                pinnedEntry.entryData.groupId
                            )
                            pinnedSection.groupPopupController.groupName = String(
                                pinnedEntry.entryData.groupName
                            )
                            pinnedSection.groupPopupController.rebuildApps()
                            pinnedSection.groupPopupController.openFor(pinnedEntry)
                            return
                        }

                        if (pinnedSection.launcherController) {
                            pinnedSection.launcherController.triggerPinnedFavorite(
                                pinnedEntry.entryData.favoriteId
                            )
                        }
                    }
                }
            }
        }
    }
}
