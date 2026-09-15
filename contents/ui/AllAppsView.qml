import QtQuick
import QtQuick.Controls as Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "Translations.js" as Translations

Item {
    id: allAppsView

    property var allAppsModel
    property var favoritesModel
    property var contextMenuController

    property string searchText: ""
    property string viewMode: "grid"
    property bool showSectionTitles: true

    readonly property bool listView: viewMode === "list"
    readonly property bool pinnedStyleView: viewMode === "pinned"

    property int columnCount: 8
    property int gridCellHeight: 88
    readonly property int iconSize: Math.max(
        24,
        Math.min(64, Plasmoid.configuration.iconSize || 36)
    )
    readonly property int effectiveGridCellHeight: Math.max(
        gridCellHeight,
        iconSize + 48
    )
    readonly property int hoverPadding: 4
    readonly property int hoverWidth: iconSize + 80
    readonly property int hoverInset: Math.max(2, 38 - iconSize)

    property string allText: ""
    property string viewListText: ""
    property string viewGridText: ""
    property string viewPinnedText: ""
    property string pinText: ""

    property string pinToTaskManagerText: ""
    property string editApplicationText: ""
    readonly property string manageApplicationText: Translations.translate(
        "Uninstall or Manage Add-Ons…",
        Plasmoid.configuration.language,
        Qt.locale().name
    )

    signal closeLauncherRequested()
    signal viewToggleRequested()

    readonly property int allAppsColumnCount:
        listView ? 1 : columnCount

    readonly property int allAppsCellHeight:
        listView
            ? Math.max(58, iconSize + 12)
            : effectiveGridCellHeight

    readonly property int sectionHeaderHeight: 34
    readonly property int sectionSpacing: 8
    readonly property int contentStartY: showSectionTitles ? 40 : 24

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

    visible: searchText.length === 0
    height: pinnedStyleView
        ? pinnedStyleGrid.y + pinnedStyleGrid.height + 16
        : allAppsColumn.y + allAppsColumn.implicitHeight + 16

    PlasmaComponents.Label {
        id: allAppsLabel

        x: 32
        y: 0

        text: allAppsView.allText

        font.pixelSize: 16
        font.bold: true

        visible: allAppsView.showSectionTitles
    }

    PlasmaComponents.Label {
        id: viewLabel

        x: parent.width - 170
        y: allAppsLabel.y
        width: 138

        text: allAppsView.pinnedStyleView
            ? allAppsView.viewPinnedText
            : (allAppsView.listView
                ? allAppsView.viewListText
                : allAppsView.viewGridText)

        horizontalAlignment: Text.AlignRight
        font.pixelSize: 14
        opacity: viewToggleMouseArea.containsMouse ? 1.0 : 0.85
        visible: allAppsView.showSectionTitles

        MouseArea {
            id: viewToggleMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                allAppsView.viewToggleRequested()
            }
        }
    }

    Rectangle {
        id: sectionDivider

        x: 32
        y: 6
        width: Math.max(1, parent.width - 64)
        height: 1
        radius: 1
        color: "#555a66"
        opacity: 0.7
        visible: !allAppsView.showSectionTitles
    }

    Column {
        id: allAppsColumn

        x: 32
        y: allAppsView.contentStartY
        width: parent.width - 64
        spacing: 0
        visible: !allAppsView.pinnedStyleView

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

                            property bool favoriteAlreadyPinned: false
                            property var manageApplicationAction: allAppsView.actionForId(
                                model.actionList,
                                "manageApplication"
                            )

                            onAboutToShow: {
                                var favoriteId = String(model.favoriteId || "")
                                favoriteAlreadyPinned = Boolean(
                                    favoriteId
                                    && allAppsView.favoritesModel
                                    && allAppsView.favoritesModel.isFavorite(favoriteId)
                                )
                            }

                            Connections {
                                target: allAppsView.contextMenuController

                                function onCloseContextMenus() {
                                    appContextMenu.close()
                                }
                            }

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

                            Controls.MenuItem {
                                visible: Boolean(appContextMenu.manageApplicationAction)
                                text: allAppsView.manageApplicationText
                                icon.name: appContextMenu.manageApplicationAction
                                    && appContextMenu.manageApplicationAction.icon
                                        ? String(appContextMenu.manageApplicationAction.icon)
                                        : "plasmadiscover"

                                onTriggered: {
                                    if (!appSection.sectionModel) {
                                        return
                                    }

                                    var closeRequested = appSection.sectionModel.trigger(
                                        index,
                                        "manageApplication",
                                        null
                                    )

                                    if (closeRequested) {
                                        allAppsView.closeLauncherRequested()
                                    }
                                }
                            }

                            Controls.MenuSeparator {
                                visible: !appContextMenu.favoriteAlreadyPinned
                            }

                            Controls.MenuItem {
                                visible: !appContextMenu.favoriteAlreadyPinned
                                text: allAppsView.pinText
                                icon.name: "pin"

                                onTriggered: {
                                    var favoriteId = model.favoriteId

                                    if (favoriteId && allAppsView.favoritesModel) {
                                        allAppsView.favoritesModel.addFavorite(
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

    GridView {
        id: pinnedStyleGrid

        x: 32
        y: allAppsView.contentStartY
        width: parent.width - 64
        height: pinnedStyleGrid.count > 0
            ? Math.ceil(pinnedStyleGrid.count / allAppsView.columnCount)
                * pinnedStyleGrid.cellHeight
            : 0

        cellWidth: width / allAppsView.columnCount
        cellHeight: allAppsView.effectiveGridCellHeight

        visible: allAppsView.pinnedStyleView
        interactive: false
        clip: false
        model: allAppsView.pinnedStyleView ? allAppsView.allAppsModel : null

        delegate: Item {
            id: flatAppItem

            width: pinnedStyleGrid.cellWidth
            height: pinnedStyleGrid.cellHeight

            Rectangle {
                id: flatAppHover

                width: Math.min(
                    parent.width - 4,
                    allAppsView.hoverWidth
                )
                x: Math.round((parent.width - width) / 2)
                y: Math.max(
                    2,
                    flatAppIcon.y - allAppsView.hoverPadding
                )
                height: Math.min(
                    parent.height - y - 2,
                    flatAppLabel.y + flatAppLabel.implicitHeight
                        + allAppsView.hoverPadding - y
                )

                radius: 12
                color: "#30343d"
                opacity: flatAppMouseArea.containsMouse ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 120 }
                }
            }

            Kirigami.Icon {
                id: flatAppIcon

                width: allAppsView.iconSize
                height: allAppsView.iconSize
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 8
                source: model.decoration
            }

            PlasmaComponents.Label {
                id: flatAppLabel

                width: Math.max(
                    1,
                    flatAppHover.width - allAppsView.hoverPadding * 2
                )
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: flatAppIcon.bottom
                anchors.topMargin: 4

                text: model.display
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                maximumLineCount: 1
                elide: Text.ElideRight
                font.pixelSize: 13
            }

            Controls.Menu {
                id: flatAppContextMenu

                property bool favoriteAlreadyPinned: false
                property var manageApplicationAction: allAppsView.actionForId(
                    model.actionList,
                    "manageApplication"
                )

                onAboutToShow: {
                    var favoriteId = String(model.favoriteId || "")
                    favoriteAlreadyPinned = Boolean(
                        favoriteId
                        && allAppsView.favoritesModel
                        && allAppsView.favoritesModel.isFavorite(favoriteId)
                    )
                }

                Connections {
                    target: allAppsView.contextMenuController

                    function onCloseContextMenus() {
                        flatAppContextMenu.close()
                    }
                }

                Controls.MenuItem {
                    text: allAppsView.pinToTaskManagerText
                    icon.name: "pin"

                    onTriggered: {
                        if (!pinnedStyleGrid.model) {
                            return
                        }

                        var closeRequested = pinnedStyleGrid.model.trigger(
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
                        if (!pinnedStyleGrid.model) {
                            return
                        }

                        var closeRequested = pinnedStyleGrid.model.trigger(
                            index,
                            "editApplication",
                            null
                        )

                        if (closeRequested) {
                            allAppsView.closeLauncherRequested()
                        }
                    }
                }

                Controls.MenuItem {
                    visible: Boolean(flatAppContextMenu.manageApplicationAction)
                    text: allAppsView.manageApplicationText
                    icon.name: flatAppContextMenu.manageApplicationAction
                        && flatAppContextMenu.manageApplicationAction.icon
                            ? String(flatAppContextMenu.manageApplicationAction.icon)
                            : "plasmadiscover"

                    onTriggered: {
                        if (!pinnedStyleGrid.model) {
                            return
                        }

                        var closeRequested = pinnedStyleGrid.model.trigger(
                            index,
                            "manageApplication",
                            null
                        )

                        if (closeRequested) {
                            allAppsView.closeLauncherRequested()
                        }
                    }
                }

                Controls.MenuSeparator {
                    visible: !flatAppContextMenu.favoriteAlreadyPinned
                }

                Controls.MenuItem {
                    visible: !flatAppContextMenu.favoriteAlreadyPinned
                    text: allAppsView.pinText
                    icon.name: "pin"

                    onTriggered: {
                        var favoriteId = model.favoriteId

                        if (favoriteId && allAppsView.favoritesModel) {
                            allAppsView.favoritesModel.addFavorite(favoriteId)
                        }
                    }
                }
            }

            MouseArea {
                id: flatAppMouseArea

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        flatAppContextMenu.popup(
                            flatAppMouseArea,
                            mouse.x,
                            mouse.y
                        )
                        return
                    }

                    if (pinnedStyleGrid.model) {
                        pinnedStyleGrid.model.trigger(index, "", null)
                    }
                }
            }
        }
    }
}
