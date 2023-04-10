# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let i3lock-wrap = pkgs.callPackage ./i3lock-wrap.nix { };
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    <home-manager/nixos>
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Sound card kernel module configuration.
  # boot.extraModprobeConfig = ''
  #   options snd slots=snd_hda_intel
  #   options snd_hda_intel enable=0,1
  #   options i2c-stub chip_addr=0x20
  # '';
  # boot.blacklistedKernelModules = [ "snd_pcsp" ];
  # boot.kernelModules = [ "i2c-dev" "i2c-stub" ];

  nixpkgs.config.allowUnfree = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # TODO (tff): I dont think this is working
  # Make the sudo password validity timeout a bit longer
  security.sudo.extraConfig = ''
    Defaults        timestamp_timeout=10
  '';

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  # networking.useDHCP = false;
  # networking.interfaces.enp59s0.useDHCP = true;
  # networking.interfaces.wlo1.useDHCP = true;

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
  services.xserver = {
    enable = true;

    # Configure keymap in X11
    layout = "us";
    desktopManager.wallpaper.mode = "fill";
    displayManager.defaultSession = "none+i3";
    windowManager.i3 = {
      enable = true;

      # TODO (tff): eliminate the override with 23.05
      # Overriding i3 with the gaps fork for _asethetics_ - version 4.22 has all the
      # gaps features rolled in so we can remove this override with the next upgrade.
      package = pkgs.i3-gaps;
      extraPackages = with pkgs; [ rofi i3status i3lock-color i3lock-wrap ];
    };
  };

  # Nvidia GPU go brrrrrr
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.opengl.enable = true;
  # hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;
  # hardware.pulseaudio.support32Bit = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.trey = {
    isNormalUser = true;
    extraGroups = [ "wheel" "dialout" "audio" ];
  };

  # home-manager configuration
  home-manager.useGlobalPkgs = true;
  home-manager.users.trey = { pkgs, ... }: {
    home.stateVersion = "22.11";

    programs.bash = {
      enable = true;
      shellAliases = {
        ll = "ls -l";
        nixos-edit = "vim /home/trey/sources/nixos-config/configuration.nix";
      } // lib.optionalAttrs
        (builtins.elem pkgs.tty-clock config.environment.systemPackages) {
          clock = "tty-clock -btc";
        };
    };

    programs.alacritty = {
      enable = true;
      settings = {
        font.normal.family = "JetBrains Mono";
        window.opacity = 0.8;
        window.padding = {
          # Pixel padding interior to the window
          x = 8;
          y = 8;
        };
      };
    };

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      plugins = with pkgs.vimPlugins; [ vim-nix rust-vim ];
      extraConfig = ''
        set number
      '';
    };

    programs.git = {
      enable = true;
      userName = "Trey Fortmuller";
      userEmail = "tfortmuller@mac.com";

      # Globally ignored
      ignores = [ "*~" "*.swp" ];

      aliases = {
        last = "log -1 HEAD";
        unstage = "reset HEAD --";
        la = "!git config -l | grep alias | cut -c 7-";
        # TODO (tff): get git recent in here
      };

      extraConfig = {
        pull.rebase = false;
        init.defaultBranch = "master";
      };

      # TODO (tff): this is untested and feels dangerous
      # xsession.windowManager.i3 = {
      #   enable = true;
      #   package = pkgs.i3-gaps;
      #   config = {
      #     gaps.inner = 10;
      #   };
      # };
    };
  };

  # The head of home-manager master has a neovim.defaultEditor option
  # to accomplish this, but its not available in 22.11
  environment.sessionVariables = rec { EDITOR = "nvim"; };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # this is covered by home-manager and we've installed neovim... not sure what this would try to do now.
    # vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    ack
    # alacritty
    git
    chromium
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
        ] ++ vscode-utils.extensionsFromVscodeMarketplace [{
          name = "cmake-tools";
          publisher = "ms-vscode";
          version = "1.12.27";
          sha256 = "Q5QpVusHt0qgWwbn7Xrgk8hGh/plTx/Z4XwxISnm72s=";
        }];
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
    simplescreenrecorder
    meshlab
  ];

  fonts.fonts = with pkgs; [ jetbrains-mono ];

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

  # TODO (tff): should the compositor also be managed by home-manager?
  services.picom.enable = true;

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
  system.stateVersion = "22.11"; # Did you read the comment?

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}

