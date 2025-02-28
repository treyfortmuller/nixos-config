# Config for Nvidia proprietary drivers for graphics and CUDA development for workstations.

{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  ...
}:
let
  cfg = config.sierras.nvidia;
in
{
  config = lib.mkIf cfg.proprietaryChaos {
    # Crimes against humanity to get Wayland to behave on Nvidia proprietary drivers so we can still do
    # CUDA dev... apparently this can dramatically increase power usage.
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      # Unclear exactly what this does...
      modesetting.enable = true;

      # accessible via `nvidia-settings`.
      nvidiaSettings = true;
    };

    boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];

    boot.extraModprobeConfig = ''
      options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x3; PowerMizerDefault=0x3; PowerMizerDefaultAC=0x3"
    '';

    home-manager.users.trey =
      { pkgs, ... }:
      {
        wayland.windowManager.sway.extraSessionCommands = ''
          export LIBVA_DRIVER_NAME=nvidia
          export XDG_SESSION_TYPE=wayland
          export GBM_BACKEND=nvidia-drm
          export __GLX_VENDOR_LIBRARY_NAME=nvidia
          export WLR_NO_HARDWARE_CURSORS=1
        '';

        programs.vscode.userSettings = {
          "window.titleBarStyle" = "custom";
        };
      };

    # These affect the system settings, /etc/nix/nix.conf, note there can still be user-specific
    # overrides in ~/.config/nix/nix.conf.
    nix.settings = {
      substituters = lib.optionals cfg.cudaDev [ "https://cuda-maintainers.cachix.org" ];

      trusted-public-keys = lib.optionals cfg.cudaDev [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
  };
}
