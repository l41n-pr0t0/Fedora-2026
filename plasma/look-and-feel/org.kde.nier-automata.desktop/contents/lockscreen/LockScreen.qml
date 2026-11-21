/*
    STEINS;GATE 0 // Future Gadget Laboratory Lock Screen for KDE Plasma 6
    Authored for l41n-pr0t0 (LENOVO Legion Pro 7)
*/
import QtQuick

Item {
    id: root
    property bool debug: false
    property string notification
    property bool locked: true
    onLockedChanged: {
        if (locked && typeof authenticator !== "undefined") {
            if (authenticator.state === 0) {
                authenticator.startAuthenticating()
            }
        }
    }
    signal clearPassword()
    signal notificationRepeated()

    // Magical properties required by kscreenlocker
    property bool viewVisible: false
    property bool suspendToRamSupported: true
    property bool suspendToDiskSupported: true

    // Magical signals required by kscreenlocker
    signal suspendToDisk()
    signal suspendToRam()

    LayoutMirroring.enabled: Application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    implicitWidth: 800
    implicitHeight: 600

    LockScreenUi {
        id: lockScreenUi
        anchors.fill: parent
    }
}
