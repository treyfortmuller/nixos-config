# TODO (tff): Look into auto-auth with the tailscale.authKeyFile option.
#
# Run `tailscale up` for an initial authentication

{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption types;
  cfg = config.sierras;
in
{
  options.sierras = {
    tailscale = mkEnableOption "tailscale VPN";
  };

  config = mkIf cfg.tailscale {
    environment.systemPackages = [
      pkgs.tailscale
    ];

    environment.shellAliases = {
      ts = "tailscale";
    };

    # Assumes complete-alias has already been sourced
    environment.interactiveShellInit = ''
      complete -F _complete_alias ts
    '';

    services.tailscale = {
      enable = true;

      # This option is essentially (or literally):
      # networking.firewall.allowedUDPPorts = [
      #   config.services.tailscale.port
      # ];
      openFirewall = true;
    };
  };
}
