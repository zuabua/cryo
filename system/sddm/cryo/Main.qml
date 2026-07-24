// cryo SDDM login screen
// Palette mirrors ~/.config/theme/colors.sh
import QtQuick 2.15
import QtQuick.Controls 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#303446"

    Image {
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
    }

    Text {
        id: clock
        anchors { top: parent.top; right: parent.right; margins: 32 }
        color: "#a5adce"
        font.family: "JetBrainsMono Nerd Font Mono"
        font.pixelSize: 18
        text: Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm")
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm")
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 380
        height: 200
        radius: 12
        color: "#292c3c"
        border.color: "#5eead4"
        border.width: 2

        Column {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 18

            // Username label
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: userModel.lastUser !== "" ? userModel.lastUser : "user"
                color: "#5eead4"
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 13
            }

            // Password field
            Rectangle {
                width: parent.width
                height: 34
                radius: 6
                color: "#414559"
                border.color: passwordInput.activeFocus ? "#5eead4" : "#414559"
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#c6d0f5"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 13
                    echoMode: TextInput.Password
                    focus: true
                    passwordCharacter: "\u2022"
                    selectionColor: "#5eead4"
                    selectedTextColor: "#303446"
                    Keys.onReturnPressed: sddm.login(
                        userModel.lastUser !== "" ? userModel.lastUser : "",
                        passwordInput.text,
                        sessionModel.lastIndex
                    )
                    // Placeholder text when empty
                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "password"
                        color: "#a5adce"
                        font: parent.font
                        visible: !passwordInput.text && !passwordInput.activeFocus
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                id: statusText
                text: ""
                color: "#f87171"
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 10
            }
        }
    }

    Row {
        anchors { bottom: parent.bottom; right: parent.right; margins: 32 }
        spacing: 14

        Text {
            text: "\uf186  sleep"
            color: "#a5adce"
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 11
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.suspend()
            }
        }
        Text {
            text: "\uf021  reboot"
            color: "#a5adce"
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 11
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.reboot()
            }
        }
        Text {
            text: "\uf011  power off"
            color: "#f87171"
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 11
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.powerOff()
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            statusText.text = "login failed"
            passwordInput.text = ""
            passwordInput.focus = true
        }
        function onLoginSucceeded() {
            statusText.text = ""
        }
    }
}
