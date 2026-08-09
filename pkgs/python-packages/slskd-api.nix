{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  setuptools-git-versioning,
  requests,
  nix-update-script,
}:

buildPythonPackage rec {
  pname = "slskd-api";
  version = "0.2.4";
  pyproject = true;

  src = fetchPypi {
    pname = "slskd_api";
    inherit version;
    hash = "sha256-7jOSBGu5n4L05GLwQgtPEdwT2ai1hpZBu3h9IaLd09E=";
  };

  build-system = [
    setuptools
    setuptools-git-versioning
  ];

  dependencies = [ requests ];

  pythonImportsCheck = [ "slskd_api" ];

  meta = {
    description = "Python client for the slskd (Soulseek) API";
    homepage = "https://github.com/bigoulours/slskd-python-api";
    license = lib.licenses.agpl3Only;
    maintainers = [ ];
  };

  passthru.updateScript = nix-update-script { };
}
