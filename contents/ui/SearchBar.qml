import QtQuick
import org.kde.plasma.components as PlasmaComponents

Rectangle {
    id: searchBar

    property string searchText: ""
    property string placeholderText: ""
    property bool launcherExpanded: false

    signal searchTextEdited(string text)

    function focusSearchField() {
        searchField.forceActiveFocus()
    }

    height: 46
    radius: 23
    color: "#17191f"
    border.color: "#30343d"
    border.width: 1

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter

        text: "⌕"
        color: "#4da3ff"
        font.pixelSize: 25
    }

    PlasmaComponents.TextField {
        id: searchField

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        leftPadding: 52
        rightPadding: 16

        placeholderText: searchBar.placeholderText
        background: null
        font.pixelSize: 15
        text: searchBar.searchText

        onTextEdited: {
            searchBar.searchTextEdited(text)
        }
    }

    Shortcut {
        sequence: "Ctrl+F"
        enabled: searchBar.launcherExpanded

        onActivated: {
            searchBar.focusSearchField()
        }
    }
}
