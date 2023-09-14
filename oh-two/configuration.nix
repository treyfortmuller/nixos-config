# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, lib, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ../base-configuration.nix
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [ 
    influxdb
    gpsd
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  services.gpsd = {
    enable = true;

    # TODO (tff): need a udev rule to make sure this thing shows up at ACM0 all the time
    devices = [ "/dev/ttyACM0" ];
    port = 2947;
    debugLevel = 3;
  };

  # System observability delivered by telegraf input plugins, stored locally
  # with a retention policy on a Prometheus instance, visualized via Grafana.
  services.telegraf = {
    enable = true;
    extraConfig = {
      # Speed up the sampling and flush to output for more immediate
      # updates in grafana.
      agent = {
        interval = "5s";
        flush_interval = "5s";
      };
      inputs = {
        system = { };
        temp = { };
        # cpu = { };
        # disk = { };
        # diskio = { };
        # ethtool = { };
        # mem = { };
        net = { };

        # This is not built into telegraf, need to figure out how to add it.
        # systemd_timings = { };

        # This is a ton of data...
        # systemd_units = { };
        # This one will need some tuning...
        # procstat = { };
      };
      outputs = {
        file = {
          files = [ "/tmp/metrics.out" ];
          data_format = "json";
        };
        influxdb = {
          urls = [ "http://localhost:8086" ];
          database = "telegraf";
        };
      };
    };
  };

  services.influxdb = { enable = true; };

  # services.prometheus = {
  #   enable = true;
  # };

  # Some sweet configuration tips: https://nixos.wiki/wiki/Grafana
  services.grafana = {
    enable = true;
    settings = {
      # auth.anonymous.enabled = true;
      security.disable_gravatar = true;
      "auth.anonymous".enabled = true;

      server = {
        # Listening Address
        http_addr = "127.0.0.1";

        # and Port
        http_port = 3000;

        # TODO (tff): There should probably be a default dashboard to auto-login to
        # home_page = "";

        # Grafana needs to know on which domain and URL it's running
        # domain = "your.domain";
        # root_url = "https://your.domain/grafana/"; # Not needed if it is `https://your.domain/`
      };
    };

    provision = {
      enable = true;
      datasources.settings = {
        datasources = [{
          name = "InfluxDB";
          database = "telegraf";
          type = "influxdb";
          url = "http://localhost:8086";
          editable = true;
        }];
      };
    };
  };
}

