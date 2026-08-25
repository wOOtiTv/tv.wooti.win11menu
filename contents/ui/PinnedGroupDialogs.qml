import QtQuick
import QtQuick.Controls as Controls

Item {
    id: groupDialogs

    property Item popupParent
    property var pinnedGroups: []
    property int maxGroupApps: 16

    property string addToGroupTitle: ""
    property string addToGroupText: ""
    property string newGroupText: ""
    property string groupNamePlaceholder: ""
    property string renameGroupTitle: ""

    signal createGroupRequested(string name, string favoriteId)
    signal addFavoriteToGroupRequested(string favoriteId, string groupId)
    signal renameGroupRequested(string groupId, string name)

    function openAddToGroup(favoriteId, favoriteName) {
        addToGroupDialog.favoriteId = String(favoriteId || "")
        addToGroupDialog.favoriteName = String(favoriteName || "")
        addToGroupDialog.rebuildChoices()
        addToGroupDialog.open()
    }

    function openRenameGroup(groupId, groupName) {
        renameGroupDialog.groupId = String(groupId || "")
        renameGroupDialog.groupName = String(groupName || "")
        renameGroupField.text = String(groupName || "")
        renameGroupDialog.open()
        renameGroupField.forceActiveFocus()
        renameGroupField.selectAll()
    }

    ListModel {
        id: groupChoiceModel
    }

    Controls.Dialog {
        id: addToGroupDialog

        parent: groupDialogs.popupParent
        x: groupDialogs.popupParent
            ? Math.round((groupDialogs.popupParent.width - width) / 2)
            : 0
        y: groupDialogs.popupParent
            ? Math.round((groupDialogs.popupParent.height - height) / 2)
            : 0
        width: 420
        modal: true
        focus: true
        title: groupDialogs.addToGroupTitle
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel

        property string favoriteId: ""
        property string favoriteName: ""

        function rebuildChoices() {
            groupChoiceModel.clear()

            var groups = groupDialogs.pinnedGroups || []

            for (var i = 0; i < groups.length; ++i) {
                var groupApps = groups[i].apps || []

                // Full groups are intentionally omitted from the target list.
                if (groupApps.length >= groupDialogs.maxGroupApps) {
                    continue
                }

                groupChoiceModel.append({
                    label: String(groups[i].name),
                    groupId: String(groups[i].id),
                    createNew: false
                })
            }

            groupChoiceModel.append({
                label: groupDialogs.newGroupText,
                groupId: "",
                createNew: true
            })

            groupChoice.currentIndex = groupChoiceModel.count > 0 ? 0 : -1
            newGroupField.text = ""
        }

        contentItem: Column {
            spacing: 12

            Controls.Label {
                width: 360
                wrapMode: Text.WordWrap
                text: groupDialogs.addToGroupText.replace(
                    "%1",
                    addToGroupDialog.favoriteName
                )
            }

            Controls.ComboBox {
                id: groupChoice
                width: 360
                model: groupChoiceModel
                textRole: "label"
            }

            Controls.TextField {
                id: newGroupField
                width: 360
                visible: groupChoice.currentIndex >= 0
                    && groupChoiceModel.get(groupChoice.currentIndex).createNew
                placeholderText: groupDialogs.groupNamePlaceholder
                onAccepted: addToGroupDialog.accept()
            }
        }

        onAccepted: {
            if (groupChoice.currentIndex < 0) {
                return
            }

            var choice = groupChoiceModel.get(groupChoice.currentIndex)

            if (choice.createNew) {
                groupDialogs.createGroupRequested(
                    newGroupField.text,
                    favoriteId
                )
            } else {
                groupDialogs.addFavoriteToGroupRequested(
                    favoriteId,
                    choice.groupId
                )
            }
        }
    }

    Controls.Dialog {
        id: renameGroupDialog

        parent: groupDialogs.popupParent
        x: groupDialogs.popupParent
            ? Math.round((groupDialogs.popupParent.width - width) / 2)
            : 0
        y: groupDialogs.popupParent
            ? Math.round((groupDialogs.popupParent.height - height) / 2)
            : 0
        width: 420
        modal: true
        focus: true
        title: groupDialogs.renameGroupTitle
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel

        property string groupId: ""
        property string groupName: ""

        contentItem: Controls.TextField {
            id: renameGroupField
            width: 360
            placeholderText: groupDialogs.groupNamePlaceholder
            onAccepted: renameGroupDialog.accept()
        }

        onAccepted: {
            groupDialogs.renameGroupRequested(
                groupId,
                renameGroupField.text
            )
        }
    }
}
