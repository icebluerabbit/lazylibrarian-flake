{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
  makeWrapper,
  python3,
  nix-update-script,
}:

let
  # LazyLibrarian isn't in nixpkgs and two of its feature deps
  # (iso639-lang, slskd-api) aren't packaged either.
  python = python3.override {
    packageOverrides = self: _super: {
      iso639-lang = self.callPackage ./python-packages/iso639-lang.nix { };
      slskd-api = self.callPackage ./python-packages/slskd-api.nix { };
    };
  };

  pyEnv = python.withPackages (
    ps: with ps; [
      apprise
      apscheduler
      beautifulsoup4
      cherrypy
      cherrypy-cors
      deluge-client
      googletrans
      html5lib
      httpagentparser
      httplib2
      irc
      iso639-lang
      lxml
      mako
      pillow
      pyopenssl
      pyparsing
      pypdf
      python-magic
      rapidfuzz
      requests
      slskd-api
      tzdata
      urllib3
      webencodings
      xmltodict
    ]
  );
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lazylibrarian";
  version = "0-unstable-2026-08-13";

  src = fetchFromGitLab {
    owner = "LazyLibrarian";
    repo = "LazyLibrarian";
    rev = "02af04640b3dd91c4b319e893a8ac15f71d74f34";
    hash = "sha256-MOhCJB6c0FIky7JIe93eGMpwtpuhndSBgs53pxI+OPk=";
  };

  # Declare ourselves a distribution package, which upstream's version.py invites
  # us to do. Left as a "source" install LazyLibrarian force-triggers a self-update
  # on every start (startup.py: no writable version.txt beside the code), which
  # cannot work from the read-only store: it fails, restarts, and loops forever.
  # As a "package" it never self-updates; LAZYLIBRARIAN_HASH keeps the running
  # commit visible in the UI, so the version check still reports commits behind.
  postPatch = ''
    substituteInPlace lazylibrarian/version.py \
      --replace-fail 'LAZYLIBRARIAN_VERSION = "master"' 'LAZYLIBRARIAN_VERSION = "Package"'
    echo 'LAZYLIBRARIAN_HASH = "${finalAttrs.src.rev}"' >> lazylibrarian/version.py
  '';

  nativeBuildInputs = [ makeWrapper ];
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/lazylibrarian
    cp -r . $out/share/lazylibrarian/
    makeWrapper ${pyEnv}/bin/python $out/bin/lazylibrarian \
      --add-flags "$out/share/lazylibrarian/LazyLibrarian.py"
    runHook postInstall
  '';

  passthru = {
    inherit python pyEnv;
    # Upstream tags no releases; track the master branch by commit.
    updateScript = nix-update-script {
      extraArgs = [ "--version=branch" ];
    };
  };

  meta = {
    description = "Book, magazine and audiobook automation for Usenet and BitTorrent";
    homepage = "https://gitlab.com/LazyLibrarian/LazyLibrarian";
    license = lib.licenses.gpl3Only;
    mainProgram = "lazylibrarian";
    maintainers = [ ];
    platforms = lib.platforms.linux;
  };
})
