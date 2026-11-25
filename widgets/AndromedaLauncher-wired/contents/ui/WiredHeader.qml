import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components 1.0 as KirigamiComponents
import org.kde.kcmutils as KCM

// Lain / Wired header: avatar ring, identity line, greeting, date + live clock
Item {
  id: wh
  property date now: new Date()

  Timer {
    interval: 1000; repeat: true; triggeredOnStart: true
    running: root.visible
    onTriggered: wh.now = new Date()
  }

  // avatar with accent ring + slowly rotating dashed orbit
  Item {
    id: avatarBox
    width: 66; height: 66
    anchors.left: parent.left
    anchors.leftMargin: 4
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: "transparent"
      border.width: 2
      border.color: main.accent
    }
    Repeater {
      model: 12
      Rectangle {
        width: 3; height: 3; radius: 1.5
        color: main.accent
        opacity: index % 3 == 0 ? 0.9 : 0.35
        x: avatarBox.width / 2 + Math.cos((index / 12) * 2 * Math.PI + orbit.angle) * 39 - 1.5
        y: avatarBox.height / 2 + Math.sin((index / 12) * 2 * Math.PI + orbit.angle) * 39 - 1.5
      }
    }
    QtObject { id: orbit; property real angle: 0 }
    NumberAnimation {
      target: orbit; property: "angle"; from: 0; to: 2 * Math.PI
      duration: 24000; loops: Animation.Infinite; running: root.visible
    }
    KirigamiComponents.AvatarButton {
      anchors.fill: parent
      anchors.margins: 6
      source: kuser.faceIconUrl
      name: kuser.fullName
      color: Qt.rgba(main.accent.r, main.accent.g, main.accent.b, 0.25)
      initialsColor: main.accent
      onClicked: { KCM.KCMLauncher.openSystemSettings("kcm_users"); root.toggle() }
    }
  }

  ColumnLayout {
    anchors.left: avatarBox.right
    anchors.leftMargin: 20
    anchors.right: clock.left
    anchors.rightMargin: 12
    anchors.verticalCenter: avatarBox.verticalCenter
    spacing: 3

    Text {
      text: "// " + kuser.loginName + "@" + kuser.host + "  ::  layer 07"
      color: main.accent
      font.family: main.monoFont
      font.pixelSize: 11
      font.letterSpacing: 1.5
      elide: Text.ElideRight
      Layout.fillWidth: true
    }
    Text {
      text: plasmoid.configuration.customGreeting ? plasmoid.configuration.customGreeting : i18n("Hi, %1", kuser.fullName)
      color: main.textColor
      font.family: main.textFont
      font.pixelSize: 21
      font.weight: Font.DemiBold
      elide: Text.ElideRight
      Layout.fillWidth: true
    }
    Text {
      text: Qt.formatDateTime(wh.now, "dddd · dd MMMM yyyy").toLowerCase() + "   —   let's all love lain"
      color: main.textColor
      opacity: 0.5
      font.family: main.monoFont
      font.pixelSize: 11
      elide: Text.ElideRight
      Layout.fillWidth: true
    }
  }

  // live clock, bottom right of the header band
  Row {
    id: clock
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 2
    spacing: 4
    Text {
      text: Qt.formatTime(wh.now, "HH:mm")
      color: main.textColor
      font.family: main.monoFont
      font.pixelSize: 38
      font.weight: Font.Light
    }
    Text {
      anchors.baseline: parent.children[0].baseline
      text: Qt.formatTime(wh.now, "ss")
      color: main.accent
      font.family: main.monoFont
      font.pixelSize: 15
    }
  }
}
