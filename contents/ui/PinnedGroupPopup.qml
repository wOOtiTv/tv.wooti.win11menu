import QtQuick
import QtQuick.Controls as Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "Translations.js" as Translations

Controls.Popup {
    id: groupPopup

    property Item popupParent
    property var favoriteDataSource
    property var groupController
    property var launcherController
    property var contextMenuController
    property int maxGroupApps: 16

    property string removeFromGroupText: ""
    readonly property string editApplicationText: Translations.translate(
        "Edit Application…",
        Plasmoid.configuration.language,
        Qt.locale().name
    )

    property string groupId: ""
    property string groupName: ""
    property var appEntries: []

    readonly property int iconSize: Math.max(
        24,
        Math.min(64, Plasmoid.configuration.iconSize || 36)
    )
    readonly property int hoverPadding: 4
    readonly property int hoverWidth: iconSize + 80

    readonly property int maxColumns: 4
    readonly property int columnSpacing: 4
    readonly property int rowSpacing: 4
    readonly property int cellWidth: 142
    readonly property int cellHeight: Math.max(86, iconSize + 46)
    readonly property int displayAppCount: Math.min(
        maxGroupApps,
        appEntries.length
    )
    readonly property int columnCount: Math.min(
        maxColumns,
        Math.max(1, displayAppCount)
    )
    readonly property int visibleRows: Math.min(
        4,
        Math.max(1, Math.ceil(displayAppCount / columnCount))
    )
    readonly property int desiredPopupWidth: Math.max(
        260,
        columnCount * cellWidth
            + Math.max(0, columnCount - 1) * columnSpacing
            + padding * 2
    )
    readonly property int appsAreaHeight:
        visibleRows * cellHeight
            + Math.max(0, visibleRows - 1) * rowSpacing

    parent: popupParent

    x: popupParent
        ? Math.round((popupParent.width - width) / 2)
        : 0
    y: 120
    width: popupParent
        ? Math.min(desiredPopupWidth, popupParent.width - 80)
        : desiredPopupWidth
    padding: 18
    modal: false
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside

    // Groups can contain up to 16 apps. The popup uses up to four columns
    // and four rows, and shrinks horizontally for smaller groups.
    height: 28 + 12 + appsAreaHeight + padding * 2

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

    function favoriteActionsForId(favoriteId, actionId) {
        var id = String(favoriteId || "")

        for (var i = 0; i < groupFavoriteActions.count; ++i) {
            var favorite = groupFavoriteActions.itemAt(i)

            if (favorite && favorite.favoriteIdValue === id) {
                return actionsForId(favorite.actionListValue, actionId)
            }
        }

        return []
    }

    function triggerFavoriteAction(favoriteId, actionId, actionArgument) {
        var id = String(favoriteId || "")
        var proxyModel = favoriteDataSource ? favoriteDataSource.model : null

        if (!proxyModel || !proxyModel.sourceModel || !id) {
            return
        }

        for (var i = 0; i < groupFavoriteActions.count; ++i) {
            var favorite = groupFavoriteActions.itemAt(i)

            if (!favorite || favorite.favoriteIdValue !== id) {
                continue
            }

            var sourceIndex = proxyModel.mapToSource(
                proxyModel.index(favorite.proxyRow, 0)
            )

            if (!sourceIndex.valid) {
                return
            }

            var closeRequested = proxyModel.sourceModel.trigger(
                sourceIndex.row,
                String(actionId || ""),
                actionArgument === undefined ? null : actionArgument
            )

            if (closeRequested) {
                Plasmoid.expanded = false
            }

            return
        }
    }

    function positionRemovedAppNearGroup(favoriteId, wasLastApp) {
        if (!Plasmoid.configuration.pinnedOrderCustomized) {
            return
        }

        var id = String(favoriteId || "")
        var currentGroupId = String(groupId || "")

        if (!id || !currentGroupId) {
            return
        }

        var order = []

        try {
            var parsed = JSON.parse(
                String(Plasmoid.configuration.pinnedOrder || "[]")
            )
            order = Array.isArray(parsed) ? parsed : []
        } catch (error) {
            console.warn("🦊 Could not update pinned order after ungrouping:", error)
            return
        }

        var appKey = "app:" + id
        var groupKey = "group:" + currentGroupId

        // The app normally has no own order key while it lives inside a group,
        // but remove any stale copy before inserting it at the new position.
        for (var i = order.length - 1; i >= 0; --i) {
            if (String(order[i]) === appKey) {
                order.splice(i, 1)
            }
        }

        var groupIndex = order.indexOf(groupKey)

        if (groupIndex < 0) {
            order.push(appKey)
        } else if (wasLastApp) {
            // The group disappears, so the app takes over its exact position.
            order.splice(groupIndex, 1, appKey)
        } else {
            // Keep the group and place the removed app immediately after it.
            order.splice(groupIndex + 1, 0, appKey)
        }

        Plasmoid.configuration.pinnedOrder = JSON.stringify(order)
    }

    function openFor(anchorItem) {
        if (!popupParent || !anchorItem) {
            return
        }

        var point = anchorItem.mapToItem(popupParent, 0, 0)
        var desiredX = point.x + Math.round((anchorItem.width - width) / 2)
        var desiredY = point.y + anchorItem.height + 8

        x = Math.max(
            20,
            Math.min(desiredX, popupParent.width - width - 20)
        )

        if (desiredY + height > popupParent.height - 20) {
            desiredY = point.y - height - 8
        }

        y = Math.max(
            20,
            Math.min(desiredY, popupParent.height - height - 20)
        )

        open()
    }

    function rebuildApps() {
        var entries = []

        if (!favoriteDataSource || !groupController) {
            appEntries = entries
            return
        }

        var groupData = null

        if (groupController.groupIndex && groupController.pinnedGroups) {
            var currentGroupIndex = groupController.groupIndex(groupId)

            if (currentGroupIndex >= 0
                    && currentGroupIndex < groupController.pinnedGroups.length) {
                groupData = groupController.pinnedGroups[currentGroupIndex]
            }
        }

        for (var i = 0; i < favoriteDataSource.count; ++i) {
            var favorite = favoriteDataSource.itemAt(i)

            if (!favorite || !favorite.favoriteIdValue) {
                continue
            }

            if (!groupController.favoriteBelongsToGroup(
                    favorite.favoriteIdValue,
                    groupId
                )) {
                continue
            }

            entries.push({
                sortName: favorite.displayName,
                favoriteId: favorite.favoriteIdValue,
                displayName: favorite.displayName,
                decoration: favorite.decorationValue
            })
        }

        if (groupData && groupData.customOrder) {
            var orderedEntries = []
            var storedApps = Array.isArray(groupData.apps)
                ? groupData.apps
                : []

            for (var appIndex = 0; appIndex < storedApps.length; ++appIndex) {
                var storedId = String(storedApps[appIndex] || "")

                for (var entryIndex = 0; entryIndex < entries.length; ++entryIndex) {
                    if (String(entries[entryIndex].favoriteId) === storedId) {
                        orderedEntries.push(entries[entryIndex])
                        break
                    }
                }
            }

            // Keep any unexpected model entries visible instead of dropping them.
            for (var fallbackIndex = 0; fallbackIndex < entries.length; ++fallbackIndex) {
                var fallbackEntry = entries[fallbackIndex]
                var alreadyAdded = false

                for (var orderedIndex = 0;
                        orderedIndex < orderedEntries.length;
                        ++orderedIndex) {
                    if (String(orderedEntries[orderedIndex].favoriteId)
                            === String(fallbackEntry.favoriteId)) {
                        alreadyAdded = true
                        break
                    }
                }

                if (!alreadyAdded) {
                    orderedEntries.push(fallbackEntry)
                }
            }

            entries = orderedEntries
        } else if (launcherController) {
            entries.sort(function(leftEntry, rightEntry) {
                return launcherController.comparePinnedEntries(
                    leftEntry,
                    rightEntry
                )
            })
        }

        appEntries = entries
    }

    function clearAllDropFeedback() {
        for (var i = 0; i < groupAppsRepeater.count; ++i) {
            var item = groupAppsRepeater.itemAt(i)

            if (item && item.clearDropFeedback) {
                item.clearDropFeedback()
            }
        }
    }

    Item {
        width: 0
        height: 0
        visible: false

        Repeater {
            id: groupFavoriteActions
            model: groupPopup.favoriteDataSource
                ? groupPopup.favoriteDataSource.model
                : null

            delegate: Item {
                width: 0
                height: 0

                property int proxyRow: index
                property string favoriteIdValue: String(model.favoriteId || "")
                property var actionListValue: model.actionList
            }
        }
    }

    Connections {
        target: groupPopup.contextMenuController

        function onCloseContextMenus() {
            groupPopup.close()
        }
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
                columns: groupPopup.columnCount
                rowSpacing: groupPopup.rowSpacing
                columnSpacing: groupPopup.columnSpacing

                Repeater {
                    id: groupAppsRepeater
                    model: groupPopup.appEntries.slice(0, groupPopup.maxGroupApps)

                    delegate: Item {
                        id: groupAppItem

                        property var appData: modelData
                        property string favoriteId: appData
                            ? String(appData.favoriteId || "")
                            : ""
                        property bool dragActive: false
                        property bool dragWasActive: false
                        property bool validDropHover: false
                        property bool dropAfter: false

                        function updateDropFeedback(drag) {
                            var source = drag ? drag.source : null
                            var sourceId = source
                                ? String(source.favoriteId || "")
                                : ""

                            validDropHover = Boolean(
                                source
                                && source !== groupAppItem
                                && sourceId
                                && groupAppItem.favoriteId
                            )

                            dropAfter = validDropHover
                                && drag.x >= groupAppItem.width / 2

                            if (drag) {
                                drag.accepted = validDropHover
                            }
                        }

                        function clearDropFeedback() {
                            validDropHover = false
                            dropAfter = false
                        }

                        width: Math.floor(
                            (groupAppsGrid.width
                                - Math.max(0, groupPopup.columnCount - 1)
                                    * groupPopup.columnSpacing)
                                / groupPopup.columnCount
                        )
                        height: groupPopup.cellHeight
                        z: dragActive ? 2000 : 0

                        Item {
                            id: groupDragProxy

                            x: 0
                            y: 0
                            width: groupAppItem.width
                            height: groupAppItem.height
                            opacity: groupAppItem.dragActive ? 0.92 : 0
                            z: 1500

                            Drag.active: groupAppItem.dragActive
                            Drag.source: groupAppItem
                            Drag.keys: ["wooti-group-app"]
                            Drag.supportedActions: Qt.MoveAction
                            Drag.proposedAction: Qt.MoveAction
                            Drag.hotSpot.x: width / 2
                            Drag.hotSpot.y: height / 2

                            Rectangle {
                                width: groupPopup.iconSize + 18
                                height: width
                                anchors.centerIn: parent
                                radius: 12
                                color: "#3a3f49"
                                border.width: 1
                                border.color: Kirigami.Theme.highlightColor

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: groupPopup.iconSize
                                    height: groupPopup.iconSize
                                    source: groupAppItem.appData
                                        ? groupAppItem.appData.decoration
                                        : ""
                                }
                            }
                        }

                        DropArea {
                            id: groupAppDropArea

                            anchors.fill: parent
                            keys: ["wooti-group-app"]

                            onEntered: function(drag) {
                                groupAppItem.updateDropFeedback(drag)
                            }

                            onPositionChanged: function(drag) {
                                groupAppItem.updateDropFeedback(drag)
                            }

                            onExited: {
                                groupAppItem.clearDropFeedback()
                            }

                            onDropped: function(drop) {
                                var source = drop.source
                                var sourceId = source
                                    ? String(source.favoriteId || "")
                                    : ""
                                var insertAfter = groupAppItem.dropAfter

                                groupPopup.clearAllDropFeedback()

                                if (!sourceId
                                        || !groupAppItem.favoriteId
                                        || sourceId === groupAppItem.favoriteId
                                        || !groupPopup.groupController
                                        || !groupPopup.groupController.moveFavoriteWithinGroup) {
                                    drop.accepted = false
                                    return
                                }

                                if (groupPopup.groupController.moveFavoriteWithinGroup(
                                        sourceId,
                                        groupPopup.groupId,
                                        groupAppItem.favoriteId,
                                        insertAfter
                                    )) {
                                    drop.acceptProposedAction()
                                    return
                                }

                                drop.accepted = false
                            }
                        }

                        Rectangle {
                            visible: groupAppItem.validDropHover
                            width: 3
                            height: Math.max(20, parent.height - 12)
                            y: 6
                            x: groupAppItem.dropAfter
                                ? parent.width - width / 2
                                : -width / 2
                            radius: width / 2
                            color: Kirigami.Theme.highlightColor
                            z: 1800
                        }

                        Rectangle {
                            id: groupAppHover

                            width: Math.min(
                                parent.width - 4,
                                groupPopup.hoverWidth
                            )
                            x: Math.round((parent.width - width) / 2)
                            y: Math.max(
                                2,
                                groupAppIcon.y - groupPopup.hoverPadding
                            )
                            height: Math.min(
                                parent.height - y - 2,
                                groupAppLabel.y + groupAppLabel.implicitHeight
                                    + groupPopup.hoverPadding - y
                            )

                            radius: 12
                            color: "#30343d"
                            opacity: groupAppMouse.containsMouse ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: 120 }
                            }
                        }

                        Kirigami.Icon {
                            id: groupAppIcon

                            width: groupPopup.iconSize
                            height: groupPopup.iconSize
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            source: groupAppItem.appData
                                ? groupAppItem.appData.decoration
                                : ""
                        }

                        PlasmaComponents.Label {
                            id: groupAppLabel

                            width: Math.max(
                                1,
                                groupAppHover.width - groupPopup.hoverPadding * 2
                            )
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: groupAppIcon.bottom
                            anchors.topMargin: 4
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

                            property var jumpListActions: groupPopup.favoriteActionsForId(
                                groupAppItem.appData.favoriteId,
                                "_kicker_jumpListAction"
                            )

                            Instantiator {
                                id: groupJumpActionsInstantiator
                                model: groupAppContextMenu.jumpListActions

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
                                        groupPopup.triggerFavoriteAction(
                                            groupAppItem.appData.favoriteId,
                                            modelData.actionId,
                                            modelData.actionArgument
                                        )
                                    }
                                }

                                onObjectAdded: function(index, object) {
                                    groupAppContextMenu.insertItem(index, object)
                                }

                                onObjectRemoved: function(index, object) {
                                    groupAppContextMenu.removeItem(object)
                                }
                            }

                            Controls.MenuSeparator {
                                visible: groupAppContextMenu.jumpListActions.length > 0
                            }

                            Connections {
                                target: groupPopup.contextMenuController

                                function onCloseContextMenus() {
                                    groupAppContextMenu.close()
                                }
                            }

                            Controls.MenuItem {
                                text: groupPopup.editApplicationText
                                icon.name: "kmenuedit"

                                onTriggered: {
                                    if (groupPopup.launcherController) {
                                        groupPopup.launcherController.triggerPinnedFavoriteAction(
                                            groupAppItem.appData.favoriteId,
                                            "editApplication"
                                        )
                                    }
                                }
                            }

                            Controls.MenuSeparator { }

                            Controls.MenuItem {
                                text: groupPopup.removeFromGroupText
                                icon.name: "list-remove"

                                onTriggered: {
                                    if (!groupPopup.groupController) {
                                        return
                                    }

                                    var favoriteId = String(
                                        groupAppItem.appData.favoriteId || ""
                                    )
                                    var wasLastApp = groupPopup.appEntries.length <= 1

                                    groupPopup.positionRemovedAppNearGroup(
                                        favoriteId,
                                        wasLastApp
                                    )

                                    if (wasLastApp) {
                                        groupAppContextMenu.close()
                                        groupPopup.close()
                                    }

                                    groupPopup.groupController.removeFavoriteFromGroup(
                                        favoriteId,
                                        groupPopup.groupId
                                    )

                                    if (!wasLastApp) {
                                        groupAppContextMenu.close()
                                        groupPopup.rebuildApps()
                                    }
                                }
                            }
                        }

                        DragHandler {
                            id: groupAppDragHandler

                            target: groupDragProxy
                            enabled: groupAppItem.favoriteId.length > 0
                            acceptedButtons: Qt.LeftButton

                            onActiveChanged: {
                                if (active) {
                                    groupDragProxy.x = 0
                                    groupDragProxy.y = 0
                                    groupAppItem.dragActive = true
                                    groupAppItem.dragWasActive = true

                                } else if (groupAppItem.dragActive) {
                                    groupDragProxy.Drag.drop()
                                    groupAppItem.dragActive = false
                                    groupDragProxy.x = 0
                                    groupDragProxy.y = 0
                                    groupPopup.clearAllDropFeedback()

                                    Qt.callLater(function() {
                                        groupAppItem.dragWasActive = false
                                    })
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

                                if (groupAppItem.dragWasActive) {
                                    return
                                }

                                groupPopup.close()

                                if (groupPopup.launcherController) {
                                    groupPopup.launcherController.triggerPinnedFavorite(
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
}
