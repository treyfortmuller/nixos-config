# These settings are purposefully not opt-in to guarantee reproducibility.

{
  inputs,
  lib,
  config,
  ...
}:
let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in
{
  nixpkgs.config.allowUnfree = true;

  # These affect the system settings, /etc/nix/nix.conf, note there can still be user-specific
  # overrides in ~/.config/nix/nix.conf.
  nix = {
    settings = {
      trusted-users = [
        "root"
        "trey" # TODO (tff): another good reason to just have a top-level single-user config
        "@wheel"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;
    };

    # Don't track channels, I don't use these so they end up going stale
    channel.enable = false;

    # Make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };
}
