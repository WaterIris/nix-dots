
{
  description = "My NixOS configuration with standalone Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs"; # keeps home-manager's nixpkgs in sync with yours
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      # pkgs instance used ONLY for standalone home-manager (see homeConfigurations below).
      # allowUnfree must be set HERE, at instantiation time — setting it inside
      # home/default.nix is too late, since `pkgs` is already built by then.
      pkgsWithUnfree = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      # ----------------------------------------------------------------
      # SYSTEM CONFIGS — built with: sudo nixos-rebuild switch --flake .#<hostname>
      # ----------------------------------------------------------------
      nixosConfigurations = {
        laptop = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./system/configuration.nix
          ];
        };
      };

      # ----------------------------------------------------------------
      # HOME-MANAGER CONFIGS (standalone) — built with: home-manager switch --flake .#<user>@<hostname>
      # ----------------------------------------------------------------
      homeConfigurations = {
        "iris@laptop" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsWithUnfree;
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./home/home.nix
          ];
        };
      };
    };
}
