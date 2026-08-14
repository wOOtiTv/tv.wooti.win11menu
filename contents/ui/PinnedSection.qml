import QtQuick
import QtQuick.Controls as Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

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
    readonly property int hoverWidth: iconSize + 48

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
    property string unpinText: ""

    readonly property real contentBottom: pinnedApps.y + pinnedApps.height

    height: contentBottom

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

                height: pinnedSection.cellHeight
                width: pinnedSection.effectiveCellWidth

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
                    opacity: pinnedEntryMouseArea.containsMouse ? 1 : 0

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

                    Controls.MenuSeparator { }

                    Controls.MenuItem {
                        text: pinnedSection.unpinText
                        icon.name: "list-remove"

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
