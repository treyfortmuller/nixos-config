# Recommended configuration for using nixbuild.net's remote builders
# See: https://nixbuild.net/get-started

{
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.sierras.nixbuild-net;
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
in
{
  options.sierras.nixbuild-net = {
    enable = mkEnableOption "nixbuild.net support";

    identityFilePath = mkOption {
      type = types.path;
      description = ''
        Absolute path to the SSH private key registered with nixbuild.net.
        Make sure the root user can reach this file since the nix-daemon will be
        using it to dispatch builds.
      '';
      example = "/home/trey/.ssh/id_ed25519";
    };
  };

  config = mkIf cfg.enable {
    # Note, its totally fine to mix NixOS and home-manager SSH options, the home-manager
    # options are user specific whereas these configs are global and applied with the
    # correct precedence.
    programs.ssh = {
      extraConfig = ''
        Host eu.nixbuild.net
          PubkeyAcceptedKeyTypes ssh-ed25519
          ServerAliveInterval 60
          IPQoS throughput
          IdentityFile ${cfg.identityFilePath}
      '';

      knownHosts = {
        nixbuild = {
          hostNames = [ "eu.nixbuild.net" ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
        };
      };
    };

    nix = {
      settings = {
        # https://nix.dev/manual/nix/2.28/command-ref/conf-file.html#conf-builders-use-substitutes
        # Allow remote build machines to use their own substitutes (e.g. cache.nixos.org)
        builders-use-substitutes = true;
      };

      distributedBuilds = true;
      buildMachines = [
        # Only sending builds to nixbuild.net for aarch64 native builds for now
        #
        # {
        #   hostName = "eu.nixbuild.net";
        #   system = "x86_64-linux";
        #   maxJobs = 100;
        #   supportedFeatures = [
        #     "benchmark"
        #     "big-parallel"
        #   ];
        # }
        {
          hostName = "eu.nixbuild.net";
          system = "aarch64-linux";
          maxJobs = 100;
          supportedFeatures = [
            "benchmark"
            "big-parallel"
          ];
        }
      ];
    };
  };
}
