# MSI trident overrides specific to that hardware.

{ config, pkgs, lib, ... }:
let
in {
  imports = [
    # Include the results of the hardware scan.
    ./work/hardware-configuration.nix
    ./configuration.nix
  ];

  # Sound card kernel module configuration.
  # TODO (tff): more hardware specifics
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
  # TODO (tff): more hardware specifics
  networking.useDHCP = false;
  networking.interfaces.enp59s0.useDHCP = true;
  networking.interfaces.wlo1.useDHCP = true;

  # Enable the X11 windowing system.
  services.xserver.videoDrivers = [ "nvidia" ]; 

  # Nvidia GPU go brrrrrr
  # TODO (tff): Move this to hardware specifics...
  hardware.opengl.enable = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;


  # TODO (tff): will need to make sure this is allowed to be different between configurations.
  system.stateVersion = "21.05"; # Did you read the comment?
}

