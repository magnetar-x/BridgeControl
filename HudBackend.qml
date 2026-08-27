import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: backendRoot

    // ── State Properties ───────────────────────────────────────────────
    property real cpuUsage: 0
    property real ramUsage: 0
    property real ramUsedGb: 0
    property real ramTotalGb: 0
    property real diskUsage: 0
    property real gpuUsage: -1        
    property real cpuTemp: -1
    property real gpuTemp: -1
    property real cpuFanRpm: -1
    property real gpuFanRpm: -1
    property string gfxMode: "--"     
    property int  batteryPct: -1
    property string batteryState: "unknown"
    property bool netUp: false
    property string netName: "--"
    property bool btUp: false
    property int btDevices: 0
    property int noproc : 0
    property string powmode : "--"
    property string paneloverd : "--"
    property int pkgcnt : 0
    property string sysuptime : "--"
    // Sidebar Metrics
    property int volLevel: -1
    property int briLevel: -1
    property int kbdBriLevel: -1
    property real netMbps: 0
    property real netPing: -1
    property string themeName: "Unknown"

    property var _prevCpu: null
    property var _prevRx: null

    // ── Theme Data ────────────────────────────────────────────────────
    property alias theme: themeObj
    QtObject {
        id: themeObj
        property color background: "#0a0e14"
        property color foreground: "#c7d3e0"
        property color accent: "#00e5ff"
        property color muted: "#5c6773"
        property color urgent: "#ff4d4d"
    }

    // ── Polling ───────────────────────────────────────────────────────
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            colorsProc.running = true
            cpuProc.running = true
            memProc.running = true
            diskProc.running = true
            gfxModeProc.running = true
            gpuProc.running = true
            sensorsProc.running = true
            fanProc.running = true
            battProc.running = true
            netProc.running = true
            btProc.running = true
            volProc.running = true
            briProc.running = true
            kbdBriProc.running = true
            rxProc.running = true
            pingProc.running = true
            themeNameProc.running = true
            noprocProc.running = true
            powmodeProc.running = true
            paneloverdProc.running = true
            sysuptimeProc.running = true
            pkgcntProc.running = true
        }
    }

    // ── Data Fetchers ─────────────────────────────────────────────────
    
    Process {
        id: sysuptimeProc
        command: ["sh", "-c", "uptime -p | cut -c 4-"]
        stdout: StdioCollector {
            onStreamFinished: {
              var md = text.trim()
              backendRoot.sysuptime = md
          }
        }
    }
    
    Process {
        id: pkgcntProc
        command: ["sh", "-c", "pacman -Qq | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: {
              var md = text.trim()
              backendRoot.pkgcnt = parseInt(md)
          }
        }
    }


    Process {
        id: paneloverdProc
        command: ["sh", "-c", "output=$(asusctl armoury get panel_overdrive | grep '(1)' 2>&1); [ -z '$output' ] && echo 'OFF' || echo 'ON' "]
        stdout: StdioCollector {
            onStreamFinished: {
              var md = text.trim()
              backendRoot.paneloverd = md
          }
        }
    }


    Process {
        id: powmodeProc
        command: ["sh", "-c", "asusctl profile get | grep 'Active' | awk '{print $3}'"]
        stdout: StdioCollector {
            onStreamFinished: {
              var md = text.trim()
              backendRoot.powmode = md
          }
        }
    }


    Process {
        id: noprocProc
        command: ["sh", "-c", "ps -e | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: {
              var n = text.trim()
              backendRoot.noproc = parseInt(n)
            }
        }
    }

    Process {
        id: colorsProc
        command: ["sh", "-c", "cat ~/.local/state/omarchy/current/theme/colors.toml 2>/dev/null || cat ~/.config/omarchy/current/theme/colors.toml 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                function tomlValue(key) {
                    var re = new RegExp("^" + key + "\\s*=\\s*\"([^\"]+)\"", "m")
                    var m = re.exec(text)
                    return m ? m[1] : null
                }
                var acc = tomlValue("accent")
                var bg = tomlValue("background")
                var fg = tomlValue("foreground")
                var mut = tomlValue("muted")
                var urg = tomlValue("urgent") || tomlValue("red")
                if (acc) { backendRoot.theme.accent = acc }
                if (bg) { backendRoot.theme.background = bg }
                if (fg) { backendRoot.theme.foreground = fg }
                if (mut) { backendRoot.theme.muted = mut }
                if (urg) { backendRoot.theme.urgent = urg }
            }
        }
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "head -n1 /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(/\s+/).slice(1).map(Number)
                var idle = parts[3] + parts[4]
                var total = parts.reduce(function(a, b) { return a + b }, 0)
                if (backendRoot._prevCpu) {
                    var totalDelta = total - backendRoot._prevCpu.total
                    var idleDelta = idle - backendRoot._prevCpu.idle
                    if (totalDelta > 0) {
                        backendRoot.cpuUsage = Math.max(0, Math.min(100, 100 * (1 - idleDelta / totalDelta)))
                    }
                }
                backendRoot._prevCpu = { total: total, idle: idle }
            }
        }
    }

    Process {
        id: memProc
        command: ["sh", "-c", "free -b | awk '/^Mem:/ {print $2, $3}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(/\s+/).map(Number)
                if (parts.length >= 2 && parts[0] > 0) {
                    backendRoot.ramTotalGb = parts[0] / (1024 * 1024 * 1024)
                    backendRoot.ramUsedGb = parts[1] / (1024 * 1024 * 1024)
                    backendRoot.ramUsage = 100 * parts[1] / parts[0]
                }
            }
        }
    }

    Process {
        id: diskProc
        command: ["sh", "-c", "df -P / | awk 'NR==2 {gsub(\"%\",\"\",$5); print $5}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseFloat(text.trim())
                if (!isNaN(v)) { backendRoot.diskUsage = v }
            }
        }
    }

    Process {
        id: gfxModeProc
        command: ["sh", "-c", "supergfxctl -g 2>/dev/null || echo 'Unknown'"]
        stdout: StdioCollector {
            onStreamFinished: { backendRoot.gfxMode = text.trim() || "Unknown" }
        }
    }

    Process {
        id: gpuProc
        command: ["sh", "-c", "mode=$(supergfxctl -g 2>/dev/null); if [ \"$mode\" = 'Integrated' ]; then echo 'OFF'; else nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo 'NA'; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = text.trim()
                if (t === "OFF") {
                    backendRoot.gpuUsage = -1
                    backendRoot.gpuTemp = -1
                } else if (t === "NA" || t === "") {
                    backendRoot.gpuUsage = -1
                } else {
                    var parts = t.split(",").map(function(s) { return parseFloat(s.trim()) })
                    backendRoot.gpuUsage = parts[0]
                    if (parts.length > 1 && !isNaN(parts[1])) { backendRoot.gpuTemp = parts[1] }
                }
            }
        }
    }

    Process {
        id: sensorsProc
        command: ["sh", "-c", "sensors -j 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    var bestTemp = -1
                    for (var chip in data) {
                        var feats = data[chip]
                        for (var feat in feats) {
                            var vals = feats[feat]
                            for (var key in vals) {
                                if (key.indexOf("_input") !== -1 && /temp/i.test(feat) && bestTemp < 0) {
                                    bestTemp = vals[key]
                                }
                            }
                        }
                    }
                    if (bestTemp > 0) { backendRoot.cpuTemp = bestTemp }
                } catch (e) {}
            }
        }
    }

    Process {
        id: fanProc
        command: ["sh", "-c", "HW=$(for d in /sys/class/hwmon/hwmon*; do n=$(cat \"$d/name\" 2>/dev/null); case \"$n\" in asus*) echo \"$d\"; break;; esac; done); if [ -n \"$HW\" ]; then f1=$(cat \"$HW/fan1_input\" 2>/dev/null); f2=$(cat \"$HW/fan2_input\" 2>/dev/null); echo \"${f1:--1} ${f2:--1}\"; else echo '-1 -1'; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(/\s+/).map(Number)
                backendRoot.cpuFanRpm = (parts.length > 0 && !isNaN(parts[0])) ? parts[0] : -1
                backendRoot.gpuFanRpm = (parts.length > 1 && !isNaN(parts[1])) ? parts[1] : -1
            }
        }
    }

    Process {
        id: battProc
        command: ["sh", "-c", "upower -i $(upower -e | grep BAT | head -n1) 2>/dev/null | awk '/percentage/{gsub(\"%\",\"\",$2); p=$2} /state/{s=$2} END{print p, s}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(/\s+/)
                if (parts.length >= 1 && parts[0] !== "") {
                    var p = parseFloat(parts[0])
                    if (!isNaN(p)) { backendRoot.batteryPct = p }
                    backendRoot.batteryState = parts.length > 1 ? parts[1] : "unknown"
                } else {
                    backendRoot.batteryPct = -1
                }
            }
        }
    }

    Process {
        id: netProc
        command: ["sh", "-c", "nmcli -t -f NAME,DEVICE,TYPE connection show --active 2>/dev/null | head -n1 || (ip route get 1.1.1.1 >/dev/null 2>&1 && echo 'connected')"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = text.trim()
                backendRoot.netUp = t.length > 0
                backendRoot.netName = t.length > 0 ? t.split(":")[0] : "offline"
            }
        }
    }

    Process {
        id: btProc
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off; bluetoothctl devices Connected 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                backendRoot.btUp = lines[0] === "on"
                backendRoot.btDevices = lines.length > 1 ? parseInt(lines[1]) || 0 : 0
            }
        }
    }

    Process {
        id: volProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '/Volume:/ {print int($2 * 100)}' || echo -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(text.trim())
                backendRoot.volLevel = isNaN(v) ? -1 : v
            }
        }
    }

    Process {
        id: briProc
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | awk -F, '{print $4}' | tr -d '%' || echo -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(text.trim())
                backendRoot.briLevel = isNaN(v) ? -1 : v
            }
        }
    }

    Process {
        id: kbdBriProc
        command: ["sh", "-c", "brightnessctl -d '*kbd_backlight*' -m 2>/dev/null | awk -F, '{print $4}' | tr -d '%' || echo -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(text.trim())
                backendRoot.kbdBriLevel = isNaN(v) ? -1 : v
            }
        }
    }

    Process {
        id: rxProc
        command: ["sh", "-c", "iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i==\"dev\") print $(i+1)}' | head -n1); [ -n \"$iface\" ] && cat /sys/class/net/$iface/statistics/rx_bytes || echo -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var currentRx = parseInt(text.trim())
                if (!isNaN(currentRx) && currentRx >= 0) {
                    if (backendRoot._prevRx !== null) {
                        var deltaBytes = currentRx - backendRoot._prevRx
                        if (deltaBytes >= 0) {
                            backendRoot.netMbps = (deltaBytes * 8 / 2) / 1000000 
                        }
                    } else {
                        backendRoot.netMbps = 0
                    }
                    backendRoot._prevRx = currentRx
                } else {
                    backendRoot.netMbps = -1
                }
            }
        }
    }

    Process {
        id: pingProc
        command: ["sh", "-c", "ping -c 1 -W 1 1.1.1.1 2>/dev/null | sed -n 's/.*time=\\([0-9.]*\\) ms.*/\\1/p' || echo -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = parseFloat(text.trim())
                backendRoot.netPing = isNaN(p) ? -1 : p
            }
        }
    }

    Process {
        id: themeNameProc
        command: ["sh", "-c", "cat /home/magnetar/.local/state/omarchy/current/theme.name || echo 'Unknown'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = text.trim()
                backendRoot.themeName = t !== "" ? t : "Unknown"
            }
        }
    }
}
