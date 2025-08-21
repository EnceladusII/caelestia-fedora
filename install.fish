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

function ensure_update
    sudo dnf upgrade $noconfirm
end

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
    # Base tools
    sudo dnf install $noconfirm git curl tar unzip libnotify swappy grim wl-clipboard ffmpeg-devel libavutil-free libavutil-devel slurp wf-recorder glib2 fuzzel python3-build python3-installer hatch python3-hatch-vcs libdrm-devel freeglut-devel clang ddcutil brightnessctl cava NetworkManager lm_sensors fish aubio pipewire glibc qt6-qtdeclarative libgcc libqalculate hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk gdm bluez bluez-tools inotify-tools wireplumber trash-cli foot fastfetch btop jq socat adw-gtk3-theme papirus-icon-theme qt5ct qt6ct rubygem-sass wayland-protocols-devel hyprland-protocols-devel hyprlang sdbus-cpp hyprwayland-scanner-devel ImageMagick pulseaudio-libs cargo go xdg-utils nodejs-npm cmake pkg-config pango cairo hyprutils libxkbcommon libjpeg-turbo
end

function dnf_install
    set pkgs $argv
    if test (count $pkgs) -gt 0
        sudo dnf install $noconfirm $pkgs
    end
end

function starship_install
    sudo dnf copr enable atim/starship
    sudo dnf install $noconfirm starship
end

function material_symbols_install
    sudo npm install material-symbols@latest
end

function fonts_install
    mkdir -p ~/.local/share/fonts

    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip -O /tmp/CascadiaCode.zip
    unzip /tmp/CascadiaCode.zip -d ~/.local/share/fonts/CascadiaCode

    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip -O /tmp/JetBrainsMono.zip
    unzip /tmp/JetBrainsMono.zip -d ~/,local/share/fonts/JetBrainsMono

    fc-cache -fv
end

function wl-screenrec_install
    cargo install wl-screenrec
end

function cliphist_install
    go install go.senan.xyz/cliphist@latest
end

function hyprptools_install
    sudo dnf copr enable aneagle/ags-3
    sudo dnf install $noconfirm hyprpicker hypridle
end

function app2unit_install --description 'Build & install app2unit (and xdg-terminal-exec if missing) safely'
    set -l build_root $XDG_CACHE_HOME
    if test -z "$build_root"
        set build_root "$HOME/.cache"
    end
    mkdir -p $build_root
    set -l workdir (mktemp -d "$build_root/app2unit.XXXXXX") ; or begin
        echo (set_color red)"ERROR: mktemp failed"(set_color normal)
        return 1
    end

    set -l pkgs git make coreutils findutils grep sed which systemd xdg-utils desktop-file-utils dash
    echo (set_color green)"==> Installing base dependencies"(set_color normal)
    sudo dnf install -y $pkgs ; or return 1

    if not type -q xdg-terminal-exec
        echo (set_color yellow)"==> Installing xdg-terminal-exec"(set_color normal)
        if sudo dnf info xdg-terminal-exec >/dev/null 2>&1
            sudo dnf install -y xdg-terminal-exec ; or return 1
        else
            set -l xte_dir "$workdir/xdg-terminal-exec"
            git clone --depth=1 https://github.com/Vladimir-csp/xdg-terminal-exec.git $xte_dir ; or return 1
            pushd $xte_dir >/dev/null ; or return 1
            make ; or begin; popd >/dev/null; return 1; end
            sudo make PREFIX=/usr install ; or begin; popd >/dev/null; return 1; end
            popd >/dev/null
        end
    end

    set -l app2_dir "$workdir/app2unit"
    git clone --depth=1 https://github.com/Vladimir-csp/app2unit.git $app2_dir ; or return 1
    if not test -f "$app2_dir/Makefile"
        echo (set_color red)"ERROR: Makefile not found in $app2_dir"(set_color normal)
        return 1
    end
    pushd $app2_dir >/dev/null ; or return 1
    make ; or begin; popd >/dev/null; return 1; end
    sudo make PREFIX=/usr install ; or begin; popd >/dev/null; return 1; end
    popd >/dev/null

    # Sanity check
    if not type -q app2unit
        echo (set_color red)"ERROR: app2unit not in PATH after install"(set_color normal)
        return 1
    end

    echo (set_color green)"==> app2unit installed successfully"(set_color normal)
    echo "Try: app2unit --help"

    # rm -rf $workdir
end

ensure_update
ensure_tools
ensure_rpmfusion
ensure_flatpak
wl-screenrec_install
starship_install
material_symbols_install
fonts_install
cliphist_install
hyprptools_install
app2unit_install

log 'All pre-setup is OK...'

# Install cli and shell

function cli_install --description 'Build & install caelestia-cli from source'
    # Dépendances de base
    set -l pkgs git python3 python3-pip python3-build python3-wheel python3-installer
    echo (set_color green)"==> Installing Python build dependencies"(set_color normal)
    sudo dnf install -y $pkgs; or return 1

    # Répertoire de travail sûr (dans ~/.cache)
    set -l build_root $XDG_CACHE_HOME
    if test -z "$build_root"
        set build_root "$HOME/.cache"
    end
    mkdir -p $build_root
    set -l workdir (mktemp -d "$build_root/caelestia-cli.XXXXXX") ; or return 1

    # Cloner le dépôt
    echo (set_color green)"==> Cloning caelestia-cli source"(set_color normal)
    git clone --depth=1 https://github.com/caelestia-dots/cli.git $workdir/cli; or return 1
    pushd $workdir/cli >/dev/null; or return 1

    # Build wheel
    echo (set_color green)"==> Building wheel"(set_color normal)
    python3 -m build --wheel; or begin; popd >/dev/null; return 1; end

    # Installer wheel
    echo (set_color green)"==> Installing wheel with python -m installer"(set_color normal)
    sudo python3 -m installer dist/*.whl; or begin; popd >/dev/null; return 1; end

    # Installer completion Fish
    echo (set_color green)"==> Installing Fish completion"(set_color normal)
    sudo mkdir -p /usr/share/fish/vendor_completions.d
    sudo cp completions/caelestia.fish /usr/share/fish/vendor_completions.d/; or begin; popd >/dev/null; return 1; end

    popd >/dev/null

    # Vérification
    if not type -q caelestia
        echo (set_color red)"ERROR: caelestia command not found after installation"(set_color normal)
        return 1
    end

    echo (set_color green)"==> caelestia-cli installed successfully"(set_color normal)
    echo "Try: caelestia --help"
end

function shell_install --description 'Install Caelestia shell into XDG config and build the beat detector'
    # --- Dépendances build & runtime ---
    set -l pkgs git gcc-c++ pkgconf-pkg-config pipewire-devel aubio-devel
    echo (set_color green)"==> Installing build dependencies"(set_color normal)
    sudo dnf install -y $pkgs; or return 1

    # --- Répertoires ---
    set -l xdg_conf $XDG_CONFIG_HOME
    if test -z "$xdg_conf"
        set xdg_conf "$HOME/.config"
    end
    set -l qsh_dir "$xdg_conf/quickshell"
    set -l dest_cfg "$qsh_dir/caelestia"
    mkdir -p $qsh_dir; or return 1

    # --- Clonage / mise à jour du dépôt shell ---
    if test -d "$dest_cfg/.git"
        echo (set_color green)"==> Updating Caelestia shell in $dest_cfg"(set_color normal)
        git -C $dest_cfg pull --ff-only; or return 1
    else
        echo (set_color green)"==> Cloning Caelestia shell to $dest_cfg"(set_color normal)
        git clone --depth=1 https://github.com/caelestia-dots/shell.git $dest_cfg; or return 1
    end

    # --- Compilation du beat detector ---
    set -l src "$dest_cfg/assets/beat_detector.cpp"
    if not test -f "$src"
        echo (set_color red)"ERROR: beat_detector.cpp introuvable: $src"(set_color normal)
        return 1
    end

    # Tente d'abord libpipewire-0.3, puis pipewire-0.3 en secours
    set -l pw_mod libpipewire-0.3
    if not pkg-config --exists $pw_mod
        if pkg-config --exists pipewire-0.3
            set pw_mod pipewire-0.3
        end
    end

    # Flags via pkg-config (silencieux) + includes forcés Fedora (garantis)
    set -l cflags_pipe (pkg-config --silence-errors --cflags $pw_mod)
    set -l libs_pipe   (pkg-config --silence-errors --libs   $pw_mod)
    set -l cflags_aub  (pkg-config --silence-errors --cflags aubio)
    set -l libs_aub    (pkg-config --silence-errors --libs   aubio)

    # Ajoute *toujours* les includes Fedora (au cas où pkg-config est muet/incomplet)
    set -l forced_includes "-I/usr/include/pipewire-0.3 -I/usr/include/spa-0.2"

    # Fallbacks défensifs
    if test -z "$libs_pipe"
        set libs_pipe "-lpipewire-0.3"
    end
    if test -z "$libs_aub"
        set libs_aub "-laubio"
    end

    # Affiche les flags pour diagnostiquer
    echo (set_color cyan)"[diag] Using PipeWire module: $pw_mod"(set_color normal)
    echo (set_color cyan)"[diag] CFLAGS pipewire: $cflags_pipe"(set_color normal)
    echo (set_color cyan)"[diag] CFLAGS aubio   : $cflags_aub"(set_color normal)
    echo (set_color cyan)"[diag] FORCED include : $forced_includes"(set_color normal)
    echo (set_color cyan)"[diag] LIBS pipewire : $libs_pipe"(set_color normal)
    echo (set_color cyan)"[diag] LIBS aubio    : $libs_aub"(set_color normal)

    set -l build_root $XDG_CACHE_HOME
    if test -z "$build_root"
        set build_root "$HOME/.cache"
    end
    mkdir -p $build_root; or return 1
    set -l workdir (mktemp -d "$build_root/caelestia-bd.XXXXXX"); or return 1
    set -l out "$workdir/beat_detector"

    echo (set_color green)"==> Compiling beat_detector"(set_color normal)
    # Ordre: CFLAGS -> includes forcés -> source -> -o -> LIBS
    g++ -std=c++17 -Wall -Wextra $cflags_pipe $cflags_aub $forced_includes $src -o $out $libs_pipe $libs_aub; or begin
        echo (set_color red)"ERROR: compilation échouée"(set_color normal)
        echo "Astuce: vérifie la présence du header:"
        echo "  ls -l /usr/include/pipewire-0.3/pipewire/pipewire.h"
        return 1
    end

    # --- Installation du binaire ---
    set -l sys_dest "/usr/lib/caelestia/beat_detector"
    echo (set_color green)"==> Installing beat_detector to $sys_dest"(set_color normal)
    sudo install -D -m 0755 $out $sys_dest; or return 1

    # Nettoyage
    rm -rf "$workdir"

    # --- Récapitulatif / Conseils ---
    echo (set_color green)"==> Caelestia shell installée dans $dest_cfg"(set_color normal)
    echo (set_color green)"==> beat_detector installé dans $sys_dest"(set_color normal)
    echo "Astuce: si tu choisis un autre chemin que $sys_dest, exporte:"
    echo "  set -Ux CAELESTIA_BD_PATH /chemin/vers/beat_detector"
end




cli_install
shell_install

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
