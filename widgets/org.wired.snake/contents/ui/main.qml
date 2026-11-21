import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    readonly property color lcd: "#d9a8ff"
    readonly property color hot: "#ff6e96"
    readonly property real ghost: 0.08

    FontLoader { id: seg; source: "../fonts/DSEG7Classic-Bold.ttf" }
    FontLoader { id: dot; source: "../fonts/DotMatrix-Bold.ttf" }

    fullRepresentation: Item {
        id: game
        Layout.preferredWidth: 470
        Layout.preferredHeight: 330
        Layout.minimumWidth: 360
        Layout.minimumHeight: 260
        focus: true

        readonly property int cols: 26
        readonly property int rows: 14
        property var snake: []
        property var board: []
        property point food: Qt.point(-1, -1)
        property point dir: Qt.point(1, 0)
        property var queue: []          // buffered turns, so fast key presses aren't lost
        property int score: 0
        property string state: "idle"   // idle | run | pause | over
        property bool showBoard: false
        property int lastRank: -1       // 0-based rank of the run that just ended, -1 if it didn't place
        property var board10: loadScores()

        function loadScores() {
            try { var s = JSON.parse(Plasmoid.configuration.scores); return Array.isArray(s) ? s : []; }
            catch (e) { return []; }
        }

        function record(points) {
            lastRank = -1;
            if (points <= 0) return;
            var list = loadScores();
            var entry = { s: points, d: Qt.formatDateTime(new Date(), "dd.MM.yy hh:mm"), t: Date.now() };
            list.push(entry);
            list.sort(function (a, b) { return b.s - a.s || a.t - b.t; });
            list = list.slice(0, 10);
            for (var i = 0; i < list.length; i++) if (list[i].t === entry.t) lastRank = i;
            Plasmoid.configuration.scores = JSON.stringify(list);
            if (points > Plasmoid.configuration.highScore) Plasmoid.configuration.highScore = points;
            board10 = list;
        }

        function cell(x, y) { return y * cols + x; }

        function redraw() {
            var b = new Array(cols * rows).fill(0);
            for (var i = 0; i < snake.length; i++) b[cell(snake[i].x, snake[i].y)] = i === 0 ? 2 : 1;
            if (food.x >= 0) b[cell(food.x, food.y)] = 3;
            board = b;
        }

        function placeFood() {
            var free = [];
            var occ = {};
            for (var i = 0; i < snake.length; i++) occ[cell(snake[i].x, snake[i].y)] = true;
            for (var y = 0; y < rows; y++) for (var x = 0; x < cols; x++) if (!occ[cell(x, y)]) free.push(Qt.point(x, y));
            food = free.length ? free[Math.floor(Math.random() * free.length)] : Qt.point(-1, -1);
        }

        function reset() {
            var cy = Math.floor(rows / 2);
            snake = [Qt.point(6, cy), Qt.point(5, cy), Qt.point(4, cy)];
            dir = Qt.point(1, 0);
            queue = [];
            score = 0;
            placeFood();
            redraw();
        }

        function start() { reset(); lastRank = -1; showBoard = false; state = "run"; }

        function turn(dx, dy) {
            var last = queue.length ? queue[queue.length - 1] : dir;
            if (last.x === -dx && last.y === -dy) return;   // no reversing into yourself
            if (last.x === dx && last.y === dy) return;
            if (queue.length < 3) queue.push(Qt.point(dx, dy));
        }

        function step() {
            if (queue.length) { dir = queue[0]; queue = queue.slice(1); }
            var head = snake[0];
            // walls wrap around: leave one edge, come back on the opposite one
            var nx = (head.x + dir.x + cols) % cols, ny = (head.y + dir.y + rows) % rows;
            var grow = (nx === food.x && ny === food.y);
            var body = grow ? snake : snake.slice(0, snake.length - 1);
            var hit = false;
            for (var i = 0; !hit && i < body.length; i++) if (body[i].x === nx && body[i].y === ny) hit = true;
            if (hit) {
                state = "over";
                record(score);
                return;
            }
            snake = [Qt.point(nx, ny)].concat(body);
            if (grow) { score += 10; placeFood(); }
            redraw();
        }

        Timer {
            interval: Math.max(65, 150 - Math.floor(game.score / 50) * 10)
            running: game.state === "run"
            repeat: true
            onTriggered: game.step()
        }

        onActiveFocusChanged: if (!activeFocus && state === "run") state = "pause"
        Component.onCompleted: reset()

        Keys.onPressed: (e) => {
            switch (e.key) {
            case Qt.Key_Up: case Qt.Key_W: turn(0, -1); break;
            case Qt.Key_Down: case Qt.Key_S: turn(0, 1); break;
            case Qt.Key_Left: case Qt.Key_A: turn(-1, 0); break;
            case Qt.Key_Right: case Qt.Key_D: turn(1, 0); break;
            case Qt.Key_Space: case Qt.Key_Return:
                if (showBoard) { showBoard = false; break; }
                if (state === "run") state = "pause";
                else if (state === "pause") state = "run";
                else start();
                break;
            case Qt.Key_Escape:
                if (showBoard) showBoard = false;
                else if (state === "run") state = "pause";
                break;
            case Qt.Key_L:
                if (state === "run") state = "pause";
                showBoard = !showBoard;
                break;
            default: return;
            }
            e.accepted = true;
        }

        MouseArea { anchors.fill: parent; onClicked: game.forceActiveFocus() }

        Item {
            id: screen
            anchors.fill: parent
            anchors.margins: 10
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true; shadowColor: root.lcd; shadowBlur: 0.55
                shadowHorizontalOffset: 0; shadowVerticalOffset: 0; shadowOpacity: 0.85
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "NAVI://SNAKE"; font.family: dot.name; font.pixelSize: 18; color: root.lcd }
                    Item { width: 8 }
                    Rectangle {
                        width: boardBtn.implicitWidth + 12; height: boardBtn.implicitHeight + 4
                        color: game.showBoard ? root.lcd : "transparent"
                        border.color: root.lcd; border.width: 1
                        Text {
                            id: boardBtn; anchors.centerIn: parent
                            text: "BOARD [L]"; font.family: dot.name; font.pixelSize: 11
                            color: game.showBoard ? "#0e0b16" : root.lcd
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { game.forceActiveFocus(); if (game.state === "run") game.state = "pause"; game.showBoard = !game.showBoard; }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "HI"; font.family: dot.name; font.pixelSize: 12; color: root.lcd }
                    Item {
                        width: 70; height: 22
                        Text { anchors.right: parent.right; text: "8888"; font.family: seg.name; font.pixelSize: 20; color: root.lcd; opacity: root.ghost }
                        Text { anchors.right: parent.right; text: Plasmoid.configuration.highScore; font.family: seg.name; font.pixelSize: 20; color: root.lcd }
                    }
                    Item { width: 10 }
                    Text { text: "SCORE"; font.family: dot.name; font.pixelSize: 12; color: root.lcd }
                    Item {
                        width: 70; height: 22
                        Text { anchors.right: parent.right; text: "8888"; font.family: seg.name; font.pixelSize: 20; color: root.lcd; opacity: root.ghost }
                        Text { anchors.right: parent.right; text: game.score; font.family: seg.name; font.pixelSize: 20; color: root.lcd }
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 2; color: root.lcd; opacity: 0.6 }

                Item {
                    id: field
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    readonly property real cs: Math.floor(Math.min(width / game.cols, height / game.rows))

                    Grid {
                        anchors.centerIn: parent
                        columns: game.cols
                        Repeater {
                            model: game.cols * game.rows
                            Item {
                                width: field.cs; height: field.cs
                                readonly property int kind: game.board.length ? game.board[index] : 0
                                Rectangle {
                                    anchors.fill: parent; anchors.margins: 1.5
                                    color: kind === 3 ? root.hot : root.lcd
                                    opacity: kind === 0 ? root.ghost : 1
                                    radius: kind === 3 ? width / 2 : 1
                                    SequentialAnimation on scale {
                                        running: kind === 3; loops: Animation.Infinite
                                        NumberAnimation { to: 0.6; duration: 350 }
                                        NumberAnimation { to: 1.0; duration: 350 }
                                    }
                                }
                            }
                        }
                    }

                    // leaderboard
                    Rectangle {
                        anchors.fill: parent
                        z: 2
                        visible: game.showBoard
                        color: "#0e0b16"; opacity: 0.94
                        border.color: root.lcd; border.width: 1

                        Column {
                            anchors.fill: parent; anchors.margins: 10
                            spacing: 2
                            Text { text: "LEADERBOARD // TOP 10"; font.family: dot.name; font.pixelSize: 15; color: root.lcd }
                            Rectangle { width: parent.width; height: 1; color: root.lcd; opacity: 0.5 }
                            Text {
                                visible: game.board10.length === 0
                                text: "NO RECORDS IN THE WIRED YET"; font.family: dot.name; font.pixelSize: 13; color: root.lcd; opacity: 0.7
                                topPadding: 8
                            }
                            Repeater {
                                model: game.board10
                                Item {
                                    width: parent.width; height: Math.max(14, (parent.height - 30) / 10)
                                    readonly property bool fresh: index === game.lastRank && game.state === "over"
                                    Text {
                                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                        text: (index < 9 ? "0" : "") + (index + 1)
                                        font.family: seg.name; font.pixelSize: 13; color: fresh ? root.hot : root.lcd
                                    }
                                    Text {
                                        anchors.left: parent.left; anchors.leftMargin: 40; anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.d; font.family: dot.name; font.pixelSize: 12; color: fresh ? root.hot : root.lcd
                                        opacity: 0.8
                                    }
                                    Text {
                                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.s; font.family: seg.name; font.pixelSize: 13; color: fresh ? root.hot : root.lcd
                                    }
                                }
                            }
                        }
                        Text {
                            anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 6
                            text: "L / ESC TO CLOSE"; font.family: dot.name; font.pixelSize: 10; color: root.lcd; opacity: 0.6
                        }
                    }

                    // overlay messages
                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        visible: game.state !== "run" && !game.showBoard
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: msg.implicitWidth + 24; height: msg.implicitHeight + 10
                            color: "#0e0b16"; opacity: 0.85; border.color: root.lcd; border.width: 1
                            Text {
                                id: msg; anchors.centerIn: parent
                                font.family: dot.name; font.pixelSize: 20
                                color: game.state === "over" ? root.hot : root.lcd
                                text: game.state === "over" ? "CONNECTION LOST"
                                    : game.state === "pause" ? "PAUSED" : "PRESENT DAY. PRESENT TIME."
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: game.state === "over" && game.lastRank >= 0
                            font.family: dot.name; font.pixelSize: 14; color: root.hot
                            text: game.lastRank === 0 ? "NEW RECORD  #1" : "RANKED  #" + (game.lastRank + 1)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: dot.name; font.pixelSize: 12; color: root.lcd
                            text: !game.activeFocus ? "CLICK TO CONNECT"
                                : game.state === "over" ? "SPACE TO RECONNECT"
                                : game.state === "pause" ? "SPACE TO RESUME" : "SPACE START // ARROWS-WASD // L BOARD"
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.25; duration: 700 }
                                NumberAnimation { to: 1.0; duration: 700 }
                            }
                        }
                    }
                }
            }
        }

        // CRT scanlines
        Column {
            anchors.fill: parent; clip: true; spacing: 2
            Repeater {
                model: Math.ceil(parent.height / 3)
                Rectangle { width: parent.width; height: 1; color: "black"; opacity: 0.22 }
            }
        }
    }
}
