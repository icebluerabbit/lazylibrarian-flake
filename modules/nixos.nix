{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.lazylibrarian;

  lazylibrarianPkg = pkgs.callPackage ../pkgs/lazylibrarian.nix {
    python3 = cfg.pythonPackage;
  };

  configMerge = import ./config-merge.nix { inherit lib pkgs; };
in
{
  options.services.lazylibrarian = {
    enable = mkEnableOption "LazyLibrarian book, magazine and audiobook manager";

    package = mkOption {
      type = types.package;
      default = lazylibrarianPkg;
      defaultText = literalExpression "pkgs.callPackage ../pkgs/lazylibrarian.nix { }";
      description = "The LazyLibrarian package to use.";
    };

    pythonPackage = mkOption {
      type = types.package;
      default = pkgs.python3;
      defaultText = literalExpression "pkgs.python3";
      description = "The Python interpreter LazyLibrarian runs under.";
    };

    port = mkOption {
      type = types.port;
      default = 5299;
      description = "Port the LazyLibrarian web interface listens on.";
    };

    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address the web interface binds to (config.ini <literal>http_host</literal>).";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/lazylibrarian";
      description = "Directory holding config.ini, the database and the cache.";
    };

    user = mkOption {
      type = types.str;
      default = "lazylibrarian";
      description = "User the service runs as. A system user is created when left at the default.";
    };

    group = mkOption {
      type = types.str;
      default = "lazylibrarian";
      description = "Group the service runs as. A group is created when left at the default.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open <option>port</option> in the firewall.";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to an environment file loaded into the service. Use it to supply the
        variables referenced by <option>secretSettings</option>, keeping secrets out
        of the world-readable Nix store.
      '';
    };

    secretSettings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''{ "General.api_key" = "LAZYLIBRARIAN_API_KEY"; }'';
      description = ''
        Map of <literal>Section.key</literal> entries in config.ini to the name of the
        environment variable holding their value. Each is patched in on start from the
        environment (sourced from <option>environmentFile</option>) when the variable is
        set and non-empty; otherwise the existing value in config.ini is left alone.
      '';
    };

    settings = import ./settings.nix { inherit lib pkgs; };
  };

  config = mkIf cfg.enable {
    services.lazylibrarian.settings.WebServer = {
      http_port = mkDefault cfg.port;
      http_host = mkDefault cfg.host;
    };

    systemd.services.lazylibrarian = {
      description = "LazyLibrarian book manager";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      # LazyLibrarian self-restarts once on first run (the launcher re-execs);
      # run directly under systemd it just exits, so let systemd bring it back.
      # No start limit, so a first run never trips it.
      startLimitIntervalSec = 0;

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = mkIf (cfg.dataDir == "/var/lib/lazylibrarian") "lazylibrarian";
        WorkingDirectory = cfg.dataDir;

        ExecStartPre = configMerge.mkPreStart {
          inherit (cfg) dataDir settings secretSettings;
        };

        ExecStart = concatStringsSep " " [
          (getExe cfg.package)
          "--datadir ${cfg.dataDir}"
          "--port ${toString cfg.port}"
          "--nolaunch"
        ];

        EnvironmentFile = optional (cfg.environmentFile != null) cfg.environmentFile;
        Restart = "always";
        RestartSec = "5s";
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    users.users = mkIf (cfg.user == "lazylibrarian") {
      lazylibrarian = {
        isSystemUser = true;
        group = cfg.group;
        description = "LazyLibrarian daemon user";
        home = cfg.dataDir;
      };
    };

    users.groups = mkIf (cfg.group == "lazylibrarian") {
      lazylibrarian = { };
    };
  };
}
