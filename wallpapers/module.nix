{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.services.wallsetter;
in
{
  options.services.wallsetter = {
    enable = mkEnableOption "wallsetter oneshot service";

    repo = mkOption {
      type = types.package;
      description = ''
        The repo to pull wallpapers from. The requirements on it are just to
        have a `wallpapers/` directory in the root of the repo full of jpgs of the
        correct size for the monitor we're using.
      '';
    };

    user = mkOption {
      type = types.str;
      description = "User account under which wallsetter runs.";
    };

    wallpaper = mkOption {
      type =
        let
          wallpaperContents = attrNames (builtins.readDir (cfg.repo + "/wallpapers"));
          wallpapers = filter (f: hasSuffix ".jpg" f) wallpaperContents;
        in
        types.enum wallpapers;
      default = "monolith.jpg";
      description = "The wallpaper to set as the desktop background";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.wallsetter = {
      enable = true;
      description = "Wallpaper background image setter";
      wantedBy = [ "multi-user.target" ];
      script =
        ''
          ${pkgs.setroot}/bin/setroot --center ${cfg.repo}/wallpapers/${cfg.wallpaper}
        '';
      serviceConfig = {
        User = cfg.user;
        Environment = [
          "DISPLAY=:0"
        ];
        Type = "oneshot";
      };
    };
  };
}
