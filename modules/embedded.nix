# Configuration for embedded projects.

{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.sierras.embedded;
in
{
  options.sierras.embedded = {
    iNav = mkEnableOption "" // {
      description = ''
        Configuration for iNav flight controller firmware development.
      '';
    };

    microbitV2 = mkEnableOption "" // {
      description = ''
        Configuration supporting micro:bit v2 discovery board firmware development.
      '';
    };
  };

  # Note: no mkIf-guard in place here since all of the config is individually predicated on one of the
  # above options, add a guard if need be.
  config = {
    environment.systemPackages = lib.optionals cfg.iNav [
      pkgs.inav-configurator
      pkgs.inav-blackbox-tools
    ];

    services.udev.extraRules = lib.optionalString cfg.iNav ''
      # STM32 microcontrollers DFU mode
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE:="0666"
    '';

    # Use OpenOCD with the micro:bit v2 discovery board, see:
    # https://doc.rust-lang.org/beta/embedded-book/intro/install/linux.html
    #
    # I seemed to be suffering from this problem with
    # udev.extraRules: https://github.com/NixOS/nixpkgs/issues/210856
    services.udev.packages = lib.optionals cfg.microbitV2 [
      (pkgs.writeTextFile {
        name = "i2c-udev-rules";
        text = ''ATTRS{idVendor}=="0d28", ATTRS{idProduct}=="0204", TAG+="uaccess"'';
        destination = "/etc/udev/rules.d/70-microbit.rules";
      })
    ];
  };
}
