import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

// ~/.config/quickshell/wificontrol.qml
// Simple WiFi popup — power toggle, scan for networks, tap to
// connect/disconnect (with an inline password prompt for secured
// networks). Same Tokyo Night theme + toggle-guard pattern as
// powermenu.qml / audiocontrol.qml / bluetoothcontrol.qml.
//
// Uses nmcli under the hood rather than an experimental native network
// service, since password-prompt support for unsaved networks isn't
// reliably available any other way yet.
//
// Run standalone with: qs -p ~/.config/quickshell/wificontrol.qml
// Bind it in hyprland.lua, e.g.:
//   hl.bind("SUPER + W", hl.dsp.exec_cmd("qs -p ~/.config/quickshell/wificontrol.qml"))
//
// Click outside, or press Escape, to dismiss.

PanelWindow {
    id: root

    // ===== Tokyo Night palette (matches the rest of the setup) =====
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
    WlrLayershell.namespace: "quickshell:wificontrol"

    // ===== Toggle guard — same pattern as the other popups =====
    Process {
        id: instanceGuard
        running: true
        command: ["sh", "-c",
            "others=$(pgrep -f 'wificontrol\\.qml' | grep -v \"^$PPID$\"); " +
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

    // ===== State =====
    property bool wifiEnabled: false
    property bool scanning: false
    property var networks: []           // [{ssid, signal, secured, connected}]
    property var savedNames: []         // ssids of saved/known connection profiles
    property string connectingSsid: ""  // ssid currently mid-connect-attempt
    property string confirmPromptFor: "" // ssid awaiting Connect/Forget choice, or ""
    property string disconnectPromptFor: "" // ssid awaiting Disconnect confirmation, or ""
    property string passwordPromptFor: "" // ssid awaiting a password, or ""
    property string passwordError: ""

    function isKnown(ssid) {
        return root.savedNames.indexOf(ssid) !== -1
    }

    function splitNmcliFields(line) {
        const parts = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            if (line[i] === "\\" && line[i + 1] === ":") { cur += ":"; i++ }
            else if (line[i] === ":") { parts.push(cur); cur = "" }
            else cur += line[i]
        }
        parts.push(cur)
        return parts
    }

    function applyNetworkLines(lines) {
        const map = {}
        for (const raw of lines) {
            const f = splitNmcliFields(raw)
            if (f.length < 4) continue
            const [active, ssid, signal, security] = f
            if (!ssid) continue
            const sig = parseInt(signal) || 0
            const secured = !!security && security !== "--"
            const isActive = active === "yes"
            if (!map[ssid] || sig > map[ssid].signal) {
                map[ssid] = { ssid, signal: sig, secured, connected: isActive }
            }
            if (isActive) map[ssid].connected = true
        }
        const list = Object.values(map)
        list.sort((a, b) => (b.connected - a.connected) || (b.signal - a.signal))
        root.networks = list
    }

    // ----- Status polling -----
    Process {
        id: statusProc
        running: false
        command: ["nmcli", "-t", "-f", "WIFI", "g"]
        stdout: SplitParser {
            onRead: data => { if (data) root.wifiEnabled = data.trim().toLowerCase() === "enabled" }
        }
    }

    // ----- Saved/known connection profiles -----
    Process {
        id: savedProc
        running: false
        property var lines: []
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]
        onRunningChanged: {
            if (running) {
                lines = []
            } else {
                root.savedNames = lines.map(l => l.replace(/\\:/g, ":"))
            }
        }
        stdout: SplitParser {
            onRead: data => { if (data) savedProc.lines.push(data) }
        }
    }

    // ----- Network list -----
    Process {
        id: listProc
        running: false
        property var lines: []
        command: ["nmcli", "-t", "-f", "active,ssid,signal,security", "dev", "wifi"]
        onRunningChanged: {
            if (running) lines = []
            else root.applyNetworkLines(lines)
        }
        stdout: SplitParser {
            onRead: data => { if (data) listProc.lines.push(data) }
        }
    }

    // ----- Rescan -----
    Process {
        id: rescanProc
        running: false
        command: ["nmcli", "device", "wifi", "rescan"]
        onRunningChanged: if (!running) scanDelay.start()
    }
    Timer {
        id: scanDelay
        interval: 2000
        onTriggered: { listProc.running = true; root.scanning = false }
    }
    function rescan() {
        root.scanning = true
        rescanProc.running = true
    }

    // ----- Connect / disconnect -----
    Process {
        id: connectProc
        running: false
        property string stderrBuf: ""
        command: []
        stdout: SplitParser { onRead: data => {} }
        stderr: SplitParser { onRead: data => { connectProc.stderrBuf += data + "\n" } }
        onRunningChanged: {
            if (running) {
                stderrBuf = ""
            } else {
                const ok = exitCode === 0
                if (ok) {
                    root.passwordError = ""
                    root.connectingSsid = ""
                    listProc.running = true
                } else if (/[Ss]ecrets were required|802-11-wireless-security|[Pp]assword/.test(stderrBuf)) {
                    if (root.connectingSsid !== "") root.passwordPromptFor = root.connectingSsid
                    root.passwordError = "Incorrect password — try again."
                    root.connectingSsid = ""
                } else {
                    root.connectingSsid = ""
                }
            }
        }
    }
    Process {
        id: disconnectProc
        running: false
        command: []
        onRunningChanged: if (!running) listProc.running = true
    }
    Process {
        id: forgetProc
        running: false
        command: []
        onRunningChanged: if (!running) { savedProc.running = true; listProc.running = true }
    }
    Process {
        id: radioProc
        running: false
        command: []
        onRunningChanged: if (!running) {
            statusProc.running = true
            if (root.wifiEnabled) listProc.running = true
        }
    }

    function toggleWifi() {
        radioProc.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]
        radioProc.running = true
    }
    function connectToNetwork(net) {
        root.confirmPromptFor = ""
        root.passwordError = ""
        root.connectingSsid = net.ssid
        connectProc.command = ["nmcli", "device", "wifi", "connect", net.ssid]
        connectProc.running = true
    }
    function submitPassword(ssid, password) {
        root.passwordPromptFor = ""
        root.passwordError = ""
        root.connectingSsid = ssid
        connectProc.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password]
        connectProc.running = true
    }
    function disconnectNetwork(ssid) {
        root.disconnectPromptFor = ""
        disconnectProc.command = ["nmcli", "connection", "down", "id", ssid]
        disconnectProc.running = true
    }
    function forgetNetwork(ssid) {
        root.confirmPromptFor = ""
        forgetProc.command = ["nmcli", "connection", "delete", "id", ssid]
        forgetProc.running = true
    }

    // ----- Periodic refresh while open -----
    Timer {
        interval: 4000
        repeat: true
        running: root.visible
        onTriggered: {
            statusProc.running = true
            if (root.wifiEnabled && !connectProc.running && !rescanProc.running) {
                listProc.running = true
                savedProc.running = true
            }
        }
    }
    Component.onCompleted: { statusProc.running = true; listProc.running = true; savedProc.running = true }

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
                        text: "\uF1EB"
                        font.family: root.fontFamily
                        font.pixelSize: 20
                        color: root.wifiEnabled ? root.cCyan : root.cSubtle
                    }
                    Text {
                        text: "Wi-Fi"
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        color: root.cForeground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    id: powerSwitch
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 24
                    radius: 12
                    color: root.wifiEnabled ? root.cBlue : root.cSurfaceAlt
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        width: 18; height: 18
                        radius: 9
                        color: root.cBackground
                        anchors.verticalCenter: parent.verticalCenter
                        x: root.wifiEnabled ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.toggleWifi()
                    }
                }
            }

            // ----- Scan row -----
            Rectangle {
                width: parent.width
                height: 36
                radius: 10
                visible: root.wifiEnabled
                color: root.scanning ? root.cBlueSurface : root.cSurfaceAlt
                opacity: root.wifiEnabled ? 1 : 0.4

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
                        text: root.scanning ? "Scanning..." : "Scan for networks"
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        color: root.scanning ? root.cBlue : root.cForegroundDim
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.wifiEnabled
                    onClicked: root.rescan()
                }
            }

            // ----- Divider -----
            Rectangle {
                width: parent.width
                height: 1
                color: root.cSurfaceAlt
                visible: root.wifiEnabled && root.networks.length > 0
            }

            // ----- Network area: capped to 7 visible rows, scrolls beyond that -----
            Column {
                width: parent.width
                visible: root.wifiEnabled
                spacing: 4

                // Up indicator — only shown once scrolled down at all.
                Rectangle {
                    width: parent.width
                    height: 16
                    radius: 6
                    color: root.cSurfaceAlt
                    opacity: 0.85
                    visible: netScroll.contentY > 2

                    Text {
                        anchors.centerIn: parent
                        text: "\uF077"
                        font.family: root.fontFamily
                        font.pixelSize: 9
                        color: root.cSubtle
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: netScroll.contentY = Math.max(0, netScroll.contentY - 88)
                    }
                }

                Flickable {
                    id: netScroll
                    width: parent.width
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentWidth: width
                    contentHeight: netListColumn.implicitHeight
                    // 7 rows (44px each) + the gaps between them.
                    height: Math.min(netListColumn.implicitHeight, 7 * 44 + 6 * 8)

                    Column {
                        id: netListColumn
                        width: parent.width
                        spacing: 8

            // ----- Empty state -----
            Text {
                width: parent.width
                visible: root.wifiEnabled && root.networks.length === 0
                text: root.scanning ? "Looking for networks..." : "No networks found yet — try scanning."
                wrapMode: Text.WordWrap
                font.family: root.fontFamily
                font.pixelSize: 12
                color: root.cSubtle
            }

            // ----- Network list -----
            Text {
                text: "NETWORKS"
                visible: root.wifiEnabled && root.networks.length > 0
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: root.cSubtle
            }

            Column {
                width: parent.width
                spacing: 4
                visible: root.wifiEnabled

                Repeater {
                    model: root.networks

                    Column {
                        id: netItem
                        required property var modelData
                        width: content.width
                        spacing: 6

                        property bool isConnecting: root.connectingSsid === modelData.ssid
                        property bool showConfirmField: root.confirmPromptFor === modelData.ssid
                        property bool showDisconnectField: root.disconnectPromptFor === modelData.ssid
                        property bool showPasswordField: root.passwordPromptFor === modelData.ssid

                        Rectangle {
                            id: netRow
                            width: parent.width
                            height: 44
                            radius: 10
                            color: netItem.modelData.connected ? root.cBlueSurface : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: netItem.modelData.secured ? "\uF023" : "\uF1EB"
                                    font.family: root.fontFamily
                                    font.pixelSize: 14
                                    color: netItem.modelData.connected ? root.cBlue : root.cSubtle
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 90
                                    spacing: 1

                                    Text {
                                        width: parent.width
                                        text: netItem.modelData.ssid
                                        elide: Text.ElideRight
                                        font.family: root.fontFamily
                                        font.pixelSize: 13
                                        color: netItem.modelData.connected ? root.cForeground : root.cForegroundDim
                                    }
                                    Text {
                                        width: parent.width
                                        text: netItem.isConnecting ? "Connecting..." :
                                              (netItem.modelData.connected ? "Connected" :
                                              (root.isKnown(netItem.modelData.ssid) ? "Known" :
                                              (netItem.modelData.secured ? "Secured" : "Open")))
                                        elide: Text.ElideRight
                                        font.family: root.fontFamily
                                        font.pixelSize: 10
                                        color: netItem.modelData.connected ? root.cGreen : root.cSubtle
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: netItem.modelData.signal + "%"
                                    font.family: root.fontFamily
                                    font.pixelSize: 11
                                    color: root.cSubtle
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !netItem.isConnecting
                                onClicked: {
                                    if (netItem.modelData.connected) {
                                        root.disconnectPromptFor = netItem.modelData.ssid
                                    } else if (root.isKnown(netItem.modelData.ssid)) {
                                        // Known/saved network — offer Connect or Forget
                                        // rather than acting immediately.
                                        root.confirmPromptFor = netItem.modelData.ssid
                                    } else if (netItem.modelData.secured) {
                                        // Genuinely new secured network — ask for a
                                        // password right away.
                                        root.passwordPromptFor = netItem.modelData.ssid
                                        root.passwordError = ""
                                    } else {
                                        // New open network — nothing to ask, just connect.
                                        root.connectToNetwork(netItem.modelData)
                                    }
                                }
                            }
                        }

                        // ----- Connected network: Disconnect -----
                        Rectangle {
                            visible: netItem.showDisconnectField
                            width: parent.width
                            height: 40
                            radius: 10
                            color: root.cSurfaceAlt

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 6
                                radius: 8
                                color: "transparent"
                                border.color: root.cRed
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "Disconnect"
                                    font.family: root.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: root.cRed
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.disconnectNetwork(netItem.modelData.ssid)
                                }
                            }
                        }

                        // ----- Known network: Connect / Forget -----
                        Rectangle {
                            visible: netItem.showConfirmField
                            width: parent.width
                            height: 40
                            radius: 10
                            color: root.cSurfaceAlt

                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8

                                Rectangle {
                                    width: (parent.width - 8) / 2
                                    height: parent.height
                                    radius: 8
                                    color: root.cBlue
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Connect"
                                        font.family: root.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        color: root.cBackground
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.connectToNetwork(netItem.modelData)
                                    }
                                }
                                Rectangle {
                                    width: (parent.width - 8) / 2
                                    height: parent.height
                                    radius: 8
                                    color: "transparent"
                                    border.color: root.cRed
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Forget"
                                        font.family: root.fontFamily
                                        font.pixelSize: 12
                                        color: root.cRed
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.forgetNetwork(netItem.modelData.ssid)
                                    }
                                }
                            }
                        }

                        // ----- Inline password prompt -----
                        Rectangle {
                            visible: netItem.showPasswordField
                            width: parent.width
                            height: 76
                            radius: 10
                            color: root.cSurfaceAlt

                            Column {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 6

                                Rectangle {
                                    width: parent.width
                                    height: 32
                                    radius: 8
                                    color: root.cBackground
                                    border.color: pwField.activeFocus ? root.cBlue : root.cSurfaceAlt
                                    border.width: 1

                                    TextInput {
                                        id: pwField
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        verticalAlignment: TextInput.AlignVCenter
                                        echoMode: TextInput.Password
                                        color: root.cForeground
                                        font.family: root.fontFamily
                                        font.pixelSize: 12
                                        focus: netItem.showPasswordField
                                        onAccepted: root.submitPassword(netItem.modelData.ssid, text)

                                        Text {
                                            visible: pwField.text.length === 0
                                            text: "Password"
                                            color: root.cSubtle
                                            font.family: root.fontFamily
                                            font.pixelSize: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Rectangle {
                                        width: (parent.width - 8) / 2
                                        height: 26
                                        radius: 8
                                        color: root.cBlue
                                        Text {
                                            anchors.centerIn: parent
                                            text: "Connect"
                                            font.family: root.fontFamily
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            color: root.cBackground
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: root.submitPassword(netItem.modelData.ssid, pwField.text)
                                        }
                                    }
                                    Rectangle {
                                        width: (parent.width - 8) / 2
                                        height: 26
                                        radius: 8
                                        color: "transparent"
                                        border.color: root.cSubtle
                                        border.width: 1
                                        Text {
                                            anchors.centerIn: parent
                                            text: "Cancel"
                                            font.family: root.fontFamily
                                            font.pixelSize: 12
                                            color: root.cForegroundDim
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: root.passwordPromptFor = ""
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: netItem.showPasswordField && root.passwordError !== ""
                            width: parent.width
                            text: root.passwordError
                            wrapMode: Text.WordWrap
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            color: root.cRed
                        }
                    }
                }
            }

                }

                } // close Flickable (netScroll)

                // Down indicator — only shown while there's more below the fold.
                Rectangle {
                    width: parent.width
                    height: 16
                    radius: 6
                    color: root.cSurfaceAlt
                    opacity: 0.85
                    visible: netScroll.contentHeight - netScroll.height - netScroll.contentY > 2

                    Text {
                        anchors.centerIn: parent
                        text: "\uF078"
                        font.family: root.fontFamily
                        font.pixelSize: 9
                        color: root.cSubtle
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: netScroll.contentY = Math.min(
                            netScroll.contentHeight - netScroll.height,
                            netScroll.contentY + 88)
                    }
                }
            }
        }
    }
}
