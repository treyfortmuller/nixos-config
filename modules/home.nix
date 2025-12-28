{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.sierras;
  dotfiles = ../dots;
in
{
  # home-manager meta-configuration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # The home-manager config itself
  home-manager.users.${config.sierras.user} =
    { ... }:
    {
      home.stateVersion = config.system.stateVersion;

      # I seem to need this to allow unfree packages to be installed system-wide as
      # well as via e.g. nix-shell invocations, this may not longer be true though.
      #
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

        # The main SSH config is managed declaratively, but servers come and go so this is extra configuration
        # meant to be managed imperatively.
        #
        # We'll fill this up with entries for individual hosts:
        # Host myserver
        #   HostName 192.168.1.42
        #   User trey
        #   IdentityFile ~/.ssh/id_ed25519
        includes = [
          "~/.ssh/user_config"
        ];
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
                echo "    ''${bluebold}Date:''${normal} $(date +"${cfg.timeDateFormat.dateTimeStr}")"
                echo
            }

            banner
          '';
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
          font.normal.family = cfg.systemFont.normal;

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
        plugins = with pkgs.vimPlugins; [
          vim-nix
          rust-vim
          telescope-nvim
          telescope-fzf-native-nvim
          nvim-treesitter.withAllGrammars
          plenary-nvim
        ];
        extraConfig = ''
          set number
          let mapleader = ','
          noremap ff <cmd>Telescope find_files<cr>
        '';
      };

      programs.git = {
        enable = true;
        userName = "Trey Fortmuller";
        userEmail = "tfortmuller@mac.com";

        # Globally ignored
        ignores = [
          "*~"
          "*.swp"
        ];

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
        profiles.default.enableExtensionUpdateCheck = false;
        profiles.default.enableUpdateCheck = false;
        profiles.default.extensions = with pkgs.vscode-extensions; [
          ms-vscode-remote.remote-ssh
          ms-python.python
          ms-vscode.cpptools
          bbenoist.nix
          eamodio.gitlens
          tamasfe.even-better-toml
          rust-lang.rust-analyzer
          arrterian.nix-env-selector
          streetsidesoftware.code-spell-checker
        ];
        profiles.default.userSettings = {
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

          "cSpell.enableFiletypes" = [ "nix" ];

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
            gapSize = 20;
          in
          {
            modifier = mod;
            terminal = "alacritty";
            output = {
              "*" = {
                bg = "/etc/wallpaper fill";
              };
            }
            // lib.optionalAttrs (cfg.laptop.enable && !isNull cfg.laptop.internalDisplay) {
              "${cfg.laptop.internalDisplay}" = {
                pos = "0 0"; # Always keep the laptop's display pinned to the top-left
              };
            };

            # Will start up swaybar by default, I've enabled with programs.waybar.systemd.enable
            bars = [ ];

            fonts = {
              names = [ cfg.systemFont.normal ];
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
              "${mod}+space" = "exec rofi -show drun -show-icons";
              "${mod}+d" = "focus mode_toggle";

              # Sway defaults differ from i3 a tiny bit here
              "${mod}+Shift+r" = "reload";
              "${mod}+Shift+e" = "exec ${pkgs.wlogout}/bin/wlogout";

              # Screenshots via grimshot, save to screenshots dir
              "Print" =
                "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot save area ~/screenshots/$(date --iso-8601=seconds).png";
              "${mod}+Print" =
                "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot save window ~/screenshots/$(date --iso-8601=seconds).png";

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
        font = cfg.systemFont.normal + " " + builtins.toString 12;
        theme = dotfiles + /rofi.rasi;
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
            font-family: ${cfg.systemFont.bold};
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

          #mode, #network, #battery, #cpu, #temperature, #memory  {
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

          @keyframes blink {
            to {
              background-color: #ffffff;
              color: black;
            }
          }
        '';
        settings = {
          mainBar = {
            layer = "bottom";
            position = "bottom";
            height = 25;
            reload_style_on_change = true;

            # Not having an output configuration just defaults to outputting on all displays,
            # including new ones hotplugged at runtime which is what I want anyway.
            #
            # output = [
            #   "${cfg.primaryDisplayOutput}" # swaymsg -t get_outputs
            # ];

            # TODO: music player daemon? at least get volume levels in here
            # Also could get the gammastep config in there.
            modules-left = [
              "sway/workspaces"
              "sway/mode"
            ];
            modules-center = [ "clock" ];

            # TODO: need to add battery and charge state for the laptop
            # Could add wifi and bluetooth stuff as well.
            modules-right = [
              # TODO: this one is complicated, come back to it.
              # "network"
              "battery"
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
              format = "{:${cfg.timeDateFormat.dateTimeStr}}";
            };

            "battery" = {
              format = "BATT {capacity}%";
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
          font = "${cfg.systemFont.normal}";
          clock = true;
          timestr = "${cfg.timeDateFormat.timeStr}";
          datestr = "%A";
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

      services.tailscale-systray.enable = true;

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
    };
}
