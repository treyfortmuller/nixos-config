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
  inherit (lib) mkIf mkEnableOption;
in
{
  options.sierras.nixbuild-net = {
    enable = mkEnableOption "nixbuild.net support";
  };

  config = mkIf cfg.enable {

    # TODO (tff): cleanup IdentityFile path
    programs.ssh.extraConfig = ''
      Host eu.nixbuild.net
      PubkeyAcceptedKeyTypes ssh-ed25519
      ServerAliveInterval 60
      IPQoS throughput
      IdentityFile /home/trey/.ssh/id_ed25519
    '';

    programs.ssh.knownHosts = {
      nixbuild = {
        hostNames = [ "eu.nixbuild.net" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
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
