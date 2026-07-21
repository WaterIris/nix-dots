import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Bluetooth
import QtQuick

// ~/.config/quickshell/bluetoothcontrol.qml
// Simple Bluetooth popup — power toggle, scan for devices, tap to
// connect/disconnect. Same Tokyo Night theme + toggle-guard pattern as
// powermenu.qml / audiocontrol.qml.
//
// Run standalone with: qs -p ~/.config/quickshell/bluetoothcontrol.qml
// Bind it in hyprland.lua, e.g.:
//   hl.bind("SUPER + B", hl.dsp.exec_cmd("qs -p ~/.config/quickshell/bluetoothcontrol.qml"))
//
// Click outside, or press Escape, to dismiss.

PanelWindow {
    id: root

    // ===== Tokyo Night palette (matches waybar / powermenu / audiocontrol) =====
    property color cBackground:  "#1a1b26"
    property color cSurfaceAlt:  "#292e42"
    property color cForeground:  "#c0caf5"
    property color cForegroundDim: "#a9b1d6"
    property color cSubtle:      "#565f89"
    property color cBlue:        "#7aa2f7"
    property color cBlueSurface: "#1f2335"
    property color cCyan:        "#7dcfff"
    property color cRed:         "#f7768e"
    property color cGreen:       "#9ece6a"

    property string fontFamily: "JetBrainsMono Nerd Font Propo"

    visible: false

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell:bluetoothcontrol"

    // ===== Toggle guard — same pattern as powermenu.qml / audiocontrol.qml =====
    Process {
        id: instanceGuard
        running: true
        command: ["sh", "-c",
            "others=$(pgrep -f 'bluetoothcontrol\\.qml' | grep -v \"^$PPID$\"); " +
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

    // ===== Reactive Bluetooth state =====
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: adapter?.enabled ?? false

    // Scanning uses the adapter's native discovering property, which
    // reflects BlueZ's actual live discovery state over D-Bus. (An earlier
    // version shelled out to `bluetoothctl scan on`, but that's a one-shot
    // command when run as CLI args — it starts discovery then exits
    // immediately, which made the "scanning" state flicker and never
    // actually track reality.)
    readonly property bool scanning: adapter?.discovering ?? false

    readonly property var pairedDevices: {
        const list = []
        if (!adapter) return list
        for (const d of adapter.devices.values) if (d.paired || d.connected) list.push(d)
        // Connected first, then alphabetical.
        list.sort((a, b) => {
            const r = (b.connected ? 1 : 0) - (a.connected ? 1 : 0)
            return r !== 0 ? r : a.name.localeCompare(b.name)
        })
        return list
    }
    readonly property var newDevices: {
        const list = []
        if (!adapter) return list
        for (const d of adapter.devices.values) if (!d.paired && !d.connected) list.push(d)
        list.sort((a, b) => a.name.localeCompare(b.name))
        return list
    }

    function toggleAdapter() {
        if (adapter) adapter.enabled = !adapter.enabled
    }
    function toggleScan() {
        if (adapter) adapter.discovering = !adapter.discovering
    }
    function toggleConnect(device) {
        device.connected = !device.connected
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

            // ----- Header: icon, title, power toggle -----
            Item {
                width: parent.width
                height: 28

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        text: root.btEnabled ? "\uF294" : "\uF293"
                        font.family: root.fontFamily
                        font.pixelSize: 20
                        color: root.btEnabled ? root.cCyan : root.cSubtle
                    }
                    Text {
                        text: "Bluetooth"
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        color: root.cForeground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // ----- Power toggle switch -----
                Rectangle {
                    id: powerSwitch
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 24
                    radius: 12
                    color: root.btEnabled ? root.cBlue : root.cSurfaceAlt
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        width: 18; height: 18
                        radius: 9
                        color: root.cBackground
                        anchors.verticalCenter: parent.verticalCenter
                        x: root.btEnabled ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.toggleAdapter()
                    }
                }
            }

            // ----- Scan row -----
            Rectangle {
                width: parent.width
                height: 36
                radius: 10
                visible: root.btEnabled
                color: root.scanning ? root.cBlueSurface : root.cSurfaceAlt
                opacity: root.btEnabled ? 1 : 0.4

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "\uF021"
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        color: root.scanning ? root.cBlue : root.cForegroundDim

                        RotationAnimation on rotation {
                            running: root.scanning
                            loops: Animation.Infinite
                            from: 0; to: 360
                            duration: 1200
                        }
                    }
                    Text {
                        text: root.scanning ? "Scanning..." : "Scan for devices"
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        color: root.scanning ? root.cBlue : root.cForegroundDim
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.btEnabled
                    onClicked: root.toggleScan()
                }
            }

            // ----- Divider (scan row -> device lists) -----
            Rectangle {
                width: parent.width
                height: 1
                color: root.cSurfaceAlt
                visible: root.btEnabled && (root.pairedDevices.length > 0 || root.newDevices.length > 0)
            }

            // ----- Device area: capped to 7 visible rows, scrolls beyond that -----
            Column {
                width: parent.width
                visible: root.btEnabled
                spacing: 4

                // Up indicator — only shown once scrolled down at all.
                Rectangle {
                    width: parent.width
                    height: 16
                    radius: 6
                    color: root.cSurfaceAlt
                    opacity: 0.85
                    visible: deviceScroll.contentY > 2

                    Text {
                        anchors.centerIn: parent
                        text: "\uF077"
                        font.family: root.fontFamily
                        font.pixelSize: 9
                        color: root.cSubtle
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: deviceScroll.contentY = Math.max(0, deviceScroll.contentY - 88)
                    }
                }

                Flickable {
                    id: deviceScroll
                    width: parent.width
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentWidth: width
                    contentHeight: deviceListColumn.implicitHeight
                    // 7 rows (44px each) + the gaps between them (spacing below).
                    height: Math.min(deviceListColumn.implicitHeight, 7 * 44 + 6 * 8)

                    Column {
                        id: deviceListColumn
                        width: parent.width
                        spacing: 8

                        // ----- Empty state -----
                        Text {
                            width: parent.width
                            visible: root.pairedDevices.length === 0 && root.newDevices.length === 0
                            text: root.scanning ? "Looking for devices..." : "No devices found yet — try scanning."
                            wrapMode: Text.WordWrap
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            color: root.cSubtle
                        }

                        // ----- Paired devices -----
                        Text {
                            text: "PAIRED DEVICES"
                            visible: root.pairedDevices.length > 0
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: root.cSubtle
                        }

                        Column {
                            width: parent.width
                            spacing: 4
                            visible: root.pairedDevices.length > 0

                            Repeater {
                                model: root.pairedDevices
                                delegate: deviceRow
                            }
                        }

                        // ----- Divider between paired and new devices -----
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: root.cSurfaceAlt
                            visible: root.pairedDevices.length > 0 && root.newDevices.length > 0
                        }

                        // ----- New / unknown devices -----
                        Text {
                            text: "NEW DEVICES"
                            visible: root.newDevices.length > 0
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: root.cSubtle
                        }

                        Column {
                            width: parent.width
                            spacing: 4
                            visible: root.newDevices.length > 0

                            Repeater {
                                model: root.newDevices
                                delegate: deviceRow
                            }
                        }
                    }
                }

                // Down indicator — only shown while there's more below the fold.
                Rectangle {
                    width: parent.width
                    height: 16
                    radius: 6
                    color: root.cSurfaceAlt
                    opacity: 0.85
                    visible: deviceScroll.contentHeight - deviceScroll.height - deviceScroll.contentY > 2

                    Text {
                        anchors.centerIn: parent
                        text: "\uF078"
                        font.family: root.fontFamily
                        font.pixelSize: 9
                        color: root.cSubtle
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: deviceScroll.contentY = Math.min(
                            deviceScroll.contentHeight - deviceScroll.height,
                            deviceScroll.contentY + 88)
                    }
                }
            }

            Component {
                id: deviceRow

                Rectangle {
                    id: devRow
                    required property var modelData
                    property bool isConnected: modelData.connected
                    property bool isPaired: modelData.paired

                    width: content.width
                    height: 44
                    radius: 10
                    color: isConnected ? root.cBlueSurface : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: devRow.isConnected ? "\uF294" : "\uF293"
                            font.family: root.fontFamily
                            font.pixelSize: 15
                            color: devRow.isConnected ? root.cBlue : root.cSubtle
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 30
                            spacing: 1

                            Text {
                                width: parent.width
                                text: devRow.modelData.name || devRow.modelData.deviceName || "Unknown device"
                                elide: Text.ElideRight
                                font.family: root.fontFamily
                                font.pixelSize: 13
                                color: devRow.isConnected ? root.cForeground : root.cForegroundDim
                            }
                            Text {
                                width: parent.width
                                text: devRow.isConnected ? "Connected" : (devRow.isPaired ? "Paired" : "Available")
                                elide: Text.ElideRight
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                color: devRow.isConnected ? root.cGreen : root.cSubtle
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.toggleConnect(devRow.modelData)
                    }
                }
            }
        }
    }
}
