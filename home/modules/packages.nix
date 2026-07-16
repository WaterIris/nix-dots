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
    discord
    zip
    unzip
    fastfetch
    tmux
    udiskie
    libmtp
    file
    epubcheck
    tesseract
    slurp
    grim
    btop
    lazygit
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
    networkmanagerapplet
    wezterm
    kitty
    qbittorrent
    mpv
    calibre
    vscode-fhs
    gnome-disk-utility
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
    nixfmt
    nil
  ];
}
