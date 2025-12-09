# ThinkPad X1 Carbon 6th Gen

{
  config,
  lib,
  pkgs,
  self,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  sierras = {
    enable = true;
    hostName = "muir";
    # primaryDisplayOutput = "eDP-1";
    # primaryDisplayModeString = "1920x1080@60.012Hz";
    includeDockerSpecialisation = false;
    laptop = true;
    nvidia.proprietaryChaos = false;
    nvidia.cudaDev = false;
    firmwareDev = true;
    bluetooth = true;
    location.latitude = 33.657;
    location.longitude = -117.787;
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.networkmanager.enable = true;

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
