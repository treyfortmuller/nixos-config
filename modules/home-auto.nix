{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.sierras.home-auto;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.sierras.home-auto = {
    enable = mkEnableOption "home automation tools";
  };

  config = mkIf cfg.enable {
    services.home-assistant = {
      enable = true;
      config = {
        homeassistant = {
          name = "Home";
          latitude = "!secret latitude";
          longitude = "!secret longitude";
          elevation = "!secret elevation";
          unit_system = "metric";
          time_zone = "UTC";
        };
        frontend = {
          themes = "!include_dir_merge_named themes";
        };
        http = { };
        feedreader.urls = [ "https://nixos.org/blogs.xml" ];
      };
    };

    environment.systemPackages = with pkgs; [
      home-assistant-cli
      home-assistant
    ];
  };
}
