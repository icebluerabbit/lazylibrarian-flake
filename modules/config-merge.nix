# Renders the script that merges the declarative `settings` (and the env-sourced
# `secretSettings`) into LazyLibrarian's runtime config.ini. Shared by the NixOS
# and Home Manager modules.
{ lib, pkgs }:

let
  mergeConfig = pkgs.writers.writePython3 "lazylibrarian-merge-config" { } ''
    import configparser
    import json
    import os
    import sys

    path, settings_json, secrets_json = sys.argv[1:4]

    settings = json.loads(settings_json)
    secrets = json.loads(secrets_json)


    def render(value):
        if isinstance(value, bool):
            return "1" if value else "0"
        if isinstance(value, list):
            return ", ".join(render(item) for item in value)
        return str(value)


    parser = configparser.ConfigParser()
    parser.read(path)


    def assign(section, key, value):
        if not parser.has_section(section):
            parser.add_section(section)
        parser.set(section, key, value)


    for section, entries in settings.items():
        for key, value in entries.items():
            assign(section, key, render(value))

    # Secrets arrive through the environment so they never enter the Nix store.
    # An unset or empty variable leaves whatever is already in config.ini alone.
    for dotted, variable in secrets.items():
        value = os.environ.get(variable, "")
        if not value:
            continue
        section, _, key = dotted.partition(".")
        assign(section, key, value)

    os.makedirs(os.path.dirname(path), exist_ok=True)
    flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC
    with open(os.open(path, flags, 0o600), "w") as handle:
        parser.write(handle)
  '';
in
{
  mkPreStart =
    {
      dataDir,
      settings,
      secretSettings,
    }:
    pkgs.writeShellScript "lazylibrarian-pre-start" ''
      set -euo pipefail
      ${lib.getExe' pkgs.coreutils "mkdir"} -p ${lib.escapeShellArg dataDir}
      ${mergeConfig} ${lib.escapeShellArg "${dataDir}/config.ini"} \
        ${lib.escapeShellArg (builtins.toJSON settings)} \
        ${lib.escapeShellArg (builtins.toJSON secretSettings)}
    '';
}
