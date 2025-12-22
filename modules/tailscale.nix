# TODO (tff): might be possible to do a one-shot daemon to auto-login with an agenix secret for the
# tailscale auth key? Could be cool idk...
#
# Strike that, the upstream module already implemented one for us! https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/services/networking/tailscale.nix#L183

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
