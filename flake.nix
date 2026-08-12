{
  description = "Declarative Home Manager configuration for the infra machines (flake)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nur, ... }:
    let
      system = "x86_64-linux";

      # nixpkgs with the NUR overlay (Firefox add-ons) and the QuPath package.
      # The `nur` channel overlay that used to live in nix/common.nix is now
      # supplied here by the flake input.
      pkgs = import nixpkgs {
        inherit system;
        # The profile includes unfree packages (VSCode, Obsidian, Zotero,
        # Proton Pass, …), so the flake must allow them or the build refuses
        # to evaluate on fresh hardware.
        config = {
          allowUnfree = true;
        };
        overlays = [
          nur.overlays.default
          (final: prev: {
            qupath = final.callPackage ./nix/packages/qupath.nix { };
            openin-native-host = final.callPackage ./nix/packages/openin-native-host.nix { };
          })
        ];
      };

      homeConfiguration = hostname: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit hostname; };
        modules = [ ./nix/home.nix ];
      };

      workstationConfiguration = homeConfiguration "workstation-orcrb";
      laptopConfiguration = homeConfiguration "laptop-xps";
    in
    {
      homeConfigurations = {
        "jonas-workstation-orcrb" = workstationConfiguration;
        "jonas-laptop-xps" = laptopConfiguration;
      };

      packages.${system} = {
        "home-workstation-orcrb" = workstationConfiguration.activationPackage;
        "home-laptop-xps" = laptopConfiguration.activationPackage;
        qupath = pkgs.qupath;
        openin-native-host = pkgs.openin-native-host;
      };
    };
}
