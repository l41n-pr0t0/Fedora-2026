/*
    STEINS;GATE 0 // Future Gadget Laboratory Lock Screen for KDE Plasma 6
    Authored for l41n-pr0t0 (LENOVO Legion Pro 7)
    Palette derived strictly from Steins;Gate 0 & huke artwork
*/
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.workspace.components as PW
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.kirigami as Kirigami
import org.kde.kscreenlocker as ScreenLocker
import org.kde.plasma.private.sessions

Item {
    id: lockScreenUi
    anchors.fill: parent

    // Dynamic UI Scale
    readonly property real s: height / 768

    // Active Tab in Header: "TERMINAL" | "DIVERGENCE" | "MEMBERS" | "HARDWARE"
    property string currentTab: "TERMINAL"

    // ── STEINS;GATE 0 & HUKE COLOR PALETTE (STRICTLY FROM USER IMAGES) ────────
    readonly property color sgBgDeep:        "#161311"
    readonly property color sgCardBg:        "#201a16"
    readonly property color sgCardDarker:    "#191512"
    readonly property color sgBorderIron:    "#45372d"
    readonly property color sgBorderBrass:   "#8f7445"
    readonly property color sgAntiqueBrass:  "#c4a255"
    readonly property color sgGearRust:      "#5c4736"
    readonly property color sgKurisuAuburn:  "#8c3827"
    readonly property color sgKurisuChestnut:"#a6442e"
    readonly property color sgNixieAmber:    "#c96e24"
    readonly property color sgParchmentLight:"#ece3cc"
    readonly property color sgParchmentDim:  "#b5a485"
    readonly property color sgParchmentFaint:"#635746"
    readonly property color sgMayuriBlue:    "#4a6577"
    readonly property color sgMayuriMauve:   "#965b7e"
    readonly property color sgErrRed:        "#9e2a2b"
    readonly property color sgSuccessGreen:  "#10f49c"

    // Typography
    readonly property string fontMono: "JetBrainsMono Nerd Font"

    // ── TIME & CLOCK ENGINE ──────────────────────────────────────────────────
    property int curH: new Date().getHours()
    property int curM: new Date().getMinutes()
    property int curS: new Date().getSeconds()
    property int curMS: new Date().getMilliseconds()
    readonly property real localTimeMS: (curH * 3600000) + (curM * 60000) + (curS * 1000) + curMS

    // Continuous smooth sub-second orbital rotation
    property real windupOffset: 0
    readonly property real smoothSecAngle: -((localTimeMS % 60000) / 60000.0) * 360.0 - windupOffset * 6.0
    readonly property real smoothMinAngle: -((localTimeMS % 3600000) / 3600000.0) * 360.0 - windupOffset * 3.0

    Timer {
        interval: 16; running: true; repeat: true
        onTriggered: {
            var d = new Date()
            lockScreenUi.curH = d.getHours()
            lockScreenUi.curM = d.getMinutes()
            lockScreenUi.curS = d.getSeconds()
            lockScreenUi.curMS = d.getMilliseconds()
        }
    }

    // Secondary Telemetry & Strings
    property string currentTime: Qt.formatTime(new Date(), "hh:mm")
    property string currentDate: Qt.formatDate(new Date(), "yyyy.MM.dd")
    property string uptimeText: "0h 18m"
    property int uptimeSeconds: 1080
    property string divergenceValue: "1.048596 %"

    // Hardware Telemetry
    property string batteryPct: "85%"
    property string batteryStatus: "AC ONLINE"
    property bool   isAcOnline: true
    property string memUsageText: "4.8 GB / 31.1 GB"

    // Password Reveal & State
    property bool showPassword: false
    property bool isUnlocking: false
    property string authStatusState: "IDLE" // "IDLE" | "BUSY" | "SUCCESS" | "FAILED"
    property string pendingPassword: ""

    SessionManagement { id: sessionManagement }
    KeyboardIndicator.KeyState { id: capsLockState; key: Qt.Key_CapsLock }

    // ── ROOT & SYSTEM CONNECTIONS (SLEEP / WAKE / LOCK / CLEAR) ──────────────
    Connections {
        target: typeof root !== "undefined" ? root : null
        function onLockedChanged() {
            if (root && root.locked && typeof authenticator !== "undefined") {
                if (authenticator.state === 0) {
                    authenticator.startAuthenticating()
                }
            }
        }
        function onClearPassword() {
            pwInput.text = ""
            lockScreenUi.pendingPassword = ""
            lockScreenUi.isUnlocking = false
            lockScreenUi.authStatusState = "IDLE"
            if (typeof authenticator !== "undefined" && authenticator.state === 0) {
                authenticator.startAuthenticating()
            }
        }
    }

    Connections {
        target: sessionManagement
        function onAboutToSuspend() {
            if (typeof root !== "undefined") {
                root.clearPassword()
            }
        }
    }

    // ── PAM AUTHENTICATOR CONNECTIONS ────────────────────────────────────────
    Connections {
        target: typeof authenticator !== "undefined" ? authenticator : null
        function onFailed(kind) {
            if (kind !== 0) {
                // Ignore background non-interactive authenticators (fingerprint/smartcard)
                return
            }
            lockScreenUi.pendingPassword = ""
            lockScreenUi.isUnlocking = false
            lockScreenUi.authStatusState = "FAILED"
            windupAnim.stop()
            lockScreenUi.windupOffset = 0
            errText.text = "ACCESS DENIED // DIVERGENCE FAILURE"
            errText.color = lockScreenUi.sgErrRed
            pwInput.text = ""
            shakeAnim.restart()
            // PAM delay requires at least 2 seconds between attempts to avoid disabling the service
            reauthTimer.restart()
        }
        function onSucceeded() {
            lockScreenUi.pendingPassword = ""
            lockScreenUi.authStatusState = "SUCCESS"
            errText.text = "OPERATION SKULD // ACCESS GRANTED // WELCOME"
            errText.color = lockScreenUi.sgSuccessGreen
            botStatusMsg.text = "OPERATION SKULD // ACCESS GRANTED // WELCOME"
            botStatusMsg.color = lockScreenUi.sgSuccessGreen

            // Workaround QTBUG-55460: Defocus text input before quitting
            pwInput.focus = false
            connectBtn.forceActiveFocus()

            Qt.quit()
        }
        function onPromptForSecretChanged() {
            if (lockScreenUi.pendingPassword !== "") {
                var pw = lockScreenUi.pendingPassword
                lockScreenUi.pendingPassword = ""
                authenticator.respond(pw)
                return
            }
            if (lockScreenUi.authStatusState !== "SUCCESS") {
                pwInput.forceActiveFocus()
            }
        }
        function onErrorMessageChanged() {
            if (authenticator && authenticator.errorMessage && lockScreenUi.authStatusState !== "SUCCESS") {
                errText.text = authenticator.errorMessage.toUpperCase()
                errText.color = lockScreenUi.sgErrRed
            }
        }
    }

    Timer {
        id: reauthTimer
        interval: 2500; repeat: false
        onTriggered: {
            if (typeof authenticator !== "undefined") {
                authenticator.startAuthenticating()
            }
            pwInput.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        pwInput.forceActiveFocus()
        if (typeof authenticator !== "undefined") {
            authenticator.startAuthenticating()
        }
    }

    // Force focus timer
    Timer {
        id: focusKeepAlive
        interval: 200; running: true; repeat: false
        onTriggered: {
            if (lockScreenUi.authStatusState !== "SUCCESS") {
                pwInput.forceActiveFocus()
            }
        }
    }

    // Telemetry Update Timer
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            lockScreenUi.currentTime = Qt.formatTime(new Date(), "hh:mm")
            lockScreenUi.currentDate = Qt.formatDate(new Date(), "yyyy.MM.dd")
            lockScreenUi.uptimeSeconds += 1
            var hrs = Math.floor(lockScreenUi.uptimeSeconds / 3600)
            var mins = Math.floor((lockScreenUi.uptimeSeconds % 3600) / 60)
            var secs = lockScreenUi.uptimeSeconds % 60
            lockScreenUi.uptimeText = hrs + "h " + (mins < 10 ? "0" : "") + mins + "m " + (secs < 10 ? "0" : "") + secs + "s"
        }
    }

    function doUnlock() {
        const password = pwInput.text
        if (password.length === 0 || lockScreenUi.isUnlocking) return
        lockScreenUi.isUnlocking = true
        lockScreenUi.authStatusState = "BUSY"
        errText.text = "OPERATION SKULD // SYNCHRONIZING..."
        errText.color = lockScreenUi.sgNixieAmber

        // Defocus text input to neutral button before responding to avoid QTBUG-55460
        pwInput.focus = false
        connectBtn.forceActiveFocus()

        windupAnim.start()
        if (typeof authenticator !== "undefined") {
            if (authenticator.state === 1 && authenticator.promptForSecret !== "") {
                authenticator.respond(password)
            } else {
                // PAM worker was not ready or was idle (e.g. woke from grace sleep)
                lockScreenUi.pendingPassword = password
                authenticator.startAuthenticating()
            }
        }
    }

    NumberAnimation {
        id: windupAnim
        target: lockScreenUi; property: "windupOffset"
        from: 0; to: 15000; duration: 400
        easing.type: Easing.InQuad
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: rightPanel; property: "anchors.rightMargin"; from: 70 * s; to: 82 * s; duration: 40; easing.type: Easing.InOutSine }
        NumberAnimation { target: rightPanel; property: "anchors.rightMargin"; to: 58 * s; duration: 40; easing.type: Easing.InOutSine }
        NumberAnimation { target: rightPanel; property: "anchors.rightMargin"; to: 70 * s; duration: 40; easing.type: Easing.InOutSine }
    }

    // ── KEYBOARD SHORTCUTS ───────────────────────────────────────────────────
    Shortcut {
        sequence: "Alt+P"
        onActivated: {
            lockScreenUi.showPassword = !lockScreenUi.showPassword
            pwInput.forceActiveFocus()
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            pwInput.text = ""
            errText.text = ""
            lockScreenUi.currentTab = "TERMINAL"
            pwInput.forceActiveFocus()
        }
    }

    Shortcut { sequence: "Alt+1"; onActivated: lockScreenUi.currentTab = "TERMINAL" }
    Shortcut { sequence: "Alt+2"; onActivated: lockScreenUi.currentTab = "DIVERGENCE" }
    Shortcut { sequence: "Alt+3"; onActivated: lockScreenUi.currentTab = "MEMBERS" }
    Shortcut { sequence: "Alt+4"; onActivated: lockScreenUi.currentTab = "HARDWARE" }

    // ── CLICK ANYWHERE TO FOCUS ──────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        z: -1
        cursorShape: Qt.ArrowCursor
        onClicked: pwInput.forceActiveFocus()
    }

    // ── BACKGROUND CANVAS (AGED SEPIA PARCHMENT & PATINA) ────────────────────
    Rectangle {
        anchors.fill: parent
        color: lockScreenUi.sgBgDeep

        // Subtle Aged Paper Fiber / Grid Wash
        Canvas {
            anchors.fill: parent
            opacity: 0.12
            onPaint: {
                var ctx = getContext("2d")
                ctx.strokeStyle = "#8f7445"
                ctx.lineWidth = 1
                var step = 48 * s
                for (var x = 0; x < width; x += step) {
                    ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke();
                }
                for (var y = 0; y < height; y += step) {
                    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke();
                }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 🏛️ TOP HEADER: STEINS;GATE 0 INTERACTIVE TABS & TELEMETRY
    // ═════════════════════════════════════════════════════════════════════════
    Rectangle {
        id: topHeaderBar
        width: parent.width; height: 48 * s
        anchors.top: parent.top
        color: lockScreenUi.sgCardBg
        border.color: lockScreenUi.sgBorderIron
        border.width: 1
        z: 100

        // Corner Calipers
        Rectangle { width: 8 * s; height: 2 * s; color: lockScreenUi.sgAntiqueBrass; anchors.top: parent.top; anchors.left: parent.left }
        Rectangle { width: 2 * s; height: 8 * s; color: lockScreenUi.sgAntiqueBrass; anchors.top: parent.top; anchors.left: parent.left }
        Rectangle { width: 8 * s; height: 2 * s; color: lockScreenUi.sgAntiqueBrass; anchors.top: parent.top; anchors.right: parent.right }
        Rectangle { width: 2 * s; height: 8 * s; color: lockScreenUi.sgAntiqueBrass; anchors.top: parent.top; anchors.right: parent.right }

        // Interactive Header Tabs
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: 18 * s
            spacing: 8 * s

            // Title Badge
            Rectangle {
                height: 28 * s; width: titleText.implicitWidth + 16 * s
                color: lockScreenUi.sgKurisuAuburn
                border.color: lockScreenUi.sgKurisuChestnut; border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: titleText; anchors.centerIn: parent
                    text: "STEINS;GATE 0"
                    font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; font.bold: true
                    font.letterSpacing: 2 * s; color: lockScreenUi.sgParchmentLight
                }
            }

            Rectangle { width: 1 * s; height: 18 * s; color: lockScreenUi.sgBorderIron; anchors.verticalCenter: parent.verticalCenter }

            // 4 Operational Tabs
            Repeater {
                model: [
                    { id: "TERMINAL",   name: "[ 01 // LAB TERMINAL ]" },
                    { id: "DIVERGENCE", name: "[ 02 // DIVERGENCE ]" },
                    { id: "MEMBERS",    name: "[ 03 // LAB MEMBERS ]" },
                    { id: "HARDWARE",   name: "[ 04 // HARDWARE ]" }
                ]
                Rectangle {
                    property bool isActive: lockScreenUi.currentTab === modelData.id
                    property bool hovered: tabMa.containsMouse
                    height: 28 * s; width: tabLbl.implicitWidth + 18 * s
                    color: isActive ? lockScreenUi.sgAntiqueBrass : (hovered ? "#2b231c" : "transparent")
                    border.color: isActive ? lockScreenUi.sgAntiqueBrass : (hovered ? lockScreenUi.sgBorderBrass : "transparent")
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: tabLbl; anchors.centerIn: parent
                        text: modelData.name
                        font.family: lockScreenUi.fontMono; font.pixelSize: 10 * s; font.bold: isActive
                        font.letterSpacing: 1.5 * s
                        color: isActive ? "#120f0c" : (hovered ? lockScreenUi.sgParchmentLight : lockScreenUi.sgParchmentDim)
                    }

                    MouseArea {
                        id: tabMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            lockScreenUi.currentTab = modelData.id
                            pwInput.forceActiveFocus()
                        }
                    }
                }
            }
        }

        // Top Right System Telemetry
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right; anchors.rightMargin: 20 * s
            spacing: 16 * s

            // Divergence Mini Readout
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5 * s
                Text { text: "DIV:"; font.family: lockScreenUi.fontMono; font.pixelSize: 9.5 * s; color: lockScreenUi.sgParchmentDim }
                Text {
                    text: lockScreenUi.divergenceValue
                    font.family: lockScreenUi.fontMono; font.pixelSize: 11.5 * s; font.bold: true
                    color: lockScreenUi.sgNixieAmber; font.letterSpacing: 1 * s
                }
            }

            Rectangle { width: 1 * s; height: 16 * s; color: lockScreenUi.sgBorderIron; anchors.verticalCenter: parent.verticalCenter }

            Row {
                spacing: 5 * s; anchors.verticalCenter: parent.verticalCenter
                Text { text: lockScreenUi.isAcOnline ? "⚡" : "🔋"; font.family: lockScreenUi.fontMono; font.pixelSize: 10 * s; color: lockScreenUi.sgAntiqueBrass }
                Text { text: lockScreenUi.batteryPct; font.family: lockScreenUi.fontMono; font.pixelSize: 9.5 * s; color: lockScreenUi.sgParchmentLight; font.bold: true }
            }

            Row {
                spacing: 5 * s; anchors.verticalCenter: parent.verticalCenter
                Text { text: "MEM:"; font.family: lockScreenUi.fontMono; font.pixelSize: 9.5 * s; color: lockScreenUi.sgParchmentDim }
                Text { text: lockScreenUi.memUsageText; font.family: lockScreenUi.fontMono; font.pixelSize: 9.5 * s; color: lockScreenUi.sgAntiqueBrass; font.bold: true }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // ⚙️ LEFT SIDE: CLOCKWORK CAST-IRON GEARS & CALIBRATED BRASS DIAL
    // ═════════════════════════════════════════════════════════════════════════
    Item {
        id: clockworkEngine
        anchors.left: parent.left; anchors.leftMargin: 60 * s
        anchors.verticalCenter: parent.verticalCenter
        width: 820 * s; height: parent.height
        visible: lockScreenUi.currentTab === "TERMINAL"
        z: 20

        readonly property real cx: 60 * s
        readonly property real cy: height * 0.5
        readonly property real minR: 280 * s   // Inner Minutes Orbital Wheel
        readonly property real secR: 420 * s   // Outer Seconds Orbital Wheel

        // Rotating Cast-Iron Cogs Canvas (Steins;Gate 0 style)
        Canvas {
            id: cogCanvas
            anchors.fill: parent
            property real rotAngle1: (lockScreenUi.localTimeMS * 0.00004) + lockScreenUi.windupOffset * 0.0001
            property real rotAngle2: -(lockScreenUi.localTimeMS * 0.00006) - lockScreenUi.windupOffset * 0.0002

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                // Helper to draw cogwheel
                function drawCog(gx, gy, radius, teeth, depth, angle, fillCol, strokeCol) {
                    ctx.save()
                    ctx.translate(gx, gy)
                    ctx.rotate(angle)
                    ctx.fillStyle = fillCol
                    ctx.strokeStyle = strokeCol
                    ctx.lineWidth = 1.5

                    ctx.beginPath()
                    var step = (Math.PI * 2) / teeth
                    for (var i = 0; i < teeth; i++) {
                        var a1 = i * step
                        var a2 = a1 + step * 0.35
                        var a3 = a1 + step * 0.65
                        var a4 = (i + 1) * step

                        var rOut = radius + depth
                        var rIn = radius

                        var x1 = Math.cos(a1) * rIn, y1 = Math.sin(a1) * rIn
                        var x2 = Math.cos(a2) * rOut, y2 = Math.sin(a2) * rOut
                        var x3 = Math.cos(a3) * rOut, y3 = Math.sin(a3) * rOut
                        var x4 = Math.cos(a4) * rIn, y4 = Math.sin(a4) * rIn

                        if (i === 0) ctx.moveTo(x1, y1)
                        ctx.lineTo(x2, y2)
                        ctx.lineTo(x3, y3)
                        ctx.lineTo(x4, y4)
                    }
                    ctx.closePath()
                    ctx.fill()
                    ctx.stroke()

                    // Center Hub
                    ctx.beginPath()
                    ctx.arc(0, 0, radius * 0.35, 0, Math.PI * 2)
                    ctx.fillStyle = "#1e1a17"
                    ctx.fill()
                    ctx.stroke()

                    // Spokes
                    ctx.strokeStyle = strokeCol
                    ctx.lineWidth = 2.5
                    for (var sp = 0; sp < 5; sp++) {
                        var sa = (sp * Math.PI * 2) / 5
                        ctx.beginPath()
                        ctx.moveTo(Math.cos(sa) * (radius * 0.35), Math.sin(sa) * (radius * 0.35))
                        ctx.lineTo(Math.cos(sa) * (radius * 0.9), Math.sin(sa) * (radius * 0.9))
                        ctx.stroke()
                    }
                    ctx.restore()
                }

                // Draw background antique iron gear wheels
                drawCog(clockworkEngine.cx - 20 * s, clockworkEngine.cy - 70 * s, 150 * s, 18, 14 * s, rotAngle1, "#28201a", "#4a3c31")
                drawCog(clockworkEngine.cx + 100 * s, clockworkEngine.cy + 110 * s, 100 * s, 14, 12 * s, rotAngle2, "#342820", "#5c4839")
            }

            Connections {
                target: lockScreenUi
                function onLocalTimeMSChanged() { cogCanvas.requestPaint() }
            }
        }

        // Steins;Gate Brass Capsule Housing (Hour Display)
        Rectangle {
            id: indicatorPill
            z: 1
            x: clockworkEngine.cx + 200 * s
            anchors.verticalCenter: parent.verticalCenter
            width: 320 * s; height: 86 * s; radius: 10 * s
            color: lockScreenUi.sgCardBg
            border.color: lockScreenUi.sgAntiqueBrass; border.width: 1.5 * s

            // Center Divider
            Rectangle {
                x: 160 * s; anchors.verticalCenter: parent.verticalCenter
                width: 1.5 * s; height: 38 * s; color: lockScreenUi.sgBorderBrass
            }

            // Minute readout inside pill
            Text {
                anchors.left: parent.left; anchors.leftMargin: 40 * s; anchors.verticalCenter: parent.verticalCenter
                text: String(lockScreenUi.curM).padStart(2, '0') + "m"
                font.family: lockScreenUi.fontMono; font.pixelSize: 26 * s; font.bold: true
                color: lockScreenUi.sgAntiqueBrass
            }

            // Second readout inside pill
            Text {
                anchors.right: parent.right; anchors.rightMargin: 40 * s; anchors.verticalCenter: parent.verticalCenter
                text: String(lockScreenUi.curS).padStart(2, '0') + "s"
                font.family: lockScreenUi.fontMono; font.pixelSize: 26 * s; font.bold: true
                color: lockScreenUi.sgParchmentLight
            }
        }

        // ── 1. MINUTES ORBITAL ROTATING WHEEL ────────────────────────────────
        Repeater {
            model: 60
            delegate: Item {
                z: 10
                property real base: index * 6
                property real relAngle: {
                    var a = (base + lockScreenUi.smoothMinAngle) % 360
                    if (a > 180) a -= 360
                    if (a < -180) a += 360
                    return a
                }
                property real spotlight: Math.max(0, 1.0 - Math.abs(relAngle) / 4.5)
                property bool isMajor: index % 5 === 0
                property real disp: (base + lockScreenUi.smoothMinAngle) * Math.PI / 180
                property real tx: clockworkEngine.cx + clockworkEngine.minR * Math.cos(disp)
                property real ty: clockworkEngine.cy + clockworkEngine.minR * Math.sin(disp)

                visible: tx > -400 * s && tx < 1800 * s

                // Radial Tick Mark
                Rectangle {
                    x: parent.tx - width/2; y: parent.ty - height/2
                    width: isMajor ? 2.5 * s : 1.2 * s; height: isMajor ? 18 * s : 10 * s
                    color: parent.spotlight > 0 ? lockScreenUi.sgParchmentLight : (parent.isMajor ? lockScreenUi.sgAntiqueBrass : lockScreenUi.sgParchmentFaint)
                    rotation: parent.disp * 180 / Math.PI + 90
                    antialiasing: true
                    transformOrigin: Item.Center
                }

                // Major Number Readout
                Text {
                    visible: parent.isMajor
                    property real nRad: clockworkEngine.minR - 30 * s
                    x: clockworkEngine.cx + nRad * Math.cos(parent.disp) - width/2
                    y: clockworkEngine.cy + nRad * Math.sin(parent.disp) - height/2
                    text: String(index).padStart(2, '0')
                    font.family: lockScreenUi.fontMono; font.pixelSize: 16 * s
                    font.bold: parent.spotlight > 0.4
                    color: parent.spotlight > 0 ? lockScreenUi.sgParchmentLight : lockScreenUi.sgBorderBrass
                    rotation: parent.disp * 180 / Math.PI
                    transformOrigin: Item.Center
                    antialiasing: true
                }
            }
        }

        // ── 2. SECONDS ORBITAL ROTATING WHEEL ────────────────────────────────
        Repeater {
            model: 60
            delegate: Item {
                z: 10
                property real base: index * 6
                property real relAngle: {
                    var a = (base + lockScreenUi.smoothSecAngle) % 360
                    if (a > 180) a -= 360
                    if (a < -180) a += 360
                    return a
                }
                property real spotlight: Math.max(0, 1.0 - Math.abs(relAngle) / 4.5)
                property bool isMajor: index % 5 === 0
                property real disp: (base + lockScreenUi.smoothSecAngle) * Math.PI / 180
                property real tx: clockworkEngine.cx + clockworkEngine.secR * Math.cos(disp)
                property real ty: clockworkEngine.cy + clockworkEngine.secR * Math.sin(disp)

                visible: tx > -400 * s && tx < 1800 * s

                // Radial Tick Mark
                Rectangle {
                    x: parent.tx - width/2; y: parent.ty - height/2
                    width: isMajor ? 2.0 * s : 1.0 * s; height: isMajor ? 14 * s : 8 * s
                    color: parent.spotlight > 0 ? lockScreenUi.sgParchmentLight : (parent.isMajor ? lockScreenUi.sgBorderBrass : lockScreenUi.sgBorderIron)
                    rotation: parent.disp * 180 / Math.PI + 90
                    antialiasing: true
                    transformOrigin: Item.Center
                }

                // Major Number Readout
                Text {
                    visible: parent.isMajor
                    property real nRad: clockworkEngine.secR - 26 * s
                    x: clockworkEngine.cx + nRad * Math.cos(parent.disp) - width/2
                    y: clockworkEngine.cy + nRad * Math.sin(parent.disp) - height/2
                    text: String(index).padStart(2, '0')
                    font.family: lockScreenUi.fontMono; font.pixelSize: 13 * s
                    font.bold: parent.spotlight > 0.4
                    color: parent.spotlight > 0 ? lockScreenUi.sgParchmentLight : lockScreenUi.sgParchmentFaint
                    rotation: parent.disp * 180 / Math.PI
                    transformOrigin: Item.Center
                    antialiasing: true
                }
            }
        }

        // Giant Bold Hour Display (Left of Pill)
        Text {
            anchors.right: indicatorPill.left; anchors.rightMargin: 30 * s
            anchors.verticalCenter: parent.verticalCenter
            text: String(lockScreenUi.curH).padStart(2, '0')
            font.family: lockScreenUi.fontMono; font.pixelSize: 96 * s; font.bold: true
            color: lockScreenUi.sgParchmentLight
        }

        // Date & Day Readout (Right of Pill)
        Column {
            anchors.left: indicatorPill.right; anchors.leftMargin: 36 * s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4 * s

            Text {
                text: Qt.formatDate(new Date(), "dddd").toUpperCase()
                font.family: lockScreenUi.fontMono; font.pixelSize: 15 * s
                font.letterSpacing: 4 * s; font.bold: true; color: lockScreenUi.sgAntiqueBrass
            }
            Text {
                text: Qt.formatDate(new Date(), "yyyy.MM.dd")
                font.family: lockScreenUi.fontMono; font.pixelSize: 12 * s
                font.letterSpacing: 2 * s; color: lockScreenUi.sgParchmentDim
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 🌐 TAB 2: DIVERGENCE WORLD LINE ANALYZER VIEW
    // ═════════════════════════════════════════════════════════════════════════
    Item {
        id: divergenceView
        anchors.left: parent.left; anchors.leftMargin: 50 * s
        anchors.top: topHeaderBar.bottom; anchors.topMargin: 30 * s
        anchors.bottom: botBar.top; anchors.bottomMargin: 30 * s
        anchors.right: rightPanel.left; anchors.rightMargin: 40 * s
        visible: lockScreenUi.currentTab === "DIVERGENCE"
        z: 20

        Column {
            anchors.fill: parent; spacing: 14 * s
            Text {
                text: "WORLD LINE DIVERGENCE METER MATRIX"
                font.family: lockScreenUi.fontMono; font.pixelSize: 14 * s; font.bold: true
                color: lockScreenUi.sgAntiqueBrass; font.letterSpacing: 2 * s
            }

            Repeater {
                model: [
                    { name: "STEINS GATE", val: "1.048596 %", desc: "Target divergence where the future remains unobserved and WWIII is averted.", active: true },
                    { name: "ALPHA ATTRACTION FIELD", val: "0.571024 %", desc: "SERN dystopia timeline. D-Mail convergence leads to Mayuri fatality.", active: false },
                    { name: "BETA ATTRACTION FIELD", val: "1.130426 %", desc: "Time machine race begins. Kurisu Makise fatality convergence point.", active: false },
                    { name: "OMEGA WORLD LINE", val: "-0.193205 %", desc: "Isolated world line where Okabe is forgotten by the lab members.", active: false }
                ]
                Rectangle {
                    width: parent.width; height: 86 * s
                    color: modelData.active ? "#2b221a" : lockScreenUi.sgCardBg
                    border.color: modelData.active ? lockScreenUi.sgAntiqueBrass : lockScreenUi.sgBorderIron
                    border.width: 1

                    Row {
                        anchors.fill: parent; anchors.margins: 14 * s; spacing: 20 * s
                        Column {
                            width: 180 * s; spacing: 4 * s; anchors.verticalCenter: parent.verticalCenter
                            Text { text: modelData.name; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; font.bold: true; color: modelData.active ? lockScreenUi.sgAntiqueBrass : lockScreenUi.sgParchmentLight }
                            Text { text: modelData.val; font.family: lockScreenUi.fontMono; font.pixelSize: 16 * s; font.bold: true; color: lockScreenUi.sgNixieAmber }
                        }
                        Text {
                            width: parent.width - 220 * s; text: modelData.desc; font.family: lockScreenUi.fontMono
                            font.pixelSize: 10 * s; color: lockScreenUi.sgParchmentDim; wrapMode: Text.WordWrap
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 👥 TAB 3: LAB MEMBERS ROSTER VIEW
    // ═════════════════════════════════════════════════════════════════════════
    Item {
        id: membersView
        anchors.left: parent.left; anchors.leftMargin: 50 * s
        anchors.top: topHeaderBar.bottom; anchors.topMargin: 30 * s
        anchors.bottom: botBar.top; anchors.bottomMargin: 30 * s
        anchors.right: rightPanel.left; anchors.rightMargin: 40 * s
        visible: lockScreenUi.currentTab === "MEMBERS"
        z: 20

        Column {
            anchors.fill: parent; spacing: 14 * s
            Text {
                text: "FUTURE GADGET LABORATORY // OFFICIAL ROSTER"
                font.family: lockScreenUi.fontMono; font.pixelSize: 14 * s; font.bold: true
                color: lockScreenUi.sgAntiqueBrass; font.letterSpacing: 2 * s
            }

            Grid {
                width: parent.width; columns: 2; spacing: 12 * s
                Repeater {
                    model: [
                        { no: "001", name: "OKABE RINTARO", alias: "Hououin Kyouma (Founder)", col: lockScreenUi.sgAntiqueBrass },
                        { no: "002", name: "SHIINA MAYURI", alias: "Mayushii (Hostage)", col: lockScreenUi.sgMayuriMauve },
                        { no: "003", name: "HASHIDA ITARU", alias: "Daru (Super Hacka)", col: lockScreenUi.sgMayuriBlue },
                        { no: "004", name: "MAKISE KURISU", alias: "Christina / Assistant", col: lockScreenUi.sgKurisuAuburn },
                        { no: "005", name: "KIRYU MOEKA", alias: "Shining Finger", col: lockScreenUi.sgParchmentDim },
                        { no: "006", name: "URUSHIBARA RUKA", alias: "Samidare Blade", col: lockScreenUi.sgParchmentDim },
                        { no: "007", name: "AKIHA RUMIHO", alias: "Faris NyanNyan", col: lockScreenUi.sgParchmentDim },
                        { no: "008", name: "AMANE SUZUHA", alias: "John Titor / Part-Timer", col: lockScreenUi.sgAntiqueBrass }
                    ]
                    Rectangle {
                        width: (membersView.width - 12 * s) / 2; height: 60 * s
                        color: lockScreenUi.sgCardBg; border.color: lockScreenUi.sgBorderIron; border.width: 1

                        Row {
                            anchors.fill: parent; anchors.margins: 10 * s; spacing: 12 * s
                            Rectangle {
                                width: 36 * s; height: 36 * s; color: "#191512"
                                border.color: modelData.col; border.width: 1
                                Text { anchors.centerIn: parent; text: modelData.no; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; font.bold: true; color: modelData.col }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter; spacing: 2 * s
                                Text { text: modelData.name; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; font.bold: true; color: lockScreenUi.sgParchmentLight }
                                Text { text: modelData.alias; font.family: lockScreenUi.fontMono; font.pixelSize: 9 * s; color: lockScreenUi.sgParchmentDim }
                            }
                        }
                    }
                }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 📊 TAB 4: HARDWARE DIAGNOSTICS VIEW
    // ═════════════════════════════════════════════════════════════════════════
    Item {
        id: hardwareView
        anchors.left: parent.left; anchors.leftMargin: 50 * s
        anchors.top: topHeaderBar.bottom; anchors.topMargin: 30 * s
        anchors.bottom: botBar.top; anchors.bottomMargin: 30 * s
        anchors.right: rightPanel.left; anchors.rightMargin: 40 * s
        visible: lockScreenUi.currentTab === "HARDWARE"
        z: 20

        Column {
            anchors.fill: parent; spacing: 14 * s
            Text {
                text: "SYSTEM HARDWARE & TELEMETRY DIAGNOSTICS"
                font.family: lockScreenUi.fontMono; font.pixelSize: 14 * s; font.bold: true
                color: lockScreenUi.sgAntiqueBrass; font.letterSpacing: 2 * s
            }

            Rectangle {
                width: parent.width; height: 320 * s
                color: lockScreenUi.sgCardBg; border.color: lockScreenUi.sgBorderIron; border.width: 1
                Column {
                    anchors.fill: parent; anchors.margins: 18 * s; spacing: 10 * s
                    Row { spacing: 10 * s; Text { text: "DEVICE MODEL:"; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; color: lockScreenUi.sgAntiqueBrass; width: 140 * s } Text { text: "LENOVO Legion Pro 7 16IRX8H"; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; color: lockScreenUi.sgParchmentLight } }
                    Row { spacing: 10 * s; Text { text: "COMPOSITOR:"; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; color: lockScreenUi.sgAntiqueBrass; width: 140 * s } Text { text: "KDE Plasma 6.6.6 (Wayland)"; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; color: lockScreenUi.sgParchmentLight } }
                    Row { spacing: 10 * s; Text { text: "AUTHENTICATION:"; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; color: lockScreenUi.sgAntiqueBrass; width: 140 * s } Text { text: "Linux-PAM ScreenLocker Armed"; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; color: lockScreenUi.sgSuccessGreen } }
                    Row { spacing: 10 * s; Text { text: "BATTERY LEVEL:"; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; color: lockScreenUi.sgAntiqueBrass; width: 140 * s } Text { text: lockScreenUi.batteryPct + " (" + lockScreenUi.batteryStatus + ")"; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; color: lockScreenUi.sgParchmentLight } }
                    Row { spacing: 10 * s; Text { text: "MEMORY USAGE:"; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; color: lockScreenUi.sgAntiqueBrass; width: 140 * s } Text { text: lockScreenUi.memUsageText; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; color: lockScreenUi.sgParchmentLight } }
                    Row { spacing: 10 * s; Text { text: "UPTIME:"; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; color: lockScreenUi.sgAntiqueBrass; width: 140 * s } Text { text: lockScreenUi.uptimeText; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; color: lockScreenUi.sgParchmentLight } }
                }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 💻 RIGHT SIDE: FUTURE GADGET LAB RETRO TERMINAL & LOGIN
    // ═════════════════════════════════════════════════════════════════════════
    Item {
        id: rightPanel
        anchors.top: topHeaderBar.bottom; anchors.topMargin: 24 * s
        anchors.bottom: botBar.top; anchors.bottomMargin: 20 * s
        anchors.right: parent.right; anchors.rightMargin: 70 * s
        width: 350 * s
        z: 30

        Column {
            anchors.top: parent.top; anchors.topMargin: 20 * s
            anchors.left: parent.left; anchors.right: parent.right
            spacing: 16 * s

            // Directive Block
            Rectangle {
                width: parent.width; height: 114 * s
                color: lockScreenUi.sgCardBg
                border.color: lockScreenUi.sgBorderIron; border.width: 1

                Rectangle {
                    width: parent.width; height: 24 * s; color: lockScreenUi.sgCardDarker
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 12 * s; anchors.verticalCenter: parent.verticalCenter
                        text: "LAB DIRECTIVE // FG-LAB"; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s
                        color: lockScreenUi.sgAntiqueBrass; font.bold: true
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 12 * s; anchors.verticalCenter: parent.verticalCenter
                        text: "IBN 5100 PROTOCOL"; font.family: lockScreenUi.fontMono; font.pixelSize: 9 * s
                        color: lockScreenUi.sgParchmentDim
                    }
                }

                Column {
                    anchors.top: parent.top; anchors.topMargin: 30 * s
                    anchors.left: parent.left; anchors.leftMargin: 14 * s
                    anchors.right: parent.right; anchors.rightMargin: 14 * s
                    spacing: 4 * s

                    Text { text: "OPERATOR: L41N-PR0T0 (ACTIVE)"; font.family: lockScreenUi.fontMono; font.pixelSize: 9 * s; color: lockScreenUi.sgAntiqueBrass; font.bold: true }
                    Text { width: parent.width; text: "Terminal is secured by PAM. Enter lab passphrase and press ENTER to proceed."; font.family: lockScreenUi.fontMono; font.pixelSize: 9 * s; color: lockScreenUi.sgParchmentDim; wrapMode: Text.WordWrap }
                    Text { text: "UPTIME: " + lockScreenUi.uptimeText; font.family: lockScreenUi.fontMono; font.pixelSize: 9 * s; color: lockScreenUi.sgParchmentLight; font.bold: true }
                }
            }

            // Passphrase Box
            Rectangle {
                id: authBox
                width: parent.width; height: 92 * s
                color: lockScreenUi.sgCardBg
                border.color: lockScreenUi.sgBorderIron; border.width: 1

                Rectangle {
                    id: authHdr; width: parent.width; height: 24 * s; color: lockScreenUi.sgCardDarker
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 12 * s; anchors.verticalCenter: parent.verticalCenter
                        text: "PAM Passphrase"; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s
                        color: lockScreenUi.sgAntiqueBrass; font.bold: true
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 10 * s; anchors.verticalCenter: parent.verticalCenter
                        text: capsLockState.active ? "⚠️ CAPS LOCK ON" : ""
                        font.family: lockScreenUi.fontMono; font.pixelSize: 9 * s; font.bold: true; color: lockScreenUi.sgNixieAmber
                    }
                }

                Rectangle {
                    anchors.top: authHdr.bottom; anchors.topMargin: 10 * s
                    anchors.left: parent.left; anchors.leftMargin: 12 * s
                    anchors.right: parent.right; anchors.rightMargin: 12 * s
                    height: 34 * s
                    color: "#14110e"
                    border.color: pwInput.activeFocus ? lockScreenUi.sgAntiqueBrass : lockScreenUi.sgBorderIron
                    border.width: 1

                    TextInput {
                        id: pwInput
                        anchors.fill: parent; anchors.leftMargin: 10 * s; anchors.rightMargin: 68 * s
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: lockScreenUi.fontMono; font.pixelSize: 14 * s
                        color: lockScreenUi.sgParchmentLight
                        echoMode: lockScreenUi.showPassword ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "*"
                        focus: true; clip: true
                        selectionColor: lockScreenUi.sgAntiqueBrass
                        font.letterSpacing: lockScreenUi.showPassword ? 1 * s : 4 * s

                        Text {
                            text: "Enter Passphrase..."; opacity: parent.text.length === 0 ? 1 : 0
                            color: lockScreenUi.sgParchmentFaint; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s
                            font.letterSpacing: 1 * s; anchors.verticalCenter: parent.verticalCenter
                        }

                        onActiveFocusChanged: {
                            if (activeFocus && typeof authenticator !== "undefined" && authenticator.state === 0) {
                                authenticator.startAuthenticating()
                            }
                        }
                        onTextEdited: {
                            errText.text = ""
                            lockScreenUi.authStatusState = "IDLE"
                            lockScreenUi.pendingPassword = ""
                            if (typeof authenticator !== "undefined" && authenticator.state === 0) {
                                authenticator.startAuthenticating()
                            }
                        }
                        onAccepted: lockScreenUi.doUnlock()
                        Keys.onReturnPressed: lockScreenUi.doUnlock()
                        Keys.onEnterPressed: lockScreenUi.doUnlock()
                    }

                    // Show Password Eye Toggle
                    Rectangle {
                        anchors.right: connectBtn.left; anchors.rightMargin: 4 * s; anchors.verticalCenter: parent.verticalCenter
                        width: 26 * s; height: 26 * s; color: eyeMa.pressed ? "#2b231c" : "#1e1814"
                        border.color: lockScreenUi.sgBorderIron; border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: lockScreenUi.showPassword ? "👁" : "🔒"
                            font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s
                            color: lockScreenUi.showPassword ? lockScreenUi.sgAntiqueBrass : lockScreenUi.sgParchmentDim
                        }
                        MouseArea {
                            id: eyeMa; anchors.fill: parent
                            onClicked: { lockScreenUi.showPassword = !lockScreenUi.showPassword; pwInput.forceActiveFocus() }
                        }
                    }

                    // CONNECT Tactile Button
                    Rectangle {
                        id: connectBtn
                        anchors.right: parent.right; anchors.rightMargin: 3 * s; anchors.verticalCenter: parent.verticalCenter
                        width: 32 * s; height: 28 * s
                        color: conMa.pressed ? "#8f7445" : conMa.containsMouse ? "#c4a255" : "#2a221b"
                        border.color: lockScreenUi.sgAntiqueBrass; border.width: 1

                        Text {
                            anchors.centerIn: parent; text: "⚙"
                            font.family: lockScreenUi.fontMono; font.pixelSize: 12 * s
                            color: conMa.containsMouse ? "#120f0c" : lockScreenUi.sgAntiqueBrass
                        }
                        MouseArea {
                            id: conMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: lockScreenUi.doUnlock()
                        }
                    }
                }

                Text {
                    id: errText
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 3 * s
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: ""; color: lockScreenUi.sgErrRed
                    font.family: lockScreenUi.fontMono; font.pixelSize: 8.5 * s; font.letterSpacing: 1.5 * s; font.bold: true
                }
            }

            // Power Management Grid
            Grid {
                width: parent.width; columns: 2; spacing: 8 * s
                Repeater {
                    model: [
                        { label: "Suspend", icon: "☾", action: "suspend" },
                        { label: "Reboot", icon: "↻", action: "reboot" },
                        { label: "Shut Down", icon: "⏻", action: "off" },
                        { label: "Hibernate", icon: "❄", action: "hibernate" }
                    ]
                    Rectangle {
                        width: (parent.width - 8 * s) / 2; height: 32 * s
                        color: pBtnMa.pressed ? "#362c23" : pBtnMa.containsMouse ? "#2a221b" : lockScreenUi.sgCardBg
                        border.color: pBtnMa.containsMouse ? lockScreenUi.sgAntiqueBrass : lockScreenUi.sgBorderIron
                        border.width: 1

                        Row {
                            anchors.centerIn: parent; spacing: 6 * s
                            Text { text: modelData.icon; font.family: lockScreenUi.fontMono; font.pixelSize: 11 * s; color: lockScreenUi.sgAntiqueBrass }
                            Text { text: modelData.label; font.family: lockScreenUi.fontMono; font.pixelSize: 9 * s; color: lockScreenUi.sgParchmentLight; font.bold: true }
                        }
                        MouseArea {
                            id: pBtnMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                if (modelData.action === "suspend") {
                                    sessionManagement.suspend()
                                } else if (modelData.action === "reboot") {
                                    sessionManagement.requestReboot(SessionManagement.ConfirmationMode ? SessionManagement.ConfirmationMode.Skip : undefined)
                                } else if (modelData.action === "off") {
                                    sessionManagement.requestShutdown(SessionManagement.ConfirmationMode ? SessionManagement.ConfirmationMode.Skip : undefined)
                                } else if (modelData.action === "hibernate") {
                                    sessionManagement.hibernate()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 📜 BOTTOM BAR: STATUS, MESSAGES & KEYBOARD HINTS
    // ═════════════════════════════════════════════════════════════════════════
    Rectangle {
        id: botBar
        width: parent.width; height: 34 * s
        anchors.bottom: parent.bottom
        color: lockScreenUi.sgCardBg
        border.color: lockScreenUi.sgBorderIron; border.width: 1
        z: 100

        Text {
            id: botStatusMsg
            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 24 * s
            text: (capsLockState && capsLockState.active) ? "⚠️ WARNING: CAPS LOCK IS ACTIVE!" : (lockScreenUi.authStatusState === "SUCCESS" ? "OPERATION SKULD // ACCESS GRANTED // WELCOME" : "EL PSY KONGROO // FUTURE GADGET LAB SECURITY INTERFACE")
            font.family: lockScreenUi.fontMono; font.pixelSize: 9.5 * s; font.letterSpacing: 1 * s
            font.bold: Boolean(lockScreenUi.authStatusState === "SUCCESS" || (capsLockState && capsLockState.active))
            color: lockScreenUi.authStatusState === "SUCCESS" ? lockScreenUi.sgSuccessGreen : ((capsLockState && capsLockState.active) ? lockScreenUi.sgNixieAmber : lockScreenUi.sgParchmentDim)
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 24 * s; spacing: 14 * s
            Repeater {
                model: [
                    { k: "Enter",   l: "Unlock Session" },
                    { k: "Esc",     l: "Clear / Return" },
                    { k: "Alt+P",   l: "Toggle Pass" },
                    { k: "Alt+1..4",l: "Tabs" }
                ]
                Row {
                    spacing: 5 * s; anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        height: 16 * s; width: chip.implicitWidth + 8 * s
                        color: "#161311"; border.color: lockScreenUi.sgBorderIron; border.width: 1
                        Text { id: chip; anchors.centerIn: parent; text: modelData.k; font.family: lockScreenUi.fontMono; font.pixelSize: 8.5 * s; color: lockScreenUi.sgAntiqueBrass }
                    }
                    Text { text: modelData.l; font.family: lockScreenUi.fontMono; font.pixelSize: 9 * s; color: lockScreenUi.sgParchmentDim; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }
}
