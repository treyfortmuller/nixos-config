# Kearsarge desktop configuration

{ config, pkgs, lib, ... }:
let
in {
  imports = [ ./hardware-configuration.nix ];

  config = {
    sierras = {
      enable = true;
      hostName = "kearsarge";
      primaryDisplayOutput = "DP-1";
      primaryDisplayModeString = "3440x1440@59.973Hz";
      nvidiaProprietaryChaos = false;
      cudaDev = false;
      includeDockerSpecialisation = false;
    };

    system.stateVersion = "22.11"; # Did you read the comment?

    # TODO (tff): make a module for laptops, sort out the cpuFreqGovernor based on those options.
    powerManagement.cpuFreqGovernor = "performance";

    # TODO (tff): definitely need to check out Pipewire instead...
    # Enable sound.
    sound.enable = true;
    hardware.pulseaudio.enable = true;

    # Disable the PC speaker "audio card"
    boot.blacklistedKernelModules = [ "snd_pcsp" ];

    # Sound card kernel module configuration.
    # boot.extraModprobeConfig = ''
    #   options snd slots=snd_hda_intel
    #   options snd_hda_intel enable=0,1
    #   options i2c-stub chip_addr=0x20
    # '';

    # boot.kernelModules = [ "i2c-dev" "i2c-stub" ];

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    # networking.useDHCP = false;
    # networking.interfaces.enp59s0.useDHCP = true;
    # networking.interfaces.wlo1.useDHCP = true;
  };
}

