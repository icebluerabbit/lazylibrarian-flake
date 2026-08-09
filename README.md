# LazyLibrarian Nix Flake

[![CI](https://github.com/icebluerabbit/lazylibrarian-flake/actions/workflows/ci.yml/badge.svg)](https://github.com/icebluerabbit/lazylibrarian-flake/actions/workflows/ci.yml)
[![Dependency Updates](https://github.com/icebluerabbit/lazylibrarian-flake/actions/workflows/flake-update.yml/badge.svg)](https://github.com/icebluerabbit/lazylibrarian-flake/actions/workflows/flake-update.yml)
[![Cachix Cache](https://img.shields.io/badge/Cachix-icebluerabbit--lazylibrarian-blue.svg)](https://icebluerabbit-lazylibrarian.cachix.org)
[![Nix Built](https://img.shields.io/badge/Nix-Flake-blue.svg?logo=nixos&logoColor=white)](https://nixos.org)

This repository provides a Nix Flake for [**LazyLibrarian**](https://gitlab.com/LazyLibrarian/LazyLibrarian) (book, magazine and audiobook automation for Usenet and BitTorrent), containing the packaged application, the two Python dependencies missing from nixpkgs, and fully configurable NixOS and Home Manager service modules.

---

## 📚 Documentation

*   [**NixOS Options (`docs/NIXOS_OPTIONS.md`)**](docs/NIXOS_OPTIONS.md): Configuration options for the NixOS service module.
*   [**Home Manager Options (`docs/HOME_MANAGER_OPTIONS.md`)**](docs/HOME_MANAGER_OPTIONS.md): Configuration options for the Home Manager service module.

---

## ✨ Key Features

*   **Complete Python Runtime**: Wraps LazyLibrarian in a Python environment carrying every optional feature dependency, including `iso639-lang` and `slskd-api`, which this flake packages itself because nixpkgs does not.
*   **No Self-Updating**: Built as a distribution package (`LAZYLIBRARIAN_VERSION = "Package"`), so LazyLibrarian never tries to update itself into the read-only Nix store — which, left as a source install, makes it fail and restart in a loop. The running commit stays visible in the web interface; you update through Nix.
*   **Declarative Configuration**: Exposes a `settings` schema that is merged into LazyLibrarian's runtime `config.ini` on every start, plus a `secretSettings` map that patches values in from the environment so API keys never reach the world-readable Nix store.

---

## ❄️ Nix Integration

Add LazyLibrarian to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    lazylibrarian-flake.url = "github:icebluerabbit/lazylibrarian-flake";
  };
}
```

### NixOS Module

Activate the module and declare settings system-wide:

```nix
{ inputs, ... }: {
  imports = [ inputs.lazylibrarian-flake.nixosModules.default ];

  services.lazylibrarian = {
    enable = true;
    port = 5299;
    openFirewall = true;

    # Reasserted on every restart, overriding changes made in the web interface.
    settings = {
      API.book_api = "OpenLibrary";
      API.api_enabled = true;
      General.loglevel = 1;
    };

    # Keeps the API key out of the Nix store: it is read from the environment
    # file at startup and patched into config.ini.
    environmentFile = "/run/secrets/lazylibrarian-env";
    secretSettings."API.api_key" = "LAZYLIBRARIAN_API_KEY";
  };
}
```

Where `/run/secrets/lazylibrarian-env` contains:

```
LAZYLIBRARIAN_API_KEY=your_api_key_here
```

### Home Manager Module

Run it per-user under a user systemd service:

```nix
{ inputs, ... }: {
  imports = [ inputs.lazylibrarian-flake.homeManagerModules.default ];

  services.lazylibrarian = {
    enable = true;
    settings.API.book_api = "GoogleBooks";
  };
}
```

---

## ⚙️ How the configuration merge works

LazyLibrarian owns its `config.ini`: it rewrites the file at runtime, storing only the values that differ from its defaults. A config file copied in from the Nix store would therefore be clobbered. Instead, the keys you declare in `settings` (and the environment-sourced ones in `secretSettings`) are merged into the existing `config.ini` before each start, and everything you have not declared is left alone.

Two consequences worth knowing:

*   A key declared in `settings` is reapplied on every restart, so it wins over the web interface. Leave a key out if you want to manage it through the UI.
*   LazyLibrarian identifies settings by key name alone and ignores the section they were found under, rewriting each into its own canonical section (`api_key` into `[API]`, `http_host` into `[WebServer]`, and so on). The section you use in `settings` is only a hint; prefer the canonical one.

---

## 🛠️ Development & Utilities

### Run Integration Tests
Launch the QEMU VM system check, which boots the service, verifies the web interface answers, asserts the declarative config merge and the env-sourced secret both landed in `config.ini`, and restarts the unit to prove it does not loop:
```bash
nix flake check -L
```

### Regenerate Option Reference Manuals
Rebuild the markdown documentation files from the Nix module schemas:
```bash
nix run .#generate-docs
```
