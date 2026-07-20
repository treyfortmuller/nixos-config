{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  config = {
    sierras =
      let
        myUser = config.users.users.${config.sierras.user};
      in
      {
        enable = true;
        hostName = "sonora";
        location.latitude = 33.657;
        location.longitude = -117.787;
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
        home-auto.enable = true;
      };

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Enable networking
    networking.networkmanager.enable = true;

    # Enable the X11 windowing system.
    # You can disable this if you're only using the Wayland session.
    services.xserver.enable = true;

    # Enable the KDE Plasma Desktop Environment.
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Install firefox.
    programs.firefox.enable = true;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
      #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      #  wget
    ];

    # Enable the OpenSSH daemon.
    services.openssh.enable = true;

    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
