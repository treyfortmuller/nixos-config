# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let
  enableDocker = false;
in
{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Sound card kernel module configuration.
  boot.extraModprobeConfig = ''
    options snd slots=snd_hda_intel
    options snd_hda_intel enable=0,1
    options i2c-stub chip_addr=0x20
  '';
  boot.blacklistedKernelModules = [ "snd_pcsp" ];
  boot.kernelModules = [ "i2c-dev" "i2c-stub" ];

  nixpkgs.config.allowUnfree = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp59s0.useDHCP = true;
  networking.interfaces.wlo1.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.displayManager.defaultSession = "none+i3";
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [ rofi i3status i3lock ];
  };

  # Nvidia GPU go brrrrrr
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

  # Configure keymap in X11
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  services.xserver.desktopManager.wallpaper.mode = "fill";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.trey = {
    isNormalUser = true;

    # Enable sudo
    extraGroups = [ "wheel" "dialout" "audio" ] ++ lib.optionals enableDocker [ "docker" ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    ack
    alacritty
    git
    google-chrome
    spotify
    tty-clock
    slack
    xclip
    fzf
    neofetch
    tmux
    htop
    jq
    mosh
    nixfmt
    libqalculate
    vlc
    ffmpeg
    go # maybe this should go in some Anduril specific stuff?
    # anduril.latticectl # TODO (tff): should get this from nixpkgs
    i2c-tools
    psmisc
    usbutils
    libgpiod
    tree
    ethtool
    grpcurl
    # Some nonsense and shenanigans
    figlet
    cmatrix
    cbonsai

    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions;
        [
          ms-vscode-remote.remote-ssh
          ms-python.python
          ms-vscode.cpptools
          bbenoist.nix
          eamodio.gitlens
          zxh404.vscode-proto3
          tamasfe.even-better-toml
          matklad.rust-analyzer
          arrterian.nix-env-selector
        ] ++ vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "cmake-tools";
            publisher = "ms-vscode";
            version = "1.12.27";
            sha256 = "Q5QpVusHt0qgWwbn7Xrgk8hGh/plTx/Z4XwxISnm72s=";
          }
        ];
    })

    imagemagick
    lsof
    gh
    nixfmt
    picocom
    zoom-us
    qgroundcontrol
    unzip
    tcpdump
    arp-scan
    cryptsetup
    ffmpeg-full
    wireshark
    wireshark-cli
    nix-tree
    socat
    spotify-tui
    fzf
    bat
    ranger
    awscli2
    cntr
    ripgrep

    # anduril specific stuff
    # anduril.mcap
    simplescreenrecorder
    meshlab
  ];

  fonts.fonts = with pkgs; [
    jetbrains-mono
  ];

  # This thing will definitely fuck your iptables
  # sudo iptables -L will list them, -F to blow them away should that be necessary
  virtualisation.docker.enable = enableDocker;

  # TODO (tff): I need to be using home manager to manage my VScode user settings:
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/vscode.nix

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Run ssh-agent.
  programs.ssh.startAgent = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # TODO (tff): remove later, import this one for anduril specifics.
  nix.binaryCaches = [
    "https://cache.nixos.org/"
    "https://s3-us-west-2.amazonaws.com/anduril-nix-cache"
    "https://s3-us-west-2.amazonaws.com/anduril-nix-polyrepo-cache"
  ];
  nix.binaryCachePublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "anduril-nix-cache:0FYOuMqEzbSX2PmByfePpJAsSV6CW+1YWoq7b21NxHc="
    "anduril-nix-polyrepo-cache:0FYOuMqEzbSX2PmByfePpJAsSV6CW+1YWoq7b21NxHc="
  ];

}

