#!/usr/bin/env bash
# =============================================================
#  warm gnome rice – setup script
#  Installs the GTK theme, icons, GNOME Tweaks, User Themes
#  extension, fish shell, OMF + agnoster, GNOME extensions,
#  and sets the Gruvbox wallpaper automatically.
# =============================================================

set -eo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[rice]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }

# ── Bibata cursor install helper ──────────────────────────────
# Release assets are .tar.xz (NOT .tar.gz — that URL never existed).
# Queries the GitHub API for the real URL, falls back to a hardcoded
# versioned URL if the API is unavailable, then validates before extract.
install_bibata_from_github() {
    local dest_tmp
    dest_tmp=$(mktemp -d)

    info "Fetching Bibata cursor release info from GitHub API..."
    local api_url="https://api.github.com/repos/ful1e5/Bibata_Cursor/releases/latest"
    local download_url
    download_url=$(curl -sfL "$api_url" \
        | grep '"browser_download_url"' \
        | grep 'Bibata-Modern-Ice\.tar\.xz' \
        | grep -v 'Right' \
        | head -1 \
        | sed 's/.*"browser_download_url": *"\([^"]*\)".*/\1/')

    if [ -z "$download_url" ]; then
        warn "Could not resolve Bibata download URL from GitHub API. Trying fallback URL..."
        # Hardcoded to v2.0.6 — the latest release as of 2024-06-18
        download_url="https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.6/Bibata-Modern-Ice.tar.xz"
    fi

    info "Downloading Bibata cursor from: $download_url"
    local tarball="$dest_tmp/Bibata-Modern-Ice.tar.xz"
    if ! curl -L --fail --retry 3 --retry-delay 2 -o "$tarball" "$download_url"; then
        warn "Download failed. Install manually: https://github.com/ful1e5/Bibata_Cursor/releases/latest"
        rm -rf "$dest_tmp"
        return 1
    fi

    # Validate it's actually an xz-compressed tar before extracting
    if ! file "$tarball" | grep -qiE 'XZ compressed|xz compressed'; then
        warn "Downloaded file is not a valid .tar.xz archive (got: $(file "$tarball"))."
        warn "Install manually: https://github.com/ful1e5/Bibata_Cursor/releases/latest"
        rm -rf "$dest_tmp"
        return 1
    fi

    info "Extracting Bibata cursor..."
    tar -xf "$tarball" -C "$dest_tmp"
    $SUDO mv "$dest_tmp/Bibata-Modern-Ice" /usr/share/icons/
    rm -rf "$dest_tmp"
    info "Bibata-Modern-Ice cursor installed to /usr/share/icons/."
}

# ── sudo shim (root inside Docker has no sudo) ────────────────
if command -v sudo &>/dev/null; then
    SUDO="sudo"
else
    SUDO=""
fi

# ── detect distro ────────────────────────────────────────────
if command -v pacman &>/dev/null; then
    DISTRO="arch"
elif command -v apt &>/dev/null; then
    DISTRO="debian"
elif command -v dnf &>/dev/null; then
    DISTRO="fedora"
elif command -v zypper &>/dev/null; then
    DISTRO="opensuse"
else
    warn "Could not detect distro. You may need to install dependencies manually."
    DISTRO="unknown"
fi

info "Detected distro family: $DISTRO"

# ── install dependencies ──────────────────────────────────────
info "Installing dependencies..."

case "$DISTRO" in
    arch)
        $SUDO pacman -Sy --needed --noconfirm \
            sassc gnome-themes-extra gnome-tweaks gnome-shell-extensions \
            fish git curl ttf-jetbrains-mono python-pipx

        if command -v yay &>/dev/null; then
            yay -S --needed --noconfirm gtk-engine-murrine
        elif command -v paru &>/dev/null; then
            paru -S --needed --noconfirm gtk-engine-murrine
        else
            warn "gtk-engine-murrine is AUR-only. Install it with: yay -S gtk-engine-murrine"
        fi

        $SUDO pacman -R --noconfirm illogical-impulse-bibata-modern-classic-bin 2>/dev/null || true
        if command -v paru &>/dev/null; then
            paru -S --noconfirm bibata-cursor-theme-bin
        elif command -v yay &>/dev/null; then
            yay -S --noconfirm bibata-cursor-theme-bin
        else
            warn "bibata-cursor-theme-bin is AUR-only. Install it with: paru -S bibata-cursor-theme-bin"
        fi
        ;;
    debian)
        $SUDO apt update
        $SUDO apt install -y \
            sassc gtk2-engines-murrine gnome-themes-extra gnome-tweaks \
            gnome-shell-extensions fish git curl fonts-jetbrains-mono \
            python3-pip pipx
        # bibata-cursor-theme is in official Debian/Ubuntu repos (bookworm+/22.04+)
        # Try apt first; fall back to GitHub .tar.xz download if unavailable
        if $SUDO apt install -y bibata-cursor-theme 2>/dev/null; then
            info "Bibata cursor installed via apt."
        else
            warn "bibata-cursor-theme not found in apt — falling back to GitHub download."
            install_bibata_from_github || true
        fi
        ;;
    fedora)
        $SUDO dnf install -y \
            sassc gtk-murrine-engine gnome-themes-extra gnome-tweaks \
            gnome-shell-extension-user-theme fish git curl jetbrains-mono-fonts \
            pipx
        $SUDO dnf copr enable -y peterwu/rendezvous
        $SUDO dnf install -y bibata-cursor-themes
        ;;
    opensuse)
        $SUDO zypper install -y \
            sassc gtk2-engine-murrine gnome-themes-extra gnome-tweaks \
            fish git curl jetbrains-mono python3-pipx
        install_bibata_from_github || true
        ;;
    *)
        warn "Skipping auto-install. Install manually: sassc, gtk-engine-murrine, gnome-themes-extra, gnome-tweaks, gnome-shell-extensions, fish, git, pipx"
        ;;
esac

# ── create directories ────────────────────────────────────────
mkdir -p "$HOME/.themes"
mkdir -p "$HOME/.local/share/icons"
mkdir -p "$HOME/.config/gtk-3.0"
mkdir -p "$HOME/.config/gtk-4.0"

RICE_TMP="$HOME/.cache/warm-gnome-rice"
mkdir -p "$RICE_TMP"

# ── GTK theme ─────────────────────────────────────────────────
info "Installing Gruvbox GTK Theme..."
if [ ! -d "$RICE_TMP/Gruvbox-GTK-Theme" ]; then
    git clone --depth 1 https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git "$RICE_TMP/Gruvbox-GTK-Theme"
fi

cd "$RICE_TMP/Gruvbox-GTK-Theme/themes"
bash ./install.sh --tweaks medium macos outline float -t orange -l
cd "$HOME"

THEME_DIR=""
for candidate in "$HOME/.themes/Gruvbox-Orange-Dark-Medium" "$HOME/.themes/Gruvbox-Orange-Light-Medium"; do
    if [ -d "$candidate/gtk-4.0" ]; then
        THEME_DIR="$candidate"
        break
    fi
done
if [ -z "$THEME_DIR" ]; then
    while IFS= read -r d; do
        if [ -d "$d/gtk-4.0" ]; then
            THEME_DIR="$d"
            break
        fi
    done < <(find "$HOME/.themes" -maxdepth 1 -type d -name "Gruvbox-Orange*" ! -name "*xhdpi*")
fi

if [ -z "$THEME_DIR" ]; then
    warn "Could not find installed Gruvbox theme folder in ~/.themes. Skipping config copy."
else
    THEME_NAME=$(basename "$THEME_DIR")
    info "Found theme: $THEME_NAME"

    GTK3_SRC="$THEME_DIR/gtk-3.0"
    if [ -d "$GTK3_SRC" ]; then
        info "Copying GTK3 files to ~/.config/gtk-3.0 ..."
        cp -rfn "$GTK3_SRC/." "$HOME/.config/gtk-3.0/" 2>/dev/null || true
    else
        warn "No gtk-3.0 folder found in theme dir."
    fi

    GTK4_SRC="$THEME_DIR/gtk-4.0"
    if [ -d "$GTK4_SRC" ]; then
        if [ "$(realpath "$GTK4_SRC")" = "$(realpath "$HOME/.config/gtk-4.0")" ]; then
            info "gtk-4.0 is already symlinked by the theme installer — skipping copy."
        else
            info "Copying GTK4 files to ~/.config/gtk-4.0 ..."
            cp -rfn "$GTK4_SRC/." "$HOME/.config/gtk-4.0/" 2>/dev/null || true
        fi
    else
        warn "No gtk-4.0 folder found in theme dir."
    fi

    info "Applying GTK theme via gsettings..."
    gsettings set org.gnome.desktop.interface gtk-theme "$THEME_NAME" \
        || warn "Could not set GTK theme via gsettings."
fi

# ── GNOME extensions via gnome-extensions-cli (gext) ─────────
info "Installing gnome-extensions-cli (gext)..."
# pipx installs into ~/.local/bin — make sure it's on PATH
export PATH="$HOME/.local/bin:$PATH"

if ! command -v gext &>/dev/null; then
    pipx install gnome-extensions-cli --system-site-packages 2>/dev/null \
        || pip3 install --user gnome-extensions-cli 2>/dev/null \
        || warn "Could not install gext via pipx or pip. Extensions must be installed manually."
fi

# All extensions including User Themes — installed the same way via gext
declare -A EXTENSIONS=(
    ["user-theme@gnome-shell-extensions.gcampax.github.com"]="19"
    ["blur-my-shell@aunetx"]="3193"
    ["caffeine@patapon.info"]="517"
    ["dash-to-dock@micxgx.gmail.com"]="307"
    ["just-perfection-desktop@just-perfection"]="3843"
    ["logomenu@aryan_k"]="4451"
    ["space-bar@luchrioh"]="5090"
    ["topbar-organizer@julian.gse.jsts.xyz"]="4356"
    ["tophat@fflewddur.github.io"]="5219"
)

ENABLED_UUIDS=""

if command -v gext &>/dev/null; then
    info "Installing GNOME extensions..."
    for UUID in "${!EXTENSIONS[@]}"; do
        EXT_ID="${EXTENSIONS[$UUID]}"
        info "  → Installing: $UUID (ID: $EXT_ID)"
        gext install "$UUID" 2>/dev/null \
            || warn "    Could not install $UUID — visit https://extensions.gnome.org/extension/$EXT_ID/"
        ENABLED_UUIDS="${ENABLED_UUIDS:+$ENABLED_UUIDS, }'$UUID'"
    done
else
    warn "gext not found. Skipping extension install. Install them manually from https://extensions.gnome.org"
    for UUID in "${!EXTENSIONS[@]}"; do
        ENABLED_UUIDS="${ENABLED_UUIDS:+$ENABLED_UUIDS, }'$UUID'"
    done
fi

# Enable all extensions in one gsettings call
gsettings set org.gnome.shell enabled-extensions "[$ENABLED_UUIDS]" \
    || warn "Could not set enabled-extensions via gsettings."

info "All extensions queued — they will activate after logout/login."

# Queue the shell theme (user-theme extension must be active first)
if [ -n "${THEME_NAME:-}" ]; then
    gsettings set org.gnome.shell.extensions.user-theme name "$THEME_NAME" 2>/dev/null || true
    info "Shell theme queued: $THEME_NAME"
fi

# ── Icon pack ─────────────────────────────────────────────────
info "Installing Gruvbox Plus icon pack..."
if [ ! -d "$RICE_TMP/gruvbox-plus-icon-pack" ]; then
    git clone --depth 1 https://github.com/SylEleuth/gruvbox-plus-icon-pack.git "$RICE_TMP/gruvbox-plus-icon-pack"
fi

cp -r "$RICE_TMP/gruvbox-plus-icon-pack/Gruvbox-Plus-Dark" "$HOME/.local/share/icons/"
info "Icon pack installed."

gsettings set org.gnome.desktop.interface icon-theme "Gruvbox-Plus-Dark" \
    || warn "Could not set icon theme via gsettings."

# ── Cursor ────────────────────────────────────────────────────
info "Setting up Bibata Modern Ice cursor..."
mkdir -p "$HOME/.local/share/icons"

if [ -d "/usr/share/icons/Bibata-Modern-Ice" ]; then
    BIBATA_SRC="/usr/share/icons/Bibata-Modern-Ice"
elif [ -d "$HOME/.local/share/icons/Bibata-Modern-Ice" ]; then
    BIBATA_SRC="$HOME/.local/share/icons/Bibata-Modern-Ice"
else
    BIBATA_SRC=""
fi

if [ -n "$BIBATA_SRC" ]; then
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice" \
        || warn "Could not set cursor theme via gsettings."
    info "Cursor set to Bibata-Modern-Ice."
else
    warn "Bibata-Modern-Ice cursor not found. Make sure bibata-cursor-theme-bin installed correctly."
fi

# ── Font ──────────────────────────────────────────────────────
gsettings set org.gnome.desktop.interface font-name "JetBrains Mono 11" 2>/dev/null \
    || warn "Could not set font. Make sure JetBrains Mono is installed."

# ── Wallpaper ─────────────────────────────────────────────────
info "Downloading and setting Gruvbox wallpaper..."
WALLPAPER_URL="https://gruvbox-wallpapers.pages.dev/wallpapers/anime/5m5kLI9.png"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
WALLPAPER_PATH="$WALLPAPER_DIR/gruvbox-anime.png"

mkdir -p "$WALLPAPER_DIR"

if curl -sL "$WALLPAPER_URL" -o "$WALLPAPER_PATH" --fail; then
    # Set wallpaper for both light and dark modes, and both desktop + lock screen
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH" \
        || warn "Could not set wallpaper (picture-uri)."
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH" \
        || warn "Could not set wallpaper (picture-uri-dark)."
    gsettings set org.gnome.desktop.background picture-options "zoom"
    gsettings set org.gnome.desktop.screensaver picture-uri "file://$WALLPAPER_PATH" \
        || warn "Could not set lock screen wallpaper."
    info "Wallpaper set: $WALLPAPER_PATH"
else
    warn "Could not download wallpaper. Set it manually from: $WALLPAPER_URL"
fi

# ── Flatpak theming (optional) ────────────────────────────────
if command -v flatpak &>/dev/null; then
    info "Applying Flatpak theme overrides..."
    $SUDO flatpak override --filesystem="$HOME/.themes"
    $SUDO flatpak override --filesystem="$HOME/.icons"
    flatpak override --user --filesystem=xdg-config/gtk-3.0
    flatpak override --user --filesystem=xdg-config/gtk-4.0
fi

# ── Fish shell ────────────────────────────────────────────────
info "Setting fish as default shell..."
FISH_PATH=$(command -v fish)
if ! grep -qF "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | $SUDO tee -a /etc/shells > /dev/null
fi
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [ "$CURRENT_SHELL" = "$FISH_PATH" ]; then
    info "fish is already the default shell."
else
    chsh -s "$FISH_PATH" || warn "Could not set fish as default shell. Run: chsh -s $FISH_PATH"
fi

# ── Oh My Fish + agnoster theme ───────────────────────────────
info "Installing Oh My Fish and agnoster theme..."
curl -sL https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install -o /tmp/omf-install

fish -c "
    source /tmp/omf-install --noninteractive --yes
    omf install agnoster
    omf theme agnoster
" 2>/dev/null || warn "OMF auto-install had issues. In fish, run:
    curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
    omf install agnoster"

rm -f /tmp/omf-install

# ── Done ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}  warm gnome rice setup complete :D          ${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo ""
echo "  Remaining manual steps:"
echo "  1. Log out and back in (required for extensions + shell theme + fish to apply)"
echo "  2. Open GNOME Tweaks → Appearance to verify theme and icons"
echo "  3. Configure individual extensions via GNOME Extensions app"
echo ""
echo "  Installed extensions:"
echo "    • Blur my Shell       – blur effects on shell panels"
echo "    • Caffeine            – prevent screen from sleeping"
echo "    • Dash to Dock        – macOS-style dock"
echo "    • Just Perfection     – fine-tune GNOME shell elements"
echo "    • Logo Menu           – replace Activities with a logo menu"
echo "    • Space Bar           – workspaces in the top bar"
echo "    • Top Bar Organizer   – reorder top bar items"
echo "    • Top Hat             – CPU/RAM monitor in top bar"
echo ""
echo "  Please star the repo & happy ricing :) "
