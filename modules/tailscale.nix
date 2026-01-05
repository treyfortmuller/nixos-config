# If auto-auth via tailscale.authKeyFile is disabled you can login manually with:
# e.g. tailscale up --ssh --hostname <hostname> --operator <user>
#
# Services that bind to Tailscale IPs should order using
# systemd.services.<name>.after tailscaled-autoconnect.service.

{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.sierras.tailscale;
in
{
  options.sierras.tailscale = {
    enable = mkEnableOption "tailscale";

    authKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        An absolute path to a file containing the auth key, tailscale will be
        automatically started if provided. Deploy this with a secrets management
        scheme like agenix or sops-nix.
      '';
      example = "/foo/bar/baz.key";
    };

    taildropPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Creates a directory at the given absolute path for taildropped files to be
        dropped into from the taildrop inbox via the `taildrop` alias. The alias only
        exists if this path is non-null.
      '';
      example = "/home/myuser/taildrop";
    };

    taildropUser = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The user who owns the taildrop directory created by the `taildropPath` option.
        This option is only relevant if `taildropPath` is non-null, and this option must
        be non-null if `taildropPath` is non-null.
      '';
    };

    hostName = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        hostname to use on the tailnet instead of the one provided by the OS.
        Null will use the hostname of the machine.
      '';
    };

    operator = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Unix username to allow to operate on tailscaled without sudo. Null indicates
        that sudo must be used by all users to make changes or use taildrop.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.tailscale
    ];

    systemd.tmpfiles.rules = lib.optionals (!isNull cfg.taildropPath && !isNull cfg.taildropUser) [
      "d ${cfg.taildropPath} - ${cfg.taildropUser} users - -"
    ];

    environment.shellAliases = {
      ts = "tailscale";
    }
    // lib.optionalAttrs (!isNull cfg.taildropPath) {
      taildrop = "tailscale file get ${cfg.taildropPath}";
    };

    programs.bash.interactiveShellInit = ''
      complete -F _complete_alias ts
    ''
    + lib.optionalString (!isNull cfg.taildropPath) ''
      complete -F _complete_alias taildrop
    '';

    services.tailscale = {
      enable = true;
      authKeyFile = cfg.authKeyFile;

      # Allows tailscale's UDP port through our firewall.
      openFirewall = true;

      # Note this are only relevant to the automatic login provided by the authKeyFile. Be aware
      # that extraUpFlags requires multi-word arguments to be included in the list separately,
      # the args are each passed through lib.escapeShellArgs:
      #
      # nix-repl> lib.escapeShellArgs [ "--ssh" "--hostname foobar" "--operator my-user" ]
      # "--ssh '--hostname foobar' '--operator my-user'"
      extraUpFlags = [
        # Enable tailscale SSH access to this host automatically.
        "--ssh"
      ]
      ++ lib.optionals (!isNull cfg.hostName) [
        "--hostname"
        "${cfg.hostName}"
      ]
      ++ lib.optionals (!isNull cfg.operator) [
        "--operator"
        "${cfg.operator}"
      ];
    };
  };
}
