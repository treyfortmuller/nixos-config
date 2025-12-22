# Base configuration shared across all machines.

{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  ...
}:
let
  cfg = config.sierras;

  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
in
{
  options.sierras = {
    enable = mkEnableOption "Enable Sierras";

    user = mkOption {
      type = types.str;
      description = ''
        The "primary" user. This user will be automatically created, and its the user for
        which home-manager config will apply. I maintain this top-level option mostly because
        I like to mix home-manager and OS-level configuration in modules, and I don't care about
        using my home-manager config outside of its NixOS deployment.
      '';
      default = "trey";
    };

    hostName = mkOption {
      type = types.str;
      description = ''
        The networking hostName for this machine. 

        https://en.wikipedia.org/wiki/List_of_mountain_peaks_of_California
      '';
      example = "kearsarge";
    };

    primaryDisplayOutput = mkOption {
      type = types.nullOr types.str;
      description = ''
        Primary output display name, used for sway and waybar configurations.
        You would grab this configuration with `swaymsg -t get_outputs` once you've launched sway.

        Leave as null if you don't have access to the system to check this at runtime.
      '';
      example = "HDMI-A-4";
      default = null;
    };

    primaryDisplayModeString = mkOption {
      type = types.nullOr types.str;
      description = ''
        Resolution and update framerate configuration string used for sway.

        Leave as null if you don't have access to the system to check this at runtime.
      '';
      example = "3440x1440@59.973Hz"; # For a DELL S3422DW 5PYVZL3
      default = null;
    };

    laptop = mkEnableOption "" // {
      description = "Enables laptop configuration";
    };

    nvidia = {
      proprietaryChaos = mkOption {
        type = types.bool;
        description = ''
          Enable Nvidia proprietary drivers, enables the use of CUDA libs. Note that this is considered
          highly sketchy on Wayland - symptoms may include flickering, significant power usage, and sudden death. 
        '';
        default = false;
      };

      cudaDev = mkOption {
        type = types.bool;
        description = ''
          Adds the cuda-maintainers cachix instance as a substituter to avoid some massive builds.
        '';
        default = false;
      };
    };

    includeDockerSpecialisation = mkOption {
      type = types.bool;
      description = ''
        Enable a NixOS "specialisation" (spelt the Euro way) which enables docker. This muddies up the GRUB
        menu with the specialisation for each NixOS generation but it means docker is available always without
        it screwing with my iptables by default.
      '';
      default = false;
    };

    location = {
      latitude = mkOption {
        type = types.float;
        description = ''
          Rough latitude for gammastep redshifting manual configuration.
        '';
        # TODO (tff): tie this into the location selection so I only have to pick the timeZone
        default = 33.0;
      };

      longitude = mkOption {
        type = types.float;
        description = ''
          Rough longitude for gammastep redshifting manual configuration.
        '';
        default = -117.0;
      };
    };

    yubikeySupport = mkEnableOption "Yubikey tooling";

    onePassword = mkEnableOption "" // {
      description = ''
        Enable the 1Password GUI and CLI.

        As of Dec 2025, authentication using the MFA configuration I have with 1Password didn't
        work in the native app, nor the CLI. I just use the browser extension for now.
      '';
    };

    systemFont = {
      normal = mkOption {
        type = types.str;
        description = "Default font to use throughout the system";
        default = "JetBrainsMono Nerd Font";
      };

      bold = mkOption {
        type = types.str;
        description = "Default _bold_ font to use throughout the system";
        default = "JetBrainsMono NF SemiBold";
      };
    };

    # https://man7.org/linux/man-pages/man3/strftime.3.html
    timeDateFormat = {
      timeStr = mkOption {
        type = types.str;
        description = "Preferred time string format used throughout the system";
        default = "%H:%M:%S"; # 00:58:05
      };

      dateStr = mkOption {
        type = types.str;
        description = "Preferred time string format used throughout the system";
        default = "%A %B %d"; # Sunday June 09
      };

      dateTimeStr = mkOption {
        type = types.str;
        description = "Preferred date+time string format used throughout the system";
        default =
          let
            fmt = cfg.timeDateFormat;
          in
          "${fmt.dateStr} ${fmt.timeStr} (%Z) %Y"; # Sunday June 09 00:58:05 (BST) 2024
      };
    };
  };

  config = mkIf cfg.enable {
    networking.hostName = cfg.hostName;

    specialisation = mkIf cfg.includeDockerSpecialisation {
      # Docker tends to get in my way, leaving processes running and screwing with my
      # iptables in ways that are hard to understand, so we'll just provide it as a specialisation
      # to hop into when I need it.
      docker.configuration = {
        virtualisation.docker.enable = true;
        users.users.${cfg.user}.extraGroups = [ "docker" ];
      };
    };

    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # networking.hostName = "nixos"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    networking.networkmanager.enable = true;

    # If null, the timezone will default to UTC and can be set imperatively
    # using timedatectl.
    time.timeZone = null;

    # Make the sudo password validity timeout a bit longer
    security.sudo.extraConfig = ''
      Defaults        timestamp_timeout=10
    '';

    # Note that PAM must be configured to enable swaylock to perform authentication.
    # The package installed through home-manager will not be able to unlock the session without this configuration.
    security.pam.services.swaylock = { };

    # Wayland requires policykit and OpenGL
    security.polkit.enable = true;
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session.command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet \
            --time \
            --time-format "${cfg.timeDateFormat.dateTimeStr}" \
            --remember \
            --remember-session \
            --asterisks \
            --user-menu \
            --cmd sway
        '';
      };
    };

    environment.etc."greetd/environments".text = ''
      sway
    '';

    # Audio setup
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Allows us to set password with ‘passwd’ at runtime
    users.mutableUsers = true;
    users.users.${cfg.user} = {
      isNormalUser = true;
      initialPassword = "password"; # Not for long, don't even try...
      extraGroups = [
        "wheel"
        "dialout"
        "audio"
      ]
      ++ lib.optionals config.networking.networkmanager.enable [ "networkmanager" ];
    };

    # TODO (tff): probably move this to home-manager? config.home-manager.users.trey.home.homeDirectory
    systemd.tmpfiles.rules = [
      # This is where my screenshots go
      "d /home/trey/screenshots - trey users - -"
    ];

    environment.etc."wallpaper" = {
      source = ../wallpapers/monolith.jpg;
    };

    # The head of home-manager master has a neovim.defaultEditor option
    # to accomplish this, but its not available in 22.11
    environment.sessionVariables = rec {
      EDITOR = "nvim";
    };

    environment.shellAliases =
      let
        systemPackages = config.environment.systemPackages;
        inherit (pkgs) tty-clock libheif;
      in
      {
        ll = "ls -lhtr";
        csv = "column -s, -t ";
        jfu = "journalctl -fu";
        ip = "ip -c";
        perms = ''stat --format "%a %n"'';
        nixos-config = "cd ~/sources/nixos-config";
        diff = "diff -y --color";
      }
      // lib.optionalAttrs (builtins.elem tty-clock systemPackages) { clock = "tty-clock -btc"; }
      // lib.optionalAttrs (builtins.elem libheif systemPackages) {
        heic-convert = "for file in *.HEIC; do heif-dec $file \${file/%.HEIC/.jpg}; done";
      };

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages =
      with pkgs;
      [
        # Matter
        bambu-studio

        # Be aggressive on new nix CLI features
        unstable.nixVersions.nix_2_31
        unstable.nix-search-cli

        # Thirdparty native
        unstable.zoom-us
        unstable.signal-desktop
        slack
        qgroundcontrol

        # TODO (tff): what should my strat be here?
        # chromium
        google-chrome

        # Media
        pango # For fonts on Wayland
        slurp # For screen area selection
        sway-contrib.grimshot # For screenshots
        wf-recorder # For screen captured videos
        vlc
        ffmpeg
        imagemagick
        meshlab
        ffmpeg-full
        spotify
        libheif
        pavucontrol
        pulseaudio

        # PDF
        evince
        kdePackages.okular
        xournalpp
        gedit

        # Some nonsense and shenanigans
        figlet
        cmatrix
        tty-clock
        cbonsai
        neofetch

        # Tools
        nixfmt-rfc-style
        ookla-speedtest
        gparted
        gh
        picocom
        zip
        unzip
        wget
        ack
        wl-clipboard
        fzf
        i2c-tools
        psmisc
        usbutils
        pciutils # lspci
        libgpiod
        tree
        ethtool
        grpcurl
        tmux
        htop
        jq
        mosh
        fzf
        bat
        ranger
        awscli2
        cntr
        ripgrep
        lsof
        lshw
        tcpdump
        arp-scan
        cryptsetup
        wireshark
        wireshark-cli
        nix-tree
        nix-diff
        socat
        feh
        git-lfs
        sshping
        nethogs
        brightnessctl
        wlogout

        # For checking on processes using XWayland
        xorg.xlsclients
      ]
      ++ lib.optionals cfg.laptop [ acpi ]
      ++ lib.optionals cfg.yubikeySupport [
        yubioath-flutter
      ]
      ++ lib.optionals cfg.onePassword [
        unstable._1password-cli
      ];

    services.openssh.enable = true;

    services.pcscd.enable = cfg.yubikeySupport;

    programs.ssh.startAgent = true;

    programs._1password-gui = {
      enable = cfg.onePassword;
      package = pkgs.unstable._1password-gui;
      polkitPolicyOwners = [ "trey" ];
    };

    # For the available nerdfonts check
    # https://www.nerdfonts.com/font-downloads
    fonts = {
      enableDefaultPackages = true;
      packages = [
        pkgs.nerd-fonts.jetbrains-mono
      ];
    };
  };
}
