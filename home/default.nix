{ ... }:
{
    imports = [
        ./modules
    ];

    home.username = "iris";
    home.homeDirectory = "/home/iris";

    home.file.".config/hypr" = {
        source = ./config/hypr;
        recursive = true;
        force = true;
    };

    home.file.".config/waybar" = {
        source = ./config/waybar;
        recursive = true;
        force = true;
    };

    home.file.".config/quickshell" = {
        source = ./config/quickshell;
        recursive = true;
        force = true;
    };

    home.file.".config/alacritty" = {
        source = ./config/alacritty;
        recursive = true;
        force = true;
    };

    home.file.".config/rofi" = {
        source = ./config/rofi;
        recursive = true;
        force = true;
    };

    home.file.".config/tmux" = {
        source = ./config/tmux;
        force = true;
    };

    home.file.".config/dunst" = {
        source = ./config/dunst;
        force = true;
    };

    home.file.".config/mpv" = {
        source = ./config/mpv;
        force = true;
    };

    home.file.".config/wallpapers" = {
        source = ./config/wallpapers;
        recursive = true;
        force = true;
    };

    programs.home-manager.enable = true;
    systemd.user.startServices = "sd-switch";
    home.stateVersion = "25.11";
}
