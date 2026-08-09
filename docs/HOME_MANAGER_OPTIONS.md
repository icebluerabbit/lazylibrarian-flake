# Home Manager Module Options

This document details the configuration options available for the LazyLibrarian Home Manager module.

## services.lazylibrarian.enable



Whether to enable LazyLibrarian book, magazine and audiobook manager.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.lazylibrarian.package



The LazyLibrarian package to use.



*Type:*
package



*Default:*

```nix
pkgs.callPackage ../pkgs/lazylibrarian.nix { }
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.lazylibrarian.dataDir

Directory holding config.ini, the database and the cache.



*Type:*
string



*Default:*

```nix
${config.home.homeDirectory}/.local/share/lazylibrarian
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.lazylibrarian.environmentFile



Path to an environment file loaded into the service. Use it to supply the
variables referenced by \<option>secretSettings\</option>, keeping secrets out
of the world-readable Nix store.



*Type:*
null or absolute path



*Default:*

```nix
null
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.lazylibrarian.host



Address the web interface binds to (config.ini \<literal>http_host\</literal>).



*Type:*
string



*Default:*

```nix
"127.0.0.1"
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.lazylibrarian.port



Port the LazyLibrarian web interface listens on.



*Type:*
16 bit unsigned integer; between 0 and 65535 (both inclusive)



*Default:*

```nix
5299
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.lazylibrarian.pythonPackage



The Python interpreter LazyLibrarian runs under.



*Type:*
package



*Default:*

```nix
pkgs.python3
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.lazylibrarian.secretSettings



Map of \<literal>Section.key\</literal> entries in config.ini to the name of the
environment variable holding their value. Each is patched in on start from the
environment (sourced from \<option>environmentFile\</option>) when the variable is
set and non-empty; otherwise the existing value in config.ini is left alone.



*Type:*
attribute set of string



*Default:*

```nix
{ }
```



*Example:*

```nix
{ "General.api_key" = "LAZYLIBRARIAN_API_KEY"; }
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.lazylibrarian.settings



Declarative settings merged into LazyLibrarian’s \<filename>config.ini\</filename>
on every start. Each attribute is an INI section; each key inside it an entry.

LazyLibrarian rewrites \<filename>config.ini\</filename> itself at runtime — storing
only the values that differ from its defaults — so the file cannot simply be
replaced by a copy from the Nix store. Instead the keys declared here are merged
into the existing file before each start, leaving keys you have not declared
untouched. A key set here is reasserted on every restart and so overrides changes
made through the web interface.

LazyLibrarian identifies settings by key name alone and ignores which section they
were found under, rewriting each into its own canonical section. Sections here are
therefore only a hint; use the canonical one (visible in the config.ini
LazyLibrarian writes back) to avoid confusion. Booleans are written as
\<literal>1\</literal>/\<literal>0\</literal>, which LazyLibrarian accepts and
normalises to \<literal>True\</literal>/\<literal>False\</literal>.

Do not put secrets here: these values are rendered into the world-readable Nix
store. Use \<option>services.lazylibrarian.secretSettings\</option> instead.



*Type:*
attribute set of section of an INI file (attrs of INI atom (null, bool, int, float or string))



*Default:*

```nix
{ }
```



*Example:*

```nix
{
  API.book_api = "OpenLibrary";
  Git.auto_update = false;
  General.loglevel = 1;
  WebServer.http_root = "/lazylibrarian";
}

```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)


