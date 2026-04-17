# dotfiles

My personal config files for macOS, kept under version control so a new machine can be set up with one command.

## What's in here

| Path in repo | Links to | Purpose |
|---|---|---|
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code settings — model, plugins, status line, hooks (terminal bell on Stop / Notification / PermissionRequest) |
| `ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` (macOS)<br>`~/.config/ghostty/config` (Linux) | Ghostty terminal config — tab behavior, bell-features for per-tab attention indicator |

## Install

```sh
git clone https://github.com/<you>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` symlinks each file into its system location. If a real file already exists at the target, it's renamed to `<path>.bak.<timestamp>` first — nothing is silently overwritten.

After installing:

- Reload Ghostty with `Cmd+Shift+,` (or restart it) so `bell-features` takes effect
- Restart Claude Code so the new hooks load

## How the Ghostty + Claude Code bell works together

Claude Code hooks fire on three events — each runs `printf '\a' > /dev/tty`, which sends a BEL character to the terminal:

- `Stop` — the model finished its turn
- `PermissionRequest` — fires immediately on every "X to proceed" permission prompt
- `Notification` — catches idle-timeout notifications that `PermissionRequest` doesn't cover

Ghostty's `bell-features = title,attention` turns that BEL into a per-tab indicator and a macOS dock bounce — no sound. With several Claude Code sessions open across tabs, inactive ones light up when they finish or need you.

To remove the Stop bell (only get pinged on input prompts), delete the `Stop` entry in `claude/settings.json`.

## Adding more configs

1. Copy the file into this repo under an app-named directory
2. Add a new `link` line at the bottom of `install.sh`
3. Commit, re-run `./install.sh`

## License

MIT
