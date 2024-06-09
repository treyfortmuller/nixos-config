{
  description = "The missile knows where it is.";

  inputs = {
    # NixOS official package source, using the nixos-23.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixpkgs-wayland, ... }@inputs: {
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
          ./base.nix
        ];

        # final and prev, a.k.a. "self" and "super" respectively. This overlay
        # makes 'pkgs.unstable' available.
        nixpkgs.overlays = [
          (final: prev: {
            unstable = import nixpkgs-unstable {
              system = final.system;
              config.allowUnfree = true;
            };
          })

          # TODO: anything good in here?
          # nixpkgs-wayland.overlay
        ];
      };
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
  };
}
