{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  nix-update-script,
}:

buildPythonPackage rec {
  pname = "iso639-lang";
  version = "2.6.3";
  pyproject = true;

  src = fetchPypi {
    pname = "iso639_lang";
    inherit version;
    hash = "sha256-B43bfNAYLcwENnaRrMgCLd9xWLbLCfCPeYr4I/qGQmU=";
  };

  build-system = [ setuptools ];

  pythonImportsCheck = [ "iso639" ];

  meta = {
    description = "Library to validate and convert ISO 639 language codes";
    homepage = "https://github.com/LBeaudoux/iso639";
    license = lib.licenses.mit;
    maintainers = [ ];
  };

  passthru.updateScript = nix-update-script { };
}
