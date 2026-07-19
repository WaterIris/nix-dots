import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// ~/.config/quickshell/audiocontrol.qml
// Simple volume popup — master volume slider, mute toggle, output device
// switcher. Same Tokyo Night theme + toggle-guard pattern as powermenu.qml.
//
// Run standalone with: qs -p ~/.config/quickshell/audiocontrol.qml
// Bind it in hyprland.lua, e.g.:
//   hl.bind("SUPER + A", hl.dsp.exec_cmd("qs -p ~/.config/quickshell/audiocontrol.qml"))
//
// Click outside, or press Escape, to dismiss.

PanelWindow {
    id: root

    // ===== Tokyo Night palette (matches waybar / powermenu) =====
    property color cBackground:  "#1a1b26"
    property color cSurface:     "#16161e"
    property color cSurfaceAlt:  "#292e42"
    property color cForeground:  "#c0caf5"
    property color cForegroundDim: "#a9b1d6"
    property color cSubtle:      "#565f89"
    property color cBlue:        "#7aa2f7"
    property color cBlueSurface: "#1f2335"
    property color cCyan:        "#7dcfff"
    property color cRed:         "#f7768e"

    property string fontFamily: "JetBrainsMono Nerd Font Propo"

    visible: false

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell:audiocontrol"

    // ===== Toggle guard — same pattern as powermenu.qml =====
    Process {
        id: instanceGuard
        running: true
        command: ["sh", "-c",
            "others=$(pgrep -f 'audiocontrol\\.qml' | grep -v \"^$PPID$\"); " +
            "if [ -n \"$others\" ]; then kill $others 2>/dev/null; echo CLOSED; else echo OK; fi"]
        stdout: SplitParser {
            onRead: data => {
                const result = data.trim()
                if (result === "OK") {
                    root.visible = true
                    card.opacity = 1
                    card.x = 0
                } else if (result === "CLOSED") {
                    Qt.quit()
                }
            }
        }
    }

    // ===== Reactive PipeWire state =====
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool sourceMuted: source?.audio?.muted ?? false

    // Hardware output devices (sinks that aren't application streams).
    readonly property var outputs: {
        const list = []
        for (const n of Pipewire.nodes.values) {
            if (n.isSink && !n.isStream && n.audio) list.push(n)
        }
        return list
    }

    // Hardware input devices (sources / microphones).
    readonly property var inputs: {
        const list = []
        for (const n of Pipewire.nodes.values) {
            if (!n.isSink && !n.isStream && n.audio) list.push(n)
        }
        return list
    }

    PwObjectTracker {
        objects: [root.sink, root.source, ...root.outputs, ...root.inputs]
    }

    function setVolume(v) {
        if (!sink?.ready || !sink?.audio) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1, v))
    }
    function toggleMute() {
        if (sink?.ready && sink?.audio) sink.audio.muted = !sink.audio.muted
    }
    function toggleMicMute() {
        if (source?.ready && source?.audio) source.audio.muted = !source.audio.muted
    }
    function setMicVolume(v) {
        if (!source?.ready || !source?.audio) return
        source.audio.muted = false
        source.audio.volume = Math.max(0, Math.min(1, v))
    }
    function selectOutput(node) {
        Pipewire.preferredDefaultAudioSink = node
    }
    function selectInput(node) {
        Pipewire.preferredDefaultAudioSource = node
    }

    // Dim background, click to dismiss
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Component.onCompleted: opacity = 0.25

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

    // ===== Card =====
    Rectangle {
        id: card
        width: 300
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 48
        anchors.rightMargin: 20
        height: content.implicitHeight + 32
        radius: 16
        color: root.cBackground
        border.color: root.cSurfaceAlt
        border.width: 2

        opacity: 0
        x: 40
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea {
            // Swallow clicks on the card itself so they don't fall through
            // to the background dismiss-area.
            anchors.fill: parent
        }

        Column {
            id: content
            anchors.centerIn: parent
            width: parent.width - 32
            spacing: 16

            // ----- Header -----
            Item {
                width: parent.width
                height: 24

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        text: root.muted ? "󰖁" : "󰕾"
                        font.family: root.fontFamily
                        font.pixelSize: 20
                        color: root.muted ? root.cRed : root.cCyan
                    }
                    Text {
                        text: "Volume"
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        color: root.cForeground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.volume * 100) + "%"
                    font.family: root.fontFamily
                    font.pixelSize: 15
                    color: root.cForegroundDim
                    horizontalAlignment: Text.AlignRight
                }
            }

            // ----- Slider row -----
            Row {
                width: parent.width
                spacing: 12

                Rectangle {
                    id: muteBtn
                    width: 34; height: 34
                    radius: 10
                    color: root.muted ? "#2b1b26" : root.cSurfaceAlt
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: root.muted ? "󰖁" : (root.volume < 0.01 ? "󰕿" : (root.volume < 0.5 ? "󰖀" : "󰕾"))
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        color: root.muted ? root.cRed : root.cForeground
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.toggleMute()
                    }
                }

                Rectangle {
                    id: track
                    width: parent.width - muteBtn.width - parent.spacing
                    height: 8
                    radius: 4
                    color: root.cSurfaceAlt
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: track.width * root.volume
                        height: parent.height
                        radius: 4
                        color: root.muted ? root.cSubtle : root.cBlue
                        Behavior on width { NumberAnimation { duration: 80 } }
                    }

                    Rectangle {
                        // Handle
                        width: 14; height: 14
                        radius: 7
                        color: root.cForeground
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(track.width - width, track.width * root.volume - width / 2))
                        Behavior on x { NumberAnimation { duration: 80 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        onPressed: mouse => root.setVolume(mouse.x / track.width)
                        onPositionChanged: mouse => { if (pressed) root.setVolume(mouse.x / track.width) }
                    }
                }
            }


            // ----- Output device list -----
            Text {
                text: "OUTPUT DEVICE"
                visible: root.outputs.length > 0
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: root.cSubtle
            }

            Column {
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.outputs

                    Rectangle {
                        id: row
                        required property var modelData
                        property bool isDefault: modelData === root.sink

                        width: content.width
                        height: 40
                        radius: 10
                        color: isDefault ? root.cBlueSurface : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.isDefault ? "\uF058" : "\uF10C"
                                font.family: root.fontFamily
                                font.pixelSize: 14
                                color: row.isDefault ? root.cBlue : root.cSubtle
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 30
                                text: row.modelData.description || row.modelData.name
                                elide: Text.ElideRight
                                font.family: root.fontFamily
                                font.pixelSize: 13
                                color: row.isDefault ? root.cForeground : root.cForegroundDim
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.selectOutput(row.modelData)
                        }
                    }
                }
            }

            // ----- Divider -----
            Rectangle {
                width: parent.width
                height: 1
                color: root.cSurfaceAlt
                visible: root.inputs.length > 0
            }

            // ----- Microphone header -----
            Item {
                id: micHeader
                width: parent.width
                height: 24
                visible: root.inputs.length > 0

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        text: root.sourceMuted ? "󰍭" : "󰍬"
                        font.family: root.fontFamily
                        font.pixelSize: 20
                        color: root.sourceMuted ? root.cRed : root.cCyan
                    }
                    Text {
                        text: "Microphone"
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        color: root.cForeground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.micVolume * 100) + "%"
                    font.family: root.fontFamily
                    font.pixelSize: 15
                    color: root.cForegroundDim
                    horizontalAlignment: Text.AlignRight
                }
            }


            // ----- Mic slider row -----
            Row {
                width: parent.width
                spacing: 12
                visible: root.inputs.length > 0

                Rectangle {
                    id: micMuteBtn
                    width: 34; height: 34
                    radius: 10
                    color: root.sourceMuted ? "#2b1b26" : root.cSurfaceAlt
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: root.sourceMuted ? "󰍭" : "󰍬"
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        color: root.sourceMuted ? root.cRed : root.cForeground
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.toggleMicMute()
                    }
                }

                Rectangle {
                    id: micTrack
                    width: parent.width - micMuteBtn.width - parent.spacing
                    height: 8
                    radius: 4
                    color: root.cSurfaceAlt
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: micTrack.width * root.micVolume
                        height: parent.height
                        radius: 4
                        color: root.sourceMuted ? root.cSubtle : root.cBlue
                        Behavior on width { NumberAnimation { duration: 80 } }
                    }

                    Rectangle {
                        // Handle
                        width: 14; height: 14
                        radius: 7
                        color: root.cForeground
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(micTrack.width - width, micTrack.width * root.micVolume - width / 2))
                        Behavior on x { NumberAnimation { duration: 80 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        onPressed: mouse => root.setMicVolume(mouse.x / micTrack.width)
                        onPositionChanged: mouse => { if (pressed) root.setMicVolume(mouse.x / micTrack.width) }
                    }
                }
            }

            // ----- Input device list -----
            Text {
                text: "INPUT DEVICE"
                visible: root.inputs.length > 0
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: root.cSubtle
            }

            Column {
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.inputs

                    Rectangle {
                        id: inRow
                        required property var modelData
                        property bool isDefault: modelData === root.source

                        width: content.width
                        height: 40
                        radius: 10
                        color: isDefault ? root.cBlueSurface : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: inRow.isDefault ? "\uF058" : "\uF10C"
                                font.family: root.fontFamily
                                font.pixelSize: 14
                                color: inRow.isDefault ? root.cBlue : root.cSubtle
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 30
                                text: inRow.modelData.description || inRow.modelData.name
                                elide: Text.ElideRight
                                font.family: root.fontFamily
                                font.pixelSize: 13
                                color: inRow.isDefault ? root.cForeground : root.cForegroundDim
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.selectInput(inRow.modelData)
                        }
                    }
                }
            }
        }
    }
}
