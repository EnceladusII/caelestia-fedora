# caelestia-fedora

This is the forked repo of the [caelestia dots](https://github.com/caelestia-dots/caelestia.git) for Fedora and contains the user configs for
apps. This repo also includes an install script to install the entire dots. This fork is based on 2 freezed version of the caelestia CLI (https://github.com/EnceladusII/caelestia-fedora-cli.git) (2025-08-23 9pm54) and SHELL (https://github.com/EnceladusII/caelestia-fedora-shell.git) (2025-08-23 9pm54)

## Installation

Simply clone this repo and run the install script using (you need
[`fish`](https://github.com/fish-shell/fish-shell) installed).

> [!WARNING]
> The install script symlinks all configs into place, so you CANNOT
> move/remove the repo folder once you run the install script. If
> you do, most apps will not behave properly and some (e.g. Hyprland)
> will fail to start completely. I recommend cloning the repo to an external folder like
> `~/.local/share/caelestia`.

The install script has some options for installing configs for some apps.

```
$ ./install.fish -h
usage: ./install.sh [-h] [--noconfirm] [--spotify] [--vscode] [--discord] [--paru]

options:
  -h, --help                  show this help message and exit
  --noconfirm                 do not confirm package installation
  --spotify=[spotify|deezer]  install Spotify (Spicetify) (or deezer-desktop)
  --vscode=[codium|code]      install VSCodium (or VSCode)
  --discord=[discord|vesktop] install Discord (OpenAsar + Equicord) (or vektop)
  --zen                       install Zen browser
```

For example:

```sh
sudo dnf install fish git npm
sudo npm install -g sass
git clone https://github.com/EnceladusII/caelestia-fedora.git ~/.local/share/caelestia
~/.local/share/caelestia/install.fish
```

### Manual installation

Dependencies:

-   hyprland
-   xdg-desktop-portal-hyprland
-   xdg-desktop-portal-gtk
-   hyprpicker (copr)
-   hypridle (copr)
-   wl-clipboard
-   cliphist (go)
-   bluez
-   bluez-tools
-   inotify-tools
-   app2unit (compile)
-   wireplumber
-   trash-cli
-   foot
-   fish
-   fastfetch
-   starship (copr)
-   btop
-   jq
-   socat
-   ImageMagick
-   curl
-   adw-gtk3-theme
-   papirus-icon-theme
-   qt5ct
-   qt6ct
-   ttf-jetbrains-mono-nerd (dl)

Install all dependencies and follow the installation guides of the
[shell](https://github.com/EnceladusII/caelestia-fedora-shell.git) and [cli](https://github.com/EnceladusII/caelestia-fedora-cli.git)
to install them.

Then copy or symlink the `hypr`, `foot`, `fish`, `fastfetch`, `uwsm`, `btop`, `qt5ct` and `qt6ct` folders to the
`$XDG_CONFIG_HOME` (usually `~/.config`) directory. e.g. `hypr -> ~/.config/hypr`.
Copy `starship.toml` to `$XDG_CONFIG_HOME/starship.toml`.

#### Installing Spicetify configs:

Follow the Spicetify [installation instructions](https://spicetify.app/docs/advanced-usage/installation),
copy or symlink the `spicetify` folder to `$XDG_CONFIG_HOME/spicetify` and run

```sh
spicetify config current_theme caelestia color_scheme caelestia custom_apps marketplace
spicetify apply
```

#### Installing VSCode/VSCodium configs:

Install VSCode or VSCodium, then copy or symlink `vscode/settings.json` and
`vscode/keybindings.json` into the `$XDG_CONFIG_HOME/Code/User` (or `$XDG_CONFIG_HOME/VSCodium/User`
if using VSCodium) folder. Then copy or symlink `vscode/flags.conf` to `$XDG_CONFIG_HOME/code-flags.conf`
(or `$XDG_CONFIG_HOME/codium-flags.conf` if using VSCodium).

Finally, install the extension VSIX from `vscode/caelestia-vscode-integration`.

```sh
# Use `codium` if using VSCodium
code --install-extension vscode/caelestia-vscode-integration/caelestia-vscode-integration-*.vsix
```

#### Installing Zen Browser configs:

Install Zen Browser, then copy or symlink `zen/userChrome.css` to the `chrome` folder in your
profile of choice in `~/.zen`. e.g. `zen/userChrome.css -> ~/.zen/<profile>/chrome/userChrome.css`.

Now install the native app by copying `zen/native_app/manifest.json` to
`~/.mozilla/native-messaging-hosts/caelestiafox.json` and replacing the `{{ $lib }}` string in it
with the absolute path of `~/.local/lib/caelestia` (this must be the absolute path, e.g.
`/home/user/.local/lib/caelestia`). Then copy or symlink `zen/native_app/app.fish` to
`~/.local/lib/caelestia/caelestiafox`.

Finally, install the CaelestiaFox extension from [here](https://addons.mozilla.org/en-US/firefox/addon/caelestiafox).

## Updating

Simply run `cd` into the repo directory and run `git pull` to update the configs.

## Usage

> [!NOTE]
> These dots do not contain a login manager (for now), so you must install a
> login manager yourself unless you want to log in from a TTY. I recommend
> [`ly`](https://github.com/fairyglade/ly.git), however you can use
> any login manager you want.

There aren't really any usage instructions... these are a set of dotfiles.

Here's a list of useful keybinds though:

-   `Super` - open launcher
-   `Super` + `#` - switch to workspace `#`
-   `Super` `Alt` + `#` - move window to workspace `#`
-   `Super` + `T` - open terminal (foot)
-   `Super` + `W` - open browser (firefox)
-   `Super` + `C` - open IDE (vscodium)
-   `Super` + `S` - toggle special workspace or close current special workspace
-   `Ctrl` `Alt` + `Delete` - open session menu
-   `Ctrl` `Super` + `Space` - toggle media play state
-   `Ctrl` `Super` `Alt` + `R` - restart the shell
