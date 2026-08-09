{
  description = "Nix Flake for LazyLibrarian (book, magazine and audiobook automation)";

  nixConfig = {
    extra-substituters = [
      "https://icebluerabbit-lazylibrarian.cachix.org"
    ];
    extra-trusted-public-keys = [
      "icebluerabbit-lazylibrarian.cachix.org-1:AkOQOlRiZScC7nl3UWz+lw3jYWFnOU7Eon+CBvocjME="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      perSystem =
        {
          config,
          self',
          pkgs,
          system,
          ...
        }:
        {
          formatter = pkgs.nixfmt-tree;

          packages = rec {
            iso639-lang = pkgs.python3Packages.callPackage ./pkgs/python-packages/iso639-lang.nix { };
            slskd-api = pkgs.python3Packages.callPackage ./pkgs/python-packages/slskd-api.nix { };
            lazylibrarian = pkgs.callPackage ./pkgs/lazylibrarian.nix { };
            docs = pkgs.callPackage ./modules/docs.nix { inherit lazylibrarian; };
            default = lazylibrarian;
          };

          apps.generate-docs = {
            type = "app";
            program = "${pkgs.writeShellScript "generate-docs" ''
              echo "==> Generating and copying LazyLibrarian options documentation..."
              mkdir -p docs
              cp -f ${self'.packages.docs}/NIXOS_OPTIONS.md docs/NIXOS_OPTIONS.md
              cp -f ${self'.packages.docs}/HOME_MANAGER_OPTIONS.md docs/HOME_MANAGER_OPTIONS.md
              echo "==> Done!"
            ''}";
          };

          checks = pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
            lazylibrarian-integration-test = pkgs.testers.runNixOSTest {
              name = "lazylibrarian-integration-test";

              nodes.machine =
                { pkgs, ... }:
                {
                  imports = [ self.nixosModules.lazylibrarian ];

                  services.lazylibrarian = {
                    enable = true;
                    package = self'.packages.lazylibrarian;
                    host = "127.0.0.1";
                    # Exercise the declarative config.ini merge and the env-sourced
                    # secret patching in one go.
                    settings.General.api_enabled = true;
                    secretSettings."General.api_key" = "LAZYLIBRARIAN_API_KEY";
                    environmentFile = pkgs.writeText "lazylibrarian-env" ''
                      LAZYLIBRARIAN_API_KEY=testapikey
                    '';
                  };

                  # Control startup from the test script instead of at boot.
                  systemd.services.lazylibrarian.wantedBy = pkgs.lib.mkForce [ ];
                };

              testScript = ''
                machine.wait_for_unit("multi-user.target")
                machine.start_job("lazylibrarian.service")
                try:
                    machine.wait_for_open_port(5299, timeout=120)
                    machine.succeed("curl -f http://127.0.0.1:5299/home")
                    # The declarative merge, the env-sourced secret and the host/port
                    # defaults all landed. LazyLibrarian rewrites config.ini into its
                    # own sections and renders booleans as True/False.
                    config = "/var/lib/lazylibrarian/config.ini"
                    machine.succeed(f"grep -qx 'api_enabled = True' {config}")
                    machine.succeed(f"grep -qx 'api_key = testapikey' {config}")
                    machine.succeed(f"grep -qx 'http_host = 127.0.0.1' {config}")
                    # Restarting must not loop: a "source" install would force a
                    # self-update against the read-only store on every start.
                    machine.succeed("systemctl restart lazylibrarian.service")
                    machine.wait_for_open_port(5299, timeout=120)
                    machine.succeed("curl -f http://127.0.0.1:5299/home")
                except Exception as e:
                    machine.log(
                        machine.succeed("journalctl -u lazylibrarian.service --no-pager")
                    )
                    raise e
              '';
            };
          };
        };

      flake = {
        nixosModules.lazylibrarian = import ./modules/nixos.nix;
        nixosModules.default = self.nixosModules.lazylibrarian;

        homeManagerModules.lazylibrarian = import ./modules/home-manager.nix;
        homeManagerModules.default = self.homeManagerModules.lazylibrarian;
      };
    };
}
