{
  description = "The missile knows where it is.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      nixosConfigurations = {
        # Custom desktop build, NZXT case
        kearsarge = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default
            ./hosts/kearsarge/configuration.nix
          ];
          specialArgs = {
            inherit inputs self;
          };
        };

        # ThinkPad X1 Carbon Gen 6
        ritter = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default
            ./hosts/ritter/configuration.nix
          ];
          specialArgs = {
            inherit inputs self;
          };
        };
      };

      nixosModules = {
        # The base configuration to be depended on by privately-managed machines
        default =
          { ... }:
          {
            imports = [
              home-manager.nixosModules.home-manager
              ./modules/base.nix
              ./modules/home.nix
              ./modules/nix.nix
              ./modules/nvidia.nix
              ./modules/tailscale.nix
              ./modules/embedded.nix
              ./modules/bluetooth.nix
              ./modules/obs-studio.nix
            ];

            # final and prev, a.k.a. "self" and "super" respectively. This overlay
            # makes 'pkgs.unstable' available.
            nixpkgs.overlays = [
              (final: prev: {
                unstable = import nixpkgs-unstable {
                  system = final.system;
                  config.allowUnfree = true;
                };

                bambu-studio = self.packages.${final.system}.bambu-studio;
              })
            ];
          };
      };

      packages = forAllSystems (system: {
        bambu-studio = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/bambu-studio.nix { };
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
