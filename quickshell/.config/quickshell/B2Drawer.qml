// Cryo B2 cloud upload drawer
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Item {
    id: root
    readonly property string home: Quickshell.env("HOME")

    property bool shown: false
    property string selectedCategory: "Misc"
    readonly property var categories: ["Pictures", "Videos", "Documents", "Code", "HTB", "Misc"]
    property bool animReady: false

    onShownChanged: {
        if (shown) {
            animReady = false
            Qt.callLater(function(){ root.animReady = true })
            refreshList.running = true
        } else {
            animReady = false
        }
    }

    FileView {
        id: stateFile
        path: root.home + "/.cache/cryo-b2-shown"
        watchChanges: true
        onLoaded: root.shown = (stateFile.text().trim() === "1")
        onFileChanged: { stateFile.reload(); root.shown = (stateFile.text().trim() === "1") }
    }
    FileView {
        id: statusFile
        path: root.home + "/.cache/cryo-b2-status"
        watchChanges: true
        property string line: ""
        onLoaded:      line = statusFile.text().trim()
        onFileChanged: { statusFile.reload(); line = statusFile.text().trim() }
    }
    Process {
        id: pickAndUpload
        command: ["bash", "-c",
            "p=$(zenity --file-selection --title='Upload to B2: " + root.selectedCategory + "') " +
            "&& ~/.config/quickshell/b2-upload.sh '" + root.selectedCategory + "' \"$p\""
        ]
        running: false
    }
    Process {
        id: pickAndUploadFolder
        command: ["bash", "-c",
            "p=$(zenity --file-selection --directory --title='Upload folder to B2: " + root.selectedCategory + "') " +
            "&& ~/.config/quickshell/b2-upload.sh '" + root.selectedCategory + "' \"$p\""
        ]
        running: false
    }
    Process {
        id: refreshList
        command: ["bash", "-c", "~/.config/quickshell/b2-list.sh"]
        running: false
    }
    Process {
        id: browseFetch
        command: ["bash", "-c", "~/.config/quickshell/b2-browse.sh fetch"]
        running: false
    }
    Process {
        id: browseDelete
        command: ["bash", "-c", "~/.config/quickshell/b2-browse.sh delete"]
        running: false
    }

    PanelWindow {
        visible: root.shown
        anchors { top: true }
        margins.top: 44
        implicitWidth: 420
        implicitHeight: 340
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        exclusiveZone: 0

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "#bf292c3c"
            border.color: "#5eead4"
            border.width: 2

            opacity: root.animReady ? 1.0 : 0.0
            scale:   root.animReady ? 1.0 : 0.95
            transformOrigin: Item.Top
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // ── Title ─────────────────────────────────
                Text {
                    text: "  B2 Drop Zone"
                    color: "#c6d0f5"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 14
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                // ── Category pills ────────────────────────
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: root.categories
                        Rectangle {
                            property bool active: modelData === root.selectedCategory
                            radius: 6
                            color: active ? "#5eead4" : "#414559"
                            width: catLabel.implicitWidth + 18
                            height: 26
                            Text {
                                id: catLabel
                                anchors.centerIn: parent
                                text: modelData
                                color: parent.active ? "#303446" : "#c6d0f5"
                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.selectedCategory = modelData
                            }
                        }
                    }
                }

                Rectangle {
                    id: dropWell
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: 8
                    color: "#303446"
                    property bool busy: pickAndUpload.running || pickAndUploadFolder.running
                    border.color: busy ? "#5eead4" : "#414559"
                    border.width: busy ? 2 : 1
                    Behavior on border.color { ColorAnimation { duration: 250 } }
                    Behavior on border.width { NumberAnimation { duration: 250 } }
                    SequentialAnimation on opacity {
                        running: dropWell.busy
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.55; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.55; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: dropWell.busy ? "  Uploading..." : "Drag here, or use buttons below"
                        color: dropWell.busy ? "#5eead4" : "#a5adce"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 11
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle {
                        Layout.fillWidth: true; height: 30; radius: 6
                        color: "#414559"; border.color: "#5eead4"; border.width: 1
                        Text { anchors.centerIn: parent; text: "Pick file"; color: "#5eead4"
                               font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; onClicked: pickAndUpload.running = true }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 30; radius: 6
                        color: "#414559"; border.color: "#5eead4"; border.width: 1
                        Text { anchors.centerIn: parent; text: "Pick folder"; color: "#5eead4"
                               font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; onClicked: pickAndUploadFolder.running = true }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle {
                        Layout.fillWidth: true; height: 30; radius: 6
                        color: "#414559"; border.color: "#818cf8"; border.width: 1
                        Text { anchors.centerIn: parent; text: "Fetch"; color: "#818cf8"
                               font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; onClicked: browseFetch.running = true }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 30; radius: 6
                        color: "#414559"; border.color: "#f87171"; border.width: 1
                        Text { anchors.centerIn: parent; text: "Delete"; color: "#f87171"
                               font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; onClicked: browseDelete.running = true }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                    text: statusFile.line === "" ? "ready" : statusFile.line
                    color: statusFile.line.indexOf("ERR") === 0 ? "#f87171"
                         : statusFile.line.indexOf("OK") === 0  ? "#5eead4"
                                                                : "#a5adce"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 10
                }

            }
        }
    }
}
