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
    sudo dnf $noconfirm upgrade
end

function ensure_rpmfusion
    if ! rpm -q rpmfusion-free-release &>/dev/null
        log 'Enabling RPM Fusion (free & nonfree)...'
        set -l rel (rpm -E %fedora)
        sudo dnf install $noconfirm  \
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
    sudo dnf install $noconfirm git curl scdoc tar unzip libnotify swappy grim wl-clipboard pkgconf-pkg-config ffmpeg-free-devel libavutil-free libavutil-free-devel slurp wf-recorder glib2 fuzzel python3-build python3-installer hatch python3-hatch-vcs libdrm-devel freeglut-devel clang ddcutil brightnessctl cava NetworkManager lm_sensors fish aubio pipewire glibc qt6-qtdeclarative libgcc libqalculate hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk gdm bluez bluez-tools inotify-tools wireplumber trash-cli foot fastfetch btop jq socat adw-gtk3-theme papirus-icon-theme qt5ct qt6ct wayland-protocols-devel hyprland-protocols-devel hyprlang sdbus-cpp hyprwayland-scanner-devel ImageMagick pulseaudio-libs cargo go xdg-utils nodejs-npm cmake pkg-config pango cairo hyprutils libxkbcommon libjpeg-turbo --allowerasing
end

function sass_install
    sudo npm install -g sass
end

function dnf_install
    set pkgs $argv
    if test (count $pkgs) -gt 0
        sudo dnf install $noconfirm $pkgs
    end
end

function starship_install
    sudo dnf copr enable $noconfirm atim/starship
    sudo dnf install $noconfirm starship
end

function quickshell_install
    sudo dnf copr enable $noconfirm errornointernet/quickshell
    sudo dnf install $noconfirm quickshell-git
end

function material_symbols_install --description 'Install Google Material Symbols fonts for current user'
   mkdir -p ~/.local/share/fonts

   wget -O ~/.local/share/fonts/MaterialYou/MaterialSymbolsRounded.ttf "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf"
   wget -O ~/.local/share/fonts/MaterialYou/MaterialSymbolsOutlined.ttf "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsOutlined%5BFILL,GRAD,opsz,wght%5D.ttf"
   wget -O ~/.local/share/fonts/MaterialYou/MaterialSymbolsSharp.ttf "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsSharp%5BFILL,GRAD,opsz,wght%5D.ttf"
end

function fonts_install
    mkdir -p ~/.local/share/fonts

    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip -O /tmp/CascadiaCode.zip
    unzip /tmp/CascadiaCode.zip -d ~/.local/share/fonts/CascadiaCode

    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip -O /tmp/JetBrainsMono.zip
    unzip /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono

    fc-cache -fv
end

function wl-screenrec_install --description 'Build & install wl-screenrec (Fedora, current stack)'
    set -l base_deps pkgconf-pkg-config gcc make

    echo (set_color green)"==> Build dependencies"(set_color normal)
    sudo dnf install -y $base_deps ffmpeg-free-devel; or return 1

    # Make sure we don't have custom pkg-config vars that hide system .pc files
    set -e PKG_CONFIG_LIBDIR
    set -e PKG_CONFIG_PATH

    echo (set_color green)"==> Verify pkg-config (libavutil)"(set_color normal)
    if not pkg-config --exists libavutil
        echo (set_color red)"ERROR: pkg-config cannot find libavutil (FFmpeg). Check ffmpeg-free-devel."(set_color normal)
        echo "Tip: rpm -ql ffmpeg-free-devel | grep pkgconfig/libavutil.pc"
        return 1
    end

    echo (set_color green)"==> Compiling wl-screenrec"(set_color normal)
    cargo install --force wl-screenrec; or return 1

    # Ensure ~/.cargo/bin is on PATH (universal for all future fish sessions)
    set -l cargo_bin "$HOME/.cargo/bin"
    set -l added_to_path 0
    if test -d $cargo_bin
        if not contains -- $cargo_bin $PATH
            echo (set_color yellow)"==> ~/.cargo/bin not in PATH; adding universally"(set_color normal)
            if type -q fish_add_path
                fish_add_path -U $cargo_bin; or true
            else
                # Fallback for older fish
                set -U fish_user_paths $cargo_bin $fish_user_paths
            end
            set added_to_path 1
        end
    else
        echo (set_color yellow)"Note: $cargo_bin does not exist yet; cargo should create it on first install."(set_color normal)
    end

    # Verify the installed binary is reachable
    set -l bin_path "$cargo_bin/wl-screenrec"
    if test -x $bin_path
        if type -q wl-screenrec
            echo (set_color green)"OK. wl-screenrec is installed and on PATH."(set_color normal)
        else
            echo (set_color yellow)"Installed, but not on current PATH. Open a new fish session or run:"(set_color normal)
            echo "  set -gx PATH $cargo_bin \$PATH"
        end
    else
        echo (set_color red)"ERROR: wl-screenrec binary not found at $bin_path"(set_color normal)
        echo "Check cargo output or reinstall."
        return 1
    end

    if test $added_to_path -eq 1
        echo (set_color yellow)"Note: PATH updated universally; new shells will include ~/.cargo/bin automatically."(set_color normal)
    end

    echo (set_color green)"OK. Try: wl-screenrec --help"(set_color normal)
end


function cliphist_install
    go install go.senan.xyz/cliphist@latest
    if test -d $HOME/go/bin
        if type -q fish_add_path
            fish_add_path -U $HOME/go/bin
        else
            set -U fish_user_paths $HOME/go/bin $fish_user_paths
        end
    end
end

function hyprptools_install
    sudo dnf copr enable aneagle/ags-3 $noconfirm
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
log 'System up-to-date'
ensure_tools
log 'Installed dependencies packages'
ensure_rpmfusion
log 'RPM fusion installed'
ensure_flatpak
log 'flatpak activated'
quickshell_install
log 'quickshell installed'
wl-screenrec_install
log 'wl-screenrec installed'
starship_install
log 'starship installed'
material_symbols_install
log 'materialyou installed'
fonts_install
log 'fonts installed'
cliphist_install
log 'cliphist installed'
hyprptools_install
log 'Hyprland tools installed'
app2unit_install
log 'App2Unit compiled'

log 'All pre-setup is OK...'

# Install cli and shell

function cli_install --description 'Build & install caelestia-cli from source'
    # --- Outils de build Python ---
    set -l pkgs git python3 python3-pip python3-build python3-wheel python3-installer
    echo (set_color green)"==> Installing Python build dependencies"(set_color normal)
    sudo dnf install -y $pkgs; or return 1

    # --- Répertoires de travail ---
    set -l build_root $XDG_CACHE_HOME
    if test -z "$build_root"
        set build_root "$HOME/.cache"
    end
    mkdir -p $build_root
    set -l workdir (mktemp -d "$build_root/caelestia-cli.XXXXXX"); or return 1

    echo (set_color green)"==> Cloning caelestia-cli source"(set_color normal)
    git clone --depth=1 https://github.com/EnceladusII/caelestia-fedora-cli.git $workdir/cli; or return 1
    pushd $workdir/cli >/dev/null; or return 1

    echo (set_color green)"==> Building wheel"(set_color normal)
    python3 -m build --wheel; or begin; popd >/dev/null; return 1; end

    # --- Nettoyage des anciennes installs (système) ---
    if test -e /usr/local/bin/caelestia
        echo (set_color yellow)"==> Removing old /usr/local/bin/caelestia"(set_color normal)
        sudo rm -f /usr/local/bin/caelestia
    end

    echo (set_color green)"==> Purging previous package from site-packages"(set_color normal)
    set -l purelib (python3 -c 'import sysconfig; print(sysconfig.get_path("purelib"))')
    if test -z "$purelib"
        set purelib "/usr/local/lib/python"(python3 -c 'import sys;print(f"{sys.version_info.major}.{sys.version_info.minor}")')"/site-packages"
    end

    set -l targets \
        "$purelib/caelestia" \
        "$purelib/caelestia_cli" \
        $purelib/caelestia-*.dist-info \
        $purelib/caelestia_cli-*.dist-info \
        $purelib/caelestia*.egg-info

    for t in $targets
        if test -e $t
            echo (set_color yellow)"   - removing $t"(set_color normal)
            sudo rm -rf $t
        end
    end

    for base in /usr/local/lib /usr/lib
        set -l alt "$base/python"(python3 -c 'import sys;print(f"{sys.version_info.major}.{sys.version_info.minor}")')"/site-packages"
        if test "$alt" != "$purelib" -a -d "$alt"
            for t in \
                "$alt/caelestia" \
                "$alt/caelestia_cli" \
                $alt/caelestia-*.dist-info \
                $alt/caelestia_cli-*.dist-info \
                $alt/caelestia*.egg-info
                if test -e $t
                    echo (set_color yellow)"   - removing $t"(set_color normal)
                    sudo rm -rf $t
                end
            end
        end
    end

    # --- Installation : préférer pip pour résoudre les dépendances ---
    set -l wheel (ls dist/*.whl ^/dev/null)
    if test -n "$wheel"
        echo (set_color green)"==> Installing wheel with pip (resolves deps)"(set_color normal)
        # Fedora protège le site-packages : --break-system-packages peut être requis
        sudo python3 -m pip install --upgrade $wheel --break-system-packages; or begin
            echo (set_color red)"pip install failed; falling back to 'python -m installer' + explicit deps"(set_color normal)

            # Fallback minimal : installer le wheel brut + dépendances connues
            sudo python3 -m installer $wheel; or begin; popd >/dev/null; return 1; end

            # Dépendances runtime explicites (complète au besoin)
            set -l reqs materialyoucolor
            echo (set_color green)"==> Installing runtime deps with pip (explicit)"(set_color normal)
            sudo python3 -m pip install --upgrade $reqs --break-system-packages; or begin; popd >/dev/null; return 1; end
        end
    else
        echo (set_color red)"ERROR: wheel not found in dist/"(set_color normal)
        popd >/dev/null
        return 1
    end

    # --- Completions Fish ---
    if test -f completions/caelestia.fish
        echo (set_color green)"==> Installing Fish completion"(set_color normal)
        sudo install -Dm644 completions/caelestia.fish /usr/share/fish/vendor_completions.d/caelestia.fish; or begin; popd >/dev/null; return 1; end
    else
        echo (set_color yellow)"==> Skipping Fish completion (file not found)"(set_color normal)
    end

    popd >/dev/null

    # --- Vérifications post-install ---
    if not type -q caelestia
        echo (set_color red)"ERROR: 'caelestia' command not found after installation"(set_color normal)
        return 1
    end

    # Test d’import de la dépendance clé
    if not python3 -c "import materialyoucolor" >/dev/null 2>&1
        echo (set_color red)"ERROR: Python runtime dependency missing (materialyoucolor)."(set_color normal)
        echo "Hint: sudo python3 -m pip install materialyoucolor --break-system-packages"
        return 1
    end

    set -l binpath (command -s caelestia)
    echo (set_color green)"==> caelestia-cli installed successfully"(set_color normal)
    echo "Binary: $binpath"
    echo "Try: caelestia --help"
end

function shell_install --description 'Install Caelestia shell and build/install beat_detector'
    # Usage:
    #   shell_install [--prefix /usr/local] [--install] [--update-only] [--no-deps] [--verbose]
    # Defaults:
    #   prefix: /usr/local
    #   Without --install, binary stays in a temp build dir and path is printed.

    set -l prefix "/usr/local"
    set -l do_install 0
    set -l update_only 0
    set -l no_deps 0
    set -l verbose 0

    for arg in $argv
        switch $arg
            case --prefix=*
                set prefix (string replace -r '^--prefix=' '' -- $arg)
            case --prefix
                # next token is the value
                continue
            case --install
                set do_install 1
            case --update-only
                set update_only 1
            case --no-deps
                set no_deps 1
            case --verbose -v
                set verbose 1
            case '*'
                if test -n "$last_arg_is_prefix"
                    set prefix $arg
                    set -e last_arg_is_prefix
                else if test $arg = --prefix
                    set last_arg_is_prefix 1
                else
                    echo (set_color yellow)"[warn] Unknown argument: $arg"(set_color normal)
                end
        end
    end

    # --- Build & runtime dependencies (Fedora/RHEL-like) ---
    if test $no_deps -eq 0
        set -l pkgs git gcc-c++ pkgconf-pkg-config pipewire-devel aubio-devel libsndfile-devel fftw-devel
        echo (set_color green)"==> Installing build dependencies"(set_color normal)
        sudo dnf install -y $pkgs; or return 1
    end

    # --- XDG directories ---
    set -l xdg_conf $XDG_CONFIG_HOME
    if test -z "$xdg_conf"
        set xdg_conf "$HOME/.config"
    end
    set -l qsh_dir "$xdg_conf/quickshell"
    set -l dest_cfg "$qsh_dir/caelestia"
    mkdir -p $qsh_dir; or return 1

    # --- Clone / update repo ---
    if test -d "$dest_cfg/.git"
        echo (set_color green)"==> Updating Caelestia shell in $dest_cfg"(set_color normal)
        git -C $dest_cfg pull --ff-only; or return 1
    else if test $update_only -eq 1
        echo (set_color red)"ERROR: --update-only set but $dest_cfg is not a git repo."(set_color normal)
        return 1
    else
        echo (set_color green)"==> Cloning Caelestia shell to $dest_cfg"(set_color normal)
        git clone --depth=1 https://github.com/EnceladusII/caelestia-fedora-shell.git $dest_cfg; or return 1
    end

    # --- Source file check ---
    set -l src "$dest_cfg/assets/cpp/beat-detector.cpp"
    if not test -f "$src"
        echo (set_color red)"ERROR: beat_detector.cpp not found: $src"(set_color normal)
        return 1
    end

    # --- Select PipeWire module name ---
    set -l pw_mod libpipewire-0.3
    if not pkg-config --exists $pw_mod
        if pkg-config --exists pipewire-0.3
            set pw_mod pipewire-0.3
        end
    end

    # --- Verify pkg-config availability ---
    if not pkg-config --exists $pw_mod
        echo (set_color red)"ERROR: PipeWire dev package not found via pkg-config ($pw_mod)."(set_color normal)
        echo "Hint: sudo dnf install pipewire-devel"
        return 1
    end
    if not pkg-config --exists aubio
        echo (set_color red)"ERROR: aubio dev package not found via pkg-config (aubio)."(set_color normal)
        echo "Hint: sudo dnf install aubio-devel"
        return 1
    end

    # --- Collect flags (trim and split safely) ---
    set -l cflags_pipe (pkg-config --cflags $pw_mod | string trim | string split -n ' ')
    set -l libs_pipe   (pkg-config --libs   $pw_mod | string trim | string split -n ' ')
    set -l cflags_aub  (pkg-config --cflags aubio   | string trim | string split -n ' ')
    set -l libs_aub    (pkg-config --libs   aubio   | string trim | string split -n ' ')

    function sanitize
        for x in $argv
            if test -n "$x"; and test "$x" != "-l"
                echo $x
            end
        end
    end
    set -l cflags_pipe (sanitize $cflags_pipe)
    set -l libs_pipe   (sanitize $libs_pipe)
    set -l cflags_aub  (sanitize $cflags_aub)
    set -l libs_aub    (sanitize $libs_aub)

    # Ensure we actually link to pipewire
    if test (count $libs_pipe) -eq 0; or not contains -- -lpipewire-0.3 $libs_pipe
        set libs_pipe $libs_pipe -lpipewire-0.3
    end

    # Extra includes for SPA if the distro doesn't expose them via pkg-config
    set -l incs
    if test -d /usr/include/spa-0.2
        set incs $incs -I/usr/include/spa-0.2
    end

    # aubio typical extras (some distros put these in aubio.pc; keep guards)
    if not contains -- -laubio $libs_aub
        set libs_aub $libs_aub -laubio
    end
    if not contains -- -lsndfile $libs_aub
        set libs_aub $libs_aub -lsndfile
    end
    if not contains -- -lfftw3f $libs_aub
        set libs_aub $libs_aub -lfftw3f
    end
    if not contains -- -lm $libs_aub
        set libs_aub $libs_aub -lm
    end

    # --- Build dir & cleanup trap ---
    set -l builddir (mktemp -d ~/.cache/caelestia-bd.XXXXXX)
    set -l out "$builddir/beat_detector"
    function __bd_cleanup --on-event fish_exit
        if test -d "$builddir"
            rm -rf "$builddir"
        end
    end

    # --- Compile ---
    set -l common_cxx -std=c++17 -Wall -Wextra -Wpedantic -O2 -pipe -fno-plt
    echo (set_color green)"==> Compiling beat_detector"(set_color normal)

    if test $verbose -eq 1
        echo "[diag] argv (1 per line):"
        for a in g++ $common_cxx $cflags_pipe $cflags_aub $incs $src -o $out $libs_pipe $libs_aub
            printf "  %s\n" $a
        end
    end

    g++ $common_cxx $cflags_pipe $cflags_aub $incs $src -o $out $libs_pipe $libs_aub
    or begin
        echo (set_color red)"ERROR: compile/link failed"(set_color normal)
        echo "Diag libs:"
        echo "  pipewire: "(string join ' ' -- $libs_pipe)
        echo "  aubio   : "(string join ' ' -- $libs_aub)
        return 1
    end

    echo (set_color green)"OK:"(set_color normal)" built -> $out"

    # --- Optional install ---
    if test $do_install -eq 1
        set -l target "$prefix/lib/caelestia/beat_detector"
        echo (set_color green)"==> Installing to $target"(set_color normal)
        if test (id -u) -ne 0
            sudo install -D -m 0755 "$out" "$target"; or return 1
        else
            install -D -m 0755 "$out" "$target"; or return 1
        end
        echo (set_color green)"Installed:"(set_color normal)" $target"
    else
        echo "You can install it with:"
        echo "  sudo install -D -m 0755 $out $prefix/lib/caelestia/beat_detector"
    end
end

cli_install
log 'Caelestia CLI is Installed'
shell_install
log 'Caelestia SHELL is Installed'

# Cd into dir
cd (dirname (status filename)) || exit 1

# Install hypr* configs
if confirm-overwrite $config/hypr
    log 'Installing hypr* configs...'
    ln -s (realpath hypr) $config/hypr
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

# qt5ct
if confirm-overwrite "$config/qt5ct"
    log 'Installing qt5ct config...'
    ln -s (realpath qt5ct) $config/qt5ct
end

# qt6ct
if confirm-overwrite "$config/qt6ct"
    log 'Installing qt6ct config...'
    ln -s (realpath qt6ct) $config/qt6ct
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

log 'Done!'
