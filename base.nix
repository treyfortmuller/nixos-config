# Base configuration shared across all machines.

{ config, pkgs, lib, inputs, outputs, ... }:
let
  system-font = "JetBrains Mono";
  i3lock-wrap = pkgs.callPackage ./i3lock-wrap.nix { };
in
{
  config = { 
    services.wallsetter = {
      enable = true;
      user = "trey";
      wallpaper = "monolith.jpg";
    };

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
    networking.networkmanager.enable = true;

    # Set your time zone.
    time.timeZone = "Europe/London";

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

      # By default, the desktop manager will look for a file called
      # ~/.background-image as the wallpaper, but this doesn't have nice
      # facilities for reloading at runtime so I made "wallsetter" for myself.
      desktopManager.wallpaper.mode = "fill";
      displayManager.defaultSession = "none+i3";

      # Seems like this is necessary to keep around despite all the config
      # being applied by home-manager.
      windowManager.i3 = {
        enable = true;
        package = pkgs.i3-gaps;
      };
    };

    # Nvidia GPU go brrrrrr
    # services.xserver.videoDrivers = [ "nvidia" ];
    # hardware.opengl.enable = true;
    # hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

    # services.xserver.xkbOptions = "eurosign:e";

    # Enable CUPS to print documents.
    services.printing.enable = true;
    services.printing.drivers = with pkgs; [ gutenprint ];

    # Enable sound.
    # sound.enable = true;
    # hardware.pulseaudio.enable = true;
    # hardware.pulseaudio.support32Bit = true;

    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.trey = {
      isNormalUser = true;
      extraGroups = [ "wheel" "dialout" "audio" "docker" ];
    };

    # TODO (tff): figure out a good place to put this...
    systemd.tmpfiles.rules = [
      # This is where my screenshots go
      "d /home/trey/screenshots - trey users - -"
    ];

    # home-manager configuration
    home-manager.useGlobalPkgs = true;
    home-manager.users.trey = { pkgs, ... }: {
      home.stateVersion = config.system.stateVersion;

      # I seem to need both of these configs to allow unfree packages to be installed
      # system-wide as well as via e.g. nix-shell invocations.
      nixpkgs.config.allowUnfree = true;
      
      # Manage the ~/.config/nixpkgs/config.nix file.
      xdg.configFile."nixpkgs/config.nix".text = ''
        { allowUnfree = true; }
      '';

      # SSH configuration docs
      # https://linux.die.net/man/5/ssh_config
      programs.ssh = {
        enable = true;
        extraConfig = ''
          ConnectTimeout=5
        '';
      };

      programs.bash = {
        enable = true;
        shellAliases = let
          systemPackages = config.environment.systemPackages;
        in {
          ll = "ls -l -h";
          csv = "column -s, -t ";
          jfu = "journalctl -fu";
          ip = "ip -c";
          perms = "stat --format \"%a %n\"";
          nixos-config = "cd ~/sources/nixos-config";
        } // lib.optionalAttrs (builtins.elem pkgs.tty-clock systemPackages) {
          clock = "tty-clock -btc";
        };
      };

      programs.alacritty = {
        enable = true;
        settings = {
          env.TERM = "xterm-256color";
          font.normal.family = system-font;

          # Alacritty can fade just its background rather than the text in the foreground
          # which is preferable, we'll apply focused/unfocused opacity control via picom.
          window.opacity = 0.9;
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
          # List aliases
          la = "!git config --list | grep -E '^alias' | cut -c 7-";

          # Beautiful one-liner log, last 20 commits
          l = "log --pretty=\"%C(Yellow)%h  %C(reset)%ad (%C(Green)%cr%C(reset))%x09 %C(Cyan)%an %C(reset)%s\" --date=short -20";

          # Most recently checked-out branches
          recent = "!git reflog show --pretty=format:'%gs ~ %gd' --date=relative | grep 'checkout:' | grep -oE '[^ ]+ ~ .*' | awk -F~ '!seen[$1]++' | head -n 10 | awk -F' ~ HEAD@{' '{printf(\"  \\033[33m%s: \\033[37m %s\\033[0m\\n\", substr($2, 1, length($2)-1), $1)}'";
          
          last = "log -1 HEAD";
          unstage = "reset HEAD --";
          b = "branch --show";
          a = "add";
          c = "commit";
          s = "status -s";
          co = "checkout";
          cob = "checkout -b";
        };

        extraConfig = {
          pull.rebase = false;
          push.autoSetupRemote = true;
          init.defaultBranch = "master";
          core.editor = "vim";
        };
      };

      programs.vscode = {
        enable = true;
        enableExtensionUpdateCheck = false;
        enableUpdateCheck = false;
        extensions = with pkgs.vscode-extensions; [
          ms-vscode-remote.remote-ssh
          ms-python.python
          ms-vscode.cpptools
          bbenoist.nix
          eamodio.gitlens
          zxh404.vscode-proto3
          tamasfe.even-better-toml
          matklad.rust-analyzer
          arrterian.nix-env-selector
          streetsidesoftware.code-spell-checker
        ];
        userSettings = {
          "workbench.colorTheme" = "Default Dark+";
          "explorer.confirmDelete" = false;
          "explorer.confirmDragAndDrop" = false;

          "editor.fontFamily" = "'JetBrains Mono Medium'";
          "editor.fontLigatures" = true;
          "editor.minimap.enabled" = true;

          "[rust]"."editor.defaultFormatter" = "rust-lang.rust-analyzer";
          "[rust]"."editor.formatOnSave" = true;
          "rust-analyzer.cargo.features" = "all";

          "[nix]"."editor.tabSize" = 2;

          "cSpell.enableFiletypes" = [
            "nix"
          ];

          "window.zoomLevel" = -1;
          "editor.rulers" = [ 120 ];
        };
      };

      xsession.windowManager.i3 = {
        enable = true;

        # Gaps for the _asethetic_, note this override can be removed with the next
        # NixOS release. i3-gaps has since merged to mainline i3.
        package = pkgs.i3-gaps;
        config =
          let
            cfg = config.home-manager.users.trey.xsession.windowManager.i3.config;
            mod = cfg.modifier;
            menu = cfg.menu;
          in
          {
            modifier = "Mod4";
            gaps.inner = 20;
            terminal = "alacritty";
            menu = "rofi -show drun";
            fonts = {
              names = [ system-font ];
              style = "Regular";
              size = 9.0;
            };
            modes.resize = lib.mkOptionDefault {
              # Return, Esc, or Mod+r again to escape resize mode
              "Return" = "mode default";
              "Escape" = "mode default";
              "${mod}+r" = "mode default";

              # Left to shrink, right to grow in width
              # Up to shrink, down to grow in height
              "Left" = "resize shrink width 75 px";
              "Right" = "resize grow width 75 px";
              "Down" = "resize grow height 75 px";
              "Up" = "resize shrink height 75 px";
            };

            keybindings = lib.mkOptionDefault {
              "${mod}+Escape" = "exec ${i3lock-wrap}/bin/i3lock-wrap";
              "${mod}+Tab" = "exec rofi -show window";
              "${mod}+s" = "exec rofi -show ssh";
              "${mod}+d" = "focus mode_toggle";
              "${mod}+space" = "exec" + " " + menu;
              "${mod}+Shift+e" = ''
                exec ${pkgs.i3-gaps}/bin/i3-nagbar -f 'pango:${system-font} 11' \
                -t warning -m 'Do you want to exit i3?' -b 'Yes' 'i3-msg exit'
              '';

              # TODO (tff): Disable stacking and tabbed layouts
              # "${mod}+w" = ""; <- remove this from the attrset defaults
              "${mod}+Shift+f" = "floating toggle";
              "${mod}+BackSpace" = "split toggle";

              # TODO (tff): get the volume in the i3 status bar and refresh it
              # Volume control
              "XF86AudioRaiseVolume" =
                "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5%";
              "XF86AudioLowerVolume" =
                "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5%";
              "XF86AudioMute" =
                "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle";
              "XF86AudioMicMute" =
                "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle";

              # Brightness control for laptops
              "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 10%-";
              "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 10%+";
            };

            colors = {
              background = "#ffffff";
              focused = {
                border = "#49abf5";
                background = "#285577";
                text = "#ffffff";
                indicator = "#9cccf0";
                childBorder = "#49abf5";
              };
              focusedInactive = {
                border = "#333333";
                background = "#5f676a";
                text = "#ffffff";
                indicator = "#484e50";
                childBorder = "#5f676a";
              };
              unfocused = {
                border = "#333333";
                background = "#222222";
                text = "#888888";
                indicator = "#292d2e";
                childBorder = "#222222";
              };
              urgent = {
                border = "#2f343a";
                background = "#900000";
                text = "#ffffff";
                indicator = "#900000";
                childBorder = "#900000";
              };
              placeholder = {
                border = "#000000";
                background = "#0c0c0c";
                text = "#ffffff";
                indicator = "#000000";
                childBorder = "#0c0c0c";
              };
            };
          };
        extraConfig = ''
          bindsym --release Print exec import ~/screenshots/$(date --iso-8601=seconds).png;
          default_border pixel 3
        '';
      };

      services.picom = {
        enable = true;
        fade = false;
        activeOpacity = 1.0;
        inactiveOpacity = 1.0;

        # Only applying opacity rules to terminal windows
        opacityRules = [
          "100:class_g = 'Alacritty' && focused"
          "90:class_g = 'Alacritty' && !focused"
        ];
      };

      programs.rofi = {
        enable = true;
        terminal = "${pkgs.alacritty}/bin/alacritty";
        font = system-font + " " + builtins.toString 12;
        theme = ./theme.rasi;

        # TODO (tff): this doesn't seem to be working
        # plugins = with pkgs; [ rofi-power-menu ];
        extraConfig = {
          display-drun = "Applications";
          display-window = "Windows";
        };
      };

      services.spotifyd = {
        enable = true;
        settings = {
          global = {
            username_cmd = "${pkgs._1password}/bin/op item get spotify --fields username";
            password_cmd = "${pkgs._1password}/bin/op item get spotify --fields password";
            device_name = "nixos";
          };
        };
      };
    };

    # TODO (tff): get rid of docker if you dont need it...
    virtualisation.docker.enable = true;

    # The head of home-manager master has a neovim.defaultEditor option
    # to accomplish this, but its not available in 22.11
    environment.sessionVariables = rec { EDITOR = "nvim"; };

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
      _1password

      # Window manager and desktop enviornment
      rofi
      i3status
      i3lock-color
      i3lock-wrap

      # Thirdparty native
      zoom-us
      
      # TODO (tff): what should my strat be here?
      # chromium
      google-chrome
      spotify-tui
      slack
      qgroundcontrol
      signal-desktop

      # Media
      vlc
      ffmpeg
      imagemagick
      simplescreenrecorder
      meshlab
      ffmpeg-full

      # PDF
      evince

      # Some nonsense and shenanigans
      figlet
      cmatrix
      tty-clock
      cbonsai
      neofetch

      # Dev
      nixfmt
      nixpkgs-fmt
      gh
      picocom

      # Tools
      wget
      ack
      xclip
      fzf
      i2c-tools
      psmisc
      usbutils
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
      unzip
      tcpdump
      arp-scan
      cryptsetup
      wireshark
      wireshark-cli
      nix-tree
      nix-diff
      socat
      remmina
      feh
      git-lfs
      sshping
      nethogs
      brightnessctl

      # TODO - this thing kinda sucks, replace with feh
      setroot
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
    # Enable the OpenSSH daemon.
    services.openssh.enable = true;

    # Run ssh-agent.
    programs.ssh.startAgent = true;

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;

    # system.stateVersion will be set on a per-machine basis to account for different
    # install times.
    # 
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    # system.stateVersion = "22.11"; # Did you read the comment?

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
  };
}

