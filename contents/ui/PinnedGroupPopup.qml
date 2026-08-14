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

    property string removeFromGroupText: ""

    property string groupId: ""
    property string groupName: ""
    property var appEntries: []
    readonly property int iconSize: Math.max(
        24,
        Math.min(48, Plasmoid.configuration.iconSize || 36)
    )

    parent: popupParent

    x: popupParent
        ? Math.round((popupParent.width - width) / 2)
        : 0
    y: 120
    width: popupParent
        ? Math.min(620, popupParent.width - 80)
        : 620
    padding: 18
    modal: false
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside

    // Groups are limited to 12 apps (4 columns × 3 rows), so the
    // complete group is shown at once without scrolling.
    property int visibleRows: Math.min(
        3,
        Math.max(1, Math.ceil(appEntries.length / 4))
    )
    property int appsAreaHeight:
        visibleRows * 86 + Math.max(0, visibleRows - 1) * 4

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
