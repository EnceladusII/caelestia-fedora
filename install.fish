#!/usr/bin/env fish

argparse -n 'install.fish' -X 0 \
    'h/help' \
    'noconfirm' \
    'spotify=?!contains -- "$_flag_value" spotify deezer' \
    'vscode=?!contains -- "$_flag_value" codium code' \
    'discord=?!contains -- "$_flag_value" discord vesktop' \
    'zen' \
    -- $argv
or exit

# Print help
if set -q _flag_h
    echo 'usage: ./install.sh [-h] [--noconfirm] [--spotify] [--vscode] [--discord] [--paru]'
    echo
    echo 'options:'
    echo ' -h, --help show this help message and exit'
    echo ' --noconfirm skip confirmations (maps to dnf -y, flatpak -y)'
    echo ' --spotify=[spotify|deezer] install Spotify (Flatpak) or Deezer (Flatpak)'
    echo ' --vscode=[codium|code] install VSCodium (COPR) or VSCode (Microsoft repo)'
    echo ' --discord=[discord|vesktop] install Discord (Flatpak) or Vektop (rpm)'
    echo ' --zen install Zen browser (Flatpak if available)'
    exit
end


# Helper funcs
function _out -a colour text
    set_color $colour
    # Pass arguments other than text to echo
    echo $argv[3..] -- ":: $text"
    set_color normal
end

function log -a text
    _out cyan $text $argv[2..]
end

function input -a text
    _out blue $text $argv[2..]
end

function confirm-overwrite -a path
    if test -e $path -o -L $path
        # No prompt if noconfirm
        if set -q noconfirm
            input "$path already exists. Overwrite? [Y/n]"
            log 'Removing...'
            rm -rf $path
        else
            # Prompt user
            read -l -p "input '$path already exists. Overwrite? [Y/n] ' -n" confirm || exit 1

            if test "$confirm" = 'n' -o "$confirm" = 'N'
                log 'Skipping...'
                return 1
            else
                log 'Removing...'
                rm -rf $path
            end
        end
    end
    return 0
end


# Variables
set -q _flag_noconfirm && set noconfirm '-y'
set -q XDG_CONFIG_HOME && set -l config $XDG_CONFIG_HOME || set -l config $HOME/.config
set -q XDG_STATE_HOME && set -l state $XDG_STATE_HOME || set -l state $HOME/.local/state

# Startup prompt
set_color magenta
echo '╭─────────────────────────────────────────────────╮'
echo '│      ______           __          __  _         │'
echo '│     / ____/___ ____  / /__  _____/ /_(_)___ _   │'
echo '│    / /   / __ `/ _ \/ / _ \/ ___/ __/ / __ `/   │'
echo '│   / /___/ /_/ /  __/ /  __(__  ) /_/ / /_/ /    │'
echo '│   \____/\__,_/\___/_/\___/____/\__/_/\__,_/     │'
echo '│                                                 │'
echo '╰─────────────────────────────────────────────────╯'
set_color normal
log 'Welcome to the Caelestia dotfiles installer (Fedora)!'
log 'Before continuing, please ensure you have made a backup of your config directory.'

# Prompt for backup
if ! set -q _flag_noconfirm
    log '[1] Two steps ahead of you!  [2] Make one for me please!'
    read -l -p "input '=> ' -n" choice || exit 1

    if contains -- "$choice" 1 2
        if test $choice = 2
            log "Backing up $config..."

            if test -e $config.bak -o -L $config.bak
                read -l -p "input 'Backup already exists. Overwrite? [Y/n] ' -n" overwrite || exit 1

                if test "$overwrite" = 'n' -o "$overwrite" = 'N'
                    log 'Skipping...'
                else
                    rm -rf $config.bak
                    cp -r $config $config.bak
                end
            else
                cp -r $config $config.bak
            end
        end
    else
        log 'No choice selected. Exiting...'
        exit 1
    end
end


# Fedora Helpers:

function ensure_rpmfusion
    if ! rpm -q rpmfusion-free-release &>/dev/null
        log 'Enabling RPM Fusion (free & nonfree)...'
        set -l rel (rpm -E %fedora)
        sudo dnf install $noconfirm \
            https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$rel.noarch.rpm \
            https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$rel.noarch.rpm
    end
end

function ensure_flatpak
    if ! command -v flatpak &>/dev/null
            log 'Installing Flatpak...'
            sudo dnf install $noconfirm flatpak
        end
        if ! flatpak remotes | string match -q '*flathub*'
            log 'Enabling Flathub...'
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    end
end

function ensure_tools
    # Base tools analogous to git/base-devel
    sudo dnf install $noconfirm git curl tar unzip libnotify swappy grim wl-clipboard slurp wf-recorder glib2 fuzzel python3-build python3-installer hatch python3-hatch-vcs libdrm-devel freeglut-devel clang ddcutil brightnessctl cava NetworkManager lm_sensors fish aubio pipewire glibc qt6-qtdeclarative libgcc libqalculate hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk gdm bluez bluez-tools inotify-tools wireplumber trash-cli foot fastfetch btop jq socat adw-gtk3-theme papirus-icon-theme qt5ct qt6ct
end

function dnf_install
    set pkgs $argv
    if test (count $pkgs) -gt 0
        sudo dnf install $noconfirm $pkgs
    end
end

ensure_tools
ensure_rpmfusion
ensure_flatpak

log 'All pre-setup is OK...'

# Install metapackage for deps
log 'Installing metapackage...'

# Cd into dir
cd (dirname (status filename)) || exit 1

# Install hypr* configs
if confirm-overwrite $config/hypr
    log 'Installing hypr* configs...'
    ln -s (realpath hypr) $config/hypr
    hyprctl reload
end

# Starship
if confirm-overwrite $config/starship.toml
    log 'Installing starship config...'
    ln -s (realpath starship.toml) $config/starship.toml
end

# Foot
if confirm-overwrite $config/foot
    log 'Installing foot config...'
    ln -s (realpath foot) $config/foot
end

# Fish
if confirm-overwrite $config/fish
    log 'Installing fish config...'
    ln -s (realpath fish) $config/fish
end

# Fastfetch
if confirm-overwrite $config/fastfetch
    log 'Installing fastfetch config...'
    ln -s (realpath fastfetch) $config/fastfetch
end

# Uwsm
if confirm-overwrite $config/uwsm
    log 'Installing uwsm config...'
    ln -s (realpath uwsm) $config/uwsm
end

# Btop
if confirm-overwrite $config/btop
    log 'Installing btop config...'
    ln -s (realpath btop) $config/btop
end

# Install spicetify
if set -q _flag_spotify
    log 'Installing spotify (spicetify)...'

    set -l has_spicetify (pacman -Q spicetify-cli 2> /dev/null)
    $aur_helper -S --needed spotify spicetify-cli spicetify-marketplace-bin $noconfirm

    # Set permissions and init if new install
    if test -z "$has_spicetify"
        sudo chmod a+wr /opt/spotify
        sudo chmod a+wr /opt/spotify/Apps -R
        spicetify backup apply
    end

    # Install configs
    if confirm-overwrite $config/spicetify
        log 'Installing spicetify config...'
        ln -s (realpath spicetify) $config/spicetify

        # Set spicetify configs
        spicetify config current_theme caelestia color_scheme caelestia custom_apps marketplace 2> /dev/null
        spicetify apply
    end
end

# Install vscode
if set -q _flag_vscode
    test "$_flag_vscode" = 'code' && set -l prog 'code' || set -l prog 'codium'
    test "$_flag_vscode" = 'code' && set -l packages 'code' || set -l packages 'vscodium-bin' 'vscodium-bin-marketplace'
    test "$_flag_vscode" = 'code' && set -l folder 'Code' || set -l folder 'VSCodium'
    set -l folder $config/$folder/User

    log "Installing vs$prog..."
    $aur_helper -S --needed $packages $noconfirm

    # Install configs
    if confirm-overwrite $folder/settings.json && confirm-overwrite $folder/keybindings.json && confirm-overwrite $config/$prog-flags.conf
        log "Installing vs$prog config..."
        ln -s (realpath vscode/settings.json) $folder/settings.json
        ln -s (realpath vscode/keybindings.json) $folder/keybindings.json
        ln -s (realpath vscode/flags.conf) $config/$prog-flags.conf

        # Install extension
        $prog --install-extension vscode/caelestia-vscode-integration/caelestia-vscode-integration-*.vsix
    end
end

# Install discord
if set -q _flag_discord
    log 'Installing discord...'
    $aur_helper -S --needed discord equicord-installer-bin $noconfirm

    # Install OpenAsar and Equicord
    sudo Equilotl -install -location /opt/discord
    sudo Equilotl -install-openasar -location /opt/discord

    # Remove installer
    $aur_helper -Rns equicord-installer-bin $noconfirm
end

# Install zen
if set -q _flag_zen
    log 'Installing zen...'
    $aur_helper -S --needed zen-browser-bin $noconfirm

    # Install userChrome css
    set -l chrome $HOME/.zen/*/chrome
    if confirm-overwrite $chrome/userChrome.css
        log 'Installing zen userChrome...'
        ln -s (realpath zen/userChrome.css) $chrome/userChrome.css
    end

    # Install native app
    set -l hosts $HOME/.mozilla/native-messaging-hosts
    set -l lib $HOME/.local/lib/caelestia

    if confirm-overwrite $hosts/caelestiafox.json
        log 'Installing zen native app manifest...'
        mkdir -p $hosts
        cp zen/native_app/manifest.json $hosts/caelestiafox.json
        sed -i "s|{{ \$lib }}|$lib|g" $hosts/caelestiafox.json
    end

    if confirm-overwrite $lib/caelestiafox
        log 'Installing zen native app...'
        mkdir -p $lib
        ln -s (realpath zen/native_app/app.fish) $lib/caelestiafox
    end

    # Prompt user to install extension
    log 'Please install the CaelestiaFox extension from https://addons.mozilla.org/en-US/firefox/addon/caelestiafox if you have not already done so.'
end

# Generate scheme stuff if needed
if ! test -f $state/caelestia/scheme.json
    caelestia scheme set -n shadotheme
    sleep .5
    hyprctl reload
end

# Start the shell
caelestia shell -d > /dev/null

log 'Done!'
