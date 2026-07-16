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

    programs.home-manager.enable = true;
    systemd.user.startServices = "sd-switch";
    home.stateVersion = "25.11";
}
