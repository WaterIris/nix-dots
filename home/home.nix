# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./modules
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = "iris";
    homeDirectory = "/home/iris";
  };

  programs.home-manager.enable = true;
  # programs.git.enable = true;
  systemd.user.startServices = "sd-switch";
  home.stateVersion = "25.11";
}
