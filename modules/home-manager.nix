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
      default = "127.0.0.1";
      description = "Address the web interface binds to (config.ini <literal>http_host</literal>).";
    };

    dataDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/share/lazylibrarian";
      defaultText = literalExpression "\${config.home.homeDirectory}/.local/share/lazylibrarian";
      description = "Directory holding config.ini, the database and the cache.";
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

    systemd.user.services.lazylibrarian = {
      Unit = {
        Description = "LazyLibrarian book manager";
        After = [ "network.target" ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };

      Service = {
        Type = "simple";
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
        # LazyLibrarian re-execs itself on first run; let systemd bring it back.
        Restart = "always";
        RestartSec = "5s";
        StartLimitIntervalSec = 0;
      };
    };
  };
}
