// Cryo inbox capture drawer
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Item {
    id: root
    readonly property string home: Quickshell.env("HOME")

    property bool shown: false
    property bool animReady: false

    onShownChanged: {
        if (shown) { animReady = false; Qt.callLater(function(){ root.animReady = true }) }
        else       { animReady = false }
    }

    FileView {
        id: shownFile
        path: root.home + "/.cache/cryo-inbox-shown"
        watchChanges: true
        onLoaded:      root.shown = (shownFile.text().trim() === "1")
        onFileChanged: { shownFile.reload(); root.shown = (shownFile.text().trim() === "1") }
    }

    Process {
        id: captureProc
        property string text: ""
        command: ["bash", "-c", "~/.local/bin/inbox \"$TXT\" >/dev/null"]
        environment: ({ "TXT": captureProc.text })
        running: false
    }
    Process {
        id: hideProc
        command: ["bash", "-c", "echo 0 > ~/.cache/cryo-inbox-shown"]
        running: false
    }

    PanelWindow {
        id: panel
        visible: root.shown
        anchors { top: true }
        margins.top: 200
        implicitWidth: 560
        implicitHeight: 90
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusiveZone: 0

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "#bf292c3c"
            border.color: input.activeFocus ? "#5eead4" : "#414559"
            border.width: 2
            Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

            opacity: root.animReady ? 1.0 : 0.0
            scale:   root.animReady ? 1.0 : 0.95
            transformOrigin: Item.Top
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Connections {
                target: root
                function onAnimReadyChanged() {
                    if (root.animReady) input.forceActiveFocus();
                }
            }

            Text {
                id: bullet
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 18
                text: "›"
                color: "#5eead4"
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 22
                font.bold: true
            }

            TextInput {
                id: input
                anchors.left: bullet.right
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 18
                color: "#c6d0f5"
                selectByMouse: true
                clip: true
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 16
                cursorVisible: activeFocus

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "what's on your mind?"
                    color: "#a5adce"
                    visible: input.text.length === 0 && !input.activeFocus
                    font.family: input.font.family
                    font.pixelSize: input.font.pixelSize
                    font.italic: true
                }

                Keys.onReturnPressed: {
                    if (text.trim().length > 0) {
                        captureProc.text = text.trim();
                        captureProc.running = true;
                    }
                    text = "";
                    hideProc.running = true;
                }
                Keys.onEnterPressed: Keys.onReturnPressed(event)
                Keys.onEscapePressed: {
                    text = "";
                    hideProc.running = true;
                }
            }

            Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 10
                anchors.bottomMargin: 4
                text: "↵ save · esc cancel"
                color: "#a5adce"
                opacity: 0.55
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 9
            }
        }
    }
}
