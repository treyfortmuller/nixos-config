{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.sierras.obs;
in
{
  options.sierras.obs = {
    enable = mkEnableOption "OBS studio with V4L support";
  };

  config = mkIf cfg.enable {
    # TODO: is this aliased to something easier?
    home-manager.users.trey.programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
      ];
    };

    # OBS Studio virtual camera setup
    boot = {
      extraModulePackages = with config.boot.kernelPackages; [
        v4l2loopback
      ];
      kernelModules = [ "v4l2loopback" ];
      extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
      '';
    };
  };
}
