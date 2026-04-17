# dotfiles

My personal config files for macOS, kept under version control so a new machine can be set up with one command.

## What's in here

| Path in repo | Links to | Purpose |
|---|---|---|
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code settings — model, plugins, status line, hooks (terminal bell on Stop / Notification / PermissionRequest) |
| `ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` (macOS)<br>`~/.config/ghostty/config` (Linux) | Ghostty terminal config — tab behavior, bell-features for per-tab attention indicator |
| `git/.gitconfig` | `~/.gitconfig` | Personal git identity + universal settings + `includeIf` rules that overlay a separate `~/.gitconfig-work` when inside work directories |
| `zsh/zshrc` | sourced from `~/.zshrc` (not symlinked) | Oh-My-Zsh setup + universal tool hooks. Deliberately not symlinked so tools like `olm doctor` that inject into `~/.zshrc` can't pollute this repo |
| `Brewfile` | run via `brew bundle --file=...` | Homebrew packages — personal / universal CLI tools. Work-only packages live in a separate `~/.Brewfile.work` |

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

## Git identity split (personal vs work)

`git/.gitconfig` sets my personal identity as the default. Work-specific configuration lives in `~/.gitconfig-work`, which is **not** synced through this public repo — it stays on the local machine (or could live in a separate private repo).

`git/.gitconfig` pulls the work overlay in automatically whenever a repo lives under a work directory, via `includeIf`:

```gitconfig
[includeIf "gitdir:~/Documents/work/"]
    path = ~/.gitconfig-work
[includeIf "gitdir:/Volumes/Office/"]
    path = ~/.gitconfig-work
```

Default → personal. Inside those paths → work identity + work credential helpers + any other work config gets layered on top. This way a missing `~/.gitconfig-work` only causes personal commits (minor, non-leaking), never the reverse. On a new machine, create `~/.gitconfig-work` by hand with at minimum:

```gitconfig
[user]
    name = <work name>
    email = <work email>
```

## Zsh setup (stub pattern, not symlinked)

`~/.zshrc` stays as a **real file** on each machine — it's not symlinked into this repo. Tools like Microsoft's `olm doctor` want to inject PATH-management lines at the top of `~/.zshrc`; a symlinked `~/.zshrc` would route those edits straight into the public repo. The stub pattern sidesteps the whole problem.

The stub looks like this and is created automatically by `install.sh` on a fresh machine:

```zsh
# Anything a tool (olm doctor, asdf, etc.) injects lands ABOVE this line
# and runs first — exactly where those tools need it to run.

source "$HOME/Documents/GitHub/dotfiles/zsh/zshrc"

# Optional machine/work-specific overlay (not tracked in the public repo)
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
```

- **`zsh/zshrc` in this repo** — universal stuff: oh-my-zsh bootstrap, `vcpkg`, `~/.local/bin` env
- **`~/.zshrc.local` (not tracked)** — machine- or work-specific PATH entries, aliases, env vars. Create by hand on each machine.

`install.sh` won't overwrite an existing `~/.zshrc`; if one exists already, it checks whether the stub source line is present and prints guidance otherwise.

## Brew packages (personal vs work split)

Two Brewfiles, same split pattern as `.gitconfig` / `.zshrc`:

- **`Brewfile`** in this repo — personal / universal CLI tools (git, node, python, ripgrep, …)
- **`~/.Brewfile.work`** on each machine (not tracked) — work-only packages: Microsoft VFS git tap, `azure-cli`, `git-credential-manager`, iOS / .NET / Swift toolchains used for Office client work

Install either:
```sh
brew bundle --file=~/Documents/GitHub/dotfiles/Brewfile    # personal
brew bundle --file=~/.Brewfile.work                         # work (if the file exists)
```

> ⚠️ **Not managed by brew.** Microsoft's VFS-enabled git and its telemetry service install as `.pkg` files (`com.git.pkg`, `com.git-ecosystem.git-telemetry-service`), not through Homebrew. Neither Brewfile will reinstall them on a new machine — download the installers from [microsoft/git releases](https://github.com/microsoft/git/releases) (or the internal equivalent) manually. `git-credential-manager` *is* brew-managed via cask.

To add new packages, install them manually first, then append the line to the appropriate Brewfile. To regenerate from scratch, `brew bundle dump --file=<path> --force` dumps everything currently installed — but you'll have to re-split personal vs work by hand.

## Adding more configs

1. Copy the file into this repo under an app-named directory
2. Add a new `link` line at the bottom of `install.sh`
3. Commit, re-run `./install.sh`

## License

MIT
