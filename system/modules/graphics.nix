{ config, pkgs, ... }:

{
  services = {
    xserver = {
      # enable = true;
      videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "pl";
        variant = "";
      };
    };
    # displayManager = {
    #   sddm.enable = true;
    #   defaultSession = "hyprland";
    # };
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
    open = false;
  };
  boot.kernelParams = [ "pcie_aspm=off" ];
}
