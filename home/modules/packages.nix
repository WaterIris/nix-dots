{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # CLI utilities
    ripgrep            # fast recursive grep alternative
    fd                  # fast, user-friendly find alternative
    brightnessctl       # control screen backlight brightness
    zip                 # create zip archives
    unzip               # extract zip archives
    fastfetch           # system info fetch tool
    tmux                # terminal multiplexer
    udiskie             # automount removable media
    libmtp              # MTP support for Android/media devices
    file                # detect file types
    slurp               # select a region on a Wayland screen
    grim                # screenshot tool for Wayland
    btop                # resource monitor (CPU/RAM/disk/net)

    # Monitoring / hardware info
    acpi                # battery and power status info
    usbutils            # list USB devices (lsusb)
    libnotify           # send desktop notifications (notify-send)

    # GUI applications
    firefox             # web browser
    pavucontrol         # PulseAudio volume control GUI
    blueman             # Bluetooth manager GUI
    obsidian            # note-taking / knowledge base app
    nemo                # file manager
    eog                 # image viewer (Eye of GNOME)
    # networkmanagerapplet
    wezterm             # GPU-accelerated terminal emulator
    kitty               # GPU-accelerated terminal emulator
    alacritty           # GPU-accelerated terminal emulator
    qbittorrent         # BitTorrent client
    mpv                 # media player
    calibre             # e-book management
    vscode-fhs          # VS Code (FHS-wrapped for extension compatibility)
    gnome-disk-utility  # disk management GUI
    quickshell          # Wayland shell/widget toolkit

    # Wayland / Hyprland specific
    wl-clipboard        # clipboard access for Wayland (wl-copy/wl-paste)
    hyprpicker          # color picker for Hyprland
    hyprpaper           # wallpaper utility for Hyprland
    hypridle            # idle management daemon for Hyprland
    hyprshot            # screenshot utility for Hyprland
    hyprlock            # screen locker for Hyprland
    waybar              # customizable status bar for Wayland

    # Desktop environment / misc
    dunst               # notification daemon
    rofi                # application launcher / menu

    # Development / editor
    neovim              # text editor
    papirus-icon-theme  # icon theme
    lua-language-server # LSP server for Lua
    tree-sitter         # incremental parsing library (syntax highlighting)
    clang               # C/C++ compiler
    luarocks            # Lua package manager
  ];
}
