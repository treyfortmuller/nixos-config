{
  description = "The missile knows where it is.";

  inputs = {
    # NixOS official package source, using the nixos-23.05 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixpkgs-wayland, ... }@inputs: {
    packages.x86_64-linux = let 
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      wallpapers = pkgs.callPackage ./wallpapers { };
    };

    nixosConfigurations = {
      # Custom desktop build, NZXT case
      kearsarge = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.default
          ./kearsarge/configuration.nix
        ];
        specialArgs = { inherit inputs; };
      };

      # TODO... add the 2002 Nuc
      # TODO... add the X1 Carbon laptop
    };

    nixosModules = {
      # The base configuration to be depended on by privately-managed machines
      default = { ... }: {
        imports = [
          home-manager.nixosModules.home-manager
          self.nixosModules.wallsetter
          ./modules/base.nix
          ./modules/laptops.nix
        ];

        # final and prev, a.k.a. "self" and "super" respectively. This overlay
        # makes 'pkgs.unstable' available.
        nixpkgs.overlays = [ (final: prev: {
            unstable = import nixpkgs-unstable {
              system = final.system;
              config.allowUnfree = true;
            };
          })

          nixpkgs-wayland.overlay
        ];
      };

      wallsetter = { ... }: {
        imports = [
          ./wallpapers/module.nix
        ];
        services.wallsetter.repo = self.packages.x86_64-linux.wallpapers;
      };
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
  };
}
