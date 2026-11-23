pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Front end for the animewall CLI (~/.local/bin/animewall). The CLI does the work
 * (rotation, downloads, favorites, bans, timer); this keeps its `status --json`
 * output for the panel and sends the actions.
 */
Singleton {
    id: root

    readonly property string binary: `${FileUtils.trimFileProtocol(Directories.home)}/.local/bin/animewall`
    property var status: null
    readonly property bool loaded: status !== null
    readonly property var current: status?.current ?? null
    readonly property string source: status?.source ?? "anime"
    readonly property var purities: status?.purities ?? []
    readonly property var timer: status?.timer ?? null
    readonly property var libraries: status?.libraries ?? ({})
    readonly property int pool: status?.pool ?? 0
    readonly property int banned: status?.banned ?? 0
    readonly property bool downloading: status?.download ?? false
    readonly property bool rotating: timer?.active ?? false
    readonly property int interval: timer?.interval_min ?? 5
    readonly property string nextChange: timer?.next ?? ""

    readonly property var sources: [
        { id: "anime", label: "Anime", icon: "animation" },
        { id: "real", label: "Real", icon: "person" },
        { id: "mixed", label: "Mixed", icon: "shuffle" },
        { id: "favorites", label: "Favorites", icon: "favorite" }
    ]
    readonly property var purityIds: ["sfw", "sketchy", "nsfw"]
    readonly property var intervals: [5, 10, 15, 30, 60]

    Component.onCompleted: refresh()

    function refresh() {
        if (!statusProc.running)
            statusProc.running = true;
    }

    function run(...args) {
        Quickshell.execDetached([root.binary, ...args]);
        refreshSoon.restart();
        refreshLater.restart();
    }

    function setSource(id) {
        run("source", id);
    }

    function togglePurity(id) {
        const wanted = root.purityIds.filter(p => p === id ? !root.purities.includes(p) : root.purities.includes(p));
        if (wanted.length === 0)
            return; // keep at least one purity selected
        run("purity", ...wanted);
    }

    function skip() {
        run("next");
    }

    function toggleFavorite() {
        run("favorite");
    }

    function ban() {
        run("ban");
    }

    function openWallhaven() {
        run("open");
    }

    function setInterval(minutes) {
        run("interval", minutes);
    }

    function toggleRotation() {
        run(root.rotating ? "pause" : "resume");
    }

    function toggleDownload() {
        run("download", root.downloading ? "stop" : "start");
    }

    function imageUrl(path) {
        return path ? "file://" + encodeURI(path) : "";
    }

    Process {
        id: statusProc
        command: [root.binary, "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.status = JSON.parse(text);
                } catch (e) {
                    console.warn("[Animewall] could not parse status:", e, text);
                }
            }
        }
    }

    Timer {
        id: refreshSoon
        interval: 2500
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshLater
        interval: 8000
        onTriggered: root.refresh()
    }
}
