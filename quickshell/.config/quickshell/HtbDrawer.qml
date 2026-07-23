// Cryo — HTB session + active-target drawer (Super+T)
// Currently in a very experimental version
// Reads ~/.cache/cryo-htb-{shown,vpn} and
// ~/.local/share/cryo-htb/active-target.json (written by the
// htb-target CLI and the htb-vpn-daemon.sh). All mutations route
// through `htb-target <sub> [args]` so CLI and drawer stay in sync.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Item {
    id: root
    readonly property string home: Quickshell.env("HOME")

    property bool htbShown: false
    property bool htbAnimReady: false
    property var  htbStatus: ({ state: "down", lab: "", iface: "", myip: "", target: "", ping: "—" })
    property var  htbTarget: ({ name: "", ip: "", os: "", status: "", creds: [], ports: [], owned_user: false, owned_root: false })
    property string htbActiveLab: ""

    property var htbVpns: []

    property bool htbSetInputShown:  false
    property bool htbCredInputShown: false
    property bool htbPortInputShown: false
    property string htbSetName: ""
    property string htbSetIp: ""
    property string htbSetOs: ""
    property string htbCredUser: ""
    property string htbCredSecret: ""
    property string htbCredSource: ""
    property string htbPortNum: ""
    property string htbPortSvc: ""
    property string htbPortVer: ""

    onHtbShownChanged: {
        if (htbShown) {
            htbAnimReady = false
            Qt.callLater(function(){ root.htbAnimReady = true })
            htbVpnsList.running = true
        } else {
            htbAnimReady = false
        }
    }

    function htbRun(sub, a1, a2, a3) {
        htbExec.sub = sub || "";
        htbExec.a1  = a1  || "";
        htbExec.a2  = a2  || "";
        htbExec.a3  = a3  || "";
        htbExec.running = true;
    }
    function htbStatusColor() {
        if (root.htbStatus.state !== "up")  return "#f87171";
        if (root.htbTarget.owned_root)      return "#5eead4";
        if (root.htbTarget.owned_user)      return "#818cf8";
        if (root.htbStatus.target !== "")   return "#5eead4";
        return "#a5adce";
    }

    // ── HTB state files ─────────────────────────────────────
    FileView {
        id: htbShownFile
        path: root.home + "/.cache/cryo-htb-shown"
        watchChanges: true
        onLoaded:      root.htbShown = (htbShownFile.text().trim() === "1")
        onFileChanged: { htbShownFile.reload(); root.htbShown = (htbShownFile.text().trim() === "1") }
    }
    FileView {
        id: htbVpnFile
        path: root.home + "/.cache/cryo-htb-vpn"
        watchChanges: true
        function parse() {
            const t = htbVpnFile.text().trim();
            const out = { state: "down", lab: "", iface: "", myip: "", target: "", ping: "—" };
            t.split(/\s+/).forEach(function(kv) {
                const eq = kv.indexOf("=");
                if (eq > 0) out[kv.substring(0, eq)] = kv.substring(eq + 1);
            });
            root.htbStatus = out;
        }
        onLoaded:      parse()
        onFileChanged: { htbVpnFile.reload(); parse() }
    }
    FileView {
        id: htbTargetFile
        path: root.home + "/.local/share/cryo-htb/active-target.json"
        watchChanges: true
        function parse() {
            const t = htbTargetFile.text().trim();
            if (!t) return;
            try {
                const j = JSON.parse(t);
                // Defensive defaults so QML repeaters/Text never see undefined
                j.creds  = j.creds  || [];
                j.ports  = j.ports  || [];
                root.htbTarget = j;
            } catch (e) {
                console.warn("htb target JSON parse:", e);
            }
        }
        onLoaded:      parse()
        onFileChanged: { htbTargetFile.reload(); parse() }
    }
    FileView {
        id: htbActiveLabFile
        path: root.home + "/.config/htb/active-lab"
        watchChanges: true
        onLoaded:      root.htbActiveLab = htbActiveLabFile.text().trim()
        onFileChanged: { htbActiveLabFile.reload(); root.htbActiveLab = htbActiveLabFile.text().trim() }
    }
    FileView {
        id: htbVpnsFile
        path: root.home + "/.cache/cryo-htb-vpns.json"
        watchChanges: true
        function parse() {
            const t = htbVpnsFile.text().trim();
            if (!t) { root.htbVpns = []; return }
            try { root.htbVpns = JSON.parse(t) }
            catch (e) { console.warn("htb vpns JSON parse:", e); root.htbVpns = [] }
        }
        onLoaded:      parse()
        onFileChanged: { htbVpnsFile.reload(); parse() }
    }

    Process {
        id: htbExec
        property string sub: ""
        property string a1: ""
        property string a2: ""
        property string a3: ""
        command: ["bash", "-c", "~/.local/bin/htb-target \"$SUB\" ${A1:+\"$A1\"} ${A2:+\"$A2\"} ${A3:+\"$A3\"}"]
        environment: ({ "SUB": htbExec.sub, "A1": htbExec.a1, "A2": htbExec.a2, "A3": htbExec.a3 })
        running: false
        onRunningChanged: {
            if (!running) {
                htbTargetFile.reload();
                htbActiveLabFile.reload();
                htbVpnsList.running = true;
            }
        }
    }
    Process {
        id: htbVpnsList
        command: ["bash", "-c", "~/.local/bin/htb-vpn-list"]
        running: false
        onRunningChanged: { if (!running) htbVpnsFile.reload() }
    }
    Process {
        id: htbCopy
        property string text: ""
        command: ["bash", "-c", "printf '%s' \"$TXT\" | wl-copy"]
        environment: ({ "TXT": htbCopy.text })
        running: false
    }
    // Pick .ovpn file using zenity and pin it as active lab.
    Process {
        id: htbPickLab
        command: ["bash", "-c",
            "p=$(zenity --file-selection --title='Pick HTB lab .ovpn' --file-filter='*.ovpn' 2>/dev/null) " +
            "&& ~/.local/bin/htb-target lab set \"$p\""]
        running: false
        onRunningChanged: {
            if (!running) {
                htbActiveLabFile.reload()
                htbVpnsList.running = true   // surface the new pill
            }
        }
    }
    // Toggle the active VPN
    Process {
        id: htbVpnToggleProc
        command: ["bash", "-c", "~/.config/quickshell/htb-vpn-toggle.sh"]
        running: false
    }
    Process {
        id: htbHidePanel
        command: ["bash", "-c", "echo 0 > ~/.cache/cryo-htb-shown"]
        running: false
    }

    PanelWindow {
        id: htbPanel
        visible: root.htbShown
        anchors { top: true }
        margins.top: 44
        implicitWidth: 480
        implicitHeight: 700
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusiveZone: 0

        component InputCell : Rectangle {
            property string placeholder: ""
            property alias  value: tin.text
            implicitHeight: 26
            radius: 5
            color: "#303446"
            border.color: tin.activeFocus ? "#5eead4" : "#414559"
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 8
                visible: tin.text.length === 0
                text: parent.placeholder
                color: "#a5adce"
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 10
            }
            TextInput {
                id: tin
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                color: "#c6d0f5"
                selectByMouse: true
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 10
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "#bf292c3c"
            border.color: root.htbStatusColor()
            border.width: 2
            Behavior on border.color { ColorAnimation { duration: 250 } }

            opacity: root.htbAnimReady ? 1.0 : 0.0
            scale:   root.htbAnimReady ? 1.0 : 0.95
            transformOrigin: Item.Top
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: "HTB · " + (root.htbStatus.lab || root.htbActiveLab || "no lab") + " · " + root.htbStatus.state
                        color: root.htbStatusColor()
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Rectangle {
                        id: vpnBtn
                        property bool up:      root.htbStatus.state === "up"
                        property bool hovered: vpnBtnMa.containsMouse
                        property color accent: up ? "#f87171" : "#5eead4"
                        width: 48; height: 24; radius: 6
                        color: hovered ? Qt.darker(accent, 1.4) : "#414559"
                        border.color: accent
                        border.width: 1
                        scale: hovered ? 1.05 : 1.0
                        Behavior on color       { ColorAnimation  { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale       { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on border.color{ ColorAnimation  { duration: 180; easing.type: Easing.OutCubic } }
                        Text {
                            anchors.centerIn: parent
                            text: parent.up ? "VPN ↓" : "VPN ↑"
                            color: parent.hovered ? "#303446" : parent.accent
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 9
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            id: vpnBtnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: htbVpnToggleProc.running = true
                        }
                    }
                    Text {
                        id: closeXText
                        property bool hovered: closeXMa.containsMouse
                        text: "✕"
                        color: hovered ? "#f87171" : "#a5adce"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 14
                        font.bold: hovered
                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        MouseArea {
                            id: closeXMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: htbHidePanel.running = true
                        }
                    }
                }

                // VPN switcher
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "VPNs"
                            color: "#a5adce"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 10
                        }
                        Text {
                            text: "+ import…"
                            color: importMa.containsMouse ? "#5eead4" : "#818cf8"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 10
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MouseArea {
                                id: importMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: htbPickLab.running = true
                            }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: root.htbVpns
                            Rectangle {
                                id: pill
                                property var vpn: modelData
                                property bool hovered: pillMa.containsMouse
                                radius: 6
                                color: vpn.pinned ? "#5eead4"
                                     : (hovered ? "#385eead4" : "#414559")
                                border.color: vpn.pinned ? "#5eead4"
                                            : (hovered ? "#5eead4" : "#414559")
                                border.width: 1
                                implicitHeight: 26
                                implicitWidth: pillRow.implicitWidth + 14
                                Behavior on color        { ColorAnimation  { duration: 180; easing.type: Easing.OutCubic } }
                                Behavior on border.color { ColorAnimation  { duration: 180; easing.type: Easing.OutCubic } }

                                MouseArea {
                                    id: pillMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: pill.vpn.pinned ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    onClicked: {
                                        if (!pill.vpn.pinned) {
                                            root.htbRun("lab", "switch", pill.vpn.name)
                                        }
                                    }
                                }

                                RowLayout {
                                    id: pillRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    spacing: 4
                                    Text {
                                        text: (pill.vpn.tag ? pill.vpn.tag + " · " : "") + pill.vpn.name
                                        color: pill.vpn.pinned ? "#303446" : "#c6d0f5"
                                        font.family: "JetBrainsMono Nerd Font Mono"
                                        font.pixelSize: 10
                                        font.bold: pill.vpn.pinned
                                    }
                                    // Connected dot — small filled circle when this VPN is
                                    // the one currently tunnelled. Useful when pinned ≠ connected.
                                    Rectangle {
                                        width: 6; height: 6; radius: 3
                                        color: pill.vpn.pinned ? "#303446" : "#5eead4"
                                        visible: pill.vpn.connected
                                    }
                                    // × remove button, fades in on hover
                                    Rectangle {
                                        width: 14; height: 14; radius: 7
                                        color: "transparent"
                                        opacity: pill.hovered ? 1.0 : 0.0
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: "×"
                                            color: pill.vpn.pinned ? "#303446" : "#f87171"
                                            font.family: "JetBrainsMono Nerd Font Mono"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: pill.hovered
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.htbRun("lab", "remove", pill.vpn.name)
                                        }
                                    }
                                }
                            }
                        }

                        // When nothings imported
                        Text {
                            visible: root.htbVpns.length === 0
                            text: "(no VPNs imported — click + import… to add one)"
                            color: "#a5adce"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 10
                            font.italic: true
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.htbVpns.some(function(v){ return v.pinned })
                        Text {
                            text: "tag active:"
                            color: "#a5adce"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 10
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 24
                            radius: 4
                            color: "#303446"
                            border.color: tagInput.activeFocus ? "#5eead4" : "#414559"
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                visible: tagInput.text.length === 0 && !tagInput.activeFocus
                                text: "e.g. Academy / Labs / Exam — Enter to save"
                                color: "#a5adce"
                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 10
                                font.italic: true
                            }

                            TextInput {
                                id: tagInput
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter
                                color: "#c6d0f5"
                                selectByMouse: true
                                clip: true
                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 10
                                Connections {
                                    target: root
                                    function onHtbVpnsChanged() {
                                        for (let i = 0; i < root.htbVpns.length; i++) {
                                            if (root.htbVpns[i].pinned) {
                                                tagInput.text = root.htbVpns[i].tag || ""
                                                return
                                            }
                                        }
                                        tagInput.text = ""
                                    }
                                }
                                Keys.onReturnPressed: {
                                    for (let i = 0; i < root.htbVpns.length; i++) {
                                        if (root.htbVpns[i].pinned) {
                                            const t = text.trim()
                                            if (t) root.htbRun("lab", "tag", root.htbVpns[i].name, t)
                                            else   root.htbRun("lab", "untag", root.htbVpns[i].name)
                                            break
                                        }
                                    }
                                }
                                Keys.onEnterPressed: Keys.onReturnPressed(event)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: "YOUR IP"
                        color: "#a5adce"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 10
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.htbStatus.myip || "—"
                        color: "#5eead4"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 12
                        font.bold: true
                    }
                    Rectangle {
                        id: copyMyIpBtn
                        property bool hovered: copyMyIpMa.containsMouse
                        width: 54; height: 24; radius: 6
                        color: hovered ? "#385eead4" : "#414559"
                        border.color: "#5eead4"; border.width: 1
                        scale: hovered ? 1.04 : 1.0
                        Behavior on color { ColorAnimation  { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Text { anchors.centerIn: parent; text: "copy"; color: "#5eead4"
                               font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 9; font.bold: true }
                        MouseArea {
                            id: copyMyIpMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                htbCopy.text = root.htbStatus.myip || "";
                                htbCopy.running = true;
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#414559" }

                ColumnLayout {
                    visible: !root.htbTarget.name
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "no active target"
                        color: "#a5adce"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 11
                        font.italic: true
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        InputCell {
                            Layout.fillWidth: true
                            placeholder: "name (e.g. Lame)"
                            onValueChanged: root.htbSetName = value
                        }
                        InputCell {
                            Layout.fillWidth: true
                            placeholder: "ip"
                            onValueChanged: root.htbSetIp = value
                        }
                        InputCell {
                            Layout.preferredWidth: 80
                            placeholder: "os"
                            onValueChanged: root.htbSetOs = value
                        }
                    }
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 100; height: 26; radius: 4
                        color: "#414559"; border.color: "#5eead4"; border.width: 1
                        Text { anchors.centerIn: parent; text: "set target"; color: "#5eead4"
                               font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10 }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.htbSetName && root.htbSetIp) {
                                    root.htbRun("set", root.htbSetName, root.htbSetIp, root.htbSetOs);
                                    root.htbSetName = ""; root.htbSetIp = ""; root.htbSetOs = "";
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    visible: !!root.htbTarget.name
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            text: (root.htbTarget.name || "") + " · " + (root.htbTarget.ip || "") +
                                  (root.htbTarget.os ? " · " + root.htbTarget.os : "")
                            color: "#c6d0f5"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Rectangle {
                            id: copyTargetBtn
                            property bool hovered: copyTargetMa.containsMouse
                            width: 54; height: 24; radius: 6
                            color: hovered ? "#38818cf8" : "#414559"
                            border.color: "#818cf8"; border.width: 1
                            scale: hovered ? 1.04 : 1.0
                            Behavior on color { ColorAnimation  { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Text { anchors.centerIn: parent; text: "copy"; color: "#818cf8"
                                   font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 9; font.bold: true }
                            MouseArea {
                                id: copyTargetMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    htbCopy.text = root.htbTarget.ip || "";
                                    htbCopy.running = true;
                                }
                            }
                        }
                        Text {
                            text: root.htbStatus.ping + " ms"
                            color: "#a5adce"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 10
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            text: "status"
                            color: "#a5adce"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 10
                        }
                        Repeater {
                            model: ["enum", "foothold", "priv"]
                            Rectangle {
                                property bool active:  root.htbTarget.status === modelData
                                property bool hovered: pillMa.containsMouse
                                width: pillT.implicitWidth + 16
                                height: 22
                                radius: 11
                                color: active ? "#5eead4" : (hovered ? "#385eead4" : "#414559")
                                border.color: active ? "#5eead4" : (hovered ? "#5eead4" : "#414559")
                                scale: hovered && !active ? 1.05 : 1.0
                                Behavior on color        { ColorAnimation  { duration: 180; easing.type: Easing.OutCubic } }
                                Behavior on border.color { ColorAnimation  { duration: 180; easing.type: Easing.OutCubic } }
                                Behavior on scale        { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                Text {
                                    id: pillT
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: parent.active ? "#303446" : "#a5adce"
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 10
                                    Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }
                                MouseArea {
                                    id: pillMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.htbRun("status", modelData)
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Text {
                            text: "owned"
                            color: "#a5adce"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 10
                        }
                        Repeater {
                            model: [
                                { flag: "user", on: root.htbTarget.owned_user, color: "#818cf8" },
                                { flag: "root", on: root.htbTarget.owned_root, color: "#5eead4" }
                            ]
                            RowLayout {
                                spacing: 6
                                Rectangle {
                                    property bool hovered: ownedMa.containsMouse
                                    width: 16; height: 16; radius: 8
                                    color: modelData.on ? modelData.color : "transparent"
                                    border.color: modelData.color
                                    border.width: hovered ? 2 : 1
                                    scale: modelData.on ? 1.1 : (hovered ? 1.15 : 1.0)
                                    Behavior on color        { ColorAnimation  { duration: 200; easing.type: Easing.OutCubic } }
                                    Behavior on border.width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    Behavior on scale        { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                                    MouseArea {
                                        id: ownedMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.htbRun("owned", modelData.flag, modelData.on ? "off" : "on")
                                    }
                                }
                                Text {
                                    text: modelData.flag
                                    color: modelData.on ? modelData.color : "#a5adce"
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 10
                                    font.bold: modelData.on
                                    Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: "Credentials"
                                color: "#c6d0f5"
                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Rectangle {
                                width: 22; height: 22; radius: 4
                                color: "#414559"; border.color: "#5eead4"; border.width: 1
                                Text { anchors.centerIn: parent
                                       text: root.htbCredInputShown ? "−" : "+"
                                       color: "#5eead4"
                                       font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 12 }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.htbCredInputShown = !root.htbCredInputShown
                                }
                            }
                        }
                        RowLayout {
                            visible: root.htbCredInputShown
                            Layout.fillWidth: true
                            spacing: 4
                            InputCell { Layout.fillWidth: true; placeholder: "user"
                                        onValueChanged: root.htbCredUser = value }
                            InputCell { Layout.fillWidth: true; placeholder: "secret"
                                        onValueChanged: root.htbCredSecret = value }
                            InputCell { Layout.preferredWidth: 80; placeholder: "source"
                                        onValueChanged: root.htbCredSource = value }
                            Rectangle {
                                width: 40; height: 26; radius: 4
                                color: "#414559"; border.color: "#5eead4"; border.width: 1
                                Text { anchors.centerIn: parent; text: "add"; color: "#5eead4"
                                       font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10 }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.htbCredUser) {
                                            root.htbRun("cred", "add",
                                                root.htbCredUser + ":" + root.htbCredSecret,
                                                root.htbCredSource);
                                            root.htbCredUser = ""; root.htbCredSecret = ""; root.htbCredSource = "";
                                        }
                                    }
                                }
                            }
                        }
                        Repeater {
                            model: root.htbTarget.creds || []
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: "  " + (modelData.user || "") + " : " + (modelData.secret || "") +
                                          (modelData.source ? "  (" + modelData.source + ")" : "")
                                    color: "#c6d0f5"
                                    elide: Text.ElideRight
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 10
                                }
                                Rectangle {
                                    width: 22; height: 18; radius: 3
                                    color: "transparent"; border.color: "#f87171"; border.width: 1
                                    Text { anchors.centerIn: parent; text: "×"; color: "#f87171"
                                           font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10 }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.htbRun("cred", "del", String(index))
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: "Ports"
                                color: "#c6d0f5"
                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Rectangle {
                                width: 22; height: 22; radius: 4
                                color: "#414559"; border.color: "#5eead4"; border.width: 1
                                Text { anchors.centerIn: parent
                                       text: root.htbPortInputShown ? "−" : "+"
                                       color: "#5eead4"
                                       font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 12 }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.htbPortInputShown = !root.htbPortInputShown
                                }
                            }
                        }
                        RowLayout {
                            visible: root.htbPortInputShown
                            Layout.fillWidth: true
                            spacing: 4
                            InputCell { Layout.preferredWidth: 60; placeholder: "port"
                                        onValueChanged: root.htbPortNum = value }
                            InputCell { Layout.preferredWidth: 80; placeholder: "svc"
                                        onValueChanged: root.htbPortSvc = value }
                            InputCell { Layout.fillWidth: true; placeholder: "version (optional)"
                                        onValueChanged: root.htbPortVer = value }
                            Rectangle {
                                width: 40; height: 26; radius: 4
                                color: "#414559"; border.color: "#5eead4"; border.width: 1
                                Text { anchors.centerIn: parent; text: "add"; color: "#5eead4"
                                       font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10 }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.htbPortNum && root.htbPortSvc) {
                                            root.htbRun("port", "add",
                                                root.htbPortNum + "/" + root.htbPortSvc,
                                                root.htbPortVer);
                                            root.htbPortNum = ""; root.htbPortSvc = ""; root.htbPortVer = "";
                                        }
                                    }
                                }
                            }
                        }
                        Repeater {
                            model: root.htbTarget.ports || []
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: "  " + (modelData.port || "") + "/" + (modelData.service || "") +
                                          (modelData.version ? "  " + modelData.version : "")
                                    color: "#c6d0f5"
                                    elide: Text.ElideRight
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    font.pixelSize: 10
                                }
                                Rectangle {
                                    width: 22; height: 18; radius: 3
                                    color: "transparent"; border.color: "#f87171"; border.width: 1
                                    Text { anchors.centerIn: parent; text: "×"; color: "#f87171"
                                           font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10 }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.htbRun("port", "del", String(modelData.port))
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }  // push the bottom actions down

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle {
                            id: archiveBtn
                            property bool hovered: archiveMa.containsMouse
                            Layout.fillWidth: true; height: 30; radius: 7
                            color: hovered ? "#385eead4" : "#414559"   // teal tint on hover
                            border.color: "#5eead4"; border.width: 1
                            scale: hovered ? 1.02 : 1.0
                            Behavior on color { ColorAnimation  { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Text { anchors.centerIn: parent; text: "Archive → writeup"; color: "#5eead4"
                                   font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10; font.bold: true }
                            MouseArea {
                                id: archiveMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.htbRun("archive")
                            }
                        }
                        Rectangle {
                            id: resetBtn
                            property bool hovered: resetMa.containsMouse
                            Layout.fillWidth: true; height: 30; radius: 7
                            color: hovered ? "#38f87171" : "#414559"   // red tint on hover
                            border.color: "#f87171"; border.width: 1
                            scale: hovered ? 1.02 : 1.0
                            Behavior on color { ColorAnimation  { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Text { anchors.centerIn: parent; text: "Reset target"; color: "#f87171"
                                   font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 10; font.bold: true }
                            MouseArea {
                                id: resetMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.htbRun("reset")
                            }
                        }
                    }
                }
            }
        }
    }
}
