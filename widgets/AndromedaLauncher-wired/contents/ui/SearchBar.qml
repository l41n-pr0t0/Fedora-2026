import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

import org.kde.plasma.plasmoid 2.0

Rectangle {

    radius: 8
    color: Qt.rgba(0, 0, 0, 0.28)
    border.width: 1
    border.color: textField.activeFocus ? main.accentLine : Qt.rgba(main.accent.r, main.accent.g, main.accent.b, 0.2)

    Rectangle {
        width: 3; radius: 1.5
        anchors.left: parent.left; anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - 18
        color: main.accent
    }
    Text {
        anchors.right: parent.right; anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: "esc · close"
        font.family: main.monoFont; font.pixelSize: 10
        color: main.textColor; opacity: 0.35
        visible: textField.text == ""
    }

    property alias textField: textField

    RowLayout {
        anchors.fill: parent
        spacing: 0
        Text {
            id: searchIcon
            Layout.leftMargin: 20
            Layout.rightMargin: 4
            text: "❯"
            font.family: main.monoFont
            font.pixelSize: 18
            font.bold: true
            color: main.accent
        }

        TextField {
            id: textField
            Layout.fillHeight: true
            Layout.fillWidth: true
            font.pixelSize: 15
            font.family: main.monoFont

            placeholderText: "search the wired_"
            placeholderTextColor: Qt.rgba(main.textColor.r, main.textColor.g, main.textColor.b, 0.4)
            background: Rectangle{
                color: "transparent"
            }
            focus: true
            onTextChanged: {
                textField.forceActiveFocus(Qt.ShortcutFocusReason)
                runnerModel.query = text;   
            }

            Keys.onPressed: event => {
                if (event.key == Qt.Key_Escape) {
                    event.accepted = true;
                    if (searching) {
                        clear();
                    } else {
                        root.toggle()
                    }
                }
            }
        }
    }
}