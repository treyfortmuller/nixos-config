{
  description = "The missile knows where it is.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      nixpkgs-wayland,
      ...
    }@inputs:
    {
      nixosConfigurations = {
        # No hardware target, useful for VMs or ISO installers
        base = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default

            # Inline definitions for sierras options
            (
              { lib, ... }:
              {
                # A root filesystem must be provided to satisfy an eval assertion, but
                # really we only use this to build system.build.images.iso-installer which
                # will onverride this config
                fileSystems."/" = lib.mkDefault {
                  device = "none";
                  fsType = "tmpfs";
                  options = [ "mode=0755" ];
                };

                sierras = {
                  enable = true;
                  laptop = true;
                  hostName = "base";
                  bluetooth = false;
                  firmwareDev = false;
                  includeDockerSpecialisation = false;
                  nvidia = {
                    proprietaryChaos = false;
                    cudaDev = false;
                  };
                  location = {
                    latitude = 33.657;
                    longitude = -117.787;
                  };
                };
              }
            )
          ];
          specialArgs = {
            inherit inputs;
          };
        };

        # Custom desktop build, NZXT case
        kearsarge = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default
            ./kearsarge/configuration.nix
          ];
          specialArgs = {
            inherit inputs;
          };
        };

        # ThinkPad X1 Carbon Gen 6
        ritter = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default
            ./ritter/configuration.nix

          ];
          specialArgs = {
            inherit inputs self;
          };
        };

        # TODO... add the 2002 Nuc
      };

      nixosModules = {
        # The base configuration to be depended on by privately-managed machines
        default =
          { ... }:
          {
            imports = [
              home-manager.nixosModules.home-manager
              ./base.nix
              ./nvidia.nix
            ];

            # final and prev, a.k.a. "self" and "super" respectively. This overlay
            # makes 'pkgs.unstable' available.
            nixpkgs.overlays = [
              (final: prev: {
                unstable = import nixpkgs-unstable {
                  system = final.system;
                  config.allowUnfree = true;
                };

                # See https://github.com/NixOS/nixpkgs/issues/440951 for bambu-studio, was running into
                # crashes using networking features in bambu-studio. 25.05's derivation builds it from source
                # whereas this uses the appimage and is a more recent version of the slicer.
                bambu-studio = prev.appimageTools.wrapType2 rec {
                  name = "BambuStudio";
                  pname = "bambu-studio";
                  version = "02.03.00.70";
                  ubuntu_version = "24.04_PR-8184";

                  src = prev.fetchurl {
                    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/Bambu_Studio_ubuntu-${ubuntu_version}.AppImage";
                    sha256 = "sha256:60ef861e204e7d6da518619bd7b7c5ab2ae2a1bd9a5fb79d10b7c4495f73b172";
                  };

                  profile = ''
                    export SSL_CERT_FILE="${prev.cacert}/etc/ssl/certs/ca-bundle.crt"
                    export GIO_MODULE_DIR="${prev.glib-networking}/lib/gio/modules/"
                  '';

                  extraPkgs =
                    pkgs: with pkgs; [
                      cacert
                      glib
                      glib-networking
                      gst_all_1.gst-plugins-bad
                      gst_all_1.gst-plugins-base
                      gst_all_1.gst-plugins-good
                      webkitgtk_4_1
                    ];
                };
              })

              # TODO: anything good in here?
              # nixpkgs-wayland.overlay
            ];
          };
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
    };
}
