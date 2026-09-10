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

        groupController.savePinnedGroups(groups)
        return true
    }

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
            model: pinnedSection.entriesModel

            delegate: Item {
                id: pinnedEntry

                property var entryData: modelData
                property bool isGroup:
                    entryData && entryData.entryType === "group"
                property string favoriteId: !isGroup && entryData
                    ? String(entryData.favoriteId || "")
                    : ""
                property bool dragActive: false
                property bool dragWasActive: false
                property bool validDropHover: false

                height: pinnedSection.cellHeight
                width: pinnedSection.effectiveCellWidth

                Drag.active: pinnedEntry.dragActive
                Drag.source: pinnedEntry
                Drag.keys: ["wooti-pinned-app"]
                Drag.supportedActions: Qt.MoveAction
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2

                DropArea {
                    id: pinnedAppDropArea

                    anchors.fill: parent
                    enabled: pinnedSection.groupsEnabled
                        && !pinnedEntry.isGroup
                        && pinnedEntry.favoriteId.length > 0
                    keys: ["wooti-pinned-app"]

                    onEntered: function(drag) {
                        var source = drag.source
                        var sourceId = source
                            ? String(source.favoriteId || "")
                            : ""

                        pinnedEntry.validDropHover = Boolean(
                            source
                            && source !== pinnedEntry
                            && sourceId
                            && sourceId !== pinnedEntry.favoriteId
                        )

                        if (!pinnedEntry.validDropHover) {
                            drag.accepted = false
                        }
                    }

                    onExited: {
                        pinnedEntry.validDropHover = false
                    }

                    onDropped: function(drop) {
                        var source = drop.source
                        var sourceId = source
                            ? String(source.favoriteId || "")
                            : ""
                        var targetId = pinnedEntry.favoriteId

                        pinnedEntry.validDropHover = false

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

                    target: null
                    enabled: pinnedSection.groupsEnabled
                        && !pinnedEntry.isGroup
                        && pinnedEntry.favoriteId.length > 0
                    acceptedButtons: Qt.LeftButton

                    onActiveChanged: {
                        if (active) {
                            pinnedEntry.dragActive = true
                            pinnedEntry.dragWasActive = true

                            if (pinnedSection.contextMenuController) {
                                pinnedSection.contextMenuController.closeContextMenus()
                            }
                        } else if (pinnedEntry.dragActive) {
                            pinnedEntry.Drag.drop()
                            pinnedEntry.dragActive = false

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
