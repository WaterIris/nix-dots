import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

PanelWindow {
    id: root

    // ===== Tokyo Night palette =====
    property color cBackground:  "#1a1b26"
    property color cSurface:     "#16161e"
    property color cSurfaceAlt:  "#292e42"
    property color cForeground:  "#c0caf5"
    property color cSubtle:      "#565f89"
    property color cRed:         "#f7768e"
    property color cRedSurface:  "#2b1b26"

    property string fontFamily: "JetBrainsMono Nerd Font Propo"

    // Start hidden — only revealed once the single-instance guard (below)
    // confirms no other powermenu instance is already running.
    visible: false

    // Full-screen transparent surface so a click anywhere outside the
    // cards dismisses the menu; the bar itself only occupies the bottom.
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell:powermenu"

    // ===== Toggle guard =====
    // If another powermenu instance is already running (found via its
    // window PID's parent, $PPID, excluded from the match), kill it and
    // exit without showing — this makes the keybind act as an open/close
    // toggle rather than just refusing to stack duplicates.
    Process {
        id: instanceGuard
        running: true
        command: ["sh", "-c",
            "others=$(pgrep -f 'powermenu\\.qml' | grep -v \"^$PPID$\"); " +
            "if [ -n \"$others\" ]; then kill $others 2>/dev/null; echo CLOSED; else echo OK; fi"]
        stdout: SplitParser {
            onRead: data => {
                const result = data.trim()
                if (result === "OK") {
                    root.visible = true
                    bar.opacity = 1
                    bar.y = 0
                } else if (result === "CLOSED") {
                    Qt.quit()
                }
            }
        }
    }

    // Dim background
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
        Keys.onLeftPressed:  root.moveSelection(-1)
        Keys.onRightPressed: root.moveSelection(1)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_H) root.moveSelection(-1)
            else if (event.key === Qt.Key_L) root.moveSelection(1)
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.run(root.options[root.selected].cmd)
            else return
            event.accepted = true
        }
    }

    // One-shot power action runner
    Process {
        id: actionProc
        onRunningChanged: if (!running) Qt.quit()
    }
    function run(cmd) {
        actionProc.command = ["sh", "-c", cmd]
        actionProc.running = true
    }

    property int selected: 0
    function moveSelection(delta) {
        selected = (selected + delta + options.length) % options.length
    }

    // ===== Options =====
    property var options: [
        { icon: "\uF023", label: "Lock",     bg: cSurfaceAlt, fg: cForeground, cmd: "hyprlock" },
        { icon: "\uF186", label: "Suspend",  bg: cSurfaceAlt, fg: cForeground, cmd: "systemctl suspend" },
        { icon: "\uF0A0", label: "Hibernate", bg: cSurfaceAlt, fg: cForeground, cmd: "systemctl hibernate" },
        { icon: "\uF08B", label: "Logout",   bg: cSurfaceAlt, fg: cForeground, cmd: "hyprctl dispatch 'hl.dsp.exit()'" },
        { icon: "\uF021", label: "Reboot",   bg: cSurfaceAlt, fg: cForeground, cmd: "systemctl reboot" },
        { icon: "\uF011", label: "Shutdown", bg: cRedSurface, fg: cRed,        cmd: "systemctl poweroff" }
    ]

    // ===== Bottom-anchored, flow-in animated bar =====
    Row {
        id: bar
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 48
        spacing: 18

        opacity: 0
        y: 40
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        Repeater {
            model: root.options

            Rectangle {
                id: card
                property var opt: modelData
                property int idx: index
                property bool hovered: hoverArea.containsMouse
                property bool isSelected: idx === root.selected || hovered

                width: 110
                height: 110
                radius: 16
                color: opt.bg
                scale: isSelected ? 1.06 : 1.0
                border.width: isSelected ? 2 : 0
                border.color: opt.fg

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on border.width { NumberAnimation { duration: 120 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: card.opt.icon
                        color: card.opt.fg
                        font.family: root.fontFamily
                        font.pixelSize: 40
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: card.opt.label
                        color: card.opt.fg
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selected = card.idx
                    onClicked: root.run(card.opt.cmd)
                }
            }
        }
    }
}
