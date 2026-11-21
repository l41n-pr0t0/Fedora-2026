import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    readonly property color lcd: "#d9a8ff"
    readonly property color hot: "#ff6e96"
    readonly property real ghost: 0.10

    FontLoader { id: seg; source: "../fonts/DSEG7Classic-Bold.ttf" }
    FontLoader { id: dot; source: "../fonts/DotMatrix-Bold.ttf" }

    Sensors.Sensor { id: cpuLoad; sensorId: "cpu/all/usage"; updateRateLimit: 1000 }
    Sensors.Sensor { id: ram;     sensorId: "memory/physical/usedPercent"; updateRateLimit: 1000 }
    Sensors.Sensor { id: cpuTemp; sensorId: "lmsensors/legion_hwmon-isa-0000/temp1"; updateRateLimit: 1000 }
    Sensors.Sensor { id: gpuTemp; sensorId: "lmsensors/legion_hwmon-isa-0000/temp2"; updateRateLimit: 1000 }
    Sensors.Sensor { id: sysDisk; sensorId: "disk/0fc875cd-9339-4631-aac7-6ad42e9c82ed/usedPercent"; updateRateLimit: 5000 }
    Sensors.Sensor { id: sciDisk; sensorId: "disk/e45c6ff55c6fc0c2/usedPercent"; updateRateLimit: 5000 }

    // one LCD row: label, ghosted 7-segment value, unit, segmented bar
    component LcdRow: Item {
        id: row
        property string label
        property var value: 0
        property real max: 100
        property string unit: "%"
        property real warn: 80
        readonly property real v: (typeof value === "number" && !isNaN(value)) ? value : 0
        readonly property color tint: v >= warn ? root.hot : root.lcd
        readonly property int lit: Math.max(0, Math.min(20, Math.round(v / max * 20)))
        Layout.fillWidth: true
        implicitHeight: 34

        Text {
            id: lbl
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            width: 112
            text: row.label
            font.family: dot.name; font.pixelSize: 15
            color: row.tint
        }
        Item {
            id: num
            anchors.left: lbl.right; anchors.verticalCenter: parent.verticalCenter
            width: 92; height: 26
            Text { anchors.right: parent.right; text: "88.8"; font.family: seg.name; font.pixelSize: 24; color: row.tint; opacity: root.ghost }
            Text { anchors.right: parent.right; text: (row.v < 10 ? "!" : "") + row.v.toFixed(1); font.family: seg.name; font.pixelSize: 24; color: row.tint }
        }
        Text {
            id: unitText
            anchors.left: num.right; anchors.leftMargin: 4; anchors.verticalCenter: parent.verticalCenter
            width: 30
            text: row.unit
            font.family: dot.name; font.pixelSize: 13
            color: row.tint
        }
        Row {
            anchors.left: unitText.right; anchors.leftMargin: 6
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Repeater {
                model: 20
                Rectangle {
                    width: (parent.width - 19 * 3) / 20; height: 14
                    color: row.tint
                    opacity: index < row.lit ? 1 : root.ghost
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                }
            }
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 470
        Layout.preferredHeight: 300
        Layout.minimumWidth: 380
        Layout.minimumHeight: 260

        Item {
            id: panel
            anchors.fill: parent
            anchors.margins: 10
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: root.lcd
                shadowBlur: 0.55
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
                shadowOpacity: 0.85
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "WIRED // VITALS"; font.family: dot.name; font.pixelSize: 18; color: root.lcd }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "NAVI ONLINE"
                        font.family: dot.name; font.pixelSize: 12; color: root.lcd
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.25; duration: 900 }
                            NumberAnimation { to: 1.0; duration: 900 }
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 2; color: root.lcd; opacity: 0.6 }

                LcdRow { label: "CPU LOAD"; value: cpuLoad.value }
                LcdRow { label: "MEMORY";   value: ram.value }
                LcdRow { label: "CPU TEMP"; value: cpuTemp.value; unit: "°C"; warn: 85 }
                LcdRow { label: "GPU TEMP"; value: gpuTemp.value; unit: "°C"; warn: 80 }
                LcdRow { label: "SYSTEM";   value: sysDisk.value; warn: 90 }
                LcdRow { label: "SCIENTIA"; value: sciDisk.value; warn: 90 }
                Item { Layout.fillHeight: true }
            }
        }

        // CRT scanlines over everything
        Column {
            anchors.fill: parent; clip: true; spacing: 2
            Repeater {
                model: Math.ceil(parent.height / 3)
                Rectangle { width: parent.width; height: 1; color: "black"; opacity: 0.22 }
            }
        }
    }
}
