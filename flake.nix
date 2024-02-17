{
  description = "The missile knows where it is.";

  inputs = {
    # NixOS official package source, using the nixos-22.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {
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
