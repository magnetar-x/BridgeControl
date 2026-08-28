import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

//Dashboard frontend
PanelWindow {
    id: hud

    // force dash on desktop
    WlrLayershell.layer: WlrLayershell.Background
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    visible: false
    function open(payloadJson) { hud.visible = true }
    function close() { hud.visible = false }
    function toggle(payloadJson) { hud.visible = !hud.visible }

    anchors {
        bottom: true
    }

    margins {
        bottom: 48
    }

    // Shrink-wrap 
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight
    color: "transparent"
    mask: Region {}

    // Data Engine init
    HudBackend {
        id: backend
    }

    // UI Components
    component Gauge: Item {
        id: gaugeRoot
        property real value: 0          
        property string label: ""
        property string unit: "%"
        property string textOverride: ""
        property real size: 84

        implicitWidth: size
        implicitHeight: size + 22

        Shape {
            id: ring
            anchors.top: parent.top
            width: gaugeRoot.size
            height: gaugeRoot.size
            layer.enabled: true
            layer.smooth: true

            ShapePath {
                strokeColor: Qt.rgba(backend.theme.foreground.r, backend.theme.foreground.g, backend.theme.foreground.b, 0.15)
                strokeWidth: 6
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: ring.width / 2 - 6
                    radiusY: ring.height / 2 - 6
                    startAngle: -220
                    sweepAngle: 260
                }
            }

            ShapePath {
                strokeColor: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.35)
                strokeWidth: 12
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: ring.width / 2 - 6
                    radiusY: ring.height / 2 - 6
                    startAngle: -220
                    sweepAngle: gaugeRoot.value < 0 ? 0 : 260 * Math.min(gaugeRoot.value, 100) / 100
                }
            }

            ShapePath {
                strokeColor: backend.theme.accent
                strokeWidth: 6
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: ring.width / 2 - 6
                    radiusY: ring.height / 2 - 6
                    startAngle: -220
                    sweepAngle: gaugeRoot.value < 0 ? 0 : 260 * Math.min(gaugeRoot.value, 100) / 100
                }
            }
        }

        Rectangle {
            anchors.centerIn: ring
            width: ring.width - 20
            height: ring.height - 20
            radius: width / 2
            color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.08)
            border.color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.35)
            border.width: 1
        }

        Column {
            anchors.centerIn: ring
            spacing: 0
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: gaugeRoot.textOverride !== "" ? gaugeRoot.textOverride : (gaugeRoot.value < 0 ? "--" : Math.round(gaugeRoot.value).toString())
                color: backend.theme.foreground
                font.family: "monospace"
                font.pixelSize: 20
                font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: gaugeRoot.value < 0 ? "N/A" : gaugeRoot.unit
                color: Qt.rgba(backend.theme.foreground.r, backend.theme.foreground.g, backend.theme.foreground.b, 0.6)
                font.family: "monospace"
                font.pixelSize: 11
            }
        }

        Text {
            anchors.top: ring.bottom
            anchors.topMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            text: gaugeRoot.label
            color: backend.theme.accent
            font.family: "monospace"
            font.pixelSize: 11
            font.letterSpacing: 1.5
        }
    }

    component StatRow: RowLayout {
        property string label: ""
        property string value: ""
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: backend.theme.accent
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            text: label
            color: Qt.rgba(backend.theme.foreground.r, backend.theme.foreground.g, backend.theme.foreground.b, 0.75)
            font.family: "monospace"
            font.pixelSize: 11
            Layout.fillWidth: true
        }
        Text {
            text: value
            color: backend.theme.foreground
            font.family: "monospace"
            font.pixelSize: 11
            font.bold: true
        }
    }

    //Root UI Layout
    RowLayout {
        id: mainLayout
        spacing: 16
        //Leftmost
        //
        Rectangle {
            id: leftmostPanel
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: leftmostCol.implicitWidth + 48
            implicitHeight: leftmostCol.implicitHeight + 48
            color: Qt.rgba(backend.theme.background.r, backend.theme.background.g, backend.theme.background.b, 0.55)
            radius: 10
            border.width: 1
            border.color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.5)
            clip: true

            Repeater {
                model: 4
                Shape {
                    property int corner: index
                    width: 18
                    height: 18
                    x: corner % 2 === 0 ? -1 : leftmostPanel.width - width + 1
                    y: corner < 2 ? -1 : leftmostPanel.height - height + 1
                    ShapePath {
                        strokeColor: backend.theme.accent
                        strokeWidth: 2
                        fillColor: "transparent"
                        startX: corner % 2 === 0 ? 0 : 18
                        startY: corner < 2 ? 18 : 0
                        PathLine { x: corner % 2 === 0 ? 0 : 18; y: corner < 2 ? 0 : 18 }
                        PathLine { x: corner % 2 === 0 ? 18 : 0; y: corner < 2 ? 0 : 18 }
                    }
                }
            }

            ColumnLayout {
                id: leftmostCol
                anchors.centerIn: parent
                spacing: 24
                
                Gauge { value: backend.cpuUsage; label: "CPU USAGE"; unit: "%" }
                }
        }

        //LL Gauge
       Rectangle {
            id: leftleftPanel
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: leftleftCol.implicitWidth + 48
            implicitHeight: leftleftCol.implicitHeight + 48
            color: Qt.rgba(backend.theme.background.r, backend.theme.background.g, backend.theme.background.b, 0.55)
            radius: 10
            border.width: 1
            border.color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.5)
            clip: true

            Repeater {
                model: 4
                Shape {
                    property int corner: index
                    width: 18
                    height: 18
                    x: corner % 2 === 0 ? -1 : leftleftPanel.width - width + 1
                    y: corner < 2 ? -1 : leftleftPanel.height - height + 1
                    ShapePath {
                        strokeColor: backend.theme.accent
                        strokeWidth: 2
                        fillColor: "transparent"
                        startX: corner % 2 === 0 ? 0 : 18
                        startY: corner < 2 ? 18 : 0
                        PathLine { x: corner % 2 === 0 ? 0 : 18; y: corner < 2 ? 0 : 18 }
                        PathLine { x: corner % 2 === 0 ? 18 : 0; y: corner < 2 ? 0 : 18 }
                    }
                }
            }

            ColumnLayout {
                id: leftleftCol
                anchors.centerIn: parent
                spacing: 24
                
                Gauge { value: backend.cpuTemp; label: "CPU TEMP"; unit: " °C" }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.25)
                }
                Gauge { value: backend.cpuFanRpm > 0 ? (backend.cpuFanRpm / 7000) * 100 : 0;textOverride: backend.cpuFanRpm < 0 ? "--" : Math.round(backend.cpuFanRpm).toString();label: "CPU FAN"; unit: "RPM" }
                }
        }
 
        // Left Gauges Panel
        Rectangle {
            id: leftPanel
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: leftCol.implicitWidth + 48
            implicitHeight: leftCol.implicitHeight + 48
            color: Qt.rgba(backend.theme.background.r, backend.theme.background.g, backend.theme.background.b, 0.55)
            radius: 10
            border.width: 1
            border.color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.5)
            clip: true
            Repeater {
                model: 4
                Shape {
                    property int corner: index
                    width: 18
                    height: 18
                    x: corner % 2 === 0 ? -1 : leftPanel.width - width + 1
                    y: corner < 2 ? -1 : leftPanel.height - height + 1
                    ShapePath {
                        strokeColor: backend.theme.accent
                        strokeWidth: 2
                        fillColor: "transparent"
                        startX: corner % 2 === 0 ? 0 : 18
                        startY: corner < 2 ? 18 : 0
                        PathLine { x: corner % 2 === 0 ? 0 : 18; y: corner < 2 ? 0 : 18 }
                        PathLine { x: corner % 2 === 0 ? 18 : 0; y: corner < 2 ? 0 : 18 }
                    }
                }
            }
            ColumnLayout {
                id: leftCol
                anchors.centerIn: parent
                spacing: 24
                
                Gauge { value: backend.volLevel; label: "VOL"; unit: "%" }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.25)
                }
                Gauge { value: backend.briLevel; label: "BRIGHT"; unit: "%" }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.25)
                }
                Gauge { value: backend.kbdBriLevel; label: "KBD"; unit: "%" }
            }
        }

        // Center Data Glass Panel
        Rectangle {
            id: rootPanel
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 380
            implicitHeight: centerLayoutContainer.implicitHeight + 32
            color: Qt.rgba(backend.theme.background.r, backend.theme.background.g, backend.theme.background.b, 0.55)
            radius: 10
            border.width: 1
            border.color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.5)
            clip: true

            Rectangle {
              //scanline
                id: scanline
                width: 3
                height: rootPanel.height * 1.6
                rotation: 20
                color: backend.theme.accent
                opacity: 0.06
                x: -width
                SequentialAnimation on x {
                    loops: Animation.Infinite
                    NumberAnimation { from: -scanline.width; to: rootPanel.width + scanline.width; duration: 5200; easing.type: Easing.InOutSine }
                    PauseAnimation { duration: 1800 }
                }
            }
/*
            Repeater {
                model: 4
                Shape {
                    property int corner: index
                    width: 18
                    height: 18
                    x: corner % 2 === 0 ? -1 : rootPanel.width - width + 1
                    y: corner < 2 ? -1 : rootPanel.height - height + 1
                    ShapePath {
                        strokeColor: backend.theme.accent
                        strokeWidth: 2
                        fillColor: "transparent"
                        startX: corner % 2 === 0 ? 0 : 18
                        startY: corner < 2 ? 18 : 0
                        PathLine { x: corner % 2 === 0 ? 0 : 18; y: corner < 2 ? 0 : 18 }
                        PathLine { x: corner % 2 === 0 ? 18 : 0; y: corner < 2 ? 0 : 18 }
                    }
                }
            }
*/
            ColumnLayout {
                id: centerLayoutContainer
                anchors.centerIn: parent
                width: parent.width - 32
                spacing: 14

                RowLayout {
                  Layout.fillWidth: true
                  Rectangle {
                    //dot
                        width: 8; height: 8; radius: 4
                        color: backend.theme.accent
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.25; duration: 900 }
                            NumberAnimation { from: 0.25; to: 1.0; duration: 900 }
                        }
                    }
                    Text {
                        text: "B R I D G E   C O N T R O L"
                        color: backend.theme.accent
                        font.family: "monospace"
                        font.pixelSize: 15
                        font.letterSpacing: 3
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Rectangle {
                      //dot
                        width: 8
                        height: 8
                        radius: 4
                        color: backend.theme.accent
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.25; duration: 900 }
                            NumberAnimation { from: 0.25; to: 1.0; duration: 900 }
                        }
                    }
                }

                Rectangle {
                  //line
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.4)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Gauge { value: backend.vramUsage; label: "VRAM" }
                    Gauge { value: backend.swapUsage; label: "SWAP" }
                    Gauge { value: backend.ramUsage; label: "RAM" }
                    Gauge { value: backend.diskUsage; label: "DISK" }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.25)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StatRow { label: "THEME"; value: backend.themeName.toUpperCase() }
                    StatRow { label: "SYSTEM UPTIME"; value: backend.sysuptime }
                    StatRow { label: "PACKAGE COUNT"; value: backend.pkgcnt }
                    StatRow { label: "PANEL OVERDRIVE"; value: backend.paneloverd }
                    StatRow { label: "POWER MODE"; value: backend.powmode }
                    StatRow { label: "GFX MODE"; value: backend.gfxMode.toUpperCase() }
                    StatRow { label: "NO PROC"; value: backend.noproc  }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.25)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 18

                    RowLayout {
                        spacing: 6
                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: backend.netUp ? backend.theme.accent : Qt.rgba(backend.theme.foreground.r, backend.theme.foreground.g, backend.theme.foreground.b, 0.3)
                        }
                        Text {
                            text: "NET · " + (backend.netUp ? backend.netName : "OFFLINE")
                            color: backend.netUp ? backend.theme.foreground : Qt.rgba(backend.theme.foreground.r, backend.theme.foreground.g, backend.theme.foreground.b, 0.5)
                            font.family: "monospace"
                            font.pixelSize: 11
                        }
                    }

                    RowLayout {
                        spacing: 6
                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: backend.btUp ? backend.theme.accent : Qt.rgba(backend.theme.foreground.r, backend.theme.foreground.g, backend.theme.foreground.b, 0.3)
                        }
                        Text {
                            text: "BT · " + (backend.btUp ? (backend.btDevices + " linked") : "OFF")
                            color: backend.btUp ? backend.theme.foreground : Qt.rgba(backend.theme.foreground.r, backend.theme.foreground.g, backend.theme.foreground.b, 0.5)
                            font.family: "monospace"
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }

        // Right Gauges Panel
        Rectangle {
            id: rightPanel
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: rightCol.implicitWidth + 48
            implicitHeight: rightCol.implicitHeight + 48
            color: Qt.rgba(backend.theme.background.r, backend.theme.background.g, backend.theme.background.b, 0.55)
            radius: 10
            border.width: 1
            border.color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.5)
            clip: true

            Repeater {
                model: 4
                Shape {
                    property int corner: index
                    width: 18
                    height: 18
                    x: corner % 2 === 0 ? -1 : rightPanel.width - width + 1
                    y: corner < 2 ? -1 : rightPanel.height - height + 1
                    ShapePath {
                        strokeColor: backend.theme.accent
                        strokeWidth: 2
                        fillColor: "transparent"
                        startX: corner % 2 === 0 ? 0 : 18
                        startY: corner < 2 ? 18 : 0
                        PathLine { x: corner % 2 === 0 ? 0 : 18; y: corner < 2 ? 0 : 18 }
                        PathLine { x: corner % 2 === 0 ? 18 : 0; y: corner < 2 ? 0 : 18 }
                    }
                }
            }

            ColumnLayout {
                id: rightCol
                anchors.centerIn: parent
                spacing: 24

                Gauge { value: backend.batteryPct; label: "BATTERY"; unit: "%" }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.25)
                }
                Gauge { 
                    value: backend.netMbps > 100 ? 100 : backend.netMbps
                    textOverride: backend.netMbps < 0 ? "--" : backend.netMbps.toFixed(1)
                    label: "NET DL"
                    unit: "Mb/s" 
                  }
                  Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.25)
                }
                Gauge { 
                    value: backend.netPing > 100 ? 100 : backend.netPing
                    textOverride: backend.netPing < 0 ? "--" : Math.round(backend.netPing).toString()
                    label: "PING"
                    unit: "ms" 
                }
              } 
            }
        //Right Right Gauge
        //
         Rectangle {
            id: rightrightPanel
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: rightrightCol.implicitWidth + 48
            implicitHeight: rightrightCol.implicitHeight + 48
            color: Qt.rgba(backend.theme.background.r, backend.theme.background.g, backend.theme.background.b, 0.55)
            radius: 10
            border.width: 1
            border.color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.5)
            clip: true

            Repeater {
                model: 4
                Shape {
                    property int corner: index
                    width: 18
                    height: 18
                    x: corner % 2 === 0 ? -1 : rightrightPanel.width - width + 1
                    y: corner < 2 ? -1 : rightrightPanel.height - height + 1
                    ShapePath {
                        strokeColor: backend.theme.accent
                        strokeWidth: 2
                        fillColor: "transparent"
                        startX: corner % 2 === 0 ? 0 : 18
                        startY: corner < 2 ? 18 : 0
                        PathLine { x: corner % 2 === 0 ? 0 : 18; y: corner < 2 ? 0 : 18 }
                        PathLine { x: corner % 2 === 0 ? 18 : 0; y: corner < 2 ? 0 : 18 }
                    }
                }
            }

            ColumnLayout {
                id: rightrightCol
                anchors.centerIn: parent
                spacing: 24
                Gauge { 
                    value: backend.gpuTemp
                    label: "GPU TEMP"
                    unit: " °C"
                  }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.25)
                }
                Gauge { value: backend.gpuFanRpm > 0 ? (backend.gpuFanRpm / 7000) * 100 : 0;textOverride: backend.gpuFanRpm < 0 ? "--" : Math.round(backend.gpuFanRpm).toString(); label: "GPU FAN"; unit: "RPM" }
              }
            }
        //Right Most Gauge
        //
          Rectangle {
            id: rightmostPanel
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: rightmostCol.implicitWidth + 48
            implicitHeight: rightmostCol.implicitHeight + 48
            color: Qt.rgba(backend.theme.background.r, backend.theme.background.g, backend.theme.background.b, 0.55)
            radius: 10
            border.width: 1
            border.color: Qt.rgba(backend.theme.accent.r, backend.theme.accent.g, backend.theme.accent.b, 0.5)
            clip: true

            Repeater {
                model: 4
                Shape {
                    property int corner: index
                    width: 18
                    height: 18
                    x: corner % 2 === 0 ? -1 : rightmostPanel.width - width + 1
                    y: corner < 2 ? -1 : rightmostPanel.height - height + 1
                    ShapePath {
                        strokeColor: backend.theme.accent
                        strokeWidth: 2
                        fillColor: "transparent"
                        startX: corner % 2 === 0 ? 0 : 18
                        startY: corner < 2 ? 18 : 0
                        PathLine { x: corner % 2 === 0 ? 0 : 18; y: corner < 2 ? 0 : 18 }
                        PathLine { x: corner % 2 === 0 ? 18 : 0; y: corner < 2 ? 0 : 18 }
                    }
                }
            }

            ColumnLayout {
                id: rightmostCol
                anchors.centerIn: parent
                spacing: 24

                Gauge { value: backend.gpuUsage; label: "GPU USAGE"; unit: "%" } 
              }
            }
          }
}

