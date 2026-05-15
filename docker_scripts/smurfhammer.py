#!/usr/bin/env python3
"""
smurf — SMuRF system orchestration tool.

A Python replacement for shawnhammer.sh. Manages carrier board startup,
pyrogue servers, and pysmurf interactive sessions with live progress
display and status introspection.

Usage:
    smurf up                Start the full system
    smurf status            Show current state of all slots
    smurf down              Tear down the system
    smurf restart [slot]    Restart pyrogue on a slot
    smurf attach <slot>     Open ipython connected to a slot
    smurf logs <slot>       Tail pyrogue server logs
    smurf config            Show parsed configuration
"""

import argparse
import os
import subprocess
import sys
import tempfile
import time

try:
    import yaml
except ImportError:
    sys.exit("PyYAML required: pip install pyyaml")

# ═══════════════════════════════════════════════════════════════════════════════
# Constants
# ═══════════════════════════════════════════════════════════════════════════════

DEFAULT_CONFIG = "/data/smurf_startup_cfg/smurf_startup.yml"
POLL_INTERVAL = 1.0
SERVER_CHECK_TIMEOUT = 10.0

# ANSI
RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
CLEAR_LINE = "\033[2K"
CURSOR_UP = "\033[A"
HIDE_CURSOR = "\033[?25l"
SHOW_CURSOR = "\033[?25h"

SPINNER_FRAMES = ["◐", "◓", "◑", "◒"]


# ═══════════════════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════════════════

class Config:
    """Load and validate smurf YAML config."""

    def __init__(self, path):
        self.path = path
        with open(path) as f:
            raw = yaml.safe_load(f)

        self.shelfmanager = raw["crate"]["shelfmanager"]
        self.crate_id = raw["crate"]["id"]
        self.fans = raw["crate"].get("fans", "full")

        self.tmux_session = raw.get("tmux_session", "smurf")
        self.pysmurf_dir = raw.get("pysmurf", "/home/cryo/docker/pysmurf/current")

        self.slots = {}
        for slot_num, slot_cfg in raw.get("slots", {}).items():
            self.slots[int(slot_num)] = {
                "pyrogue": slot_cfg["pyrogue"],
                "pysmurf_cfg": slot_cfg.get("pysmurf_cfg"),
            }

        startup = raw.get("startup", {})
        self.reboot = startup.get("reboot", False)
        self.timing_master = startup.get("timing_master", False)
        self.setup = startup.get("setup", True)

    def carrier_ip(self, slot):
        return f"10.0.{self.crate_id}.{slot + 100}"

    def epics_prefix(self, slot):
        return f"smurf_server_s{slot}"


# ═══════════════════════════════════════════════════════════════════════════════
# Shell / Docker / Tmux helpers
# ═══════════════════════════════════════════════════════════════════════════════

def sh(cmd, check=False, capture=True, timeout=30):
    """Run a shell command. Returns CompletedProcess."""
    return subprocess.run(
        cmd, shell=isinstance(cmd, str),
        capture_output=capture, text=True,
        check=check, timeout=timeout,
    )


def ssh(host, cmd):
    """Run command on remote host via SSH (no password, key-based)."""
    return sh(["ssh", "-o", "StrictHostKeyChecking=no",
               "-o", "ConnectTimeout=5", f"root@{host}", cmd])


def docker_running(name):
    """Check if a docker container with this name is running."""
    r = sh(f"docker ps --format '{{{{.Names}}}}' | grep -q '^{name}$'")
    return r.returncode == 0


def docker_stop(name):
    """Stop and remove a docker container."""
    sh(f"docker rm -f {name} 2>/dev/null")


def tmux_has_session(session):
    """Check if tmux session exists."""
    return sh(["tmux", "has-session", "-t", session]).returncode == 0


def tmux_kill_session(session):
    """Kill a tmux session."""
    sh(["tmux", "kill-session", "-t", session])


def tmux_new_session(session):
    """Create a new detached tmux session."""
    sh(["tmux", "new-session", "-d", "-s", session])


def tmux_new_window(session, window, name=None):
    """Create a new tmux window."""
    cmd = ["tmux", "new-window", "-t", f"{session}:{window}"]
    if name:
        cmd += ["-n", name]
    sh(cmd)


def tmux_send(session, window, command, pane=None):
    """Send a command to a tmux window/pane."""
    target = f"{session}:{window}"
    if pane is not None:
        target += f".{pane}"
    sh(["tmux", "send-keys", "-t", target, command, "C-m"])


def tmux_split(session, window):
    """Split a tmux window vertically."""
    sh(["tmux", "split-window", "-v", "-t", f"{session}:{window}"])


def tmux_capture(session, window, lines=10, pane=None):
    """Capture recent output from a tmux pane."""
    target = f"{session}:{window}"
    if pane is not None:
        target += f".{pane}"
    r = sh(["tmux", "capture-pane", "-pt", target, "-S", f"-{lines}"])
    return r.stdout if r.returncode == 0 else ""


# ═══════════════════════════════════════════════════════════════════════════════
# Health checks
# ═══════════════════════════════════════════════════════════════════════════════

def ping_carrier(config, slot):
    """Check if carrier board is reachable."""
    ip = config.carrier_ip(slot)
    r = sh(["ping", "-c", "1", "-W", "2", ip])
    return r.returncode == 0


def is_pyrogue_up(slot):
    """Check if pyrogue docker container is running."""
    return docker_running(f"smurf_server_s{slot}")


def read_server_time(slot):
    """Read the LocalTime PV from a rogue server. Returns epoch or None."""
    pv = f"smurf_server_s{slot}:AMCc:LocalTime"
    r = sh(f"docker exec smurf_utils caget -w 1.0 -t {pv} -S", timeout=5)
    if r.returncode != 0 or not r.stdout.strip():
        return None
    try:
        t = sh(f'date "+%s" -d "{r.stdout.strip()}"', timeout=5)
        return int(t.stdout.strip()) if t.returncode == 0 else None
    except (ValueError, subprocess.TimeoutExpired):
        return None


def is_server_ready(slot):
    """Check if rogue server is responsive (LocalTime incrementing)."""
    t0 = read_server_time(slot)
    if t0 is None:
        return False
    time.sleep(1.1)
    t1 = read_server_time(slot)
    if t1 is None:
        return False
    return t1 > t0


def is_setup_complete(session, slot):
    """Check if pysmurf setup() has finished (success or failure)."""
    output = tmux_capture(session, slot, lines=15, pane=1)
    if "Done with setup" in output:
        return "done"
    if "Setup failed" in output:
        return "failed"
    return None


# ═══════════════════════════════════════════════════════════════════════════════
# Live Display
# ═══════════════════════════════════════════════════════════════════════════════

class LiveDisplay:
    """Renders a live-updating status table to the terminal."""

    STAGES = ["Carrier", "Pyrogue", "Server", "PySmRF", "Setup"]

    # Status symbols
    PENDING = f"{DIM}·{RESET}"
    WORKING = f"{YELLOW}{{frame}}{RESET}"
    DONE = f"{GREEN}✓{RESET}"
    FAILED = f"{RED}✗{RESET}"

    def __init__(self, slots):
        self.slots = sorted(slots)
        self.state = {s: ["pending"] * 5 for s in self.slots}
        self.frame_idx = 0
        self.start_time = time.time()
        self.lines_printed = 0

    def update(self, slot, stage_idx, status):
        """Update status: 'pending', 'working', 'done', 'failed'."""
        self.state[slot][stage_idx] = status

    def _symbol(self, status):
        if status == "pending":
            return f" {DIM}·{RESET}       "
        elif status == "working":
            frame = SPINNER_FRAMES[self.frame_idx % len(SPINNER_FRAMES)]
            return f" {YELLOW}{frame}{RESET}       "
        elif status == "done":
            return f" {GREEN}✓{RESET}       "
        elif status == "failed":
            return f" {RED}✗ FAIL{RESET}  "
        return f" {status:<8}"

    def render(self):
        """Redraw the table in-place."""
        self.frame_idx += 1
        elapsed = int(time.time() - self.start_time)

        # Clear previous output
        if self.lines_printed > 0:
            sys.stdout.write(f"\033[{self.lines_printed}A")

        lines = []
        lines.append(f"{BOLD} smurf up {'─' * 48}{RESET}")
        lines.append(f" ┌──────┬──────────┬──────────┬──────────┬──────────┬──────────┐")
        lines.append(f" │{BOLD} Slot │ Carrier  │ Pyrogue  │  Server  │  PySmRF  │  Setup  {RESET}│")
        lines.append(f" ├──────┼──────────┼──────────┼──────────┼──────────┼──────────┤")

        for slot in self.slots:
            cells = [self._symbol(s) for s in self.state[slot]]
            lines.append(
                f" │  {slot:<3} │{cells[0]}│{cells[1]}│{cells[2]}│{cells[3]}│{cells[4]}│"
            )

        lines.append(f" └──────┴──────────┴──────────┴──────────┴──────────┴──────────┘")
        lines.append(f" {DIM}elapsed: {elapsed}s{RESET}")

        output = "\n".join(f"{CLEAR_LINE}{line}" for line in lines)
        sys.stdout.write(output + "\n")
        sys.stdout.flush()
        self.lines_printed = len(lines)

    def finish(self, success=True):
        """Final render with completion message."""
        self.render()
        if success:
            print(f"\n {GREEN}{BOLD}All slots ready.{RESET}\n")
        else:
            print(f"\n {RED}{BOLD}Some slots failed — see above.{RESET}\n")


# ═══════════════════════════════════════════════════════════════════════════════
# Slot State Machine
# ═══════════════════════════════════════════════════════════════════════════════

class SlotState:
    """Tracks and advances the startup state for a single slot."""

    # Stage indices
    CARRIER = 0
    PYROGUE = 1
    SERVER = 2
    PYSMURF = 3
    SETUP = 4

    def __init__(self, slot, config):
        self.slot = slot
        self.config = config
        self.stage = self.CARRIER
        self.status = "working"  # current stage status
        self._server_check_start = None

    @property
    def is_done(self):
        return self.stage == self.SETUP and self.status == "done"

    @property
    def is_failed(self):
        return self.status == "failed"

    def advance(self, display):
        """Try to advance to the next state. Called each poll cycle."""
        if self.is_done or self.is_failed:
            return

        if self.stage == self.CARRIER:
            if ping_carrier(self.config, self.slot):
                display.update(self.slot, self.CARRIER, "done")
                self.stage = self.PYROGUE
                self.status = "working"
                display.update(self.slot, self.PYROGUE, "working")
                self._start_pyrogue()
            else:
                display.update(self.slot, self.CARRIER, "working")

        elif self.stage == self.PYROGUE:
            if is_pyrogue_up(self.slot):
                display.update(self.slot, self.PYROGUE, "done")
                self.stage = self.SERVER
                self.status = "working"
                display.update(self.slot, self.SERVER, "working")
                self._server_check_start = time.time()

        elif self.stage == self.SERVER:
            if is_server_ready(self.slot):
                display.update(self.slot, self.SERVER, "done")
                self.stage = self.PYSMURF
                self.status = "working"
                display.update(self.slot, self.PYSMURF, "working")
                self._start_pysmurf()
            elif (time.time() - self._server_check_start) > 120:
                display.update(self.slot, self.SERVER, "failed")
                self.status = "failed"

        elif self.stage == self.PYSMURF:
            # Give pysmurf a moment to initialize
            if self.config.setup:
                display.update(self.slot, self.PYSMURF, "done")
                self.stage = self.SETUP
                self.status = "working"
                display.update(self.slot, self.SETUP, "working")
                self._run_setup()
            else:
                display.update(self.slot, self.PYSMURF, "done")
                display.update(self.slot, self.SETUP, "done")
                self.stage = self.SETUP
                self.status = "done"

        elif self.stage == self.SETUP:
            result = is_setup_complete(self.config.tmux_session, self.slot)
            if result == "done":
                display.update(self.slot, self.SETUP, "done")
                self.status = "done"
            elif result == "failed":
                display.update(self.slot, self.SETUP, "failed")
                self.status = "failed"

    def _start_pyrogue(self):
        """Start pyrogue server in a tmux window."""
        session = self.config.tmux_session
        slot = self.slot
        pyrogue_dir = self.config.slots[slot]["pyrogue"]

        tmux_new_window(session, slot, name=f"slot{slot}")
        tmux_send(session, slot, f"cd {pyrogue_dir}")
        tmux_send(session, slot,
                  f"./run.sh -N {slot}; sleep 2; docker logs smurf_server_s{slot} -f")

    def _start_pysmurf(self):
        """Start pysmurf in a split pane below pyrogue."""
        session = self.config.tmux_session
        slot = self.slot

        tmux_split(session, slot)
        tmux_send(session, slot, f"cd {self.config.pysmurf_dir}", pane=1)
        tmux_send(session, slot, "./run.sh", pane=1)
        time.sleep(2)

        # Generate init script
        init_script = self._make_init_script()
        tmux_send(session, slot, f"ipython3 -i {init_script}", pane=1)
        time.sleep(3)

    def _run_setup(self):
        """Send S.setup() to the pysmurf pane."""
        tmux_send(self.config.tmux_session, self.slot, "S.setup()", pane=1)

    def _make_init_script(self):
        """Generate a temporary pysmurf init script."""
        slot = self.slot
        cfg = self.config.slots[slot].get("pysmurf_cfg", "")
        shelfmanager = self.config.shelfmanager
        epics_prefix = self.config.epics_prefix(slot)

        if cfg and not os.path.isabs(cfg):
            cfg = os.path.abspath(cfg)

        script = f'''import matplotlib
matplotlib.use("Agg")
import pysmurf.client
import numpy as np

S = pysmurf.client.SmurfControl(
    epics_root="{epics_prefix}",
    cfg_file="{cfg}",
    setup=False,
    make_logfile=False,
    shelf_manager="{shelfmanager}",
)
print("SmurfControl ready — use S to interact")
'''
        fd, path = tempfile.mkstemp(suffix=".py", prefix=f"smurf_s{slot}_")
        os.write(fd, script.encode())
        os.close(fd)
        return path


# ═══════════════════════════════════════════════════════════════════════════════
# Commands
# ═══════════════════════════════════════════════════════════════════════════════

def cmd_up(args, config):
    """Start the SMuRF system."""
    slots = [args.slot] if args.slot else sorted(config.slots.keys())
    reboot = config.reboot and not args.no_reboot
    session = config.tmux_session

    print(f"{BOLD}smurf up{RESET}")
    print(f"  config: {config.path}")
    print(f"  slots:  {slots}")
    print(f"  reboot: {reboot}")
    print()

    # 1. Kill existing tmux session
    if tmux_has_session(session):
        print(f"  Killing existing tmux session '{session}'...")
        tmux_kill_session(session)
        time.sleep(1)

    # 2. Stop existing pyrogue servers
    print("  Stopping existing pyrogue servers...")
    for slot in slots:
        pyrogue_dir = config.slots[slot]["pyrogue"]
        sh(f"cd {pyrogue_dir} && ./stop.sh -N {slot} 2>/dev/null")
    time.sleep(1)

    # 3. Crate fans
    if config.fans:
        level = config.fans if config.fans != "full" else 15
        print(f"  Setting crate fans to level {level}...")
        ssh(config.shelfmanager,
            f"clia minfanlevel {level}; clia setfanlevel all {level}")

    # 4. Reboot carriers
    if reboot:
        print("  Rebooting carriers...")
        for slot in slots:
            ssh(config.shelfmanager, f"clia deactivate board {slot}")
        time.sleep(5)
        for slot in slots:
            ssh(config.shelfmanager, f"clia activate board {slot}")
        print("  Waiting for carriers to come online...")
        time.sleep(10)

    # 5. Create tmux session and start utils
    tmux_new_session(session)
    time.sleep(0.5)

    # 6. Parallel state machine with live display
    print()
    sys.stdout.write(HIDE_CURSOR)

    display = LiveDisplay(slots)
    states = {s: SlotState(s, config) for s in slots}

    # Initial display
    for slot in slots:
        display.update(slot, SlotState.CARRIER, "working")
    display.render()

    try:
        while True:
            for slot in slots:
                states[slot].advance(display)
            display.render()

            if all(s.is_done or s.is_failed for s in states.values()):
                break

            time.sleep(POLL_INTERVAL)

    except KeyboardInterrupt:
        sys.stdout.write(SHOW_CURSOR)
        print(f"\n\n {YELLOW}Interrupted.{RESET} Tmux session '{session}' left running.\n")
        return

    sys.stdout.write(SHOW_CURSOR)
    all_ok = all(s.is_done for s in states.values())
    display.finish(success=all_ok)

    if all_ok:
        print(f"  Tmux session: {BOLD}tmux attach -t {session}{RESET}")
    else:
        failed = [s for s, st in states.items() if st.is_failed]
        print(f"  Failed slots: {failed}")
        print(f"  Check logs:   smurf logs <slot>")


def cmd_status(args, config):
    """Show current status of all configured slots."""
    slots = sorted(config.slots.keys())

    print(f"{BOLD}smurf status{RESET}")
    print(f" ┌──────┬─────────────────┬──────────┬──────────┐")
    print(f" │{BOLD} Slot │    Carrier      │ Pyrogue  │  Server  {RESET}│")
    print(f" ├──────┼─────────────────┼──────────┼──────────┤")

    for slot in slots:
        ip = config.carrier_ip(slot)

        # Carrier ping
        carrier_up = ping_carrier(config, slot)
        carrier_str = f"{GREEN}✓{RESET} {ip}" if carrier_up else f"{RED}✗{RESET} {ip}"

        # Pyrogue docker
        pyrogue_up = is_pyrogue_up(slot)
        pyrogue_str = f"{GREEN}✓ running{RESET}" if pyrogue_up else f"{DIM}· down{RESET}   "

        # Server EPICS
        if pyrogue_up:
            server_up = is_server_ready(slot)
            server_str = f"{GREEN}✓ ready{RESET} " if server_up else f"{YELLOW}◔ wait{RESET}  "
        else:
            server_str = f"{DIM}· down{RESET}   "

        print(f" │  {slot:<3} │ {carrier_str:<24}│ {pyrogue_str} │ {server_str} │")

    print(f" └──────┴─────────────────┴──────────┴──────────┘")


def cmd_down(args, config):
    """Tear down the system."""
    slots = [args.slot] if args.slot else sorted(config.slots.keys())
    session = config.tmux_session

    print(f"{BOLD}smurf down{RESET}")

    # Stop pyrogue servers
    for slot in slots:
        pyrogue_dir = config.slots[slot]["pyrogue"]
        name = f"smurf_server_s{slot}"
        if docker_running(name):
            print(f"  Stopping pyrogue on slot {slot}...")
            sh(f"cd {pyrogue_dir} && ./stop.sh -N {slot}")

    # Kill tmux session
    if tmux_has_session(session):
        print(f"  Killing tmux session '{session}'...")
        tmux_kill_session(session)

    print(f"  {GREEN}Done.{RESET}")


def cmd_restart(args, config):
    """Restart pyrogue on a slot."""
    slot = args.slot
    if slot is None:
        sys.exit("Usage: smurf restart <slot>")

    if slot not in config.slots:
        sys.exit(f"Slot {slot} not in config")

    pyrogue_dir = config.slots[slot]["pyrogue"]
    session = config.tmux_session

    print(f"{BOLD}smurf restart{RESET} slot {slot}")

    # Stop
    print(f"  Stopping pyrogue...")
    sh(f"cd {pyrogue_dir} && ./stop.sh -N {slot}")
    time.sleep(2)

    # Start
    print(f"  Starting pyrogue...")
    if tmux_has_session(session):
        tmux_send(session, slot,
                  f"cd {pyrogue_dir} && ./run.sh -N {slot}; "
                  f"sleep 2; docker logs smurf_server_s{slot} -f",
                  pane=0)
    else:
        sh(f"cd {pyrogue_dir} && ./run.sh -N {slot}")

    # Wait for ready
    print(f"  Waiting for server...", end="", flush=True)
    for _ in range(60):
        time.sleep(2)
        if is_pyrogue_up(slot) and is_server_ready(slot):
            print(f" {GREEN}ready{RESET}")
            return
        print(".", end="", flush=True)
    print(f" {RED}timeout{RESET}")


def cmd_attach(args, config):
    """Open an interactive pysmurf session connected to a slot."""
    slot = args.slot
    if slot not in config.slots:
        sys.exit(f"Slot {slot} not in config")

    cfg = config.slots[slot].get("pysmurf_cfg", "")
    if cfg and not os.path.isabs(cfg):
        cfg = os.path.abspath(cfg)

    epics_prefix = config.epics_prefix(slot)

    script = f'''import matplotlib
matplotlib.use("Agg")
import pysmurf.client
import numpy as np

S = pysmurf.client.SmurfControl(
    epics_root="{epics_prefix}",
    cfg_file="{cfg}",
    setup=False,
    make_logfile=False,
    shelf_manager="{config.shelfmanager}",
)
print()
print("\\033[1mSmurfControl ready\\033[0m — slot {slot}")
print("  S.setup()              Run full setup")
print("  S.tracking_setup(b)    Start tracking on band b")
print("  S.which_on(b)          Show active channels")
print()
'''
    fd, path = tempfile.mkstemp(suffix=".py", prefix=f"smurf_s{slot}_")
    os.write(fd, script.encode())
    os.close(fd)

    print(f"{BOLD}smurf attach{RESET} slot {slot}")
    print(f"  server: {epics_prefix}")
    print(f"  config: {cfg or '(none)'}")
    print()

    os.execvp("ipython3", ["ipython3", "-i", path])


def cmd_logs(args, config):
    """Tail pyrogue server logs."""
    slot = args.slot
    name = f"smurf_server_s{slot}"

    if not docker_running(name):
        sys.exit(f"Pyrogue server for slot {slot} is not running")

    print(f"{BOLD}smurf logs{RESET} slot {slot}  (Ctrl-C to stop)")
    print()
    os.execvp("docker", ["docker", "logs", name, "-f", "--tail", "50"])


def cmd_release(args, config):
    """Release/install SMuRF docker applications."""
    script_dir = os.path.dirname(os.path.realpath(__file__))
    release_script = os.path.join(script_dir, "release-docker.sh")

    if not os.path.exists(release_script):
        sys.exit(f"release-docker.sh not found at {release_script}")

    # Strip leading '--' that argparse REMAINDER may include
    release_args = args.release_args
    if release_args and release_args[0] == "--":
        release_args = release_args[1:]

    if not release_args:
        # Show release-docker.sh help if no args given
        release_args = ["--help"]

    cmd = [release_script] + release_args
    os.execvp(cmd[0], cmd)


def cmd_config(args, config):
    """Print parsed configuration."""
    print(f"{BOLD}smurf config{RESET}")
    print(f"  file: {config.path}")
    print()
    print(f"  {BOLD}Crate{RESET}")
    print(f"    shelfmanager: {config.shelfmanager}")
    print(f"    crate_id:     {config.crate_id}")
    print(f"    fans:         {config.fans}")
    print()
    print(f"  {BOLD}Tmux{RESET}")
    print(f"    session:      {config.tmux_session}")
    print()
    print(f"  {BOLD}Startup{RESET}")
    print(f"    reboot:       {config.reboot}")
    print(f"    setup:        {config.setup}")
    print(f"    timing_master:{config.timing_master}")
    print()
    print(f"  {BOLD}Pysmurf{RESET}")
    print(f"    docker:       {config.pysmurf_dir}")
    print()
    print(f"  {BOLD}Slots{RESET}")
    for slot, cfg in sorted(config.slots.items()):
        print(f"    slot {slot}:")
        print(f"      pyrogue:     {cfg['pyrogue']}")
        print(f"      pysmurf_cfg: {cfg.get('pysmurf_cfg', '(none)')}")


# ═══════════════════════════════════════════════════════════════════════════════
# Main / Argument Parsing
# ═══════════════════════════════════════════════════════════════════════════════

DESCRIPTION = f"""{BOLD}smurf{RESET} — SMuRF system orchestration tool

Commands:
  {BOLD}up{RESET}        Start the system (carriers, pyrogue, pysmurf, setup)
  {BOLD}status{RESET}    Show current state of all configured slots
  {BOLD}down{RESET}      Tear down pyrogue servers and tmux session
  {BOLD}restart{RESET}   Restart pyrogue server on a slot
  {BOLD}attach{RESET}    Open interactive pysmurf session for a slot
  {BOLD}logs{RESET}      Tail pyrogue server logs for a slot
  {BOLD}config{RESET}    Print the parsed configuration
  {BOLD}release{RESET}   Install/release SMuRF docker applications

Examples:
  smurf up                    Start everything
  smurf up --slot 2           Start only slot 2
  smurf status                Check what's running
  smurf attach 2              Jump into slot 2's pysmurf
  smurf down                  Shut it all down
  smurf restart 3             Restart slot 3's pyrogue
  smurf release -t system     Install a system release

Config file:
  Default: {DEFAULT_CONFIG}
  Override: smurf -c /path/to/config.yml <command>
"""

UP_HELP = """Start the SMuRF system (carriers, pyrogue servers, pysmurf sessions).

Sequence:
  1. Kill any existing tmux/smurf session
  2. Stop running pyrogue servers
  3. Set crate fans to configured level
  4. Reboot carriers (unless --no-reboot)
  5. Start pyrogue servers and wait for readiness
  6. Launch pysmurf sessions and run setup()

All slots are started in parallel. Progress is shown in a live table.

Examples:
  smurf up
  smurf up --slot 2
  smurf up --no-reboot
  smurf up --no-setup
"""

STATUS_HELP = """Show current state of all configured slots.

Checks carrier ping, pyrogue docker, and EPICS server readiness.
Does not modify anything — safe to run at any time.
"""

DOWN_HELP = """Tear down the system.

Stops pyrogue servers and kills the tmux session.
Use --slot to only stop a specific slot.
"""

RESTART_HELP = """Restart the pyrogue server on a slot.

Stops the pyrogue docker, restarts it, and waits for the
rogue server to become responsive again.

Example:
  smurf restart 2
"""

ATTACH_HELP = """Open an interactive pysmurf (ipython) session for a slot.

Generates a temporary init script and launches ipython3 connected
to the specified slot's rogue server. You get an 'S' object ready
to use.

Example:
  smurf attach 2
  >>> S.tracking_setup(0)
"""

LOGS_HELP = """Tail the pyrogue server logs for a slot.

Equivalent to: docker logs smurf_server_s<slot> -f --tail 50

Press Ctrl-C to stop.
"""

CONFIG_HELP = """Print the parsed configuration file in a readable format.

Shows all settings that will be used by other commands.
"""

RELEASE_HELP = """Install/release SMuRF docker applications.

This is a wrapper around release-docker.sh. All arguments after
'release' are passed directly to it.

Application types:
  system        SMuRF with preinstalled pysmurf, rogue, and firmware
  system-dev    System with modifiable pysmurf/rogue/firmware files
  pysmurf-dev   Pysmurf client with modifiable source
  utils         Utility container (EPICS tools, etc.)
  tpg           Timing Pattern Generator
  pcie          PCIe utilities for 6-carrier operation
  atca-monitor  ATCA crate monitoring interface
  guis          Remote GUI interface

Examples:
  smurf release -t system                  Install stable system
  smurf release -t system-dev              Install dev system
  smurf release -t utils                   Install utilities
  smurf release -t system -l               List available versions
  smurf release -t system -h               Show system-specific help
  smurf release --upgrade v1.2.0           Upgrade release scripts
"""


def main():
    # Intercept 'release' before argparse — it passes raw args to release-docker.sh
    if len(sys.argv) > 1 and sys.argv[1] == "release":
        args = argparse.Namespace(release_args=sys.argv[2:])
        cmd_release(args, None)
        return

    parser = argparse.ArgumentParser(
        description=DESCRIPTION,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("-c", "--config", default=DEFAULT_CONFIG,
                        help=f"Config file (default: {DEFAULT_CONFIG})")

    sub = parser.add_subparsers(dest="command")

    # up
    p_up = sub.add_parser("up", help="Start the system",
                          description=UP_HELP,
                          formatter_class=argparse.RawDescriptionHelpFormatter)
    p_up.add_argument("--slot", type=int, default=None,
                      help="Only start this slot")
    p_up.add_argument("--no-reboot", action="store_true",
                      help="Skip carrier reboot")
    p_up.add_argument("--no-setup", action="store_true",
                      help="Don't run S.setup()")

    # status
    sub.add_parser("status", help="Show slot status",
                   description=STATUS_HELP,
                   formatter_class=argparse.RawDescriptionHelpFormatter)

    # down
    p_down = sub.add_parser("down", help="Tear down the system",
                            description=DOWN_HELP,
                            formatter_class=argparse.RawDescriptionHelpFormatter)
    p_down.add_argument("--slot", type=int, default=None,
                        help="Only stop this slot")

    # restart
    p_restart = sub.add_parser("restart", help="Restart pyrogue on a slot",
                               description=RESTART_HELP,
                               formatter_class=argparse.RawDescriptionHelpFormatter)
    p_restart.add_argument("slot", type=int, nargs="?",
                           help="Slot number to restart")

    # attach
    p_attach = sub.add_parser("attach", help="Open pysmurf session for a slot",
                              description=ATTACH_HELP,
                              formatter_class=argparse.RawDescriptionHelpFormatter)
    p_attach.add_argument("slot", type=int, help="Slot number")

    # logs
    p_logs = sub.add_parser("logs", help="Tail pyrogue logs for a slot",
                            description=LOGS_HELP,
                            formatter_class=argparse.RawDescriptionHelpFormatter)
    p_logs.add_argument("slot", type=int, help="Slot number")

    # config
    sub.add_parser("config", help="Print parsed config",
                   description=CONFIG_HELP,
                   formatter_class=argparse.RawDescriptionHelpFormatter)

    # release
    p_release = sub.add_parser("release",
                               help="Install/release SMuRF docker applications",
                               description=RELEASE_HELP,
                               formatter_class=argparse.RawDescriptionHelpFormatter)
    p_release.add_argument("release_args", nargs=argparse.REMAINDER,
                           help="Arguments passed to release-docker.sh (use -- before flags)")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(0)

    # Commands that don't need a config file
    no_config_commands = {"release"}

    if args.command in no_config_commands:
        commands_no_config = {
            "release": cmd_release,
        }
        commands_no_config[args.command](args, None)
        return

    # Load config
    if not os.path.exists(args.config):
        sys.exit(f"Config file not found: {args.config}")
    config = Config(args.config)

    # Handle --no-setup
    if args.command == "up" and args.no_setup:
        config.setup = False

    # Dispatch
    commands = {
        "up": cmd_up,
        "status": cmd_status,
        "down": cmd_down,
        "restart": cmd_restart,
        "attach": cmd_attach,
        "logs": cmd_logs,
        "config": cmd_config,
    }
    commands[args.command](args, config)


if __name__ == "__main__":
    main()
