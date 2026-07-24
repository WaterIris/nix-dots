{pkgs,...}:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/audio.nix
    ./modules/bluetooth.nix
    ./modules/boot.nix
    ./modules/fonts.nix
    ./modules/graphics.nix
    ./modules/hyprland.nix
    ./modules/locale.nix
    ./modules/networking.nix
    ./modules/nix-ld.nix
    ./modules/services.nix
    ./modules/steam.nix
  ];
  users.users.iris = {
    isNormalUser = true;
    description = "iris";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = [
    pkgs.home-manager
    pkgs.vim
    pkgs.wget
    pkgs.git
  ];
  system.stateVersion = "25.11";
}
