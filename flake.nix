{
  description = "The missile knows where it is.";

  inputs = {
    # NixOS official package source, using the nixos-23.05 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    home-manager.url = "github:nix-community/home-manager?ref=release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
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
          self.nixosModules.base
          ./kearsarge/configuration.nix
        ];
        specialArgs = { inherit inputs; };
      };

      # TODO... add the 2002 Nuc
      # TODO... add the X1 Carbon laptop
    };

    nixosModules = {
      # The base configuration to be depended on by privately-managed machines
      base = { ... }: {
        imports = [
          home-manager.nixosModules.home-manager
          self.nixosModules.wallsetter
          ./base.nix
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
