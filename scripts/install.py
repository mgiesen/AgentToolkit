#!/usr/bin/env python3
"""AgentToolkit Installer — cross-platform (macOS, Linux, Windows).

Verteilt Skills per Symlink in die Skill-Verzeichnisse der unterstützten
Agent-Systeme.

Benutzung:
    python scripts/install.py               # interaktives Menü
    python scripts/install.py --all         # alles für alle Agents installieren
    python scripts/install.py --status      # Installationsstatus zeigen
    python scripts/install.py --uninstall  # alles deinstallieren

Windows: Symlinks brauchen entweder den Developer-Mode (Settings → Developer-Mode)
oder ein Terminal mit Admin-Rechten.
"""

from __future__ import annotations

import argparse
import os
import platform
import sys
from dataclasses import dataclass
from pathlib import Path

# ──────────────────────────────────────────────────────────────
# Pfade & Konstanten
# ──────────────────────────────────────────────────────────────

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / "assets" / "skills"


# ──────────────────────────────────────────────────────────────
# Agent-Konfiguration
# ──────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class AgentTarget:
    name: str
    skills_dir: Path


HOME = Path.home()

AGENTS: list[AgentTarget] = [
    AgentTarget(
        name="Claude Code",
        skills_dir=HOME / ".claude" / "skills",
    ),
    AgentTarget(
        name="Codex",
        skills_dir=HOME / ".codex" / "skills",
    ),
    AgentTarget(
        name="Gemini CLI",
        skills_dir=HOME / ".gemini" / "skills",
    ),
    AgentTarget(
        name="OpenCode",
        skills_dir=HOME / ".opencode" / "skills",
    ),
]


# ──────────────────────────────────────────────────────────────
# OS-Erkennung & Terminal-Styling
# ──────────────────────────────────────────────────────────────

def detect_os() -> str:
    return {
        "Darwin": "macos",
        "Linux": "linux",
        "Windows": "windows",
    }.get(platform.system(), platform.system().lower())


def _enable_windows_ansi() -> bool:
    if platform.system() != "Windows":
        return True
    try:
        import ctypes
        kernel32 = ctypes.windll.kernel32
        return bool(kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7))
    except Exception:
        return False


_USE_COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR") and _enable_windows_ansi()


def _wrap(code: str, text: str) -> str:
    return f"\033[{code}m{text}\033[0m" if _USE_COLOR else text


def bold(s: str) -> str: return _wrap("1", s)
def dim(s: str) -> str: return _wrap("2", s)
def red(s: str) -> str: return _wrap("31", s)
def green(s: str) -> str: return _wrap("32", s)
def yellow(s: str) -> str: return _wrap("33", s)
def cyan(s: str) -> str: return _wrap("36", s)


def banner() -> None:
    print()
    print(cyan(bold("  ╔══════════════════════════════════════════╗")))
    print(cyan(bold("  ║          AgentToolkit Installer          ║")))
    print(cyan(bold("  ║                @mgiesen                  ║")))
    print(cyan(bold("  ╚══════════════════════════════════════════╝")))
    print()


# ──────────────────────────────────────────────────────────────
# Discovery
# ──────────────────────────────────────────────────────────────

def get_skills() -> list[Path]:
    return [d for d in sorted(SKILLS_DIR.iterdir()) if (d / "SKILL.md").exists()]


# ──────────────────────────────────────────────────────────────
# Symlink-Helpers (cross-platform)
# ──────────────────────────────────────────────────────────────

def _readlink(p: Path) -> Path | None:
    try:
        return Path(os.readlink(p))
    except OSError:
        return None


def ensure_symlink(source: Path, target: Path) -> str:
    """Stellt sicher, dass `target` ein Symlink auf `source` ist.

    Rückgabe: 'created' | 'ok' | 'blocked' | 'failed'.
    """
    if target.is_symlink():
        if _readlink(target) == source:
            return "ok"
        target.unlink()
    elif target.exists():
        return "blocked"

    target.parent.mkdir(parents=True, exist_ok=True)
    try:
        os.symlink(source, target, target_is_directory=source.is_dir())
        return "created"
    except OSError as e:
        if platform.system() == "Windows":
            print(red(f"    ✗ Symlink fehlgeschlagen für {target.name}: "
                      "Windows benötigt Developer-Mode oder Admin-Rechte."))
        else:
            print(red(f"    ✗ Symlink fehlgeschlagen für {target.name}: {e}"))
        return "failed"


def remove_symlink_to(target: Path, source: Path) -> bool:
    if target.is_symlink() and _readlink(target) == source:
        target.unlink()
        return True
    return False


# ──────────────────────────────────────────────────────────────
# Skills
# ──────────────────────────────────────────────────────────────

def install_skills(agent: AgentTarget) -> None:
    print(dim("  Skills"))
    created = ok = blocked = 0
    for skill in get_skills():
        result = ensure_symlink(skill, agent.skills_dir / skill.name)
        if result == "created":
            print(green("    ✓"), skill.name)
            created += 1
        elif result == "ok":
            ok += 1
        elif result == "blocked":
            blocked += 1
    summary = []
    if created: summary.append(green(f"{created} installiert"))
    if ok: summary.append(f"{ok} bereits vorhanden")
    if blocked: summary.append(yellow(f"{blocked} blockiert"))
    print("    " + (", ".join(summary) if summary else dim("nichts zu tun")))


def uninstall_skills(agent: AgentTarget) -> None:
    print(dim("  Skills"))
    removed = sum(
        remove_symlink_to(agent.skills_dir / s.name, s) for s in get_skills()
    )
    print("    " + (green(f"{removed} entfernt") if removed else dim("nichts installiert")))


# ──────────────────────────────────────────────────────────────
# Status
# ──────────────────────────────────────────────────────────────

def show_status() -> None:
    skills = get_skills()
    print(f"  {bold('Repo')}: {len(skills)} Skills "
          f"(OS: {detect_os()})")
    print()

    for agent in AGENTS:
        skills_ok = skills_broken = 0
        if agent.skills_dir.exists():
            for s in skills:
                link = agent.skills_dir / s.name
                if link.is_symlink():
                    skills_ok += 1 if link.exists() else 0
                    skills_broken += 0 if link.exists() else 1

        total = len(skills)
        if total > 0 and skills_ok == total:
            marker = green("●")
        elif skills_ok > 0:
            marker = yellow("●")
        else:
            marker = dim("○")

        print(f"  {marker} {bold(agent.name)}")
        broken = f" {red(f'({skills_broken} broken)')}" if skills_broken else ""
        print(f"    Skills: {skills_ok}/{len(skills)}{broken}")

    print()


# ──────────────────────────────────────────────────────────────
# Interaktives Menü
# ──────────────────────────────────────────────────────────────

def _choose_one(prompt: str, options: list[str]) -> str | None:
    print()
    print(f"  {bold(prompt)}")
    print()
    for i, opt in enumerate(options, 1):
        print(f"  {bold(str(i))}) {opt}")
    print()
    raw = input("  Auswahl: ").strip()
    if raw.isdigit() and 1 <= int(raw) <= len(options):
        return options[int(raw) - 1]
    return None


def _choose_multi(prompt: str, options: list[str]) -> list[str]:
    print()
    print(f"  {bold(prompt)}")
    print()
    for i, opt in enumerate(options, 1):
        print(f"  {bold(str(i))}) {opt}")
    print(f"  {bold('A')}) Alle")
    print()
    raw = input("  Auswahl (z.B. 1,3 oder A): ").strip()
    if raw.lower() == "a":
        return list(options)
    chosen: list[str] = []
    for part in raw.split(","):
        part = part.strip()
        if part.isdigit() and 1 <= int(part) <= len(options):
            chosen.append(options[int(part) - 1])
    return chosen


def interactive() -> None:
    action = _choose_one("Aktion", ["Installieren", "Deinstallieren", "Status", "Beenden"])
    if action in (None, "Beenden"):
        return
    if action == "Status":
        print()
        show_status()
        return

    agent_names = [a.name for a in AGENTS]
    chosen_names = _choose_multi("Agents auswaehlen", agent_names)
    if not chosen_names:
        print(red("\n  Keine gueltige Auswahl"))
        return

    targets = [a for a in AGENTS if a.name in chosen_names]
    print()
    if action == "Installieren":
        do_install(targets)
    else:
        do_uninstall(targets)


# ──────────────────────────────────────────────────────────────
# Install / Uninstall Aktionen
# ──────────────────────────────────────────────────────────────

def do_install(targets: list[AgentTarget]) -> None:
    for agent in targets:
        print(f"  {cyan(bold(agent.name))}")
        install_skills(agent)
        print()


def do_uninstall(targets: list[AgentTarget]) -> None:
    for agent in targets:
        print(f"  {cyan(bold(agent.name))}")
        uninstall_skills(agent)
        print()


# ──────────────────────────────────────────────────────────────
# CLI
# ──────────────────────────────────────────────────────────────

def main() -> int:
    if sys.version_info < (3, 9):
        print("Fehler: Python 3.9 oder neuer erforderlich.", file=sys.stderr)
        return 1

    parser = argparse.ArgumentParser(
        description="AgentToolkit Installer — cross-platform.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Ohne Flags: interaktives Menü.",
    )
    g = parser.add_mutually_exclusive_group()
    g.add_argument("--all", action="store_true", help="alles für alle Agents installieren")
    g.add_argument("--uninstall", action="store_true", help="alles deinstallieren")
    g.add_argument("--status", action="store_true", help="Installationsstatus zeigen")
    args = parser.parse_args()

    banner()

    if args.all:
        do_install(AGENTS)
    elif args.uninstall:
        do_uninstall(AGENTS)
    elif args.status:
        show_status()
    else:
        interactive()

    return 0


if __name__ == "__main__":
    sys.exit(main())
