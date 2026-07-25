{ ... }:
{
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelParams = ["pcie_aspm=off"];
    # "nvidia-drm.modeset=1"
    # "amd_pstate=active"
}
