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

  sierras =
    let
      myUser = config.users.users.${config.sierras.user};
    in
    {
      enable = true;
      hostName = "ritter";
      includeDockerSpecialisation = false;
      laptop.enable = true;
      laptop.internalDisplay = "eDP-1";
      nvidia.proprietaryChaos = false;
      nvidia.cudaDev = false;
      embedded = {
        iNav = true;
        microbitV2 = true;
      };
      bluetooth.enable = true;
      location.latitude = 33.657;
      location.longitude = -117.787;
      yubikeySupport = true;
      obs.enable = false;
      tailscale = {
        enable = true;
        authKeyFile = null; # TODO: can add in secrets management later
        taildropPath = myUser.home + "/taildrop";
        taildropUser = myUser.name;
        hostName = "sierras-${config.networking.hostName}";
        operator = myUser.name;
      };
      nixbuild-net = {
        enable = true;
        identityFilePath = myUser.home + "/.ssh/id_ed25519";
      };
    };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?
}
