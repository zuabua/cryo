// Cryo keybinds cheatsheet drawer
// takes a .md and renders it.
// uses KEYBINDS.md to generate a keybind
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Item {
    id: root
    readonly property string home: Quickshell.env("HOME")

    property bool shown: false
    property bool animReady: false
    property string filter: ""
    property var sections: []

    onShownChanged: {
        if (shown) {
            animReady = false
            Qt.callLater(function(){ root.animReady = true })
        } else {
            animReady = false
            filter = ""
        }
    }

    // Parse the markdown into [{title, rows:[{key, action}]}, …].
    // We only consume `## ` headers + pipe-tables. Header row and
    // separator row are skipped. Extra columns are joined with " · ".
    function parseKeybinds(text) {
        const lines = (text || "").split("\n")
        const sections = []
        let cur = null
        let inTable = false
        let headerSeen = false
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (line.indexOf("## ") === 0) {
                cur = { title: line.substring(3).trim(), rows: [] }
                sections.push(cur)
                inTable = false
                headerSeen = false
                continue
            }
            if (line.length > 0 && line.charAt(0) === "|") {
                if (/^\|[\s\-:|]+\|\s*$/.test(line)) {
                    inTable = true
                    continue
                }
                const trimmed = line.replace(/^\|/, "").replace(/\|\s*$/, "")
                const cells = trimmed.split("|").map(function(c){ return c.trim() })
                if (!headerSeen) { headerSeen = true; continue }
                if (cur && cells.length >= 2) {
                    // Peel markdown code-span delimiters. Double-backtick
                    // first so `` `Super+` `` keeps its inner backtick,
                    // then single-backtick for the common `Foo` form.
                    const peel = function(s) {
                        return s.replace(/``\s*(.+?)\s*``/g, "$1")
                                .replace(/`([^`]*)`/g, "$1")
                                .trim()
                    }
                    const key = peel(cells[0])
                    const action = peel(cells.slice(1).join("  ·  "))
                    cur.rows.push({ key: key, action: action })
                }
            } else if (inTable) {
                inTable = false
                headerSeen = false
            }
        }
        return sections.filter(function(s){ return s.rows.length > 0 })
    }

    function filteredSections() {
        const q = (filter || "").toLowerCase()
        if (!q) return sections
        const out = []
        for (let i = 0; i < sections.length; i++) {
            const s = sections[i]
            if (s.title.toLowerCase().indexOf(q) !== -1) {
                out.push({ title: s.title, rows: s.rows })
                continue
            }
            const matched = s.rows.filter(function(r){
                return r.key.toLowerCase().indexOf(q) !== -1
                    || r.action.toLowerCase().indexOf(q) !== -1
            })
            if (matched.length > 0) out.push({ title: s.title, rows: matched })
        }
        return out
    }

    FileView {
        id: shownFile
        path: root.home + "/.cache/cryo-keybinds-shown"
        watchChanges: true
        onLoaded:      root.shown = (shownFile.text().trim() === "1")
        onFileChanged: { shownFile.reload(); root.shown = (shownFile.text().trim() === "1") }
    }
    FileView {
        id: dataFile
        path: root.home + "/.cache/cryo-keybinds.md"
        watchChanges: true
        onLoaded:      root.sections = root.parseKeybinds(dataFile.text())
        onFileChanged: { dataFile.reload(); root.sections = root.parseKeybinds(dataFile.text()) }
    }
    Process {
        id: hideProc
        command: ["bash", "-c", "echo 0 > ~/.cache/cryo-keybinds-shown"]
        running: false
    }

    PanelWindow {
        id: panel
        visible: root.shown
        anchors { top: true }
        margins.top: 60
        implicitWidth: 760
        implicitHeight: 680
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        // Exclusive — the filter input wants every keystroke including
        // Esc, and we don't want typing to leak to background windows.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
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

            Connections {
                target: root
                function onAnimReadyChanged() {
                    if (root.animReady) filterInput.forceActiveFocus()
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Header: title + filter + close
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: "  Keybinds"
                        color: "#c6d0f5"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 6
                        color: "#303446"
                        border.color: filterInput.activeFocus ? "#5eead4" : "#414559"
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            visible: filterInput.text.length === 0
                            text: "filter…  (super, htb, screenshot, tmux, …)"
                            color: "#a5adce"
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 11
                            font.italic: true
                        }
                        TextInput {
                            id: filterInput
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#c6d0f5"
                            selectByMouse: true
                            clip: true
                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 11
                            cursorVisible: activeFocus
                            onTextChanged: root.filter = text
                            Keys.onEscapePressed: hideProc.running = true
                        }
                    }
                    Text {
                        text: "✕"
                        color: closeMa.containsMouse ? "#f87171" : "#a5adce"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 14
                        Behavior on color { ColorAnimation { duration: 150 } }
                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: hideProc.running = true
                        }
                    }
                }

                // Scrollable list of sections
                ListView {
                    id: sectionList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 10
                    model: root.filteredSections()
                    delegate: Rectangle {
                        width: ListView.view ? ListView.view.width : 0
                        radius: 8
                        color: "#33303446"
                        border.color: "#414559"
                        border.width: 1
                        implicitHeight: sectionCol.implicitHeight + 16

                        ColumnLayout {
                            id: sectionCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            spacing: 4

                            Text {
                                text: modelData.title
                                color: "#5eead4"
                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 11
                                font.bold: true
                                Layout.bottomMargin: 4
                            }
                            Repeater {
                                model: modelData.rows
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 14
                                    Text {
                                        Layout.preferredWidth: 240
                                        text: modelData.key
                                        color: "#818cf8"
                                        elide: Text.ElideRight
                                        font.family: "JetBrainsMono Nerd Font Mono"
                                        font.pixelSize: 10
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.action
                                        color: "#c6d0f5"
                                        wrapMode: Text.WordWrap
                                        font.family: "JetBrainsMono Nerd Font Mono"
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }
                    }

                    // Empty-state hint when filter matches nothing
                    Text {
                        anchors.centerIn: parent
                        visible: sectionList.count === 0
                        text: root.sections.length === 0
                              ? "(no keybinds loaded — press Super+F1 once to seed the cache)"
                              : "no matches for “" + root.filter + "”"
                        color: "#a5adce"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 11
                        font.italic: true
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignRight
                    text: "esc close · type to filter"
                    color: "#a5adce"
                    opacity: 0.6
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 9
                }
            }
        }
    }
}
