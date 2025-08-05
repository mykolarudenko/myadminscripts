#!/bin/bash
# This script sets up a customized XFCE desktop environment for the current user.
# It installs necessary packages, fonts, and applications, then applies a
# pre-defined configuration from the 'scripts/xfce-config' directory using a manifest.
#
# WARNING: This script will OVERWRITE existing XFCE configurations in ~/.config/xfce4.
set -e

# --- Utility Functions ---

# Checks if a package is installed.
is_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed"
}

# Checks for a list of packages and installs them if they are missing.
install_packages() {
    local packages_to_install=()
    local required_packages=(
        "xfce4" "xfce4-session" "yaru-theme-gtk" "yaru-theme-icon" "xfce4-cpugraph-plugin"
        "xfce4-whiskermenu-plugin" "wget" "unzip" "jq" "curl"
        "xfce4-sensors-plugin" "lm-sensors" "xfce4-terminal" "xfce4-notifyd"
    )

    echo "🔧 Checking for required packages..."
    for pkg in "${required_packages[@]}"; do
        if ! is_installed "$pkg"; then
            packages_to_install+=("$pkg")
        fi
    done

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        echo "🚀 The following packages are missing and will be installed: ${packages_to_install[*]}"
        sudo apt-get update
        sudo apt-get install -y --no-install-recommends "${packages_to_install[@]}"
    else
        echo "✅ All required packages are already installed."
    fi
}

# --- Configuration Functions ---


clear_old_config() {
    echo "🧹 Clearing old XFCE configuration for a clean slate..."
    local config_dir="$HOME/.config/xfce4"
    if [ -d "$config_dir" ]; then
        read -p "🚨 WARNING: This will permanently delete your existing XFCE configuration at $config_dir. Are you sure? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "🛑 Aborting setup as requested."
            exit 1
        fi
        echo "🛑 Stopping running XFCE panel to prevent errors..."
        pkill xfce4-panel || true
        sleep 1 # Give it a moment to terminate

        echo "Removing old configuration directory: $config_dir"
        rm -rf "$config_dir"
        echo "✅ Old XFCE configuration removed."
    else
        echo "✅ No old XFCE configuration found."
    fi
}

install_fonts() {
    echo "📦 Installing required fonts..."
    local font_dir="$HOME/.local/share/fonts"
    mkdir -p "$font_dir"
    local cache_needs_rebuild=false

    # --- Install Iosevka ---
    local iosevka_install_dir="$font_dir/Iosevka-33.2.7"
    if [ -d "$iosevka_install_dir" ]; then
        echo "✅ Iosevka fonts seem to be already installed."
    else
        echo "-> Downloading and installing Iosevka..."
        local iosevka_zip_url="https://github.com/be5invis/Iosevka/releases/download/v33.2.7/PkgTTC-Iosevka-33.2.7.zip"
        local iosevka_tmp_zip="/tmp/iosevka.zip"
        wget -q --show-progress -O "$iosevka_tmp_zip" "$iosevka_zip_url"
        unzip -oq "$iosevka_tmp_zip" -d "$iosevka_install_dir"
        rm "$iosevka_tmp_zip"
        cache_needs_rebuild=true
        echo "✅ Iosevka fonts installed."
    fi

    # --- Install Inter ---
    local inter_install_dir="$font_dir/Inter"
    if [ -d "$inter_install_dir" ]; then
        echo "✅ Inter font seems to be already installed."
    else
        echo "-> Downloading and installing Inter..."
        local inter_zip_url="https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip"
        local inter_tmp_zip="/tmp/inter.zip"
        mkdir -p "$inter_install_dir"
        wget -q --show-progress -O "$inter_tmp_zip" "$inter_zip_url"
        unzip -oq "$inter_tmp_zip" -d "$inter_install_dir"
        rm "$inter_tmp_zip"
        cache_needs_rebuild=true
        echo "✅ Inter font installed."
    fi

    if [ "$cache_needs_rebuild" = true ]; then
        echo "🔄 Rebuilding font cache..."
        fc-cache -f -v
    fi
}

install_ulauncher() {
    echo "📦 Installing ulauncher from .deb package..."
    if command -v ulauncher &> /dev/null; then
        echo "✅ ulauncher is already installed."
        return
    fi

    echo "-> Finding latest ulauncher release..."
    local latest
    latest=$(curl -sL https://api.github.com/repos/Ulauncher/Ulauncher/releases/latest | grep "tag_name" | cut -d '"' -f 4)
    if [ -z "$latest" ]; then
        echo "❌ Could not determine latest ulauncher version. Aborting ulauncher install."
        return
    fi

    # The tag from GitHub has a 'v' prefix (e.g., v5.15.0), but the .deb filename does not (e.g., ulauncher_5.15.0_all.deb).
    local version_num=${latest#v}
    local deb_file="/tmp/ulauncher.deb"
    local deb_url="https://github.com/Ulauncher/Ulauncher/releases/download/${latest}/ulauncher_${version_num}_all.deb"

    echo "-> Downloading ulauncher version ${version_num}..."
    wget -q --show-progress -O "$deb_file" "$deb_url"

    echo "-> Installing .deb package..."
    sudo apt install -y "$deb_file"
    rm "$deb_file"

    echo "✅ ulauncher installed from .deb package."
}

configure_wallpapers() {
    echo "🖼️  Downloading and setting wallpapers..."
    local download_dir="$HOME/Downloads"
    mkdir -p "$download_dir"

    local wallpaper1_url="https://hdwallsbox.com/wallpapers/l/1920x1080/76/trees-forests-houses-town-hk-skies-alpine-1920x1080-75149.jpg"
    local wallpaper1_path="$download_dir/def_wallpaper.jpg"
    local wallpaper2_url="https://i.pinimg.com/originals/52/a0/51/52a051e64bac5179fa1ca1732088cf86.jpg"
    local wallpaper2_path="$download_dir/wallpaper2.jpg"

    echo "Downloading wallpaper 1..."
    wget -q --show-progress -O "$wallpaper1_path" "$wallpaper1_url"
    echo "Downloading wallpaper 2..."
    wget -q --show-progress -O "$wallpaper2_path" "$wallpaper2_url"

    echo "✅ Wallpapers downloaded."
}

apply_config_from_templates() {
    echo "⚙️  Applying configuration from templates via cargo.list..."
    local script_dir
    script_dir=$(dirname "${BASH_SOURCE[0]}")
    local template_root="$script_dir/xfce-config"
    local cargo_list="$template_root/cargo.list"

    if [ ! -f "$cargo_list" ]; then
        echo "❌ ERROR: Manifest file not found at $cargo_list" >&2
        exit 1
    fi

    # Read the cargo.list file, ignoring comments and empty lines
    grep -vE '^\s*#|^\s*$' "$cargo_list" | while IFS='=' read -r source_part dest_part; do
        # Remove quotes from source and destination
        local source_file
        source_file=$(echo "$source_part" | tr -d '"')
        local dest_file
        dest_file=$(echo "$dest_part" | tr -d '"')

        # Construct full source path
        local source_path="$template_root/$source_file"
        
        # Replace placeholder in destination path with actual HOME
        local final_dest_path
        final_dest_path=${dest_file//\$\{user_home\}/$HOME}

        if [ ! -f "$source_path" ]; then
            echo "⚠️ WARNING: Source file not found, skipping: $source_path"
            continue
        fi
        
        echo "-> Applying '$source_file' -> '$final_dest_path'"

        # Create destination directory if it doesn't exist
        mkdir -p "$(dirname "$final_dest_path")"
        
        # Copy file and replace placeholder in its content
        sed "s|\${user_home}|$HOME|g" "$source_path" > "$final_dest_path"
    done
    
    echo "✅ Configuration files applied."
}


# --- Main Execution ---

main() {
    echo "🚀 Starting XFCE setup..."
    
    clear_old_config
    install_packages
    install_ulauncher
    install_fonts
    configure_wallpapers
    apply_config_from_templates

    echo "✅✅✅ XFCE setup complete! ✅✅✅"
    echo "💡 All settings have been written to configuration files."
    echo "💡 Please logout and log back in to your XFCE session for all changes to take effect."
    echo "💡 For temperature monitoring, you may need to run 'sudo sensors-detect' and follow the prompts."
}

main "$@"
