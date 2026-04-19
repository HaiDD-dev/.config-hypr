import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects
import QtCore
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window
    focus: true

    // --- Responsive Scaling Logic ---
    Scaler {
        id: scaler
        currentWidth: Screen.width
    }
    
    function s(val) { 
        return scaler.s(val); 
    }

    // -------------------------------------------------------------------------
    // COLORS (Dynamic Matugen Palette)
    // -------------------------------------------------------------------------
    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0
    readonly property color overlay1: _theme.overlay1
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    
    readonly property color peach: _theme.peach

    // -------------------------------------------------------------------------
    // STATE & CONFIG
    // -------------------------------------------------------------------------
    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/watchers"
    
    readonly property color tabColor: window.peach
    
    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    // Brightness State
    property int activeBright: 0
    
    property var draggingNodes: ({})
    property bool draggingMaster: false
    Timer { id: syncDelay; interval: 600; onTriggered: { window.draggingNodes = ({}); window.draggingMaster = false; } }

    // -------------------------------------------------------------------------
    // CACHING & DATA LOGIC
    // -------------------------------------------------------------------------
    Settings {
        id: cache
        property string lastBrightJson: ""
    }

    Component.onCompleted: {
        if (cache.lastBrightJson !== "") processBrightJson(cache.lastBrightJson);
    }

    function processBrightJson(textData) {
        if (!textData) return;
        try {
            let data = JSON.parse(textData);
            if (!window.draggingMaster) {
                window.activeBright = data.brightness;
            }
            cache.lastBrightJson = textData;
        } catch(e) {}
    }

    Process {
        id: brightPoller
        command: ["bash", window.scriptsDir + "/bright_fetch.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                processBrightJson(this.text.trim());
            }
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true;
        onTriggered: brightPoller.running = true
    }

    // -------------------------------------------------------------------------
    // ANIMATIONS
    // -------------------------------------------------------------------------
    property real introMain: 0
    property real introHeader: 0
    property real introContent: 0

    ParallelAnimation {
        running: true
        NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutExpo }
        SequentialAnimation {
            PauseAnimation { duration: 100 }
            NumberAnimation { target: window; property: "introHeader"; from: 0; to: 1.0; duration: 700; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }
        SequentialAnimation {
            PauseAnimation { duration: 200 }
            NumberAnimation { target: window; property: "introContent"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutExpo }
        }
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        scale: 0.95 + (0.05 * introMain)
        opacity: introMain
        transform: Translate { y: window.s(20) * (1 - introMain) }

        Rectangle {
            anchors.fill: parent
            radius: window.s(20)
            color: window.base
            border.color: window.surface0
            border.width: 1
            clip: true

            // Rotating Background Blobs
            Rectangle {
                width: parent.width * 0.8; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)
                opacity: 0.06
                color: window.tabColor
                Behavior on color { ColorAnimation { duration: 800 } }
            }
            Rectangle {
                width: parent.width * 0.9; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)
                opacity: 0.04
                color: Qt.lighter(window.tabColor, 1.3)
                Behavior on color { ColorAnimation { duration: 800 } }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: window.s(25)
                spacing: window.s(20)

                // ==========================================
                // HERO ORB & MASTER SLIDER (TOP SECTION)
                // ==========================================
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.s(150)
                    opacity: introHeader
                    transform: Translate { y: window.s(30) * (1.0 - introHeader) }

                    RowLayout {
                        anchors.fill: parent
                        spacing: window.s(25)

                        // 1. The Orb
                        Item {
                            Layout.preferredWidth: window.s(130)
                            Layout.preferredHeight: window.s(130)
                            scale: masterOrbMa.pressed ? 0.95 : (masterOrbMa.containsMouse ? 1.05 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

                            // Solid pulsing background ring
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + window.s(40)
                                height: width
                                radius: width / 2
                                color: window.tabColor
                                opacity: 0.15
                                z: -1
                                Behavior on color { ColorAnimation { duration: 300 } }

                                SequentialAnimation on scale {
                                    loops: Animation.Infinite; running: true
                                    NumberAnimation { to: masterOrbMa.containsMouse ? 1.15 : 1.1; duration: masterOrbMa.containsMouse ? 800 : 2000; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 1.0; duration: masterOrbMa.containsMouse ? 800 : 2000; easing.type: Easing.InOutSine }
                                }
                            }

                            // Core Shadow
                            MultiEffect {
                                source: centralCore
                                anchors.fill: centralCore
                                shadowEnabled: true
                                shadowColor: "#000000"
                                shadowOpacity: 0.5
                                shadowBlur: 1.2
                                shadowVerticalOffset: window.s(6)
                                z: -1
                            }

                            // Core Rectangle
                            Rectangle {
                                id: centralCore
                                anchors.fill: parent
                                radius: width / 2
                                color: window.base
                                border.color: Qt.lighter(window.tabColor, 1.1)
                                border.width: 2
                                clip: true
                                Behavior on border.color { ColorAnimation { duration: 300 } }

                                // Brightness Wave Fill
                                Canvas {
                                    id: orbWave
                                    anchors.fill: parent
                                    
                                    property real wavePhase: 0.0
                                    NumberAnimation on wavePhase {
                                        running: window.activeBright > 0 && window.activeBright < 100
                                        loops: Animation.Infinite
                                        from: 0; to: Math.PI * 2; duration: 1200
                                    }
                                    onWavePhaseChanged: requestPaint()

                                    Connections {
                                        target: window
                                        function onActiveBrightChanged() { orbWave.requestPaint() }
                                    }

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        if (window.activeBright <= 0) return;

                                        var fillRatio = window.activeBright / 100.0;
                                        var r = width / 2;
                                        var fillY = height * (1.0 - fillRatio);

                                        ctx.save();
                                        
                                        // 1. Establish the circular clipping mask
                                        ctx.beginPath();
                                        ctx.arc(r, r, r, 0, 2 * Math.PI);
                                        ctx.clip();
                                        
                                        // 2. Draw the actual wave filling
                                        ctx.beginPath();
                                        ctx.moveTo(0, fillY);
                                        
                                        if (fillRatio < 0.99) {
                                            var waveAmp = window.s(8) * Math.sin(fillRatio * Math.PI); 
                                            var cp1y = fillY + Math.sin(wavePhase) * waveAmp;
                                            var cp2y = fillY + Math.cos(wavePhase + Math.PI) * waveAmp;
                                            ctx.bezierCurveTo(width * 0.33, cp2y, width * 0.66, cp1y, width, fillY);
                                            ctx.lineTo(width, height);
                                            ctx.lineTo(0, height);
                                        } else {
                                            ctx.lineTo(width, 0);
                                            ctx.lineTo(width, height);
                                            ctx.lineTo(0, height);
                                        }
                                        ctx.closePath();
                                        
                                        var grad = ctx.createLinearGradient(0, 0, 0, height);
                                        grad.addColorStop(0, Qt.lighter(window.tabColor, 1.15).toString());
                                        grad.addColorStop(1, window.tabColor.toString());
                                        ctx.fillStyle = grad;
                                        ctx.globalAlpha = 1.0;
                                        ctx.fill();
                                        ctx.restore();
                                    }
                                }

                                // Dual-Layer Text for contrast clipping
                                Text {
                                    anchors.centerIn: parent
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Black
                                    font.pixelSize: window.s(32)
                                    color: window.text
                                    text: window.activeBright + "%"
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }

                                // 2. Clipped Text (Dark text that reveals over the wave fill dynamically)
                                Item {
                                    id: waveClipItem
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right

                                    property real fillRatio: window.activeBright / 100.0
                                    property real waveAmp: fillRatio < 0.99 ? window.s(8) * Math.sin(fillRatio * Math.PI) : 0
                                    property real waveCenterOffset: 0.375 * waveAmp * (Math.sin(orbWave.wavePhase) - Math.cos(orbWave.wavePhase))
                                    property real baseClipHeight: parent.height * fillRatio

                                    height: Math.min(parent.height, Math.max(0, baseClipHeight - waveCenterOffset))
                                    clip: true
                                    visible: window.activeBright > 0

                                    Text {
                                        x: waveClipItem.width / 2 - width / 2
                                        y: (centralCore.height / 2) - (height / 2) - (centralCore.height - waveClipItem.height)
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Black
                                        font.pixelSize: window.s(32)
                                        color: window.crust
                                        text: window.activeBright + "%"
                                    }
                                }

                                MouseArea {
                                    id: masterOrbMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["bash", window.scriptsDir + "/bright_fetch.sh", "--toggle"]);
                                        brightPoller.running = true;
                                    }
                                }
                            }
                        }

                        // 2. Details & Slider
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: window.s(10)

                            ColumnLayout {
                                spacing: window.s(2)
                                Text {
                                    Layout.fillWidth: true; elide: Text.ElideRight
                                    font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(20)
                                    color: window.text
                                    text: "Brightness"
                                }
                                Text {
                                    Layout.fillWidth: true; elide: Text.ElideRight
                                    font.family: "JetBrains Mono"; font.pixelSize: window.s(13)
                                    color: window.subtext0
                                    text: "Screen backlight"
                                }
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: window.s(15)

                                Item {
                                    Layout.fillWidth: true
                                    height: window.s(24)

                                    Timer {
                                        id: masterCmdThrottle
                                        interval: 50
                                        property int targetPct: -1
                                        onTriggered: {
                                            if (targetPct >= 0) {
                                                Quickshell.execDetached(["bash", "-c", "brightnessctl set " + targetPct + "% >/dev/null 2>&1"]);
                                                targetPct = -1;
                                            }
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent; radius: window.s(12)
                                        color: "#0dffffff"; border.color: "#1affffff"; border.width: 1
                                        clip: true

                                        Rectangle {
                                            height: parent.height
                                            width: parent.width * (Math.min(100, window.activeBright) / 100)
                                            radius: window.s(12)
                                            opacity: masterSliderMa.containsMouse ? 1.0 : 0.85
                                            Behavior on opacity { NumberAnimation { duration: 200 } }
                                            Behavior on width { enabled: !window.draggingMaster; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

                                            gradient: Gradient {
                                                orientation: Gradient.Horizontal
                                                GradientStop { position: 0.0; color: window.tabColor; Behavior on color { ColorAnimation{duration: 300} } }
                                                GradientStop { position: 1.0; color: Qt.lighter(window.tabColor, 1.25); Behavior on color { ColorAnimation{duration: 300} } }
                                            }
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: masterSliderMa
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onPressed: (mouse) => { syncDelay.stop(); window.draggingMaster = true; updateBright(mouse.x); }
                                        onPositionChanged: (mouse) => { if (pressed) updateBright(mouse.x); }
                                        onReleased: { syncDelay.restart(); brightPoller.running = true; }
                                        
                                        function updateBright(mx) {
                                            let pct = Math.max(1, Math.min(100, Math.round((mx / width) * 100)));
                                            window.activeBright = pct;

                                            masterCmdThrottle.targetPct = pct;
                                            if (!masterCmdThrottle.running) masterCmdThrottle.start();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ==========================================
                // LIST VIEW CONTENT (Placeholder)
                // ==========================================
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    opacity: introContent
                    transform: Translate { y: window.s(20) * (1.0 - introContent) }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: window.s(10)
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: window.s(48)
                            color: window.peach
                            text: "󰛩"
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            font.family: "JetBrains Mono"
                            font.pixelSize: window.s(14)
                            color: window.overlay0
                            text: "Click orb or use scroll wheel"
                        }
                    }
                }
            }
        }
    }
}