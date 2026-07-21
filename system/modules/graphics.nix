{ config, pkgs, ... }:

{
    services = {
        xserver = {
            videoDrivers = [ "nvidia" ];
            xkb = {
                layout = "pl";
                variant = "";
            };
        };
    };

    hardware.graphics = {
        enable = true;
        enable32Bit = true;
    };

    hardware.nvidia = {
        modesetting.enable = true;
        nvidiaSettings = true;
        powerManagement = {
            enable = true;
        };
        open = true;  # changed from false — required/recommended for your Ada Lovelace (RTX 4070)
            package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    boot.kernelParams = [
        "nvidia-drm.modeset=1"
            "amd_pstate=active"
            "pcie_aspm=off"
    ];
}
