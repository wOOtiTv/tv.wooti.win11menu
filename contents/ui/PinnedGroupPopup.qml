import QtQuick
import QtQuick.Controls as Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Controls.Popup {
    id: groupPopup

    property Item popupParent
    property var favoriteDataSource
    property var groupController
    property var launcherController
    property var contextMenuController
    property int maxGroupApps: 16

    property string removeFromGroupText: ""

    property string groupId: ""
    property string groupName: ""
    property var appEntries: []

    readonly property int iconSize: Math.max(
        24,
        Math.min(48, Plasmoid.configuration.iconSize || 36)
    )
    readonly property int hoverPadding: 4
    readonly property int hoverWidth: iconSize + 80

    readonly property int maxColumns: 4
    readonly property int columnSpacing: 4
    readonly property int rowSpacing: 4
    readonly property int cellWidth: 142
    readonly property int cellHeight: 86
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

        if (launcherController) {
            entries.sort(function(leftEntry, rightEntry) {
                return launcherController.comparePinnedEntries(
                    leftEntry,
                    rightEntry
                )
            })
        }

        appEntries = entries
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
                    model: groupPopup.appEntries.slice(0, groupPopup.maxGroupApps)

                    delegate: Item {
                        id: groupAppItem
                        property var appData: modelData

                        width: Math.floor(
                            (groupAppsGrid.width
                                - Math.max(0, groupPopup.columnCount - 1)
                                    * groupPopup.columnSpacing)
                                / groupPopup.columnCount
                        )
                        height: groupPopup.cellHeight

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

                            Connections {
                                target: groupPopup.contextMenuController

                                function onCloseContextMenus() {
                                    groupAppContextMenu.close()
                                }
                            }

                            Controls.MenuItem {
                                text: groupPopup.removeFromGroupText
                                icon.name: "list-remove"

                                onTriggered: {
                                    if (!groupPopup.groupController) {
                                        return
                                    }

                                    var wasLastApp = groupPopup.appEntries.length <= 1

                                    if (wasLastApp) {
                                        groupAppContextMenu.close()
                                        groupPopup.close()
                                    }

                                    groupPopup.groupController.removeFavoriteFromGroup(
                                        groupAppItem.appData.favoriteId,
                                        groupPopup.groupId
                                    )

                                    if (!wasLastApp) {
                                        groupAppContextMenu.close()
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
