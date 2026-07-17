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

    home.file.".config/alacritty" = {
        source = ./config/alacritty;
        recursive = true;
        force = true;
    };

    home.file.".config/rofi" = {
        source = ./config/rofi;
        force = true;
    };

    programs.home-manager.enable = true;
    systemd.user.startServices = "sd-switch";
    home.stateVersion = "25.11";
}
