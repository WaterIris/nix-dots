{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/fonts.nix
    ./modules/bluetooth.nix
    ./modules/graphics.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "alduin"; # Define your hostname.

  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pl_PL.UTF-8";
    LC_IDENTIFICATION = "pl_PL.UTF-8";
    LC_MEASUREMENT = "pl_PL.UTF-8";
    LC_MONETARY = "pl_PL.UTF-8";
    LC_NAME = "pl_PL.UTF-8";
    LC_NUMERIC = "pl_PL.UTF-8";
    LC_PAPER = "pl_PL.UTF-8";
    LC_TELEPHONE = "pl_PL.UTF-8";
    LC_TIME = "pl_PL.UTF-8";
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.logind.settings.Login.HandleLidSwitch = "ignore";
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 0; # Dummy value
      STOP_CHARGE_THRESH_BAT0 = 1; # Actualy enables conservation mode
    };
  };
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  programs.nix-ld.enable = true;

  console.keyMap = "pl2";
  virtualisation.vmware.host.enable = true;

  users.users.iris = {
    isNormalUser = true;
    description = "iris";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [ ];
  };
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  environment.systemPackages = [
    pkgs.home-manager
    pkgs.vim
    pkgs.wget
    pkgs.git
  ];
  system.stateVersion = "25.11";
}
