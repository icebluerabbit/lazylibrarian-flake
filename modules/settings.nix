{ lib, pkgs }:

lib.mkOption {
  type = (pkgs.formats.ini { }).type;
  default = { };
  example = lib.literalExpression ''
    {
      API.book_api = "OpenLibrary";
      Git.auto_update = false;
      General.loglevel = 1;
      WebServer.http_root = "/lazylibrarian";
    }
  '';
  description = ''
    Declarative settings merged into LazyLibrarian's `config.ini`
    on every start. Each attribute is an INI section; each key inside it an entry.

    LazyLibrarian rewrites `config.ini` itself at runtime — storing
    only the values that differ from its defaults — so the file cannot simply be
    replaced by a copy from the Nix store. Instead the keys declared here are merged
    into the existing file before each start, leaving keys you have not declared
    untouched. A key set here is reasserted on every restart and so overrides changes
    made through the web interface.

    LazyLibrarian identifies settings by key name alone and ignores which section they
    were found under, rewriting each into its own canonical section. Sections here are
    therefore only a hint; use the canonical one (visible in the config.ini
    LazyLibrarian writes back) to avoid confusion. Booleans are written as
    <literal>1</literal>/<literal>0</literal>, which LazyLibrarian accepts and
    normalises to <literal>True</literal>/<literal>False</literal>.

    Do not put secrets here: these values are rendered into the world-readable Nix
    store. Use <option>services.lazylibrarian.secretSettings</option> instead.
  '';
}
