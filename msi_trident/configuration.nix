# MSI trident overrides specific to that hardware.

{ config, pkgs, lib, ... }:
let
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../base-configuration.nix
  ];

  config = {
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.05"; # Did you read the comment?

    # Sound card kernel module configuration.
    boot.extraModprobeConfig = ''
      options snd slots=snd_hda_intel
      options snd_hda_intel enable=0,1
      options i2c-stub chip_addr=0x20
    '';
    boot.blacklistedKernelModules = [ "snd_pcsp" ];
    boot.kernelModules = [ "i2c-dev" "i2c-stub" ];

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    networking.useDHCP = false;
    networking.interfaces.enp59s0.useDHCP = true;
    networking.interfaces.wlo1.useDHCP = true;

    # Enable the X11 windowing system.
    services.xserver.videoDrivers = [ "nvidia" ];

    # Nvidia GPU go brrrrrr
    hardware.opengl.enable = true;
    hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Enable sound.
    sound.enable = true;
    hardware.pulseaudio.enable = true;
    hardware.pulseaudio.support32Bit = true;

    environment.systemPackages = with pkgs; [ google-chrome ];
  };
}

