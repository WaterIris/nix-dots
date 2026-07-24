{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # Cli apps
    ripgrep # better grep
    fd # better find
    brightnessctl
    zip
    unzip
    fastfetch
    tmux
    udiskie
    libmtp
    file
    slurp
    grim
    btop
    # Monitoring
    acpi
    usbutils
    libnotify
    # Gui apps
    firefox
    pavucontrol
    blueman
    obsidian
    nemo
    eog
    # networkmanagerapplet
    wezterm
    kitty
    qbittorrent
    mpv
    calibre
    vscode-fhs
    gnome-disk-utility
    alacritty
    quickshell
    # Wayland specific
    wl-clipboard
    hyprpicker
    hyprpaper
    hypridle
    hyprshot
    hyprlock
    waybar
    #Other
    dunst
    rofi
    neovim
    papirus-icon-theme
    lua-language-server
    tree-sitter
    clang
    luarocks
  ];
}
