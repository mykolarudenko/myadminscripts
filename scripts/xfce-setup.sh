#!/bin/bash
# This script sets up a customized XFCE desktop environment.
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
        "xfce4" "yaru-theme-gtk" "yaru-theme-icon" "xfce4-cpugraph-plugin"
        "xfce4-whiskermenu-plugin" "ulauncher" "wget" "unzip" "jq"
        "xfce4-sensors-plugin" "lm-sensors"
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

install_fonts() {
    echo "📦 Installing Iosevka fonts..."
    local font_dir="$HOME/.local/share/fonts"
    local font_zip_url="https://github.com/be5invis/Iosevka/releases/download/v33.2.7/PkgTTC-Iosevka-33.2.7.zip"
    local tmp_zip="/tmp/iosevka.zip"
    local font_install_dir="$font_dir/Iosevka-33.2.7"

    if [ -d "$font_install_dir" ]; then
        echo "✅ Iosevka fonts seem to be already installed."
        return
    fi

    mkdir -p "$font_dir"
    echo "Downloading fonts..."
    wget -q --show-progress -O "$tmp_zip" "$font_zip_url"
    unzip -o "$tmp_zip" -d "$font_install_dir"
    rm "$tmp_zip"

    echo "🔄 Rebuilding font cache..."
    fc-cache -f -v
    echo "✅ Fonts installed."
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

    # Set desktop wallpaper
    local desktop_props
    desktop_props=$(xfconf-query -c xfce4-desktop -l | grep 'last-image$')
    for prop in $desktop_props; do
        xfconf-query -c xfce4-desktop -p "$prop" -s "$wallpaper1_path"
    done
    echo "✅ Desktop wallpaper set."

    # Set terminal wallpaper
    local terminal_rc="$HOME/.config/xfce4/terminal/terminalrc"
    if [ -f "$terminal_rc" ]; then
        if grep -q "^BackgroundImage=" "$terminal_rc"; then
            sed -i "s|^BackgroundImage=.*|BackgroundImage=TRUE|" "$terminal_rc"
        else
            echo "BackgroundImage=TRUE" >> "$terminal_rc"
        fi

        escaped_path=$(printf '%s\n' "$wallpaper1_path" | sed 's:[&/\]:\\&:g')
        if grep -q "^BackgroundImageFile=" "$terminal_rc"; then
            sed -i "s|^BackgroundImageFile=.*|BackgroundImageFile=$escaped_path|" "$terminal_rc"
        else
            echo "BackgroundImageFile=$wallpaper1_path" >> "$terminal_rc"
        fi
        echo "✅ Terminal wallpaper set."
    else
        echo "⚠️  xfce4-terminal config not found. Skipping terminal wallpaper."
    fi
}

configure_theme_and_look() {
    echo "🎨 Applying Yaru-dark theme and visual settings..."
    # Set theme for GTK apps, window manager, and icons
    xfconf-query -c xsettings -p /Net/ThemeName -s "Yaru-dark"
    xfconf-query -c xfwm4 -p /general/theme -s "Yaru-dark"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Yaru-dark"

    # Disable menu/UI animations
    xfconf-query -c xsettings -p /Gtk/EnableAnimations -s false

    # Enable font anti-aliasing
    xfconf-query -c xsettings -p /Xft/Antialias -s 1
    xfconf-query -c xsettings -p /Xft/Hinting -s 1
    xfconf-query -c xsettings -p /Xft/HintStyle -s "hintslight"
    xfconf-query -c xsettings -p /Xft/RGBA -s "rgb"
    
    echo "✅ Theme and look configured."
}

configure_desktop_and_wm() {
    echo "🖥️  Configuring desktop and window manager..."
    # Disable all desktop icons
    xfconf-query -c xfce4-desktop -p /desktop-icons/style -s 0
    
    # Hide window title on maximized windows
    xfconf-query -c xfwm4 -p /general/titleless_maximized -s true

    echo "✅ Desktop and WM configured."
}

configure_ulauncher() {
    echo "🚀 Configuring ulauncher..."
    local ulauncher_settings="$HOME/.config/ulauncher/settings.json"
    if ! command -v ulauncher &> /dev/null; then
        echo "⚠️ ulauncher is not installed, skipping configuration."
        return
    fi
    
    # Ensure ulauncher has created its config
    if [ ! -f "$ulauncher_settings" ]; then
        echo "⚠️ ulauncher settings not found. Please run ulauncher once to create its config file."
        return
    fi

    # Use jq to set the theme
    jq '."theme-name" = "Yaru-dark"' "$ulauncher_settings" > "${ulauncher_settings}.tmp" && mv "${ulauncher_settings}.tmp" "$ulauncher_settings"
    echo "✅ ulauncher theme set to dark."
}

configure_panel() {
    echo "📊 Configuring XFCE panel..."

    # Kill running panel to apply changes cleanly
    pkill xfce4-panel || true
    sleep 1

    # Clear existing panel configuration
    xfconf-query -c xfce4-panel -p /panels -r -R
    xfconf-query -c xfce4-panel -p /plugins -r -R
    sleep 1

    # Create a new panel (panel 1)
    xfconf-query -c xfce4-panel -p /panels -n -t int -s 1 -a

    # Configure the panel
    xfconf-query -c xfce4-panel -p /panels/panel-1/position -n -t string -s "p=2;x=0;y=0" # p=2 is bottom
    xfconf-query -c xfce4-panel -p /panels/panel-1/position-locked -n -t bool -s true
    xfconf-query -c xfce4-panel -p /panels/panel-1/size -n -t int -s 32
    xfconf-query -c xfce4-panel -p /panels/panel-1/length-adjust -n -t bool -s true # Full width
    xfconf-query -c xfce4-panel -p /panels/panel-1/autohide-behavior -n -t int -s 0 # Never autohide

    # Define plugins and their IDs
    plugin_ids=(1 2 3 4 5 6 7 8 9 10)
    plugin_names=(
        "whiskermenu" "tasklist" "separator" "cpugraph" "sensors"
        "separator" "systray" "notification-plugin" "clock" "actions"
    )

    # Add plugins to panel
    prop_str=""
    for id in "${plugin_ids[@]}"; do
        prop_str+=" -t int -s $id"
    done
    xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -n -a $prop_str

    # Configure each plugin type
    for i in "${!plugin_ids[@]}"; do
        id=${plugin_ids[$i]}
        name=${plugin_names[$i]}
        xfconf-query -c xfce4-panel -p "/plugins/plugin-$id" -n -t string -s "$name"
    done

    # --- Plugin-specific settings ---
    # 2: Tasklist (Window Buttons)
    xfconf-query -c xfce4-panel -p /plugins/plugin-2/flat-buttons -n -t bool -s true
    
    # 3: Separator (Expanding Spacer)
    xfconf-query -c xfce4-panel -p /plugins/plugin-3/expand -n -t bool -s true
    xfconf-query -c xfce4-panel -p /plugins/plugin-3/style -n -t int -s 0 # Transparent

    # 4: CPU Graph
    xfconf-query -c xfce4-panel -p /plugins/plugin-4/width -n -t int -s 160
    xfconf-query -c xfce4-panel -p /plugins/plugin-4/display-style -n -t int -s 1 # LCD

    # 6: Separator (non-expanding)
    xfconf-query -c xfce4-panel -p /plugins/plugin-6/style -n -t int -s 0 # Transparent

    # 7: System Tray
    xfconf-query -c xfce4-panel -p /plugins/plugin-7/show-frame -n -t bool -s false
    
    # 9: Clock
    xfconf-query -c xfce4-panel -p /plugins/plugin-9/digital-format -n -t string -s "%H:%M" # 24h
    xfconf-query -c xfce4-panel -p /plugins/plugin-9/digital-layout -n -t int -s 3 # LCD
    xfconf-query -c xfce4-panel -p /plugins/plugin-9/digital-flash -n -t bool -s true # Blinking dots

    echo "✅ Panel configured."
}

# --- Main Execution ---

main() {
    echo "🚀 Starting XFCE setup..."
    
    install_packages
    install_fonts
    configure_wallpapers
    configure_theme_and_look
    configure_desktop_and_wm
    configure_panel
    configure_ulauncher

    echo "🔄 Launching new panel configuration..."
    (xfce4-panel &)
    disown

    echo "✅✅✅ XFCE setup complete! ✅✅✅"
    echo "💡 Some changes may require a logout/login to take full effect."
    echo "💡 For temperature monitoring, you may need to run 'sudo sensors-detect' and follow the prompts."
}

main "$@"
