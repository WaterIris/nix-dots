import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

// Keybinding cheatsheet. Reads the live binds from `hyprctl binds -j` and
// shows every bind that has a description, grouped by the "Group: Action"
// prefix of that description (see hypr/hyprConf/keybinds.lua).
PanelWindow {
    id: root

    // ===== Tokyo Night palette =====
    property color cBackground:  "#1a1b26"
    property color cSurface:     "#16161e"
    property color cSurfaceAlt:  "#292e42"
    property color cForeground:  "#c0caf5"
    property color cSubtle:      "#565f89"
    property color cBlue:        "#7aa2f7"
    property color cMagenta:     "#bb9af7"

    property string fontFamily: "JetBrainsMono Nerd Font Propo"

    // Start hidden — only revealed once the single-instance guard (below)
    // confirms no other instance is already running.
    visible: false

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell:keybinds"

    // ===== Toggle guard =====
    // Same as powermenu.qml: a second launch closes the running instance.
    // The pattern matches only quickshell itself, so an editor or shell
    // that has this file name on its command line is not killed.
    Process {
        id: instanceGuard
        running: true
        command: ["sh", "-c",
            "others=$(pgrep -f 'quickshell -p .*keybinds\\.qml' | grep -v \"^$PPID$\"); " +
            "if [ -n \"$others\" ]; then kill $others 2>/dev/null; echo CLOSED; else echo OK; fi"]
        stdout: SplitParser {
            onRead: data => {
                const result = data.trim()
                if (result === "OK") {
                    root.visible = true
                    panel.opacity = 1
                    panel.scale = 1
                } else if (result === "CLOSED") {
                    Qt.quit()
                }
            }
        }
    }

    // ===== Bind loading =====
    property var groups: []

    Process {
        id: bindsProc
        running: true
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.groups = root.buildGroups(text)
        }
    }

    // Hyprland modmask bits, in the order they are displayed.
    readonly property var modNames: [
        { bit: 64, name: "SUPER" },
        { bit: 4,  name: "CTRL" },
        { bit: 8,  name: "ALT" },
        { bit: 1,  name: "SHIFT" }
    ]

    readonly property var keyNames: {
        "mouse:272": "LMB",
        "mouse:273": "RMB",
        "mouse_down": "Scroll down",
        "mouse_up": "Scroll up",
        "Return": "Enter",
        "Escape": "Esc",
        "slash": "/",
        "semicolon": ";",
        "apostrophe": "'",
        "left": "←",
        "right": "→",
        "up": "↑",
        "down": "↓"
    }

    function keyLabel(key) {
        if (keyNames[key] !== undefined) return keyNames[key]
        if (key.startsWith("XF86")) return key.slice(4)
        return key.length === 1 ? key.toUpperCase() : key
    }

    // Returns the parts of a bind's key combo, e.g. ["SUPER", "SHIFT", "1"].
    function comboParts(bind) {
        const parts = modNames.filter(m => (bind.modmask & m.bit) !== 0).map(m => m.name)
        parts.push(keyLabel(bind.key))
        return parts
    }

    // Turns hyprctl JSON into [{ name, binds: [{ combos, action }] }], keeping
    // config order. Binds with the same description are merged into one row.
    function buildGroups(json) {
        let binds = []
        try {
            binds = JSON.parse(json)
        } catch (e) {
            console.warn("keybinds: cannot parse hyprctl output:", e)
            return []
        }

        const result = []
        const byName = {}
        for (const bind of binds) {
            if (!bind.has_description || !bind.description) continue

            const sep = bind.description.indexOf(":")
            const groupName = sep > 0 ? bind.description.slice(0, sep).trim() : "Other"
            const action = sep > 0 ? bind.description.slice(sep + 1).trim() : bind.description

            if (byName[groupName] === undefined) {
                byName[groupName] = { name: groupName, binds: [] }
                result.push(byName[groupName])
            }
            const group = byName[groupName]
            const existing = group.binds.find(b => b.action === action)
            if (existing) existing.combos.push(comboParts(bind))
            else group.binds.push({ action: action, combos: [comboParts(bind)] })
        }
        return result
    }

    // ===== Dim background =====
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Component.onCompleted: opacity = 0.35

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Qt.quit()
    }

    // ===== Cheatsheet panel =====
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(content.implicitWidth + 64, parent.width - 64)
        height: Math.min(content.implicitHeight + 64, parent.height - 64)
        radius: 6
        color: root.cBackground
        border.width: 1
        border.color: "#101014"
        clip: true

        opacity: 0
        scale: 0.96
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        // Swallow clicks so they don't reach the dismiss area behind.
        MouseArea { anchors.fill: parent }

        Flickable {
            anchors.fill: parent
            anchors.margins: 32
            contentWidth: width
            contentHeight: content.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: content
                spacing: 20

                Text {
                    text: "Keybindings"
                    color: root.cForeground
                    font.family: root.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }

                Flow {
                    id: groupFlow
                    // Lay groups out in as many 360px columns as fit on screen.
                    width: Math.min(root.groups.length, Math.max(1, Math.floor((root.width - 128 + spacing) / (360 + spacing)))) * (360 + spacing) - spacing
                    spacing: 28

                    Repeater {
                        model: root.groups

                        Column {
                            id: groupColumn
                            property var group: modelData
                            width: 360
                            spacing: 6

                            Text {
                                text: groupColumn.group.name
                                color: root.cMagenta
                                font.family: root.fontFamily
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                bottomPadding: 4
                            }

                            Repeater {
                                model: groupColumn.group.binds

                                Item {
                                    id: bindRow
                                    property var bind: modelData
                                    width: groupColumn.width
                                    height: Math.max(combos.implicitHeight, actionText.implicitHeight)

                                    Text {
                                        id: actionText
                                        anchors.left: parent.left
                                        anchors.right: combos.left
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: bindRow.bind.action
                                        color: root.cForeground
                                        elide: Text.ElideRight
                                        font.family: root.fontFamily
                                        font.pixelSize: 13
                                    }

                                    Row {
                                        id: combos
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 6

                                        Repeater {
                                            model: bindRow.bind.combos

                                            Row {
                                                property var parts: modelData
                                                spacing: 3

                                                Repeater {
                                                    model: parent.parts

                                                    Rectangle {
                                                        width: keyText.implicitWidth + 12
                                                        height: keyText.implicitHeight + 6
                                                        radius: 4
                                                        color: root.cSurfaceAlt

                                                        Text {
                                                            id: keyText
                                                            anchors.centerIn: parent
                                                            text: modelData
                                                            color: root.cBlue
                                                            font.family: root.fontFamily
                                                            font.pixelSize: 11
                                                            font.weight: Font.DemiBold
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    text: "Esc or click outside to close"
                    color: root.cSubtle
                    font.family: root.fontFamily
                    font.pixelSize: 11
                }
            }
        }
    }
}
