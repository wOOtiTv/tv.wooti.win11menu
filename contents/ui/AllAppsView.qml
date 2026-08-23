import QtQuick
import QtQuick.Controls as Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: allAppsView

    property var allAppsModel
    property var favoritesModel
    property var contextMenuController

    property string searchText: ""
    property bool listView: false

    property int columnCount: 8
    property int gridCellHeight: 88
    property int visibleHeight: 520
    property int appRows: 7
    readonly property int iconSize: Math.max(
        24,
        Math.min(48, Plasmoid.configuration.iconSize || 36)
    )
    readonly property int hoverInset: Math.max(2, 38 - iconSize)

    property string allText: ""
    property string viewListText: ""
    property string viewGridText: ""
    property string pinText: ""

    property string pinToTaskManagerText: ""
    property string editApplicationText: ""

    signal closeLauncherRequested()

    signal listViewToggleRequested()

    readonly property int allAppsColumnCount:
        listView ? 1 : columnCount

    readonly property int allAppsCellHeight:
        listView ? 58 : gridCellHeight

    readonly property int sectionHeaderHeight: 34
    readonly property int sectionSpacing: 8

    function resetScrollPosition() {
        allAppsScroll.contentY = 0
    }

    Connections {
        target: allAppsView.contextMenuController

        function onExpandedChanged() {
            if (allAppsView.contextMenuController
                    && !allAppsView.contextMenuController.expanded) {
                allAppsView.resetScrollPosition()
            }
        }
    }

    function contentHeight() {
        if (!allAppsModel) {
            return gridCellHeight * appRows
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

        return Math.max(total, gridCellHeight * appRows)
    }

    PlasmaComponents.Label {
        id: allAppsLabel

        x: 32
        y: 0

        text: allAppsView.allText

        font.pixelSize: 16
        font.bold: true

        visible: allAppsView.searchText.length === 0
    }

    PlasmaComponents.Label {
        id: viewLabel

        x: parent.width - 140
        y: allAppsLabel.y

        text: allAppsView.listView
            ? allAppsView.viewListText
            : allAppsView.viewGridText

        font.pixelSize: 14
        opacity: viewToggleMouseArea.containsMouse ? 1.0 : 0.85

        visible: allAppsView.searchText.length === 0

        MouseArea {
            id: viewToggleMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                allAppsView.listViewToggleRequested()
            }
        }
    }

    Flickable {
        id: allAppsScroll

        x: 32
        y: allAppsLabel.y + 40

        width: parent.width - 64
        height: Math.max(
            0,
            Math.min(
                allAppsView.visibleHeight,
                parent.height - y - 100
            )
        )

        clip: true

        contentWidth: width
        contentHeight: allAppsView.contentHeight()

        boundsBehavior: Flickable.StopAtBounds

        Controls.ScrollBar.vertical: Controls.ScrollBar {
            id: allAppsScrollBar

            policy: Controls.ScrollBar.AlwaysOn

            // Wider than the visible track so the fade-in already
            // triggers when the cursor gets close, not only once it
            // lands exactly on the thin bar.
            width: 18

            // Left empty on purpose: Qt keeps re-asserting this item's
            // height/y to the *true* proportional handle size on every
            // scroll or resize, which fought any attempt to bind a taller
            // custom height here. The visible thumb below is a fully
            // separate sibling so our own size/position math sticks.
            contentItem: Item {}

            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }

            opacity: (allAppsScrollBar.hovered
                || allAppsScrollThumbDrag.pressed
                || allAppsScroll.moving)
                ? 1
                : 0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            Rectangle {
                id: allAppsScrollThumb

                anchors.horizontalCenter: parent.horizontalCenter

                width: 8
                radius: width / 2
                color: "#555a66"
                opacity: allAppsScrollThumbDrag.pressed ? 0.9 : 0.65

                readonly property real trackLength: allAppsScrollBar.height
                readonly property real progress: allAppsScrollBar.size >= 1
                    ? 0
                    : allAppsScrollBar.position / (1 - allAppsScrollBar.size)

                // Twice the natural proportional length, with a floor so it
                // never shrinks to an unusable sliver on long app lists.
                height: Math.min(
                    trackLength,
                    Math.max(24, allAppsScrollBar.size * trackLength * 2)
                )
                y: progress * (trackLength - height)

                MouseArea {
                    id: allAppsScrollThumbDrag

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

                    property real lastGlobalY: 0

                    onPressed: function(mouse) {
                        lastGlobalY = mapToGlobal(mouse.x, mouse.y).y
                    }

                    onPositionChanged: function(mouse) {
                        if (!pressed) {
                            return
                        }

                        var g = mapToGlobal(mouse.x, mouse.y)
                        var deltaY = g.y - lastGlobalY
                        lastGlobalY = g.y

                        var travel = allAppsScrollThumb.trackLength - allAppsScrollThumb.height

                        if (travel <= 0) {
                            return
                        }

                        var newProgress = Math.max(
                            0,
                            Math.min(1, allAppsScrollThumb.progress + deltaY / travel)
                        )

                        allAppsScrollBar.position = newProgress * (1 - allAppsScrollBar.size)
                    }
                }
            }
        }

        visible: allAppsView.searchText.length === 0

        Column {
            id: allAppsColumn

            width: allAppsScroll.width
            spacing: 0

            Repeater {
                model: allAppsView.allAppsModel
                    ? allAppsView.allAppsModel.count
                    : 0

                delegate: Item {
                    id: appSection

                    width: allAppsColumn.width

                    property var sectionModel: allAppsView.allAppsModel
                        ? allAppsView.allAppsModel.modelForRow(index)
                        : null

                    height: allAppsView.sectionHeaderHeight +
                            (sectionModel
                            ? Math.ceil(
                                sectionModel.count /
                                allAppsView.allAppsColumnCount
                            ) * allAppsView.allAppsCellHeight
                            : 0) +
                            allAppsView.sectionSpacing

                    PlasmaComponents.Label {
                        id: sectionLabel

                        x: 0
                        y: 0

                        width: parent.width
                        height: allAppsView.sectionHeaderHeight

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
                                allAppsView.allAppsColumnCount
                            ) * allAppsView.allAppsCellHeight
                            : 0

                        cellWidth: width / allAppsView.allAppsColumnCount
                        cellHeight: allAppsView.allAppsCellHeight

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
                                anchors.margins: allAppsView.listView
                                    ? 2
                                    : allAppsView.hoverInset

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

                                width: allAppsView.iconSize
                                height: allAppsView.iconSize

                                x: allAppsView.listView
                                    ? 16
                                    : (parent.width - width) / 2

                                y: allAppsView.listView
                                    ? (parent.height - height) / 2
                                    : 8

                                source: model.decoration
                            }

                            PlasmaComponents.Label {
                                x: allAppsView.listView
                                    ? appIcon.x + appIcon.width + 12
                                    : 4

                                y: allAppsView.listView
                                    ? (parent.height - height) / 2
                                    : appIcon.y + appIcon.height + 4

                                width: allAppsView.listView
                                    ? parent.width - appIcon.x - appIcon.width - 28
                                    : parent.width - 8

                                height: allAppsView.listView
                                    ? 28
                                    : parent.height - appIcon.height - appIcon.y - 4

                                text: model.display

                                horizontalAlignment: allAppsView.listView
                                    ? Text.AlignLeft
                                    : Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter

                                maximumLineCount: 1
                                elide: Text.ElideRight

                                font.pixelSize: 13
                            }

                            Controls.Menu {
                                id: appContextMenu

                                Connections {
                                    target: allAppsView.contextMenuController

                                    function onCloseContextMenus() {
                                        appContextMenu.close()
                                    }
                                }

                                Controls.MenuItem {
                                    text: allAppsView.pinText
                                    icon.name: "list-add"

                                    onTriggered: {
                                        var favoriteId = model.favoriteId

                                        if (favoriteId && allAppsView.favoritesModel) {
                                            allAppsView.favoritesModel.addFavorite(
                                                favoriteId
                                            )
                                        }
                                    }
                                }

                                Controls.MenuSeparator { }

                                Controls.MenuItem {
                                    text: allAppsView.pinToTaskManagerText
                                    icon.name: "pin"

                                    onTriggered: {
                                        if (!appSection.sectionModel) {
                                            return
                                        }

                                        var closeRequested = appSection.sectionModel.trigger(
                                            index,
                                            "addToTaskManager",
                                            null
                                        )

                                        if (closeRequested) {
                                            allAppsView.closeLauncherRequested()
                                        }
                                    }
                                }

                                Controls.MenuItem {
                                    text: allAppsView.editApplicationText
                                    icon.name: "kmenuedit"

                                    onTriggered: {
                                        if (!appSection.sectionModel) {
                                            return
                                        }

                                        var closeRequested = appSection.sectionModel.trigger(
                                            index,
                                            "editApplication",
                                            null
                                        )

                                        if (closeRequested) {
                                            allAppsView.closeLauncherRequested()
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
}
