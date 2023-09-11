# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, lib, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ../base-configuration.nix
    ./hardware-configuration.nix
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  # System observability delivered by telegraf input plugins, stored locally
  # with a retention policy on a Prometheus instance, visualized via Grafana.
  services.telegraf = {
    enable = true;
    extraConfig = {
      inputs = {
        system = { };
        temp = { };
      };
      outputs = {
        file = {
          files = [ "/tmp/metrics.out" ];
          data_format = "json";
        };
      };
    };
  };
}

