// Cryo Waybar controller drawer (Super+Shift+W)
// Change order and position of pills in the bar, aswell as enable and disable them
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Item {
    id: root
    readonly property string home: Quickshell.env("HOME")

    property bool barCtlShown: false
    property var  barCtlLeft:   []
    property var  barCtlCenter: []
    property var  barCtlRight:  []
    property var  barCtlAvail:  []
    property bool barCtlDirty:  false
    property bool barCtlAnimReady: false

    onBarCtlShownChanged: {
        if (barCtlShown) {
            barCtlAnimReady = false
            Qt.callLater(function(){ root.barCtlAnimReady = true })
            barCtlListProc.running = true
        } else {
            barCtlAnimReady = false
        }
    }

    function barCtlMove(zone, idx, dir) {
        var arr = (zone === "left") ? barCtlLeft.slice()
                : (zone === "center") ? barCtlCenter.slice()
                : barCtlRight.slice();
        var ni = idx + dir;
        if (ni < 0 || ni >= arr.length) return;
        var tmp = arr[idx]; arr[idx] = arr[ni]; arr[ni] = tmp;
        if (zone === "left")   root.barCtlLeft   = arr;
        if (zone === "center") root.barCtlCenter = arr;
        if (zone === "right")  root.barCtlRight  = arr;
        root.barCtlDirty = true;
    }
    function barCtlRemove(zone, idx) {
        var arr = (zone === "left") ? barCtlLeft.slice()
                : (zone === "center") ? barCtlCenter.slice()
                : barCtlRight.slice();
        arr.splice(idx, 1);
        if (zone === "left")   root.barCtlLeft   = arr;
        if (zone === "center") root.barCtlCenter = arr;
        if (zone === "right")  root.barCtlRight  = arr;
        root.barCtlDirty = true;
    }
    function barCtlAdd(zone, mod) {
        var arr = (zone === "left") ? barCtlLeft.slice()
                : (zone === "center") ? barCtlCenter.slice()
                : barCtlRight.slice();
        if (arr.indexOf(mod) !== -1) return;     // no duplicates
        arr.push(mod);
        if (zone === "left")   root.barCtlLeft   = arr;
        if (zone === "center") root.barCtlCenter = arr;
        if (zone === "right")  root.barCtlRight  = arr;
        root.barCtlDirty = true;
    }
    function barCtlUnusedFor(zone) {
        var taken = barCtlLeft.concat(barCtlCenter, barCtlRight);
        var out = [];
        for (var i = 0; i < barCtlAvail.length; i++) {
            if (taken.indexOf(barCtlAvail[i]) === -1) out.push(barCtlAvail[i]);
        }
        return out;
    }

    Process {
        id: barCtlListProc
        command: ["bash", "-c", "~/.local/bin/waybar-layout list > ~/.cache/cryo-waybar-layout.json"]
        running: false
        onRunningChanged: { if (!running) barCtlListFile.reload() }
    }
    FileView {
        id: barCtlListFile
        path: root.home + "/.cache/cryo-waybar-layout.json"
        watchChanges: true
        function ingest() {
            const t = barCtlListFile.text().trim();
            if (!t) return;
            try {
                const j = JSON.parse(t);
                root.barCtlAvail  = j.available || [];
                root.barCtlLeft   = j.left      || [];
                root.barCtlCenter = j.center    || [];
                root.barCtlRight  = j.right     || [];
                root.barCtlDirty  = false;
            } catch (e) { console.warn("waybar-layout JSON parse:", e); }
        }
        onLoaded:      ingest()
        onFileChanged: { barCtlListFile.reload(); ingest() }
    }
    Process {
        id: barCtlApplyProc
        property string leftCsv:   ""
        property string centerCsv: ""
        property string rightCsv:  ""
        command: ["bash", "-c",
            "~/.local/bin/waybar-layout set left   \"$L\" >/dev/null && " +
            "~/.local/bin/waybar-layout set center \"$C\" >/dev/null && " +
            "~/.local/bin/waybar-layout set right  \"$R\" >/dev/null && " +
            "~/.local/bin/waybar-layout apply >/dev/null"]
        environment: ({
            "L": barCtlApplyProc.leftCsv,
            "C": barCtlApplyProc.centerCsv,
            "R": barCtlApplyProc.rightCsv
        })
        running: false
        onRunningChanged: {
            if (!running) {
                root.barCtlDirty = false
                barCtlListProc.running = true
            }
        }
    }
    Process {
        id: barCtlResetProc
        command: ["bash", "-c", "~/.local/bin/waybar-layout reset >/dev/null"]
        running: false
        onRunningChanged: { if (!running) barCtlListProc.running = true }
    }
    Process {
        id: barCtlHide
        command: ["bash", "-c", "echo 0 > ~/.cache/cryo-barctl-shown"]
        running: false
    }
    FileView {
        id: barCtlShownFile
        path: root.home + "/.cache/cryo-barctl-shown"
        watchChanges: true
        onLoaded:      root.barCtlShown = (barCtlShownFile.text().trim() === "1")
        onFileChanged: { barCtlShownFile.reload(); root.barCtlShown = (barCtlShownFile.text().trim() === "1") }
    }

    PanelWindow {
        id: barCtlPanel
        visible: root.barCtlShown
        anchors { top: true }
        margins.top: 60
        implicitWidth: 760
        implicitHeight: 640
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusiveZone: 0

        component ZoneRow : Rectangle {
            id: zoneRow
            property string zone: ""
            property int    rowIndex: 0
            property int    total: 1
            property string moduleName: ""
            implicitHeight: 28
            radius: 6
            color: rowMa.containsMouse ? "#385eead4" : "#303446"
            border.color: "#414559"
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 6
                spacing: 4
                Text {
                    Layout.fillWidth: true
                    text: zoneRow.moduleName
                    color: "#c6d0f5"
                    elide: Text.ElideRight
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 11
                }
                // ↑
                Rectangle {
                    width: 22; height: 22; radius: 4
                    color: "transparent"; border.color: "#5eead4"; border.width: 1
                    opacity: zoneRow.rowIndex > 0 ? 1.0 : 0.3
                    Text { anchors.centerIn: parent; text: "▲"; color: "#5eead4"
                           font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 9 }
                    MouseArea {
                        anchors.fill: parent
                        enabled: zoneRow.rowIndex > 0
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                        onClicked: root.barCtlMove(zoneRow.zone, zoneRow.rowIndex, -1)
                    }
                }
                // ↓
                Rectangle {
                    width: 22; height: 22; radius: 4
                    color: "transparent"; border.color: "#5eead4"; border.width: 1
                    opacity: zoneRow.rowIndex < zoneRow.total - 1 ? 1.0 : 0.3
                    Text { anchors.centerIn: parent; text: "▼"; color: "#5eead4"
                           font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 9 }
                    MouseArea {
                        anchors.fill: parent
                        enabled: zoneRow.rowIndex < zoneRow.total - 1
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                        onClicked: root.barCtlMove(zoneRow.zone, zoneRow.rowIndex, 1)
                    }
                }
                // ×
                Rectangle {
                    width: 22; height: 22; radius: 4
                    color: "transparent"; border.color: "#f87171"; border.width: 1
                    Text { anchors.centerIn: parent; text: "×"; color: "#f87171"
                           font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 11 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.barCtlRemove(zoneRow.zone, zoneRow.rowIndex)
                    }
                }
            }
            MouseArea { id: rowMa; anchors.fill: parent; hoverEnabled: true; z: -1 }
        }

        component ZoneColumn : ColumnLayout {
            id: zoneCol
            property string title: ""
            property string zone:  ""
            property var    items: []
            spacing: 4

            Text {
                text: zoneCol.title
                color: "#a5adce"
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 10
                font.bold: true
                Layout.bottomMargin: 4
            }
            Repeater {
                model: zoneCol.items
                ZoneRow {
                    Layout.fillWidth: true
                    zone:       zoneCol.zone
                    rowIndex:   index
                    total:      zoneCol.items.length
                    moduleName: modelData
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "#bf292c3c"
            border.color: "#5eead4"
            border.width: 2
            opacity: root.barCtlAnimReady ? 1.0 : 0.0
            scale:   root.barCtlAnimReady ? 1.0 : 0.95
            transformOrigin: Item.Top
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Waybar layout" + (root.barCtlDirty ? " · unsaved changes" : "")
                        color: root.barCtlDirty ? "#818cf8" : "#c6d0f5"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Text {
                        text: "✕"
                        color: closeMa2.containsMouse ? "#f87171" : "#a5adce"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 16
                        Behavior on color { ColorAnimation { duration: 150 } }
                        MouseArea {
                            id: closeMa2
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: barCtlHide.running = true
                        }
                    }
                }

                // Three zone columns side-by-side
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 16
                    ZoneColumn {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignTop
                        title: "LEFT"
                        zone:  "left"
                        items: root.barCtlLeft
                    }
                    ZoneColumn {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignTop
                        title: "CENTER"
                        zone:  "center"
                        items: root.barCtlCenter
                    }
                    ZoneColumn {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignTop
                        title: "RIGHT"
                        zone:  "right"
                        items: root.barCtlRight
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        property int unusedCount: root.barCtlUnusedFor("").length
                        text: unusedCount === 0
                              ? "Available · all modules in use"
                              : "Available · " + unusedCount + " unused — click L / C / R to add"
                        color: "#a5adce"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: root.barCtlUnusedFor("")
                            Rectangle {
                                id: chip
                                property string modName: modelData
                                radius: 6
                                color: "#303446"
                                border.color: "#414559"
                                border.width: 1
                                implicitHeight: 26
                                implicitWidth: chipRow.implicitWidth + 14

                                RowLayout {
                                    id: chipRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    spacing: 6

                                    Text {
                                        text: chip.modName
                                        color: "#c6d0f5"
                                        font.family: "JetBrainsMono Nerd Font Mono"
                                        font.pixelSize: 10
                                    }
                                    Rectangle {
                                        width: 18; height: 18; radius: 3
                                        color: lMa.containsMouse ? "#385eead4" : "#414559"
                                        border.color: "#5eead4"; border.width: 1
                                        Text { anchors.centerIn: parent; text: "L"; color: "#5eead4"
                                               font.family: "JetBrainsMono Nerd Font Mono"
                                               font.pixelSize: 9; font.bold: true }
                                        MouseArea {
                                            id: lMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.barCtlAdd("left", chip.modName)
                                        }
                                    }
                                    Rectangle {
                                        width: 18; height: 18; radius: 3
                                        color: cMa.containsMouse ? "#385eead4" : "#414559"
                                        border.color: "#5eead4"; border.width: 1
                                        Text { anchors.centerIn: parent; text: "C"; color: "#5eead4"
                                               font.family: "JetBrainsMono Nerd Font Mono"
                                               font.pixelSize: 9; font.bold: true }
                                        MouseArea {
                                            id: cMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.barCtlAdd("center", chip.modName)
                                        }
                                    }
                                    Rectangle {
                                        width: 18; height: 18; radius: 3
                                        color: rMa.containsMouse ? "#385eead4" : "#414559"
                                        border.color: "#5eead4"; border.width: 1
                                        Text { anchors.centerIn: parent; text: "R"; color: "#5eead4"
                                               font.family: "JetBrainsMono Nerd Font Mono"
                                               font.pixelSize: 9; font.bold: true }
                                        MouseArea {
                                            id: rMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.barCtlAdd("right", chip.modName)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle {
                        property bool hovered: resetCtlMa.containsMouse
                        Layout.preferredWidth: 140; height: 32; radius: 7
                        color: hovered ? "#38f87171" : "#414559"
                        border.color: "#f87171"; border.width: 1
                        scale: hovered ? 1.02 : 1.0
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on scale { NumberAnimation { duration: 180 } }
                        Text { anchors.centerIn: parent; text: "Reset to defaults"; color: "#f87171"
                               font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10; font.bold: true }
                        MouseArea { id: resetCtlMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor; onClicked: barCtlResetProc.running = true }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        property bool hovered: applyMa.containsMouse
                        Layout.preferredWidth: 140; height: 32; radius: 7
                        color: hovered ? "#385eead4" : "#414559"
                        border.color: "#5eead4"; border.width: 1
                        scale: hovered ? 1.02 : 1.0
                        opacity: root.barCtlDirty ? 1.0 : 0.5
                        Behavior on color   { ColorAnimation  { duration: 180 } }
                        Behavior on scale   { NumberAnimation { duration: 180 } }
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                        Text { anchors.centerIn: parent; text: "Apply"; color: "#5eead4"
                               font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 11; font.bold: true }
                        MouseArea {
                            id: applyMa
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.barCtlDirty
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                            onClicked: {
                                barCtlApplyProc.leftCsv   = root.barCtlLeft.join(",");
                                barCtlApplyProc.centerCsv = root.barCtlCenter.join(",");
                                barCtlApplyProc.rightCsv  = root.barCtlRight.join(",");
                                barCtlApplyProc.running = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
