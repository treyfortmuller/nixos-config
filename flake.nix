{
  description = "The missile knows where it is.";

  inputs = {
    # NixOS official package source, using the nixos-22.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      # TODO (tff): currently a placeholder
      kearsarge = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./msi_trident/configuration.nix
        ];
        specialArgs = { inherit inputs; };
      };

      # TODO... more of them
    };

    nixosModules = {
      # The base configuration to be dependended on private machines
      base = import ./base-configuration.nix;
    };
  };
}
