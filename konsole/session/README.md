# konsole-session

Save every Konsole window and tab before a restart and bring them back at the next login, including the
Claude Code and Codex conversations running in them.

**openSUSE-specific.** Requires openSUSE Tumbleweed with KDE Plasma 6 (X11 or Wayland) and Plasma's
systemd-managed session.

## Install

```sh
bash konsole/session/install.sh
```

Copies `konsole-session` to `~/.local/bin/` and `konsole-session-restore.service` to
`~/.config/systemd/user/`, then enables the unit. Dependencies: `konsole`, `qt6-tools-qdbus`, `kf6-kconfig`,
`python3`.

## Use

```sh
konsole-session save     # right before restarting
```

The next login restores everything once, then archives the snapshot under
`~/.local/state/konsole-session/restored-*`. If some windows fail to open (e.g. Konsole's D-Bus service
wasn't ready), only those stay in `snapshot.json` and the unit exits non-zero, so the next login retries
just them. Snapshots and launchers hold full command lines and are created user-only (`0600`/`0700`).

A snapshot can also be restored by hand:

```sh
konsole-session restore [SNAPSHOT] [--stagger SECONDS]
```

## What comes back

| Saved | Restored as |
| --- | --- |
| Window virtual desktop, screen, geometry, maximized | Placed through a KWin script |
| Tab order, title, color, profile, working directory, active tab | Same |
| Claude Code tab | `claude … --resume <id>` with the original flags, in the directory the session was in |
| Claude Code wrapper tab (`claude-<name>`, state in `~/.claude-<name>`) | `<wrapper> … --resume <id>` of the transcript it wrote last |
| Codex tab (direct or via a wrapper script) | `codex resume <id>` of the rollout file it was writing |
| Claude Code / Codex whose conversation can't be identified | Started fresh |
| Viewer or editor on the replay allowlist (`nvim`, `vim`, `vi`, `hx`, `less`, `man`, `htop`, `btop`, `top`, `lazygit`, `tig`) | Same command line, after the resumed conversations |
| Anything else (builds, deploys, `ssh`, scripts, …) | Plain shell that prints the command it was running — never replayed unattended |
| `sudo`/`su`/`doas`/`pkexec`/`run0` | Same: plain shell, command shown, never replayed |

Extend the allowlist with `KONSOLE_SESSION_REPLAY=prog1:prog2 konsole-session save` (it is applied when
saving).

Not restored: scrollback, split views (restored as tabs), replies that were mid-flight (the conversation
resumes at its last saved message), and background tasks an agent had running.

## Staggered start

Tabs open immediately, but the commands inside them start one every `--stagger` seconds (default 20), most
recently active conversation first, so a restore doesn't start every agent at once. Slots are measured from
one shared start time, so a slow window doesn't push its tabs behind later ones. Each waiting tab shows a
countdown; Ctrl-C skips that tab's command and prints how to start it by hand.

A conversation that is already running somewhere else is not resumed a second time; its tab opens as a
plain shell.

## How it works

- Konsole's D-Bus `runCommand`/`sendText` are disabled by default, so tabs with a command start from a small
  launcher script (countdown, command, then a normal interactive shell) passed via `--tabs-from-file`.
- Each window runs in its own transient `app-konsole-session-restore-*` unit so it outlives the oneshot
  restore service.
- Plasma's own session restore reopens Konsole without the programs that were running; those windows are
  closed during a login restore and replaced.
- The unit is wanted by `xdg-desktop-autostart.target`. Hooking it to `plasma-workspace.target` creates an
  ordering cycle with `plasma-restoresession.service`, and systemd silently drops the job.
- Screen names differ between X11 and Wayland (e.g. `DP-0` vs `DP-1`), so a snapshot taken under one and
  restored under the other can put windows on the wrong screen.
