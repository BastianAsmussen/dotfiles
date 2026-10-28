"""Show noctalia's backing bar on outputs whose active window is maximized."""

import json
import queue
import subprocess
import sys
import threading
import time

BAR = "backing"
THRESHOLD = 0.98
RETRY = 2
RESYNC = 30


def niri_json(*args):
    """Run a niri msg query and decode its JSON reply."""
    out = subprocess.run(
        ["niri", "msg", "--json", *args],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(out.stdout)


class State:
    """Window, workspace and output state mirrored from niri events."""

    def __init__(self):
        self.widths = {}
        self.workspaces = {}
        self.windows = {}
        self.overview = False
        self.handlers = {
            "WorkspacesChanged": self._workspaces_changed,
            "WorkspaceActivated": self._workspace_activated,
            "WorkspaceActiveWindowChanged": self._active_window_changed,
            "WindowsChanged": self._windows_changed,
            "WindowOpenedOrChanged": self._window_changed,
            "WindowClosed": self._window_closed,
            "WindowLayoutsChanged": self._layouts_changed,
            "OverviewOpenedOrClosed": self._overview_changed,
            "ConfigLoaded": lambda _: self.load_outputs(),
        }

    def load_outputs(self):
        """Refresh the logical width of every enabled output."""
        self.widths = {
            name: output["logical"]["width"]
            for name, output in niri_json("outputs").items()
            if output.get("logical")
        }

    def handle(self, event):
        """Apply one niri event to the mirrored state."""
        kind, body = next(iter(event.items()))
        handler = self.handlers.get(kind)
        if handler is not None:
            handler(body)

    def _workspaces_changed(self, body):
        self.workspaces = {ws["id"]: ws for ws in body["workspaces"]}
        outputs = {ws["output"] for ws in body["workspaces"]}
        if not outputs <= self.widths.keys() | {None}:
            self.load_outputs()

    def _workspace_activated(self, body):
        active = self.workspaces.get(body["id"])
        if active is None:
            return
        for ws in self.workspaces.values():
            if ws["output"] == active["output"]:
                ws["is_active"] = ws["id"] == body["id"]

    def _active_window_changed(self, body):
        ws = self.workspaces.get(body["workspace_id"])
        if ws is not None:
            ws["active_window_id"] = body["active_window_id"]

    def _windows_changed(self, body):
        self.windows = {w["id"]: w for w in body["windows"]}

    def _window_changed(self, body):
        self.windows[body["window"]["id"]] = body["window"]

    def _window_closed(self, body):
        self.windows.pop(body["id"], None)

    def _layouts_changed(self, body):
        for window_id, layout in body["changes"]:
            if window_id in self.windows:
                self.windows[window_id]["layout"] = layout

    def _overview_changed(self, body):
        self.overview = body["is_open"]

    def maximized(self, ws):
        """Whether the workspace's active window spans its output."""
        window = self.windows.get(ws["active_window_id"])
        if window is None or window["is_floating"]:
            return False
        width = window["layout"]["tile_size"][0]
        return width >= THRESHOLD * self.widths[ws["output"]]

    def wanted(self):
        """Map each output to whether its backing bar should show."""
        return {
            ws["output"]: not self.overview and self.maximized(ws)
            for ws in self.workspaces.values()
            if ws["is_active"] and ws["output"] in self.widths
        }


def show_backing(output, show):
    """Show or hide the backing bar on one output; True on success."""
    action = "bar-show" if show else "bar-hide"
    result = subprocess.run(
        ["noctalia", "msg", action, BAR, output],
        capture_output=True,
        text=True,
        check=False,
    )
    return result.returncode == 0 and not result.stdout.startswith("error")


def read_events(stream, events):
    """Queue decoded niri events; None marks the end of the stream."""
    for line in stream:
        events.put(json.loads(line))
    events.put(None)


def main():
    """Mirror niri state and keep each output's backing bar in sync."""
    state = State()
    state.load_outputs()
    events = queue.Queue()

    with subprocess.Popen(
        ["niri", "msg", "--json", "event-stream"],
        stdout=subprocess.PIPE,
        text=True,
    ) as stream:
        threading.Thread(
            target=read_events, args=(stream.stdout, events), daemon=True
        ).start()

        applied = {}
        last_sync = time.monotonic()
        while True:
            try:
                event = events.get(timeout=RETRY)
            except queue.Empty:
                event = {}

            if event is None:
                sys.exit("niri event stream closed")
            if event:
                state.handle(event)

            if time.monotonic() - last_sync >= RESYNC:
                applied.clear()
                last_sync = time.monotonic()

            for output, show in state.wanted().items():
                if applied.get(output) != show and show_backing(output, show):
                    applied[output] = show


if __name__ == "__main__":
    main()
