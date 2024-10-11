# Base configuration shared across all machines.

{ config, pkgs, lib, inputs, outputs, ... }:
let
  cfg = config.sierras;

  systemFont = "JetBrainsMono Nerd Font";
  systemFontBold = "JetBrainsMono NF SemiBold";

  # Preferred datetime format, used throughout the system
  # Sunday June 09 00:58:05 (BST) 2024
  preferredTimeStr = "%H:%M:%S";
  preferredDateStr = "%A %B %d";
  preferredStrftime = "${preferredDateStr} ${preferredTimeStr} (%Z) %Y";

  inherit (lib) mkEnableOption mkOption mkIf types;
in
{
  options.sierras = {
    enable = mkEnableOption "Enable Sierras";

    hostName = mkOption {
      type = types.str;
      description = ''
        The networking hostName for this machine. 

        https://en.wikipedia.org/wiki/List_of_mountain_peaks_of_California
      '';
      example = "kearsarge";
    };

    primaryDisplayOutput = mkOption {
      type = types.str;
      description = ''
        Primary output display name, used for sway and waybar configurations.
        You would grab this configuration with `swaymsg -t get_outputs` once you've launched sway.
      '';
      default = "DP-1";
      example = "HDMI-A-4";
    };

    primaryDisplayModeString = mkOption {
      type = types.str;
      description = ''
        Resolution and update framerate configuration string used for sway.
      '';

      # This is for a DELL S3422DW 5PYVZL3
      default = "3440x1440@59.973Hz";
    };

    laptop = mkEnableOption "Enables laptop configuration";

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
      timeZone = mkOption {
        type = types.str;
        description = ''
          Default timezone for this system. Here's the tz database timezone names:
          https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
        '';
        default = "America/Los_Angeles";
      };

      latitude = mkOption {
        type = types.float ;
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
  };

  config = mkIf cfg.enable {
    networking.hostName = cfg.hostName;

    specialisation = mkIf cfg.includeDockerSpecialisation {
      # Docker tends to get in my way, leaving processes running and screwing with my
      # iptables in ways that are hard to understand, so we'll just provide it as a specialisation
      # to hop into when I need it.
      docker.configuration = {
        virtualisation.docker.enable = true;
        users.users.trey.extraGroups = [ "docker" ];
      };
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

    time.timeZone = cfg.location.timeZone;

    # TODO (tff): I dont think this is working
    # Make the sudo password validity timeout a bit longer
    security.sudo.extraConfig = ''
      Defaults        timestamp_timeout=10
    '';

    # Note that PAM must be configured to enable swaylock to perform authentication.
    # The package installed through home-manager will not be able to unlock the session without this configuration.
    security.pam.services.swaylock = { };

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    # networking.useDHCP = false;
    # networking.interfaces.enp59s0.useDHCP = true;
    # networking.interfaces.wlo1.useDHCP = true;

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Wayland requires policykit and OpenGL
    security.polkit.enable = true;
    hardware.opengl.enable = true;

    # Enable CUPS to print documents.
    services.printing.enable = true;
    services.printing.drivers = with pkgs; [ gutenprint ];

    services.greetd = {
      enable = true;
      settings = {
        default_session.command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet \
            --time \
            --time-format "${preferredStrftime}" \
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

    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.trey = {
      isNormalUser = true;
      extraGroups = [ "wheel" "dialout" "audio" ]
        ++ lib.optionals config.networking.networkmanager.enable
        [ "networkmanager" ];
    };

    # TODO (tff): probably move this to home-manager? config.home-manager.users.trey.home.homeDirectory
    systemd.tmpfiles.rules = [
      # This is where my screenshots go
      "d /home/trey/screenshots - trey users - -"
    ];

    environment.etc."wallpaper" = {
      source = ./wallpapers/monolith.jpg;
    };


    # home-manager configuration
    home-manager.useGlobalPkgs = true;
    home-manager.users.trey = { pkgs, ... }:
      let
        wallpaperFile = ".wallpaper";
      in
      {
        home.stateVersion = config.system.stateVersion;

        home.file = {
          "${wallpaperFile}" = {
            source = ./wallpapers/monolith.jpg;
          };
        };

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

        programs.bash =
          let
            tput = "${pkgs.ncurses}/bin/tput";

            # Common local variables for colorcoding the bash prompt and banner.
            commonFormatting = ''
              local normal=$(${tput} sgr0)
              local bold=$(${tput} bold)
              local blue=$(${tput} setaf 12)    #0000ff
              local green=$(${tput} setaf 2)    #008000
              local bluebold=''${blue}''${bold}
              local greenbold=''${green}''${bold}

              # Indicates non-printing characters for the bash prompt
              local normalnp="\[''${normal}\]"
              local blueboldnp="\[''${bluebold}\]"
              local greenboldnp="\[''${greenbold}\]"
            '';
          in
          {
            enable = true;
            bashrcExtra = ''
              function prompt() {
                ${commonFormatting}
                customprompt="\n''${greenboldnp}\t (''${blueboldnp}\W''${greenboldnp}) \$''${normalnp} "
              }
              prompt
              export PS1="$customprompt"
            '';

            initExtra = ''
              function banner() {
                  ${commonFormatting}
                  echo
                  echo "    ''${bluebold}$(whoami)''${normal}@''${bluebold}$(hostname)''${normal}"
                  echo
                  echo "    ''${bluebold}NixOS:''${normal} $(nixos-version)"
                  echo "    ''${bluebold}Date:''${normal} $(date +"${preferredStrftime}")"
                  echo
              }

              banner
            '';

            shellAliases =
              let systemPackages = config.environment.systemPackages;
              in {
                ll = "ls -lhtr";
                csv = "column -s, -t ";
                jfu = "journalctl -fu";
                ip = "ip -c";
                perms = ''stat --format "%a %n"'';
                nixos-config = "cd ~/sources/nixos-config";
                diff = "diff -y --color";
              } // lib.optionalAttrs (builtins.elem pkgs.tty-clock systemPackages) {
                clock = "tty-clock -btc";
              };
          };

        programs.fzf = {
          enable = true;
          enableBashIntegration = true;

          # Can go crazy with this later...
          # colors = { };

          # Haven't experimented with this yet, uses fxf-tmux
          # tmux.enableShellIntegration
        };

        programs.alacritty = {
          enable = true;
          settings = {
            env.TERM = "xterm-256color";
            font.normal.family = systemFont;

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

        wayland.windowManager.sway = {
          enable = true;
          # We fail to access my wallpaper file if we leave checks on...
          checkConfig = false;
          # Whether to enable sway-session.target on sway startup. We can use this to autostart waybar, etc.
          systemd.enable = true;
          config =
            let
              mod = "Mod4";

              # Default inner gaps, in pixels
              gapSize= 20;
            in
            {
              modifier = mod;
              terminal = "alacritty";
              output = {
                "${cfg.primaryDisplayOutput}" = {
                  mode = "${cfg.primaryDisplayModeString}";
                  bg = "/etc/wallpaper fill";
                };
              };

              # Will start up swaybar by default, I've enabled with programs.waybar.systemd.enable
              bars = [ ];

              fonts = {
                names = [ systemFont ];
                style = "Regular";
                size = 10.0;
              };

              gaps.inner = gapSize;

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
                "${mod}+Tab" = "workspace next_on_output";
                "${mod}+Shift+Tab" = "workspace prev_on_output";

                "${mod}+g" = "gaps inner all toggle ${builtins.toString gapSize}";
                "${mod}+Escape" = "exec ${pkgs.swaylock-effects}/bin/swaylock";
                
                # This is overriding the default stacked and tabbed layouts
                "${mod}+w" = "exec rofi -show window"; 
                "${mod}+s" = "exec rofi -show ssh";
                "${mod}+space" = "exec rofi -show drun";
                "${mod}+d" = "focus mode_toggle";

                # Sway defaults differ from i3 a tiny bit here
                "${mod}+Shift+r" = "reload";
                "${mod}+Shift+e" = "exec ${pkgs.wlogout}/bin/wlogout";

                # Screenshots via grimshot, save to screenshots dir
                "Print" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot save area ~/screenshots/$(date --iso-8601=seconds).png";
                "${mod}+Print" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot save window ~/screenshots/$(date --iso-8601=seconds).png";

                # Copy to the clipboard and don't save
                "Shift+Print" = "exec grimshot copy area";
                "${mod}+Shift+Print" = "exec grimshot copy window";


                "${mod}+Shift+f" = "floating toggle";
                "${mod}+BackSpace" = "split toggle";

                # TODO (tff): get the volume in waybar!
                # Volume control
                "XF86AudioRaiseVolume" =
                  "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
                "XF86AudioLowerVolume" =
                  "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
                "XF86AudioMute" =
                  "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
                "XF86AudioMicMute" =
                  "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";

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

            # Eliminate titlebars
            extraConfig = ''
              default_border pixel 3
              default_floating_border pixel 3
            '';
        };

        programs.rofi = {
          enable = true;
          package = pkgs.rofi-wayland;
          terminal = "${pkgs.alacritty}/bin/alacritty";
          font = systemFont + " " + builtins.toString 12;
          theme = ./rofi.rasi;
          extraConfig = {
            display-drun = "Applications";
            display-window = "Windows";
          };
        };

        # https://github.com/Alexays/Waybar/wiki
        programs.waybar = {
          enable = true;

          # Start waybar as a systemd unit WantedBy sway-session.target
          systemd.enable = true;
          systemd.target = "sway-session.target";
          style = ''
            * {
              border: none;
              border-radius: 0;
              font-family: ${systemFontBold};
              font-size: 15px;
              min-height: 0;
            }

            window#waybar {
              background: black;
              color: white;
            }

            tooltip {
              background: rgba(43, 48, 59, 0.5);
              border: 1px solid rgba(100, 114, 125, 0.5);
            }

            tooltip label {
              color: white;
            }

            #workspaces button {
              padding: 0 5px;
              background: transparent;
              color: white;
              border-bottom: 3px solid transparent;
            }

            #workspaces button.focused {
              background: #64727D;
              border-bottom: 3px solid white;
            }

            #mode, #network, #cpu, #temperature, #memory  {
              padding-right: 15px;
              padding-left: 15px;
              border-right: 1px solid white;
            }

            #user {
              padding-right: 15px;
              padding-left: 15px;
            }

            #mode {
              background: #64727D;
              border-bottom: 3px solid white;
            }

            #battery {
              background-color: #ffffff;
              color: black;
            }

            #battery.charging {
              color: white;
              background-color: #26A65B;
            }

            @keyframes blink {
              to {
                background-color: #ffffff;
                color: black;
              }
            }

            #battery.warning:not(.charging) {
              background: #f53c3c;
              color: white;
              animation-name: blink;
              animation-duration: 0.5s;
              animation-timing-function: steps(12);
              animation-iteration-count: infinite;
              animation-direction: alternate;
            }
          '';
          settings = {
            mainBar = {
              layer = "bottom";
              position = "bottom";
              height = 25;
              reload_style_on_change = true;

              # Hopefully not having an output configures just defaults to outputting on
              # all displays.
              # output = [
              #   "${cfg.primaryDisplayOutput}"
              # ];

              # TODO: music player daemon? at least get volume levels in here
              # Also could get the gammastep config in there.
              modules-left = [ "sway/workspaces" "sway/mode" ];
              modules-center = [ "clock" ];

              # TODO: need to add battery and charge state for the laptop
              # Could add wifi and bluetooth stuff as well.
              modules-right = [
                # TODO: this one is complicated, come back to it.
                # "network"
                "cpu"
                "temperature"
                "memory"
                "user"
                "tray"
              ];

              "sway/workspaces" = {
                disable-scroll = true;
                all-outputs = true;
              };

              "clock" = {
                interval = 5;
                format = "{:${preferredStrftime}}";
              };

              "cpu" = {
                format = "CPU {usage}%";
              };

              "temperature" = {
                format = "{temperatureF} °F";
              };

              "memory" = {
                format = "MEM {used:0.1f}G/{total:0.1f}G";
              };


              "user" = {
                format = "UP {work_d} days {work_H}:{work_M}";
                interval = 60;
              };

              "tray" = {
                "icon-size" = 21;
                "spacing" = 10;
              };
            };
          };
        };

        # Swaylock doesn't have all the features of i3lock-colors, so this is kind of a joke.
        programs.swaylock = {
          enable = true;
          package = pkgs.swaylock-effects;
          settings = {
            color = "000000ff";
            ignore-empty-password = true;
            font = "${systemFont}";
            clock = true;
            timestr = "${preferredTimeStr}";
            datestr = "${preferredDateStr}";
            screenshots = false;
            indicator = true;
            inside-color = "000000ff";
            inside-clear-color = "000000ff";
            inside-caps-lock-color = "000000ff";
            text-color = "ffffffff";
            text-clear-color = "ffffffff";
            text-caps-lock-color = "ffffffff";
          };
        };

        # https://github.com/ArtsyMacaw/wlogout#config
        programs.wlogout = {
          enable = true;

          # For future ricing...
          # style = builtins.readFile ./some-path.css;
        };

        services.gammastep = {
          enable = true;
          provider = "manual";
          latitude = cfg.location.latitude;
          longitude = cfg.location.longitude;
          temperature = {
            day = 6500;
            night = 3700;
          };
          tray = true;
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

    # The head of home-manager master has a neovim.defaultEditor option
    # to accomplish this, but its not available in 22.11
    environment.sessionVariables = rec { EDITOR = "nvim"; };

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
      pavucontrol
      pulseaudio
      wf-recorder
      unstable.nix-search-cli

      # Fixes some really bad issues with `nix copy` progress indication compared
      # to nix CLI 2.13.
      unstable.nixVersions.nix_2_19

      _1password

      pango # For fonts on Wayland 
      slurp # For screen area selection
      sway-contrib.grimshot # For screenshots
      wf-recorder # For screen captured videos

      # Thirdparty native
      unstable.zoom-us

      # TODO (tff): what should my strat be here?
      # chromium
      google-chrome
      slack
      qgroundcontrol
      signal-desktop

      # Media
      vlc
      ffmpeg
      imagemagick

      # TODO: replace with something wayland compatible
      # simplescreenrecorder
      meshlab
      ffmpeg-full

      # PDF
      evince
      okular

      # Some nonsense and shenanigans
      figlet
      cmatrix
      tty-clock
      cbonsai
      neofetch

      # Dev
      nixfmt-rfc-style
      gh
      picocom

      # Yubikey management
      yubikey-manager
      yubikey-manager-qt

      # Tools
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
      wlogout

      # For checking on processes using XWayland
      xorg.xlsclients
    ] ++ lib.optionals cfg.laptop [
      acpi
    ];

    # For the available nerdfonts check
    # https://www.nerdfonts.com/font-downloads
    fonts = {
      enableDefaultPackages = true;
      packages = [
        (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      ];
    };

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

    # These affect the system settings, /etc/nix/nix.conf, note there can still be user-specific
    # overrides in ~/.config/nix/nix.conf.
    nix.settings = {
      trusted-users = [ "root" "trey" "@wheel" ];
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
}

