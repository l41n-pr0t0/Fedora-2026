/*
    ORV Dokkaebi Hologram Cyberpunk Practical HUD for SDDM Greeter
    Authored for l41n-pr0t0
    Chassis: LENOVO Legion Pro 7 16IRX8H (82WQ)
    Theme: ORV Dokkaebi Hologram (Electric Cyan #00d4ff + Azure Blue + Pure White)
*/
import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

Rectangle {
    // Wayland Cursor Fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }
    
    id: root
    width:  Screen.width
    height: Screen.height
    color:  "#070b12"

    // Dynamic UI Scale
    property real uiScale: (typeof config !== "undefined" && config.scale !== undefined && parseFloat(config.scale) > 0)
                           ? parseFloat(config.scale) : 0.90
    readonly property real s: (Screen.height / 768) * uiScale

    // Active Navigation Tab: "LOGIN", "HARDWARE", "NETWORK", "DISPLAY", "DIAGS", "SHORTCUTS"
    property string currentTab: "LOGIN"

    // ── VIBRANT ORV DOKKAEBI HOLOGRAM PALETTE ────────────────────────────────
    readonly property color orvBg:         "#070b12"
    readonly property color orvCardBg:     "#0b111c"
    readonly property color orvDarker:     "#05080e"
    readonly property color orvBorder:     "#1e3a5f"
    readonly property color orvBorderGlow: "#00d4ff"
    readonly property color orvAccent:     "#00d4ff"
    readonly property color orvAzure:      "#3b82f6"
    readonly property color orvText:       "#f8fafc"
    readonly property color orvTextMid:    "#94a3b8"
    readonly property color orvSelected:   "#132a4a"
    readonly property color orvSuccess:    "#10b981"
    readonly property color orvWarning:    "#f59e0b"

    // Aliases for compatibility
    readonly property color nierBg:        orvBg
    readonly property color nierDarker:    orvDarker
    readonly property color nierBorder:    orvBorder
    readonly property color nierAccent:    orvAccent
    readonly property color nierText:      orvText
    property color nierDark:       orvCardBg
    property color nierTextMid:    orvTextMid
    property color nierSelected:   orvSelected

    // Quickshell
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined

    // Effect
    property real scanPos: 0
    NumberAnimation {
        target: root; property: "scanPos"; from: 0; to: 1; duration: 3500; loops: Animation.Infinite; running: true
    }

    property real  uiOpacity:    0
    property real  panelOffset:  40 * s
    property real  brandReveal:  0
    
    property int   sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0)
                                 ? sessionModel.lastIndex : 0
    property string currentTime: Qt.formatTime(new Date(), "hh:mm")
    property string currentDate: Qt.formatDate(new Date(), "yyyy.MM.dd")

    // Practical Password Visibility & Caps Lock
    property bool showPassword: false

    // Real Hardware & Telemetry Data
    property string batteryPct: "80%"
    property string batteryStatus: "AC ONLINE"
    property bool   isAcOnline: true
    property string memUsageText: "4.2 GB / 31.1 GB"
    property real   memPercent: 0.14
    property string uptimeText: "0h 18m"
    property string loadAvgText: "1.24, 1.45, 1.10"
    property int    uptimeSeconds: 1080

    TextConstants { id: textConstants }
    
    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader { id: nierFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }

    // Shared font name string
    readonly property string fontName: "JetBrainsMono Nerd Font"

    // Auto-focus fix
    Timer { interval: 300; running: true; onTriggered: pwInput.forceActiveFocus() }
    Component.onCompleted: keyboard.numLock = true

    // Real-time clock & telemetry updater
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            root.currentTime = Qt.formatTime(new Date(), "hh:mm")
            root.currentDate = Qt.formatDate(new Date(), "yyyy.MM.dd")
            root.uptimeSeconds += 1
            var hrs = Math.floor(root.uptimeSeconds / 3600)
            var mins = Math.floor((root.uptimeSeconds % 3600) / 60)
            var secs = root.uptimeSeconds % 60
            root.uptimeText = hrs + "h " + (mins < 10 ? "0" : "") + mins + "m " + (secs < 10 ? "0" : "") + secs + "s"
            fetchTelemetry()
        }
    }

    function fetchTelemetry() {
        var xhrBat = new XMLHttpRequest()
        xhrBat.open("GET", "file:///sys/class/power_supply/BAT0/capacity")
        xhrBat.onreadystatechange = function() {
            if (xhrBat.readyState === XMLHttpRequest.DONE && xhrBat.responseText) {
                var val = xhrBat.responseText.trim()
                if (val.length > 0) root.batteryPct = val + "%"
            }
        }
        xhrBat.send()

        var xhrAc = new XMLHttpRequest()
        xhrAc.open("GET", "file:///sys/class/power_supply/ADP0/online")
        xhrAc.onreadystatechange = function() {
            if (xhrAc.readyState === XMLHttpRequest.DONE && xhrAc.responseText) {
                var isOnline = xhrAc.responseText.trim() === "1"
                root.isAcOnline = isOnline
                root.batteryStatus = isOnline ? "AC ONLINE" : "BATTERY"
            }
        }
        xhrAc.send()

        var xhrMem = new XMLHttpRequest()
        xhrMem.open("GET", "file:///proc/meminfo")
        xhrMem.onreadystatechange = function() {
            if (xhrMem.readyState === XMLHttpRequest.DONE && xhrMem.responseText) {
                var lines = xhrMem.responseText.split("\n")
                var total = 0, avail = 0
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].indexOf("MemTotal:") === 0) total = parseInt(lines[i].replace(/[^0-9]/g, ""))
                    if (lines[i].indexOf("MemAvailable:") === 0) avail = parseInt(lines[i].replace(/[^0-9]/g, ""))
                }
                if (total > 0) {
                    var used = total - avail
                    var usedGB = (used / 1048576).toFixed(1)
                    var totalGB = (total / 1048576).toFixed(1)
                    root.memUsageText = usedGB + " GB / " + totalGB + " GB"
                    root.memPercent = used / total
                }
            }
        }
        xhrMem.send()

        var xhrLoad = new XMLHttpRequest()
        xhrLoad.open("GET", "file:///proc/loadavg")
        xhrLoad.onreadystatechange = function() {
            if (xhrLoad.readyState === XMLHttpRequest.DONE && xhrLoad.responseText) {
                var parts = xhrLoad.responseText.trim().split(" ")
                if (parts.length >= 3) {
                    root.loadAvgText = parts[0] + ", " + parts[1] + ", " + parts[2]
                }
            }
        }
        xhrLoad.send()
    }

    ListView {
        id: sessionHelper
        model: typeof sessionModel !== "undefined" ? sessionModel : null; currentIndex: root.sessionIndex
        visible: false; width: 0; height: 0
        delegate: Item { property string sName: model.name || "" }
    }

    function switchTab(tabName) {
        if (root.currentTab === tabName) return;
        glitchAnim.restart()
        root.currentTab = tabName
        if (tabName === "LOGIN") {
            loginFocusTimer.restart()
        }
    }

    Timer {
        id: loginFocusTimer
        interval: 120; repeat: false
        onTriggered: pwInput.forceActiveFocus()
    }

    Item {
        focus: true
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true
                root.switchTab("LOGIN")
            } else if (event.modifiers & Qt.AltModifier) {
                if (event.key === Qt.Key_1) { event.accepted = true; root.switchTab("LOGIN") }
                else if (event.key === Qt.Key_2) { event.accepted = true; root.switchTab("HARDWARE") }
                else if (event.key === Qt.Key_3) { event.accepted = true; root.switchTab("NETWORK") }
                else if (event.key === Qt.Key_4) { event.accepted = true; root.switchTab("DISPLAY") }
                else if (event.key === Qt.Key_5) { event.accepted = true; root.switchTab("DIAGS") }
                else if (event.key === Qt.Key_6) { event.accepted = true; root.switchTab("SHORTCUTS") }
                else if (event.key === Qt.Key_P) { event.accepted = true; root.showPassword = !root.showPassword }
            }
        }
    }

    // ── CRYSTAL-CLEAR VIDEO BACKGROUND ────────────────────────────────────────
    Item {
        anchors.fill: parent

        Loader {
            id: bgLoader
            anchors.fill: parent
            source: "BackgroundVideo.qml"
        }

        Canvas {
            anchors.fill: parent; opacity: 0.08
            onPaint: {
                var ctx = getContext("2d"); ctx.strokeStyle = "#00d4ff"; ctx.lineWidth = 1;
                var step = 40 * s
                for (var x = 0; x < width; x += step) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke(); }
                for (var y = 0; y < height; y += step) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke(); }
            }
        }

        // Sweeping Global Scanner Beam
        Rectangle {
            width: parent.width; height: 1.5 * s
            color: root.orvAccent; opacity: 0.35
            y: root.scanPos * parent.height
        }

        Canvas {
            anchors.fill: parent; opacity: 0.04
            onPaint: {
                var ctx = getContext("2d"); ctx.strokeStyle = "#00d4ff"; ctx.lineWidth = 1;
                for (var y = 0; y < height; y += 4 * s) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke(); }
            }
        }
    }

    // Decorative Left Line
    Rectangle {
        anchors.left: parent.left; anchors.leftMargin: 20 * s
        anchors.top: topBar.bottom; anchors.bottom: botBar.top
        width: 1; color: root.orvBorder; opacity: 0.4
    }

    // ── TOP HEADER BAR ───────────────────────────────────────────────────────
    Rectangle {
        id: topBar
        width: parent.width; height: 40 * s
        color: "#080d16"
        opacity: 0.96
        z: 100
        border.color: root.orvBorder; border.width: 1

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height); ctx.fillStyle = "#1e3a5f"
                var step = 10 * s; var count = Math.floor(width / step); var triSize = 3 * s
                for (var i = 0; i < count; i++) {
                    var x = i * step + 2 * s
                    ctx.beginPath(); ctx.moveTo(x, 5 * s); ctx.lineTo(x + triSize, 5 * s); ctx.lineTo(x + triSize/2, 5 * s + triSize); ctx.fill()
                    ctx.beginPath(); ctx.moveTo(x, 35 * s); ctx.lineTo(x + triSize, 35 * s); ctx.lineTo(x + triSize/2, 35 * s - triSize); ctx.fill()
                }
            }
        }

        // 6 Focused Tabs
        Row {
            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10 * s; spacing: 0
            Repeater {
                model: [
                    { name: "LOGIN",     icon: "◈" },
                    { name: "HARDWARE",  icon: "⚙" },
                    { name: "NETWORK",   icon: "📶" },
                    { name: "DISPLAY",   icon: "🎛" },
                    { name: "DIAGS",     icon: "📋" },
                    { name: "SHORTCUTS", icon: "⌨" }
                ]
                Rectangle {
                    id: tabBtn
                    property bool isActive: modelData.name === root.currentTab
                    property bool hovered: tMa.containsMouse
                    width: tabContent.implicitWidth + 24 * s; height: topBar.height
                    color: isActive ? root.orvSelected : (hovered ? "#0e1d32" : "transparent")
                    border.color: isActive ? root.orvAccent : (hovered ? root.orvBorder : "transparent")
                    border.width: (isActive || hovered) ? 1 : 0
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 2 * s
                        color: root.orvAccent; visible: isActive
                    }

                    Row {
                        id: tabContent; anchors.centerIn: parent; spacing: 6 * s
                        Text { text: modelData.icon; font.family: root.fontName; font.pixelSize: 9 * s; color: (isActive || hovered) ? root.orvAccent : root.orvTextMid; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData.name; font.family: root.fontName; font.pixelSize: 10 * s; font.letterSpacing: 2 * s; font.bold: isActive; color: (isActive || hovered) ? root.orvAccent : root.orvTextMid }
                    }
                    MouseArea {
                        id: tMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.switchTab(modelData.name)
                    }
                }
            }
        }

        // Top Right Live Badges
        Row {
            anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 16 * s; spacing: 16 * s
            Row {
                spacing: 5 * s; anchors.verticalCenter: parent.verticalCenter
                Text { text: "NODE:"; font.family: root.fontName; font.pixelSize: 8 * s; color: root.orvTextMid }
                Text { text: "wired_navi0x17"; font.family: root.fontName; font.pixelSize: 8 * s; color: root.orvAccent; font.bold: true; font.letterSpacing: 1 }
            }
            Row {
                spacing: 4 * s; anchors.verticalCenter: parent.verticalCenter
                Text { text: root.isAcOnline ? "⚡" : "🔋"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.isAcOnline ? root.orvSuccess : root.orvAccent }
                Text { text: root.batteryPct + " (" + root.batteryStatus + ")"; font.family: root.fontName; font.pixelSize: 8 * s; color: root.orvText; font.bold: true }
            }
            Row {
                spacing: 4 * s; anchors.verticalCenter: parent.verticalCenter
                Text { text: "MEM:"; font.family: root.fontName; font.pixelSize: 8 * s; color: root.orvTextMid }
                Text { text: root.memUsageText; font.family: root.fontName; font.pixelSize: 8 * s; color: root.orvAccent; font.bold: true }
            }
        }
    }

    // ── BOTTOM STATUS BAR ────────────────────────────────────────────────────
    Rectangle {
        id: botBar
        width: parent.width; height: 34 * s; anchors.bottom: parent.bottom; color: "#080d16"; opacity: 0.96; z: 100
        border.color: root.orvBorder; border.width: 1

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height); ctx.fillStyle = "#1e3a5f"
                var step = 10 * s; var count = Math.floor(width / step); var triSize = 3 * s
                for (var i = 0; i < count; i++) {
                    var x = i * step + 2 * s
                    ctx.beginPath(); ctx.moveTo(x, 3 * s); ctx.lineTo(x + triSize, 3 * s); ctx.lineTo(x + triSize/2, 3 * s + triSize); ctx.fill()
                    ctx.beginPath(); ctx.moveTo(x, 31 * s); ctx.lineTo(x + triSize, 31 * s); ctx.lineTo(x + triSize/2, 31 * s - triSize); ctx.fill()
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 14 * s
            text: root.currentTab === "LOGIN" 
                  ? (keyboard.capsLock ? "⚠️ WARNING: CAPS LOCK IS ON!" : "Enter passphrase to proceed. Press Alt+P to reveal passphrase.")
                  : ("Dokkaebi System Interface // VIEW: [" + root.currentTab + "]")
            font.family: root.fontName; font.pixelSize: 10 * s; font.letterSpacing: 0.5
            color: (root.currentTab === "LOGIN" && keyboard.capsLock) ? root.orvWarning : root.orvText
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 14 * s; spacing: 10 * s
            Repeater {
                model: root.currentTab === "LOGIN" ? [
                    { k: "↑↓",      l: "User" },
                    { k: "Enter",   l: "Login" },
                    { k: "Tab",     l: "Session" },
                    { k: "Alt+P",   l: "Show Pass" },
                    { k: "Alt+1..6",l: "Tools" }
                ] : [
                    { k: "Esc",     l: "Login" },
                    { k: "Alt+1..6",l: "Switch" }
                ]
                Row {
                    spacing: 4 * s; anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        height: 15 * s; width: chip.implicitWidth + 8 * s; color: "#0f172a"; border.color: root.orvBorder; border.width: 1
                        Text { id: chip; anchors.centerIn: parent; text: modelData.k; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvAccent }
                    }
                    Text { text: modelData.l; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvTextMid; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }

    // ── GLITCH OVERLAY ────────────────────────────────────────────────────────
    Rectangle {
        id: glitchOverlay
        anchors.fill: parent; color: root.orvAccent; opacity: 0; z: 999; visible: opacity > 0
        Canvas {
            id: glitchCanvas; anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height); ctx.fillStyle = "rgba(0, 212, 255, 0.25)"
                for (var i = 0; i < 18; i++) {
                    var y = Math.random() * height; var h = Math.random() * 10 * s + 2 * s; ctx.fillRect(0, y, width, h)
                }
            }
        }
    }

    SequentialAnimation {
        id: glitchAnim
        ScriptAction { script: glitchCanvas.requestPaint() }
        PropertyAnimation { target: glitchOverlay; property: "opacity"; from: 0; to: 0.3; duration: 35 }
        PropertyAnimation { target: glitchOverlay; property: "opacity"; from: 0.3; to: 0.05; duration: 35 }
        ScriptAction { script: glitchCanvas.requestPaint() }
        PropertyAnimation { target: glitchOverlay; property: "opacity"; from: 0.05; to: 0.2; duration: 35 }
        PropertyAnimation { target: glitchOverlay; property: "opacity"; from: 0.2; to: 0; duration: 50 }
    }

    // ── MAIN CONTENT CONTAINER ───────────────────────────────────────────────
    Item {
        id: ui
        anchors.top:    topBar.bottom
        anchors.bottom: botBar.top
        anchors.left:   parent.left
        anchors.right:  parent.right
        opacity: root.uiOpacity

        Component.onCompleted: SequentialAnimation {
            PauseAnimation  { duration: 400 }
            ParallelAnimation {
                NumberAnimation { target: root; property: "uiOpacity"; from: 0; to: 1; duration: 1200; easing.type: Easing.OutExpo }
                NumberAnimation { target: root; property: "panelOffset"; from: 60 * s; to: 0; duration: 1400; easing.type: Easing.OutExpo }
                NumberAnimation { target: root; property: "brandReveal"; from: 0; to: 1; duration: 1800; easing.type: Easing.OutQuart }
            }
            ScriptAction { script: missionTypewriter.start() }
        }

        // ═════════════════════════════════════════════════════════════════════════
        // 1. LOGIN VIEW (WITH MERGED POWER ACTIONS)
        // ═════════════════════════════════════════════════════════════════════════
        Item {
            id: loginView
            anchors.fill: parent
            visible: root.currentTab === "LOGIN"

            // ── LEFT COLUMN ──────────────────────────────────────────────────
            Item {
                id: leftPanel
                anchors.top:    parent.top;    anchors.topMargin:    20 * s
                anchors.bottom: parent.bottom; anchors.bottomMargin: 24 * s
                anchors.left:   parent.left;   anchors.leftMargin:   70 * s - root.panelOffset
                width: 330 * s; opacity: root.uiOpacity

                Item {
                    id: heading; width: parent.width; height: 62 * s
                    Text {
                        text: "LOGIN"
                        font.family: root.fontName; font.pixelSize: 32 * s; font.letterSpacing: 4 * s; font.bold: true; color: root.orvAccent
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 1 * s
                    }
                    Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: root.orvBorder }
                }

                // User list
                ListView {
                    id: userList
                    anchors.top: heading.bottom; anchors.topMargin: 12 * s
                    anchors.bottom: missionBlock.top; anchors.bottomMargin: 24 * s
                    anchors.left: parent.left; anchors.right: parent.right
                    model: typeof userModel !== "undefined" ? userModel : null
                    currentIndex: typeof userModel !== "undefined" ? userModel.lastIndex : 0
                    clip: true; spacing: 0; focus: true
                    keyNavigationEnabled: true

                    delegate: Item {
                        id: rowItem
                        width: userList.width; height: 42 * s
                        property bool sel: userList.currentIndex === index
                        property bool hovered: rowMa.containsMouse

                        Item {
                            anchors.fill: parent
                            x: (rowItem.sel || rowItem.hovered) ? 4 * s : 0
                            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

                            Rectangle {
                                anchors.fill: parent
                                color: rowItem.sel ? root.orvSelected : (rowItem.hovered ? "#0e1d32" : "transparent")
                                border.color: rowItem.sel ? root.orvAccent : (rowItem.hovered ? root.orvBorder : "transparent")
                                border.width: (rowItem.sel || rowItem.hovered) ? 1 : 0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    text: rowItem.sel ? "◈" : "⊙"
                                    font.family: root.fontName; font.pixelSize: 11 * s
                                    color: (rowItem.sel || rowItem.hovered) ? root.orvAccent : root.orvTextMid
                                    anchors.verticalCenter: parent.verticalCenter; x: 14 * s
                                }

                                Text {
                                    text: (model.realName || model.name).toUpperCase()
                                    font.family: root.fontName; font.pixelSize: 14 * s; font.letterSpacing: 0.8
                                    color: (rowItem.sel || rowItem.hovered) ? root.orvText : root.orvTextMid
                                    font.bold: rowItem.sel
                                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 36 * s
                                }

                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.orvBorder; opacity: 0.3 }
                            }
                        }

                        MouseArea {
                            id: rowMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: { userList.currentIndex = index; pwInput.forceActiveFocus() }
                        }
                    }
                }

                // Bottom Left Mission Block
                Item {
                    id: missionBlock
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 14 * s
                    width: parent.width; height: 210 * s

                    Rectangle { width: parent.width; height: 1; color: root.orvBorder; opacity: 0.5; anchors.top: parent.top }

                    Column {
                        anchors.top: parent.top; anchors.topMargin: 22 * s
                        anchors.left: parent.left; anchors.right: parent.right
                        spacing: 16 * s

                        Column {
                            width: parent.width; spacing: 6 * s
                            Text { text: "DIRECTIVE: USER AUTHENTICATION"; font.family: root.fontName; font.pixelSize: 9 * s; font.letterSpacing: 1.5; color: root.orvAccent }
                            Text {
                                width: parent.width; wrapMode: Text.WordWrap
                                property string fullText: "Input authorized passphrase to unlock desktop session and initialize Plasma Wayland environment."
                                text: ""
                                font.family: root.fontName; font.pixelSize: 10 * s; color: root.orvTextMid; lineHeight: 1.4

                                Timer {
                                    id: missionTypewriter; interval: 15; repeat: true
                                    property int charIdx: 0
                                    onTriggered: {
                                        parent.text += parent.fullText[charIdx]
                                        charIdx++
                                        if (charIdx >= parent.fullText.length) stop()
                                    }
                                }
                            }
                        }

                        Column {
                            width: parent.width; spacing: 4 * s
                            Text { text: "HARDWARE TELEMETRY LINK: ONLINE"; font.family: root.fontName; font.pixelSize: 7 * s; color: root.orvTextMid }
                            Text { text: "UPTIME: " + root.uptimeText; font.family: root.fontName; font.pixelSize: 11 * s; color: root.orvSuccess; font.bold: true }
                        }
                    }
                }
            }

            // ── RIGHT COLUMN: Auth Box & Merged Power Grid ────────────────────
            Item {
                id: rightPanel
                anchors.top:    parent.top;    anchors.topMargin:    20 * s
                anchors.bottom: parent.bottom; anchors.bottomMargin: 24 * s
                anchors.right:  parent.right;  anchors.rightMargin:  70 * s - root.panelOffset
                width: 310 * s; opacity: root.uiOpacity

                Column {
                    id: interactiveGroup
                    anchors.top: parent.top; anchors.topMargin: 24 * s
                    anchors.left: parent.left; anchors.right: parent.right
                    spacing: 16 * s; z: 10

                    // Status Panel
                    Rectangle {
                        id: statusBox
                        width: parent.width; height: 140 * s
                        color: root.orvCardBg; border.color: root.orvBorder; border.width: 1
                        
                        Rectangle {
                            id: statusHdr; width: parent.width; height: 22 * s; color: "#0e1726"
                            Text { anchors.left: parent.left; anchors.leftMargin: 12 * s; anchors.verticalCenter: parent.verticalCenter; text: "System State"; font.family: root.fontName; font.pixelSize: 13 * s; font.letterSpacing: 1.5; color: root.orvAccent; font.bold: true }
                            Text { anchors.right: parent.right; anchors.rightMargin: 12 * s; anchors.verticalCenter: parent.verticalCenter; text: "Legion Pro 7"; font.family: root.fontName; font.pixelSize: 10 * s; color: root.orvTextMid }
                        }

                        Column {
                            anchors.top: statusHdr.bottom; anchors.topMargin: 8 * s; anchors.left: parent.left; anchors.leftMargin: 12 * s; anchors.right: parent.right; anchors.rightMargin: 12 * s; spacing: 0
                            Repeater {
                                model: [ 
                                    { label: "Battery", value: root.batteryPct + " (" + root.batteryStatus + ")" },
                                    { label: "Memory", value: root.memUsageText },
                                    { label: "Load Avg", value: root.loadAvgText },
                                    { label: "Display", value: "2560x1600 @ 240Hz" }
                                ]
                                Item {
                                    width: parent.width; height: 18 * s
                                    Text { text: modelData.label; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvTextMid; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: modelData.value; font.family: root.fontName; font.pixelSize: 8 * s; color: root.orvText; font.bold: true; anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right }
                                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.orvBorder; opacity: 0.3 }
                                }
                            }
                        }
                    }

                    // Authentication Panel
                    Rectangle {
                        id: authBox
                        width: parent.width; height: 86 * s
                        color: root.orvCardBg; border.color: root.orvBorder; border.width: 1
                        
                        Rectangle {
                            id: authHdr; width: parent.width; height: 24 * s; color: "#0e1726"
                            Text { anchors.left: parent.left; anchors.leftMargin: 12 * s; anchors.verticalCenter: parent.verticalCenter; text: "Authentication"; font.family: root.fontName; font.pixelSize: 12 * s; font.letterSpacing: 1.5; color: root.orvAccent; font.bold: true }
                            Text { anchors.right: parent.right; anchors.rightMargin: 10 * s; anchors.verticalCenter: parent.verticalCenter; text: keyboard.capsLock ? "⚠️ CAPS ON" : ""; font.family: root.fontName; font.pixelSize: 9 * s; font.bold: true; color: root.orvWarning }
                        }

                        Rectangle {
                            anchors.top: authHdr.bottom; anchors.topMargin: 8 * s; anchors.left: parent.left; anchors.leftMargin: 12 * s; anchors.right: parent.right; anchors.rightMargin: 12 * s; height: 32 * s
                            color: pwInput.activeFocus ? "#132742" : "#0c1524"; border.color: pwInput.activeFocus ? root.orvAccent : root.orvBorder; border.width: 1
                            
                            TextInput {
                                id: pwInput; anchors.fill: parent; anchors.leftMargin: 10 * s; anchors.rightMargin: 64 * s
                                verticalAlignment: TextInput.AlignVCenter; font.family: root.fontName; font.pixelSize: 13 * s; color: root.orvText
                                echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                                passwordCharacter: "■"; focus: true; clip: true
                                selectionColor: root.orvAccent
                                font.letterSpacing: root.showPassword ? 1 * s : 4 * s
                                
                                Text { 
                                    text: "Passphrase..."; opacity: parent.text.length === 0 ? 1 : 0
                                    color: root.orvTextMid; font.family: root.fontName; font.pixelSize: 11 * s; font.letterSpacing: 1.5 * s
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                onTextEdited: errText.text = ""
                                Keys.onPressed: function(event) { 
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) doLogin(); 
                                    else if (event.key === Qt.Key_Tab) { 
                                        event.accepted = true; 
                                        if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0) root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount(); 
                                    } else if (event.key === Qt.Key_Up) { 
                                        event.accepted = true; 
                                        userList.currentIndex = Math.max(0, userList.currentIndex - 1); 
                                    } else if (event.key === Qt.Key_Down) { 
                                        event.accepted = true; 
                                        userList.currentIndex = Math.min(userList.model.count - 1, userList.currentIndex + 1); 
                                    } 
                                }
                            }

                            // Show / Hide Password Eye Toggle Button
                            Rectangle {
                                id: showPwBtn
                                anchors.right: loginBtn.left; anchors.rightMargin: 4 * s; anchors.verticalCenter: parent.verticalCenter
                                width: 26 * s; height: 26 * s
                                color: eyeMa.pressed ? "#1e3a5f" : "#0f1b2e"; border.color: root.orvBorder; border.width: 1
                                Text { anchors.centerIn: parent; text: root.showPassword ? "👁" : "🔒"; font.family: root.fontName; font.pixelSize: 11 * s; color: root.showPassword ? root.orvAccent : root.orvTextMid }
                                MouseArea { id: eyeMa; anchors.fill: parent; hoverEnabled: true; onClicked: { root.showPassword = !root.showPassword; pwInput.forceActiveFocus() } }
                            }

                            // Login Submit Button
                            Rectangle { 
                                id: loginBtn
                                anchors.right: parent.right; anchors.rightMargin: 2 * s; anchors.verticalCenter: parent.verticalCenter; width: 28 * s; height: 28 * s
                                color: subMa.pressed ? "#0095b6" : subMa.containsMouse ? "#00d4ff" : "#132742"; border.color: root.orvAccent; border.width: 1
                                Text { anchors.centerIn: parent; text: "▶"; font.family: root.fontName; font.pixelSize: 11 * s; color: subMa.containsMouse ? "#000000" : root.orvAccent } 
                                MouseArea { id: subMa; anchors.fill: parent; hoverEnabled: true; onClicked: doLogin() } 
                            }
                        }
                        Text {
                            id: errText; anchors.bottom: parent.bottom; anchors.bottomMargin: 2 * s; anchors.horizontalCenter: parent.horizontalCenter
                            text: ""; color: "#ff4444"; font.family: root.fontName; font.pixelSize: 8 * s; font.letterSpacing: 2
                        }
                    }

                    // ── MERGED FAST POWER GRID (4 BUTTONS) ───────────────────
                    Grid {
                        width: parent.width; columns: 2; spacing: 8 * s
                        Repeater {
                            model: [
                                { label: "Suspend", icon: "☾", action: "suspend" },
                                { label: "Reboot", icon: "↻", action: "reboot" },
                                { label: "Power Off", icon: "⏻", action: "off" },
                                { label: "Hibernate", icon: "❄", action: "hibernate" }
                            ]
                            Rectangle {
                                width: (parent.width - 8 * s) / 2; height: 32 * s
                                color: pBtnMa.pressed ? "#1e3a5f" : pBtnMa.containsMouse ? "#132a4a" : root.orvCardBg
                                border.color: pBtnMa.containsMouse ? root.orvAccent : root.orvBorder; border.width: 1

                                Row {
                                    anchors.centerIn: parent; spacing: 6 * s
                                    Text { text: modelData.icon; font.family: root.fontName; font.pixelSize: 11 * s; color: root.orvAccent }
                                    Text { text: modelData.label; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText; font.bold: true }
                                }
                                MouseArea {
                                    id: pBtnMa; anchors.fill: parent; hoverEnabled: true
                                    onClicked: {
                                        if (typeof sddm !== "undefined") {
                                            if (modelData.action === "suspend") sddm.suspend()
                                            else if (modelData.action === "reboot") sddm.reboot()
                                            else if (modelData.action === "off") sddm.powerOff()
                                            else if (modelData.action === "hibernate") sddm.hibernate()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Session Selector Bar
                    Item {
                        visible: !root.isQuickshell; width: parent.width; height: 28 * s
                        Rectangle {
                            anchors.fill: parent; color: root.orvCardBg; border.color: root.orvBorder; border.width: 1
                            Row {
                                anchors.centerIn: parent; spacing: 8 * s
                                Text { text: "◆ Session:"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvTextMid }
                                Text { 
                                    text: ((typeof sessionModel !== "undefined" && sessionModel && sessionModel.count > root.sessionIndex && root.sessionIndex >= 0 && typeof sessionHelper !== "undefined" && sessionHelper.currentItem && sessionHelper.currentItem.sName) ? sessionHelper.currentItem.sName : "Plasma Wayland")
                                    font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvAccent; font.bold: true
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0) {
                                        root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── CENTER BRAND & CLOCK ─────────────────────────────────────────
            Item {
                id: centerBrand
                anchors.centerIn: parent; anchors.verticalCenterOffset: -30 * s; width: 320 * s; height: 320 * s

                Rectangle {
                    anchors.centerIn: parent; width: 300 * s; height: 300 * s; radius: width/2; color: "transparent"
                    border.color: root.orvBorder; border.width: 1; opacity: 0.25
                    Timer { interval: 50; running: true; repeat: true; onTriggered: parent.rotation += 0.2 }
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 10 * s; spacing: 2 * s
                    Text { text: "SYSTEM TIME // DATA SYNC"; font.family: root.fontName; font.pixelSize: 7 * s; color: root.orvAccent; font.letterSpacing: 1; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { id: clockMainText; anchors.horizontalCenter: parent.horizontalCenter; text: root.currentTime; font.family: root.fontName; font.pixelSize: 44 * s; font.letterSpacing: 2; color: root.orvText; font.bold: true }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.currentDate; font.family: root.fontName; font.pixelSize: 11 * s; font.letterSpacing: 4; color: root.orvAccent }
                    Item { width: 1; height: 16 * s }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "< DOKKAEBI SYSTEM >"; font.family: root.fontName; font.pixelSize: 20 * s; font.letterSpacing: 4; color: root.orvAccent; font.bold: true }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Omniscient Interface Protocol"; font.family: root.fontName; font.pixelSize: 9 * s; font.letterSpacing: 2; color: root.orvTextMid }
                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 200 * s; height: 1; color: root.orvBorder; opacity: 0.6 }
                }

                Canvas {
                    id: emblem
                    anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 8 * s; width: 110 * s; height: 110 * s
                    property real rot: 0
                    SequentialAnimation on rot { loops: Animation.Infinite; NumberAnimation { from: 0; to: 360; duration: 40000; easing.type: Easing.Linear } }
                    transform: Rotation { origin.x: emblem.width / 2; origin.y: emblem.height / 2; angle: emblem.rot }
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height); var cx = width / 2; var cy = height / 2; var r = width * 0.40
                        ctx.strokeStyle = "rgba(0, 212, 255, 0.5)"; ctx.lineWidth = 1
                        ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.stroke()
                        ctx.beginPath(); ctx.arc(cx, cy, r * 0.62, 0, Math.PI*2); ctx.stroke()
                        ctx.beginPath(); ctx.arc(cx, cy, r * 0.28, 0, Math.PI*2); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(cx - r * 1.1, cy); ctx.lineTo(cx + r * 1.1, cy); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(cx, cy - r * 1.1); ctx.lineTo(cx, cy + r * 1.1); ctx.stroke()
                        ctx.fillStyle = "rgba(0, 212, 255, 0.8)"; ctx.beginPath(); ctx.arc(cx, cy, 3, 0, Math.PI*2); ctx.fill()
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════════
        // 2. HARDWARE VIEW (ORV DOKKAEBI SYSTEM STATUS WINDOW)
        // ═════════════════════════════════════════════════════════════════════════
        Item {
            id: hwView
            anchors.fill: parent
            visible: root.currentTab === "HARDWARE"

            Item {
                id: orvCard
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.88, 760 * s)
                height: Math.min(parent.height - 24 * s, 540 * s)

                // 1. Dark translucent glass background with ORV Chamfered Geometry & Glowing Borders
                Canvas {
                    id: orvCanvas
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height); var cut = 24 * s
                        var borderCol = "#1e3a5f"; var accentCol = "#00d4ff"

                        // Outer Fill Path (Deep Void Obsidian glass)
                        ctx.fillStyle = "rgba(7, 11, 18, 0.94)"
                        ctx.beginPath()
                        ctx.moveTo(cut, 0); ctx.lineTo(width, 0); ctx.lineTo(width, height - cut); ctx.lineTo(width - cut, height); ctx.lineTo(0, height); ctx.lineTo(0, cut)
                        ctx.closePath(); ctx.fill()

                        // Outer Border Line
                        ctx.strokeStyle = accentCol; ctx.lineWidth = 1.5; ctx.stroke()

                        // Inner decorative border line
                        var pad = 4 * s
                        ctx.beginPath()
                        ctx.moveTo(cut + pad * 0.5, pad); ctx.lineTo(width - pad, pad); ctx.lineTo(width - pad, height - cut - pad * 0.5); ctx.lineTo(width - cut - pad * 0.5, height - pad); ctx.lineTo(pad, height - pad); ctx.lineTo(pad, cut + pad * 0.5)
                        ctx.closePath()
                        ctx.strokeStyle = "rgba(30, 58, 95, 0.7)"; ctx.lineWidth = 1; ctx.stroke()

                        // Bottom-Right 45° Diagonal Hatched Lines (///)
                        ctx.strokeStyle = accentCol; ctx.lineWidth = 1.5
                        for (var i = 0; i < 4; i++) {
                            var off = (i * 6 + 4) * s
                            ctx.beginPath(); ctx.moveTo(width - cut + off * 0.7, height); ctx.lineTo(width, height - cut + off * 0.7); ctx.stroke()
                        }

                        // Holographic Data-Chip Pixel Notches on Borders
                        ctx.fillStyle = accentCol
                        ctx.fillRect(80 * s, -3 * s, 14 * s, 3 * s)
                        ctx.fillRect(240 * s, -2 * s, 8 * s, 2 * s)
                        ctx.fillRect(width - 200 * s, height, 18 * s, 3 * s)
                        ctx.fillRect(-3 * s, 60 * s, 3 * s, 12 * s)
                        ctx.fillRect(-3 * s, 220 * s, 3 * s, 16 * s)
                        ctx.fillRect(width, 140 * s, 3 * s, 14 * s)
                        ctx.fillRect(width, 320 * s, 3 * s, 10 * s)
                    }
                }

                // Title Bar Row
                Item {
                    id: orvTitleBar
                    anchors.top: parent.top; anchors.topMargin: 12 * s
                    anchors.left: parent.left; anchors.leftMargin: 20 * s
                    anchors.right: parent.right; anchors.rightMargin: 16 * s
                    height: 36 * s

                    // Header Title
                    Text {
                        anchors.centerIn: parent
                        text: "< HARDWARE SPECIFICATION & ATTRIBUTES >"
                        font.family: root.fontName; font.pixelSize: 13 * s; font.bold: true; font.letterSpacing: 2 * s
                        color: root.orvAccent
                    }

                    // Top-Right Window Controls: [ — ] [ ⧉ ] [ ✕ ]
                    Row {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        spacing: 6 * s

                        Repeater {
                            model: ["—", "⧉", "✕"]
                            Rectangle {
                                width: 22 * s; height: 18 * s
                                color: wBtnMa.containsMouse ? "#132a4a" : "#0f172a"
                                border.color: wBtnMa.containsMouse ? root.orvAccent : root.orvBorder; border.width: 1

                                Text {
                                    anchors.centerIn: parent; text: modelData
                                    font.family: root.fontName; font.pixelSize: 10 * s
                                    color: wBtnMa.containsMouse ? root.orvAccent : root.orvTextMid
                                }
                                MouseArea {
                                    id: wBtnMa; anchors.fill: parent; hoverEnabled: true
                                    onClicked: {
                                        if (modelData === "✕" || modelData === "—") root.switchTab("LOGIN")
                                    }
                                }
                            }
                        }
                    }
                }

                // Decorative divider
                Rectangle {
                    id: orvDiv
                    anchors.top: orvTitleBar.bottom; anchors.topMargin: 4 * s
                    anchors.left: parent.left; anchors.leftMargin: 16 * s
                    anchors.right: parent.right; anchors.rightMargin: 16 * s
                    height: 1; color: root.orvBorder; opacity: 0.7
                }

                // Attributes Content Column
                Column {
                    anchors.top: orvDiv.bottom; anchors.topMargin: 14 * s
                    anchors.left: parent.left; anchors.leftMargin: 24 * s
                    anchors.right: parent.right; anchors.rightMargin: 24 * s
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 20 * s
                    spacing: 8 * s

                    Repeater {
                        model: [
                            { k: "HOST PLATFORM", v: "LENOVO Legion Pro 7 16IRX8H (Type 82WQ)", hl: false },
                            { k: "OPERATING SYSTEM", v: "NixOS 26.05 (x86_64) // Linux 6.18.46 (64-bit LTS)", hl: true },
                            { k: "DESKTOP RUNTIME", v: "KDE Plasma 6.6.6 // Frameworks 6.26.0 // Qt 6.11.1 (Wayland)", hl: false },
                            { k: "PRIMARY PROCESSOR", v: "32 × 13th Gen Intel® Core™ i9-13900HX (24C / 32T @ Up to 5.40 GHz)", hl: false },
                            { k: "DISCRETE GRAPHICS", v: "NVIDIA GeForce RTX 4090 Laptop GPU (16 GiB GDDR6 // 175W TGP)", hl: true },
                            { k: "INTEGRATED GRAPHICS", v: "Mesa Intel® UHD Graphics (Raptor Lake-HX GT1)", hl: false },
                            { k: "DISPLAY PANEL", v: "16.0\" 16:10 WQXGA (2560 × 1600) IPS @ 240.00 Hz (HDR 500 nits)", hl: true },
                            { k: "AUDIO SUBSYSTEM", v: "Texas Instruments TAS2781 Dual Smart-Amplifiers + PipeWire HD", hl: false },
                            { k: "POWER & BATTERY", v: root.batteryPct + " (" + root.batteryStatus + ") // 99.9 Wh Li-Ion (330W Adapter)", hl: false },
                            { k: "SYSTEM TELEMETRY", v: "Load: " + root.loadAvgText + "  |  Uptime: " + root.uptimeText, hl: false }
                        ]

                        Item {
                            width: parent.width; height: 21 * s

                            Row {
                                anchors.fill: parent; spacing: 14 * s
                                Text {
                                    width: 170 * s; text: modelData.k + " :"
                                    font.family: root.fontName; font.pixelSize: 10 * s
                                    font.bold: true; color: root.orvAccent
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    width: parent.width - 184 * s; text: modelData.v
                                    font.family: root.fontName; font.pixelSize: 10 * s
                                    color: modelData.hl ? root.orvSuccess : root.orvText
                                    font.bold: modelData.hl; elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.orvBorder; opacity: 0.3 }
                        }
                    }

                    // Live Memory Allocation Gauge Bar (Special ORV Row)
                    Item {
                        width: parent.width; height: 26 * s

                        Row {
                            anchors.fill: parent; spacing: 14 * s
                            Text {
                                width: 170 * s; text: "RAM ALLOCATION :"
                                font.family: root.fontName; font.pixelSize: 10 * s
                                font.bold: true; color: root.orvAccent
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Row {
                                spacing: 12 * s; anchors.verticalCenter: parent.verticalCenter
                                Rectangle {
                                    width: 260 * s; height: 10 * s
                                    color: "#0c1524"; border.color: root.orvBorder; border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: (parent.width - 2) * Math.min(1.0, root.memPercent)
                                        height: parent.height - 2; x: 1; y: 1
                                        color: root.orvAccent
                                    }
                                }
                                Text {
                                    text: root.memUsageText + " (DDR5 @ 5600 MT/s)"
                                    font.family: root.fontName; font.pixelSize: 10 * s
                                    color: root.orvAccent; font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════════
        // 3. NETWORK VIEW
        // ═════════════════════════════════════════════════════════════════════════
        Item {
            id: netView
            anchors.fill: parent
            visible: root.currentTab === "NETWORK"
            anchors.margins: 24 * s

            Text { id: netHdr; text: "NETWORK & CONNECTIVITY STATUS"; font.family: root.fontName; font.pixelSize: 22 * s; font.bold: true; color: root.orvAccent }
            Rectangle { anchors.top: netHdr.bottom; anchors.topMargin: 4 * s; width: parent.width; height: 1; color: root.orvBorder }

            Grid {
                anchors.top: netHdr.bottom; anchors.topMargin: 16 * s
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                columns: 2; spacing: 16 * s

                Rectangle {
                    width: (parent.width - 16 * s) / 2; height: (parent.height - 16 * s) / 2
                    color: root.orvCardBg; border.color: root.orvBorder; border.width: 1
                    Column {
                        anchors.fill: parent; anchors.margins: 14 * s; spacing: 8 * s
                        Text { text: "01 // WIRELESS INTERFACE (Wi-Fi 6E)"; font.family: root.fontName; font.pixelSize: 11 * s; color: root.orvAccent; font.bold: true }
                        Rectangle { width: parent.width; height: 1; color: root.orvBorder; opacity: 0.4 }
                        Text { text: "• Adapter: Intel Wi-Fi 6E AX211 160MHz"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                        Text { text: "• Connection State: CONNECTED / ONLINE"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvSuccess; font.bold: true }
                    }
                }

                Rectangle {
                    width: (parent.width - 16 * s) / 2; height: (parent.height - 16 * s) / 2
                    color: root.orvCardBg; border.color: root.orvBorder; border.width: 1
                    Column {
                        anchors.fill: parent; anchors.margins: 14 * s; spacing: 8 * s
                        Text { text: "02 // HOST TELEMETRY"; font.family: root.fontName; font.pixelSize: 11 * s; color: root.orvAccent; font.bold: true }
                        Rectangle { width: parent.width; height: 1; color: root.orvBorder; opacity: 0.4 }
                        Text { text: "• Hostname: wired_navi0x17"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                        Text { text: "• Subnet: 192.168.1.0/24 (DHCP Active)"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                    }
                }

                Rectangle {
                    width: (parent.width - 16 * s) / 2; height: (parent.height - 16 * s) / 2
                    color: root.orvCardBg; border.color: root.orvBorder; border.width: 1
                    Column {
                        anchors.fill: parent; anchors.margins: 14 * s; spacing: 8 * s
                        Text { text: "03 // ETHERNET & BLUETOOTH"; font.family: root.fontName; font.pixelSize: 11 * s; color: root.orvAccent; font.bold: true }
                        Rectangle { width: parent.width; height: 1; color: root.orvBorder; opacity: 0.4 }
                        Text { text: "• Bluetooth: Intel Bluetooth 5.3 Controller Enabled"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                        Text { text: "• Ethernet: Realtek 2.5GbE High-Speed LAN"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                    }
                }

                Rectangle {
                    width: (parent.width - 16 * s) / 2; height: (parent.height - 16 * s) / 2
                    color: root.orvCardBg; border.color: root.orvBorder; border.width: 1
                    Column {
                        anchors.fill: parent; anchors.margins: 14 * s; spacing: 8 * s
                        Text { text: "04 // SECURITY"; font.family: root.fontName; font.pixelSize: 11 * s; color: root.orvAccent; font.bold: true }
                        Rectangle { width: parent.width; height: 1; color: root.orvBorder; opacity: 0.4 }
                        Text { text: "• Firewall: NixOS Stateful IPTables Active"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════════
        // 4. DISPLAY & AUDIO VIEW
        // ═════════════════════════════════════════════════════════════════════════
        Item {
            id: dispView
            anchors.fill: parent
            visible: root.currentTab === "DISPLAY"
            anchors.margins: 24 * s

            Item {
                id: dispLeftPanel
                anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left; width: 340 * s

                Text { id: dHdr; text: "THEME PREFERENCES"; font.family: root.fontName; font.pixelSize: 22 * s; font.bold: true; color: root.orvAccent }
                Rectangle { anchors.top: dHdr.bottom; anchors.topMargin: 4 * s; width: parent.width; height: 1; color: root.orvBorder }

                Column {
                    anchors.top: dHdr.bottom; anchors.topMargin: 16 * s
                    anchors.left: parent.left; anchors.right: parent.right
                    spacing: 16 * s

                    // Live UI Scale Adjuster Card
                    Rectangle {
                        width: parent.width; height: 100 * s; color: root.orvCardBg; border.color: root.orvBorder; border.width: 1
                        Column {
                            anchors.fill: parent; anchors.margins: 10 * s; spacing: 8 * s
                            Text { text: "LIVE UI SCALE TUNER"; font.family: root.fontName; font.pixelSize: 10 * s; color: root.orvAccent; font.bold: true }
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter; spacing: 14 * s
                                Rectangle {
                                    width: 36 * s; height: 28 * s; color: sMinusMa2.pressed ? "#1e3a5f" : "#0f172a"; border.color: root.orvBorder; border.width: 1
                                    Text { anchors.centerIn: parent; text: "－"; font.family: root.fontName; font.pixelSize: 14 * s; color: root.orvAccent }
                                    MouseArea { id: sMinusMa2; anchors.fill: parent; onClicked: root.uiScale = Math.max(0.65, root.uiScale - 0.05) }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.uiScale.toFixed(2) + "x"
                                    font.family: root.fontName; font.pixelSize: 14 * s; color: root.orvText; font.bold: true
                                }
                                Rectangle {
                                    width: 36 * s; height: 28 * s; color: sPlusMa2.pressed ? "#1e3a5f" : "#0f172a"; border.color: root.orvBorder; border.width: 1
                                    Text { anchors.centerIn: parent; text: "＋"; font.family: root.fontName; font.pixelSize: 14 * s; color: root.orvAccent }
                                    MouseArea { id: sPlusMa2; anchors.fill: parent; onClicked: root.uiScale = Math.min(1.25, root.uiScale + 0.05) }
                                }
                            }
                        }
                    }

                    // Return Button
                    Rectangle {
                        width: parent.width; height: 38 * s; color: retMa2.pressed ? "#1e3a5f" : retMa2.containsMouse ? "#132a4a" : root.orvCardBg; border.color: root.orvBorder; border.width: 1
                        Text { anchors.centerIn: parent; text: "◆ RETURN TO LOGIN SCREEN"; font.family: root.fontName; font.pixelSize: 10 * s; color: root.orvAccent; font.bold: true }
                        MouseArea { id: retMa2; anchors.fill: parent; hoverEnabled: true; onClicked: root.switchTab("LOGIN") }
                    }
                }
            }

            Rectangle {
                anchors.left: dispLeftPanel.right; anchors.leftMargin: 24 * s
                anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                color: root.orvCardBg; border.color: root.orvBorder; border.width: 1

                Column {
                    anchors.fill: parent; anchors.margins: 18 * s; spacing: 14 * s
                    Text { text: "DISPLAY & AUDIO ARCHITECTURE"; font.family: root.fontName; font.pixelSize: 14 * s; font.bold: true; color: root.orvAccent }
                    Rectangle { width: parent.width; height: 1; color: root.orvBorder }

                    Column {
                        width: parent.width; spacing: 8 * s
                        Text { text: "• Primary Display: Lenovo Legion 16-inch IPS Panel (eDP-1)"; font.family: root.fontName; font.pixelSize: 10 * s; color: root.orvText }
                        Text { text: "• Native Resolution: 2560 × 1600 (16:10 WQXGA)"; font.family: root.fontName; font.pixelSize: 10 * s; color: root.orvText }
                        Text { text: "• Refresh Rate: 240.00 Hz (Ultra-Smooth Motion)"; font.family: root.fontName; font.pixelSize: 10 * s; color: root.orvSuccess; font.bold: true }
                        Text { text: "• Smart Amp Hardware: Texas Instruments TAS2781 Dual Amplifiers"; font.family: root.fontName; font.pixelSize: 10 * s; color: root.orvText }
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════════
        // 5. DIAGNOSTICS VIEW
        // ═════════════════════════════════════════════════════════════════════════
        Item {
            id: diagsView
            anchors.fill: parent
            visible: root.currentTab === "DIAGS"
            anchors.margins: 24 * s

            Text { id: dgHdr; text: "SYSTEM HEALTH & SOFTWARE MATRIX"; font.family: root.fontName; font.pixelSize: 22 * s; font.bold: true; color: root.orvAccent }
            Rectangle { anchors.top: dgHdr.bottom; anchors.topMargin: 4 * s; width: parent.width; height: 1; color: root.orvBorder }

            Grid {
                anchors.top: dgHdr.bottom; anchors.topMargin: 16 * s
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                columns: 2; spacing: 16 * s

                Rectangle {
                    width: (parent.width - 16 * s) / 2; height: (parent.height - 16 * s) / 2
                    color: root.orvCardBg; border.color: root.orvBorder; border.width: 1
                    Column {
                        anchors.fill: parent; anchors.margins: 14 * s; spacing: 8 * s
                        Text { text: "01 // DESKTOP & TOOLKIT RUNTIME"; font.family: root.fontName; font.pixelSize: 11 * s; color: root.orvAccent; font.bold: true }
                        Rectangle { width: parent.width; height: 1; color: root.orvBorder; opacity: 0.4 }
                        Text { text: "• KDE Plasma Version: 6.6.6"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvSuccess; font.bold: true }
                        Text { text: "• KDE Frameworks Version: 6.26.0"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                        Text { text: "• Qt Toolkit Version: 6.11.1"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                        Text { text: "• Display Manager: SDDM 0.21.0 (Qt6 Wayland Greeter)"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                    }
                }

                Rectangle {
                    width: (parent.width - 16 * s) / 2; height: (parent.height - 16 * s) / 2
                    color: root.orvCardBg; border.color: root.orvBorder; border.width: 1
                    Column {
                        anchors.fill: parent; anchors.margins: 14 * s; spacing: 8 * s
                        Text { text: "02 // NIXOS DISTRIBUTION & KERNEL"; font.family: root.fontName; font.pixelSize: 11 * s; color: root.orvAccent; font.bold: true }
                        Rectangle { width: parent.width; height: 1; color: root.orvBorder; opacity: 0.4 }
                        Text { text: "• Operating System: NixOS 26.05"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                        Text { text: "• Kernel Release: 6.18.46 (64-bit LTS)"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvSuccess; font.bold: true }
                        Text { text: "• Flake Configuration: /etc/nixos/configuration.nix"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════════
        // 6. SHORTCUTS VIEW
        // ═════════════════════════════════════════════════════════════════════════
        Item {
            id: scView
            anchors.fill: parent
            visible: root.currentTab === "SHORTCUTS"
            anchors.margins: 24 * s

            Text { id: scHdr; text: "KEYBOARD SHORTCUTS & EMERGENCY TTY RECOVERY"; font.family: root.fontName; font.pixelSize: 22 * s; font.bold: true; color: root.orvAccent }
            Rectangle { anchors.top: scHdr.bottom; anchors.topMargin: 4 * s; width: parent.width; height: 1; color: root.orvBorder }

            Grid {
                anchors.top: scHdr.bottom; anchors.topMargin: 16 * s
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                columns: 2; spacing: 16 * s

                Rectangle {
                    width: (parent.width - 16 * s) / 2; height: (parent.height - 16 * s) / 2
                    color: root.orvCardBg; border.color: root.orvBorder; border.width: 1
                    Column {
                        anchors.fill: parent; anchors.margins: 14 * s; spacing: 8 * s
                        Text { text: "01 // EMERGENCY TTY RECOVERY CONSOLES"; font.family: root.fontName; font.pixelSize: 11 * s; color: root.orvAccent; font.bold: true }
                        Rectangle { width: parent.width; height: 1; color: root.orvBorder; opacity: 0.4 }
                        Text { text: "• Ctrl + Alt + F3 : Open TTY3 Emergency Shell"; font.family: root.fontName; font.pixelSize: 10 * s; color: root.orvWarning; font.bold: true }
                        Text { text: "• Ctrl + Alt + F2 / F1 : Return to SDDM Graphical Greeter"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                    }
                }

                Rectangle {
                    width: (parent.width - 16 * s) / 2; height: (parent.height - 16 * s) / 2
                    color: root.orvCardBg; border.color: root.orvBorder; border.width: 1
                    Column {
                        anchors.fill: parent; anchors.margins: 14 * s; spacing: 8 * s
                        Text { text: "02 // SDDM GREETER NAVIGATION"; font.family: root.fontName; font.pixelSize: 11 * s; color: root.orvAccent; font.bold: true }
                        Rectangle { width: parent.width; height: 1; color: root.orvBorder; opacity: 0.4 }
                        Text { text: "• Enter : Submit passphrase and launch desktop"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                        Text { text: "• Alt + P : Toggle passphrase reveal (Show/Hide)"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                        Text { text: "• Esc : Return immediately to the LOGIN screen"; font.family: root.fontName; font.pixelSize: 9 * s; color: root.orvText }
                    }
                }
            }
        }
    }

    // ── LOGIN ACTION & SDDM CONNECTIONS ──────────────────────────────────────
    function doLogin() {
        var uname = ""
        if (typeof userModel !== "undefined") {
            uname = userList.model.data(
                userList.model.index(userList.currentIndex, 0),
                Qt.UserRole + 1
            )
        }
        if (typeof sddm !== "undefined") sddm.login(uname, pwInput.text, root.sessionIndex)
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            errText.text = "ACCESS DENIED"
            pwInput.text = ""
            pwInput.forceActiveFocus()
        }
    }
}
