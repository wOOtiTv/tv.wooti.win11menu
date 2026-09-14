import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons

Rectangle {
    id: footer

    property var sessionManager

    property bool showLockButton: true
    property bool showLogoutButton: true
    property bool showRestartButton: true
    property bool showShutdownButton: true
    readonly property bool showSessionButtonLabels:
        Plasmoid.configuration.showSessionButtonLabels !== false
    readonly property string sessionButtonAlignment:
        String(Plasmoid.configuration.sessionButtonAlignment || "right")
    readonly property bool centerSessionButtons:
        sessionButtonAlignment === "center"

    property string lockText: ""
    property string logoutText: ""
    property string restartText: ""
    property string shutdownText: ""

    signal closeLauncherRequested()

    height: 78
    radius: 18
    color: "#15171d"

    KCoreAddons.KUser {
        id: currentUser
    }

    Item {
        id: userInfo

        visible: Plasmoid.configuration.showUserInfo

        anchors.left: parent.left
        anchors.leftMargin: 24

        anchors.verticalCenter: parent.bottom
        anchors.verticalCenterOffset: -39

        width: Math.max(
            120,
            Math.min(250, sessionActions.x - 40)
        )
        height: 48

        Rectangle {
            id: avatarFrame

            width: 32
            height: 32

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            radius: width / 2
            color: "#30343d"
            clip: true

            Image {
                id: userAvatar

                anchors.fill: parent
                source: currentUser.faceIconUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }

            OpacityMask {
                anchors.fill: userAvatar
                source: userAvatar
                maskSource: avatarMask
                visible: userAvatar.status === Image.Ready
            }

            Rectangle {
                id: avatarMask

                anchors.fill: parent
                radius: width / 2
                color: "white"
                visible: false
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 24
                height: 24
                source: "user"
                visible: userAvatar.status !== Image.Ready
            }
        }

        PlasmaComponents.Label {
            anchors.left: avatarFrame.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.verticalCenter: avatarFrame.verticalCenter

            text: currentUser.fullName
            font.pixelSize: 15
            font.bold: true
            maximumLineCount: 1
            elide: Text.ElideRight
        }
    }

    Row {
        id: sessionActions

        x: footer.centerSessionButtons
            ? Math.round((parent.width - width) / 2)
            : parent.width - width - 24
        anchors.verticalCenter: parent.bottom
        anchors.verticalCenterOffset: -39

        spacing: 8

        Rectangle {
            id: lockButton

            visible: footer.showLockButton
            width: footer.showSessionButtonLabels
                ? Math.max(118, lockContent.implicitWidth + 28)
                : 54
            height: footer.showSessionButtonLabels ? 42 : 50
            radius: 12

            color: lockMouse.containsMouse
                ? "#30343d"
                : "transparent"

            opacity: footer.sessionManager && footer.sessionManager.canLock ? 1 : 0.45

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Row {
                id: lockContent

                anchors.centerIn: parent
                spacing: footer.showSessionButtonLabels ? 8 : 0

                Kirigami.Icon {
                    width: footer.showSessionButtonLabels ? 20 : 30
                    height: width
                    source: "system-lock-screen"
                }

                PlasmaComponents.Label {
                    visible: footer.showSessionButtonLabels
                    height: 20
                    verticalAlignment: Text.AlignVCenter
                    text: footer.lockText
                    font.pixelSize: 13
                }
            }

            MouseArea {
                id: lockMouse

                anchors.fill: parent
                hoverEnabled: true
                enabled: footer.sessionManager ? footer.sessionManager.canLock : false
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                    footer.closeLauncherRequested()
                    footer.sessionManager.lock()
                }
            }
        }

        Rectangle {
            id: logoutButton

            visible: footer.showLogoutButton
            width: footer.showSessionButtonLabels
                ? Math.max(118, logoutContent.implicitWidth + 28)
                : 54
            height: footer.showSessionButtonLabels ? 42 : 50
            radius: 12

            color: logoutMouse.containsMouse
                ? "#30343d"
                : "transparent"

            opacity: footer.sessionManager && footer.sessionManager.canLogout ? 1 : 0.45

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Row {
                id: logoutContent

                anchors.centerIn: parent
                spacing: footer.showSessionButtonLabels ? 8 : 0

                Kirigami.Icon {
                    width: footer.showSessionButtonLabels ? 20 : 30
                    height: width
                    source: "system-log-out"
                }

                PlasmaComponents.Label {
                    visible: footer.showSessionButtonLabels
                    height: 20
                    verticalAlignment: Text.AlignVCenter
                    text: footer.logoutText
                    font.pixelSize: 13
                }
            }

            MouseArea {
                id: logoutMouse

                anchors.fill: parent
                hoverEnabled: true
                enabled: footer.sessionManager ? footer.sessionManager.canLogout : false
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                    footer.sessionManager.requestLogout(1)
                }
            }
        }

        Rectangle {
            id: rebootButton

            visible: footer.showRestartButton
            width: footer.showSessionButtonLabels
                ? Math.max(112, rebootContent.implicitWidth + 28)
                : 54
            height: footer.showSessionButtonLabels ? 42 : 50
            radius: 12

            color: rebootMouse.containsMouse
                ? "#30343d"
                : "transparent"

            opacity: footer.sessionManager && footer.sessionManager.canReboot ? 1 : 0.45

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Row {
                id: rebootContent

                anchors.centerIn: parent
                spacing: footer.showSessionButtonLabels ? 8 : 0

                Kirigami.Icon {
                    width: footer.showSessionButtonLabels ? 20 : 30
                    height: width
                    source: "system-reboot"
                }

                PlasmaComponents.Label {
                    visible: footer.showSessionButtonLabels
                    height: 20
                    verticalAlignment: Text.AlignVCenter
                    text: footer.restartText
                    font.pixelSize: 13
                }
            }

            MouseArea {
                id: rebootMouse

                anchors.fill: parent
                hoverEnabled: true
                enabled: footer.sessionManager ? footer.sessionManager.canReboot : false
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                    footer.sessionManager.requestReboot(1)
                }
            }
        }

        Rectangle {
            id: shutdownButton

            visible: footer.showShutdownButton
            width: footer.showSessionButtonLabels
                ? Math.max(108, shutdownContent.implicitWidth + 28)
                : 54
            height: footer.showSessionButtonLabels ? 42 : 50
            radius: 12

            color: shutdownMouse.containsMouse
                ? "#30343d"
                : "transparent"

            opacity: footer.sessionManager && footer.sessionManager.canShutdown ? 1 : 0.45

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Row {
                id: shutdownContent

                anchors.centerIn: parent
                spacing: footer.showSessionButtonLabels ? 8 : 0

                Kirigami.Icon {
                    width: footer.showSessionButtonLabels ? 20 : 30
                    height: width
                    source: "system-shutdown"
                }

                PlasmaComponents.Label {
                    visible: footer.showSessionButtonLabels
                    height: 20
                    verticalAlignment: Text.AlignVCenter
                    text: footer.shutdownText
                    font.pixelSize: 13
                }
            }

            MouseArea {
                id: shutdownMouse

                anchors.fill: parent
                hoverEnabled: true
                enabled: footer.sessionManager ? footer.sessionManager.canShutdown : false
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                    footer.sessionManager.requestShutdown(1)
                }
            }
        }
    }
}
