import QtQuick
import QtQuick.Controls as Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: searchResultsView

    property string searchText: ""

    property var appRunnerModel
    property var fileSearchResultsModel
    property var settingsRunnerModel
    property var favoritesModel
    property var contextMenuController

    property int columnCount: 8

    property string searchResultsText: ""
    property string appsText: ""
    property string filesText: ""
    property string settingsText: ""
    property string pinText: ""
    property string unpinText: ""
    property string noResultsText: ""
    property string balooNoResultsText: ""

    signal closeLauncherRequested()
    signal removeFavoriteFromGroupsRequested(string favoriteId)

    visible: searchText.length > 0

    Flickable {
        id: searchResultsScroll

        anchors.fill: parent
        clip: true

        contentWidth: width
        contentHeight: Math.max(
            settingsSearchGrid.visible
                ? settingsSearchGrid.y + settingsSearchGrid.height + 30
                : fileSearchGrid.visible
                    ? fileSearchGrid.y + fileSearchGrid.height + 30
                    : appSearchGrid.visible
                        ? appSearchGrid.y + appSearchGrid.height + 30
                        : noSearchResultsLabel.y + noSearchResultsLabel.height + 30,
            height
        )

        boundsBehavior: Flickable.StopAtBounds

        Controls.ScrollBar.vertical: Controls.ScrollBar {
            policy: Controls.ScrollBar.AlwaysOn

            width: 6

            contentItem: Rectangle {
                implicitWidth: 5
                radius: width / 2
                color: "#555a66"
                opacity: parent.pressed ? 0.9 : 0.65
            }

            background: Rectangle {
                color: "transparent"
            }
        }

        PlasmaComponents.Label {
            id: searchResultsLabel

            x: 32
            y: 5

            text: searchResultsView.searchResultsText

            font.pixelSize: 16
            font.bold: true

            visible: searchResultsView.searchText.length > 0
        }

        PlasmaComponents.Label {
            id: appsResultsLabel

            x: 32
            y: 45

            text: searchResultsView.appsText

            font.pixelSize: 14
            font.bold: true
            opacity: 0.85

            visible: searchResultsView.searchText.length > 0
                && appSearchGrid.count > 0
        }

        GridView {
            id: appSearchGrid

            x: 32
            y: 75

            height: appSearchGrid.count > 0
                ? Math.ceil(appSearchGrid.count / searchResultsView.columnCount) * appSearchGrid.cellHeight
                : 0
            width: parent.width - 64

            clip: true

            cellHeight: 80
            cellWidth: width / searchResultsView.columnCount

            visible: searchResultsView.searchText.length > 0
                && appSearchGrid.count > 0

            interactive: false

            model: searchResultsView.appRunnerModel
                && searchResultsView.appRunnerModel.count > 0
                    ? searchResultsView.appRunnerModel.modelForRow(0)
                    : null

            delegate: Item {
                id: searchAppItem

                height: appSearchGrid.cellHeight
                width: appSearchGrid.cellWidth

                Rectangle {
                    id: searchAppHover

                    anchors.fill: parent
                    anchors.margins: 2

                    radius: 12
                    color: "#30343d"

                    opacity: searchAppMouseArea.containsMouse ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }
                }

                Kirigami.Icon {
                    id: searchAppIcon

                    width: 36
                    height: 36

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 8

                    source: model.decoration
                }

                PlasmaComponents.Label {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: searchAppIcon.bottom
                    anchors.topMargin: 5
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4

                    text: model.display
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.pixelSize: 13
                }

                Controls.Menu {
                    id: searchAppContextMenu

                    Connections {
                        target: searchResultsView.contextMenuController

                        function onCloseContextMenus() {
                            searchAppContextMenu.close()
                        }
                    }

                    Controls.MenuItem {
                        text: searchResultsView.favoritesModel
                            && searchResultsView.favoritesModel.isFavorite(model.favoriteId)
                                ? searchResultsView.unpinText
                                : searchResultsView.pinText
                        icon.name: searchResultsView.favoritesModel
                            && searchResultsView.favoritesModel.isFavorite(model.favoriteId)
                                ? "list-remove"
                                : "list-add"

                        onTriggered: {
                            var favoriteId = String(model.favoriteId || "")

                            if (!favoriteId || !searchResultsView.favoritesModel) {
                                return
                            }

                            if (searchResultsView.favoritesModel.isFavorite(favoriteId)) {
                                searchResultsView.removeFavoriteFromGroupsRequested(favoriteId)
                                searchResultsView.favoritesModel.removeFavorite(favoriteId)
                            } else {
                                searchResultsView.favoritesModel.addFavorite(favoriteId)
                            }
                        }
                    }
                }

                MouseArea {
                    id: searchAppMouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            searchAppContextMenu.popup(
                                searchAppMouseArea,
                                mouse.x,
                                mouse.y
                            )
                            return
                        }

                        appSearchGrid.model.trigger(index, "", null)
                        searchResultsView.closeLauncherRequested()
                    }
                }
            }
        }

        PlasmaComponents.Label {
            id: filesResultsLabel

            x: 32
            y: appSearchGrid.count > 0
                ? appSearchGrid.y + appSearchGrid.height + 18
                : 45

            text: searchResultsView.filesText

            font.pixelSize: 14
            font.bold: true
            opacity: 0.85

            visible: searchResultsView.searchText.length > 0
                && fileSearchGrid.count > 0
        }

        GridView {
            id: fileSearchGrid

            x: 32
            y: filesResultsLabel.y + 30

            height: fileSearchGrid.count > 0
                ? Math.ceil(fileSearchGrid.count / searchResultsView.columnCount) * fileSearchGrid.cellHeight
                : 0
            width: parent.width - 64

            clip: true

            cellHeight: 80
            cellWidth: width / searchResultsView.columnCount

            visible: searchResultsView.searchText.length > 0
                && fileSearchGrid.count > 0

            interactive: false
            model: searchResultsView.fileSearchResultsModel

            delegate: Item {
                id: searchFileItem

                height: fileSearchGrid.cellHeight
                width: fileSearchGrid.cellWidth

                Rectangle {
                    id: searchFileHover

                    anchors.fill: parent
                    anchors.margins: 2

                    radius: 12
                    color: "#30343d"
                    opacity: searchFileMouseArea.containsMouse ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }
                }

                Kirigami.Icon {
                    id: searchFileIcon

                    width: 36
                    height: 36

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 8

                    source: model.decoration || "text-x-generic"
                }

                PlasmaComponents.Label {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: searchFileIcon.bottom
                    anchors.topMargin: 5
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4

                    text: model.display
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.pixelSize: 13
                }

                MouseArea {
                    id: searchFileMouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (fileSearchGrid.model) {
                            fileSearchGrid.model.trigger(index, "", null)
                        }
                        searchResultsView.closeLauncherRequested()
                    }
                }
            }
        }

        PlasmaComponents.Label {
            id: settingsResultsLabel

            x: 32
            y: fileSearchGrid.count > 0
                ? fileSearchGrid.y + fileSearchGrid.height + 18
                : appSearchGrid.count > 0
                    ? appSearchGrid.y + appSearchGrid.height + 18
                    : 45

            text: searchResultsView.settingsText

            font.pixelSize: 14
            font.bold: true
            opacity: 0.85

            visible: searchResultsView.searchText.length > 0
                && settingsSearchGrid.count > 0
        }

        GridView {
            id: settingsSearchGrid

            x: 32
            y: settingsResultsLabel.y + 30

            height: settingsSearchGrid.count > 0
                ? Math.ceil(settingsSearchGrid.count / searchResultsView.columnCount) * settingsSearchGrid.cellHeight
                : 0
            width: parent.width - 64

            clip: true

            cellHeight: 80
            cellWidth: width / searchResultsView.columnCount

            visible: searchResultsView.searchText.length > 0
                && settingsSearchGrid.count > 0

            interactive: false

            model: searchResultsView.settingsRunnerModel
                && searchResultsView.settingsRunnerModel.count > 0
                    ? searchResultsView.settingsRunnerModel.modelForRow(0)
                    : null

            delegate: Item {
                id: searchSettingsItem

                height: settingsSearchGrid.cellHeight
                width: settingsSearchGrid.cellWidth

                Rectangle {
                    id: searchSettingsHover

                    anchors.fill: parent
                    anchors.margins: 2

                    radius: 12
                    color: "#30343d"
                    opacity: searchSettingsMouseArea.containsMouse ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }
                }

                Kirigami.Icon {
                    id: searchSettingsIcon

                    width: 36
                    height: 36

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 8

                    source: model.decoration
                }

                PlasmaComponents.Label {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: searchSettingsIcon.bottom
                    anchors.topMargin: 5
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4

                    text: model.display
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.pixelSize: 13
                }

                MouseArea {
                    id: searchSettingsMouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        settingsSearchGrid.model.trigger(index, "", null)
                        searchResultsView.closeLauncherRequested()
                    }
                }
            }
        }

        PlasmaComponents.Label {
            id: noSearchResultsLabel

            anchors.left: parent.left
            anchors.right: parent.right

            y: 75
            height: 150

            text: searchResultsView.searchText.length >= 3
                && searchResultsView.fileSearchResultsModel
                && searchResultsView.fileSearchResultsModel.count === 0
                    ? searchResultsView.balooNoResultsText
                    : searchResultsView.noResultsText

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            font.pixelSize: 16
            opacity: 0.7

            visible: searchResultsView.searchText.length > 0
                && appSearchGrid.count === 0
                && fileSearchGrid.count === 0
                && settingsSearchGrid.count === 0
        }
    }
}
