# Configurations associated with laptops... those are hard mode.

{ config, pkgs, lib, ... }:
with lib; let
  cfg = config.myModules.laptops;
in {
  options.myModules.laptops = {
    enable = mkEnableOption "Hardware agnostic configuration for laptops.";

    wirelessInterface = mkOption {
      description = ''
        The public network interface name to use for captive-browser, should make
        wifi access a bit nicer.
      '';
      example = "wlp0s20f3";
      type = types.str;
    };

    touchScreenDeviceId = mkOption {
      description = ''
        Never in my life have a wanted my laptop to do anything when I touch the screen.
        In order to disable touchscreens (assuming you're running X11), grab the device ID
        from the output of 'xinput'.
      '';
      example = "ELAN2D24:00";
      default = null;
      type = types.nullOr types.str;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Battery status and thermal info
      acpi
    ];

    powerManagement = {
      enable = true;

      # By default the kernel configures the "performance" governor.
      # "conservative" might be a better choice for higher performance on battery.
      cpuFreqGovernor = "powersave";

      # Whether to enable powertop auto tuning on startup.
      powertop.enable = true;
    };

    programs.captive-browser = {
      enable = true;
      interface = cfg.wirelessInterface;
    };

    # Includes the 'light' backlight control command and the udev rules it needs.
    programs.light.enable = true;

    # Turn off touchscreens should we have the misfortune of having one.
    services.xserver.displayManager.sessionCommands = mkIf (cfg.touchScreenDeviceId != null) ''
      deviceId=$(${pkgs.xorg.xinput}/bin/xinput list | grep ${cfg.touchScreenDeviceId} | cut -f2 | cut -d= -f2);
      ${pkgs.xorg.xinput}/bin/xinput disable $deviceId;
    '';

    services.xserver.libinput = {
      # Enable touchpad support.
      enable = true;

      # I need to _feel_ something, turn off tap-to-click.
      touchpad = {
        tapping = false;
        disableWhileTyping = true;
      };
    };
  };
}