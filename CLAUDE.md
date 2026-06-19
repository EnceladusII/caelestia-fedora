# CLAUDE.md — caelestia-fedora

## What this repo is

A Fedora Linux port of the [caelestia](https://github.com/caelestia-dots/caelestia) dotfiles — a Quickshell + Hyprland desktop environment originally targeting Arch Linux / pacman / AUR. This branch (`fedora`) lives inside the same remote as the upstream but diverges from commit `e456e8a` to replace all Arch-specific tooling with Fedora equivalents.

**Git relationship:**
- Remote: `https://github.com/caelestia-dots/caelestia.git`
- Branch: `fedora` (tracked as `origin/fedora`)
- Upstream branch: `origin/main`
- Merge-base with upstream main: `e456e8a` (hypr: update execs to use resizer daemon)
- As of the last sync: fedora branch is ~94 commits ahead of merge-base; upstream main is ~80 commits ahead of the same base

When syncing with upstream, the correct approach is to manually cherry-pick or copy file changes — **not** `git rebase` or `git merge`, because the install scripts are fundamentally different and will always conflict.

---

## Repository layout

```
caelestia-fedora/
├── install.fish           # Fedora installer (dnf/flatpak/copr — see below)
├── hypr/                  # Hyprland window manager config
│   ├── hyprland.conf      # Top-level sourcing file
│   ├── variables.conf     # All user-facing tunables (apps, keybinds, gaps, etc.)
│   ├── hypridle.conf      # Idle/lock config (kept here; removed from upstream)
│   ├── hyprland/          # Modular Hyprland sub-configs
│   │   ├── env.conf       # Environment variables for Hyprland
│   │   ├── execs.conf     # exec-once startup commands
│   │   ├── keybinds.conf  # All keybinds (references $kb* vars from variables.conf)
│   │   ├── rules.conf     # Window rules
│   │   ├── gestures.conf  # Touchpad gesture config
│   │   ├── scrolling.conf # Scroll behaviour
│   │   ├── input.conf     # Input device settings
│   │   ├── misc.conf      # Miscellaneous Hyprland settings
│   │   ├── animations.conf
│   │   ├── decoration.conf
│   │   ├── general.conf
│   │   ├── group.conf
│   │   └── monitors/      # Fedora-specific; NOT sourced by hyprland.conf anymore
│   ├── scripts/
│   │   ├── wsaction.fish  # Workspace action helper (must be executable)
│   │   └── configs.fish   # Creates ~/.config/caelestia/{hypr-vars,hypr-user}.conf if missing
│   └── scheme/            # Colour scheme files
├── fish/                  # Fish shell config
│   ├── config.fish        # Interactive config (starship, zoxide, eza aliases, git abbrs)
│   └── functions/
│       └── fish_greeting.fish
├── foot/foot.ini          # Foot terminal emulator config
├── btop/btop.conf         # Btop system monitor config
├── fastfetch/             # Fastfetch config + fedora-specific saturn.txt logo
├── uwsm/
│   ├── env                # QT theme env vars (QT_QPA_PLATFORMTHEME=qtengine)
│   └── env-hyprland       # Wayland/XDG env vars for Hyprland session
├── firefox/               # Browser integration (from upstream, new in sync)
│   ├── userChrome.css     # Firefox/Zen chrome CSS
│   ├── user.js            # Firefox user preferences
│   ├── init_firefox.sh    # Firefox initialisation script
│   ├── native_app/        # Native messaging host for CaelestiaFox extension
│   │   ├── app.fish
│   │   └── manifest.json
│   └── caelestia-firefox-integration/  # TypeScript browser extension source
├── zen/                   # Zen browser configs (predates firefox/ split)
│   ├── userChrome.css     # Zen-specific chrome (kept in sync with upstream)
│   ├── native_app/        # Older native app location (still used by install.fish)
│   └── caelestia-firefox-integration/  # Older extension source copy
├── spicetify/Themes/caelestia/user.css
├── vscode/settings.json
├── qt5ct/                 # Fedora-only: Qt5 theme config (qt5ct tool)
│   ├── qt5ct.conf
│   └── colors/caelestia.colors
├── qt6ct/                 # Fedora-only: Qt6 theme config (qt6ct tool)
│   ├── qt6ct.conf
│   └── colors/caelestia.colors
└── starship.toml
```

**Files that do NOT exist here (Arch-only):** `PKGBUILD`, `manifest.toml`, `packages/`

---

## The installer (`install.fish`)

The installer is the largest divergence from upstream. It requires **fish shell** and runs as the installing user (uses `sudo` internally).

### What it does, in order

1. **System upgrade** — `sudo dnf upgrade`
2. **Base dependencies** — large `dnf install` of everything needed (hyprland, pipewire, ffmpeg-free-devel, cargo, go, nodejs-npm, etc.)
3. **RPM Fusion** (free + nonfree) — only if not already enabled
4. **Flatpak + Flathub** — only if not already present
5. **Quickshell** — via COPR `errornointernet/quickshell` → `quickshell-git`
6. **wl-screenrec** — compiled from source via `cargo install` (requires ffmpeg-free-devel)
7. **Starship** — via COPR `atim/starship`
8. **Material Symbols fonts** — downloaded via `wget` to `~/.local/share/fonts/MaterialYou/`
9. **Nerd Fonts** (CascadiaCode + JetBrainsMono v3.4.0) — downloaded via `wget`
10. **cliphist** — `go install go.senan.xyz/cliphist@latest`
11. **hyprpicker + hypridle** — via COPR `aneagle/ags-3`
12. **app2unit** — cloned from GitHub and built with `make`
13. **caelestia-cli** — cloned from `https://github.com/EnceladusII/caelestia-fedora-cli.git`, built as a Python wheel, installed with pip (`--break-system-packages` required on Fedora)
14. **caelestia shell** — cloned from `https://github.com/EnceladusII/caelestia-fedora-shell.git`, then compiles `beat_detector` (C++ binary using pipewire + aubio)
15. **Config symlinks** — symlinks all config directories into `$XDG_CONFIG_HOME`

### CLI flags

| Flag | Effect |
|------|--------|
| `--noconfirm` | Passes `-y` to dnf and flatpak |
| `--spotify=[spotify\|deezer]` | Installs Spotify or Deezer via Flatpak + Spicetify theme |
| `--vscode=[codium\|code]` | Installs VSCodium (COPR) or VSCode (Microsoft repo) |
| `--discord=[discord\|vesktop]` | Installs Discord (Flatpak) or Vesktop (rpm) |
| `--zen` | Installs Zen browser (Flatpak) + userChrome + native app |

### Known incomplete sections in install.fish

The `--spotify`, `--vscode`, and `--discord` optional blocks still contain `$aur_helper` and `pacman -Q` references copied from upstream that were never ported to Fedora. These blocks will fail if invoked. The `--zen` block similarly references `$aur_helper -S --needed zen-browser-bin` which is invalid on Fedora (the flatpak install is not yet wired up in code, only in the help text).

---

## Key Fedora-vs-upstream differences

### Package manager
| Upstream (Arch) | Fedora fork |
|-----------------|-------------|
| `pacman` / AUR helper (yay/paru) | `dnf` + COPR repos + Flatpak |
| PKGBUILD meta-package | Manual `dnf install` list in `ensure_tools` |
| `caelestia-meta` AUR package | No equivalent; deps installed directly |

### Tools installed differently
| Tool | Upstream | Fedora |
|------|----------|--------|
| quickshell | AUR | COPR `errornointernet/quickshell` |
| starship | AUR | COPR `atim/starship` |
| wl-screenrec | AUR | `cargo install wl-screenrec` (built from source) |
| cliphist | AUR | `go install` |
| app2unit | AUR | Cloned + `make install` |
| caelestia-cli | AUR | Cloned from `EnceladusII/caelestia-fedora-cli`, built as Python wheel |
| caelestia-shell | AUR | Cloned from `EnceladusII/caelestia-fedora-shell`, beat_detector compiled with g++ |
| hypridle / hyprpicker | AUR | COPR `aneagle/ags-3` |

### Fedora-specific additions (not in upstream)
- `qt5ct/` and `qt6ct/` configs — Qt theming on Fedora requires these separate tools instead of `qtengine`
- `hypr/hyprland/monitors/` — preset monitor configs for common resolutions (1080p, 1440p, etc.)
- `hypr/hypridle.conf` — upstream removed hypridle; fedora fork keeps it
- `fastfetch/saturn.txt` — custom Fedora logo for fastfetch greeting
- `uwsm/env` sets `QT_QPA_PLATFORMTHEME=qtengine` (upstream uses the same value but needs qt5ct/qt6ct as fallback on Fedora)

### Monitor configuration
Upstream replaced the `monitors/` directory with a single `monitor = , preferred, auto, 1` line in `hyprland.conf`. The `monitors/` directory files in this repo are **no longer auto-sourced**. Custom monitor configuration should go in `~/.config/caelestia/hypr-user.conf` (sourced at the bottom of `hyprland.conf`).

### Hyprland idle/lock
Upstream removed `hypridle` as a hard dependency. This fork keeps `hypr/hypridle.conf` for users who want idle-triggered locking. Run `hypridle -c ~/.config/hypr/hypridle.conf` separately or add it to `execs.conf`.

---

## Syncing with upstream (caelestia main branch)

The divergence strategy is to copy non-installer files directly and manually port installer changes.

### Safe to copy verbatim from upstream
All files that contain only app configs with no package manager calls:
- `btop/`, `fish/`, `foot/`, `hypr/` (all files), `spicetify/`, `uwsm/`, `vscode/`, `zen/userChrome.css`, `firefox/`, `.gitignore`, `README.md`, `starship.toml`

### Must NOT be taken from upstream
- `install.fish` — completely different; only port targeted functional changes
- `PKGBUILD`, `manifest.toml`, `packages/` — Arch-only, do not add

### Porting install.fish changes
Check `git diff e456e8a..HEAD -- install.fish` in the upstream repo (or compare the two files) and port only functional changes that apply to Fedora (e.g. new config symlinks, new `chmod` calls, new optional component logic).

### Last sync performed
Synced from upstream commit `5e99587` (June 2026). Changes applied:
- Updated 20 config files to upstream HEAD
- Added `firefox/` directory (native app, extension source, userChrome, user.js)
- Added `hypr/hyprland/gestures.conf`, `scrolling.conf`, `scripts/configs.fish`
- Added `chmod u+x $config/hypr/scripts/wsaction.fish` to installer

---

## User customisation points

Hyprland reads two user override files from `~/.config/caelestia/` (created automatically on first launch by `hypr/scripts/configs.fish`):

| File | Purpose |
|------|---------|
| `~/.config/caelestia/hypr-vars.conf` | Override Hyprland variables (apps, gaps, colours, keybinds) |
| `~/.config/caelestia/hypr-user.conf` | Arbitrary extra Hyprland config (monitor setup, extra rules, etc.) |
| `~/.config/caelestia/user-config.fish` | Extra fish shell config (sourced at end of `config.fish`) |

Put custom monitor configuration in `hypr-user.conf`, e.g.:
```ini
monitor = DP-1, 2560x1440@144, 0x0, 1
monitor = HDMI-A-1, 1920x1080@60, 2560x0, 1
```

---

## Runtime dependencies summary (Fedora)

Core (installed by `ensure_tools`): `hyprland`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`, `wireplumber`, `pipewire`, `wl-clipboard`, `inotify-tools`, `trash-cli`, `foot`, `fish`, `fastfetch`, `btop`, `jq`, `socat`, `fuzzel`, `grim`, `slurp`, `swappy`, `cava`, `brightnessctl`, `ddcutil`, `NetworkManager`, `gdm`, `bluez`, `adw-gtk3-theme`, `papirus-icon-theme`, `qt5ct`, `qt6ct`, `ImageMagick`, `cargo`, `go`, `nodejs-npm`

Built from source / non-dnf: `quickshell` (COPR), `starship` (COPR), `wl-screenrec` (cargo), `cliphist` (go), `app2unit` (make), `caelestia-cli` (Python wheel), `caelestia-shell` (g++), Material Symbols fonts (wget), CascadiaCode + JetBrainsMono Nerd Fonts (wget)
