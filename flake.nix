{
  description = "The missile knows where it is.";

  inputs = {
    # NixOS official package source, using the nixos-22.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    home-manager.url = "github:nix-community/home-manager?ref=release-22.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
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
    };

    nixosModules = {
      # The base configuration to be dependended on private machines
      base = { ... }: {
        imports = [
          home-manager.nixosModules.home-manager
          ./base.nix
        ];
      };
    };
  };
}
