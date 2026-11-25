import QtQuick
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects


Rectangle {
    id: highlight
    /*!
    This property holds whether the control is hovered.

    This is set automatically when used in a ListView and GridView.
    */
    property bool hovered: ListView.view !== null || GridView.view !== null

    /*!
      This property holds whether the highlight has a pressed appearance.
     */
    property bool pressed: false

    /*!
      \qmlproperty int Highlight::marginHints

      This property holds the margin hints used by the background.
    */
    property alias marginHints: background.margins

    /*!
      This property holds whether the item is active. True by default. Set it to
      false to visually mark an item that's in the "current item" or "selected"
      state but is not currently being hovered.
     */
    property bool active: true

    /*!
      This property holds whether the item should not show a background. False by default. Set it to
      true to visually hide the background, mainly used when glow is enabled in plasmoid config
     */
    property bool hideBg: false

    width: {
        const view = ListView.view;
        return view ? view.width - view.leftMargin - view.rightMargin : undefined;
    } 

    radius: 8
    z: -20

    Rectangle {
        anchors.fill: parent
        visible: !highlight.hideBg
        radius: highlight.radius
        color: Qt.rgba(main.accent.r, main.accent.g, main.accent.b, highlight.pressed ? 0.26 : 0.15)
        border.width: 1
        border.color: Qt.rgba(main.accent.r, main.accent.g, main.accent.b, 0.55)
        Rectangle {
            width: 3; radius: 1.5
            height: parent.height * 0.45
            anchors.left: parent.left; anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            color: main.accent
        }
    }
    color: "transparent"
    clip: true

    // apply rounded corners mask
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            x: highlight.x; y: highlight.y
            width: highlight.width
            height: highlight.height
            radius: highlight.radius
        }
    }

    KSvg.FrameSvgItem {
        id: background

       // anchors.fill: parent
        width: highlight.width + highlight.radius
        height: highlight.height + highlight.radius
        anchors.centerIn: parent

        opacity: 0

        imagePath: "widgets/viewitem"
        prefix: {
            if (highlight.pressed) {
                return highlight.hovered ? 'selected+hover' : 'selected';
            }

            return highlight.hovered ? 'hover' : 'normal';
        }

        Behavior on opacity {
            enabled: Kirigami.Units.veryShortDuration > 0
            NumberAnimation {
                duration: Kirigami.Units.veryShortDuration
                easing.type: Easing.OutQuad
            }
        }
    }
}