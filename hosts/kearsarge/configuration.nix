# Kearsarge desktop configuration

{
  config,
  pkgs,
  lib,
  ...
}:
let
in
{
  imports = [ ./hardware-configuration.nix ];

  config = {
    sierras = {
      enable = true;
      hostName = "kearsarge";
      includeDockerSpecialisation = false;
      nvidia.proprietaryChaos = true;
      nvidia.cudaDev = true;
      yubikeySupport = true;
      embedded = {
        iNav = true;
        microbitV2 = true;
      };
    };

    system.stateVersion = "22.11"; # Did you read the comment?

    # TODO (tff): make a module for laptops, sort out the cpuFreqGovernor based on those options.
    powerManagement.cpuFreqGovernor = "performance";

    # Disable the PC speaker "audio card"
    boot.blacklistedKernelModules = [ "snd_pcsp" ];
  };
}
