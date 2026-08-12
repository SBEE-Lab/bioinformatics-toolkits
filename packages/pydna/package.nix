{
  lib,
  python3Packages,
  withAllExtras ? false,
  withClipboard ? withAllExtras,
  withDownload ? withAllExtras,
  withExpress ? withAllExtras,
  withGel ? withAllExtras,
  withPrimerScreen ? withAllExtras,
}:

let
  biopython = python3Packages.biopython.overridePythonAttrs (_: {
    version = "1.87";

    src = python3Packages.fetchPypi {
      pname = "biopython";
      version = "1.87";
      hash = "sha256-hFbIA0WbZ5qXEkIuWn/ZgJ8vCJv2m7CF87B3lGrJvb8=";
    };

    # The nixpkgs patch targets the previous release and is already upstream.
    patches = [ ];
  });

  seguid = python3Packages.buildPythonPackage {
    pname = "seguid";
    version = "0.2.1";
    pyproject = true;

    src = python3Packages.fetchPypi {
      pname = "seguid";
      version = "0.2.1";
      hash = "sha256-zFSCrqYmTVNwB2qCVZt8zQgQ1OOEiUN6npEYr/qXYuU=";
    };

    build-system = [ python3Packages.poetry-core ];
    pythonImportsCheck = [ "seguid" ];
  };

  opencloning-linkml = python3Packages.buildPythonPackage {
    pname = "opencloning-linkml";
    version = "1.0.0";
    pyproject = true;

    src = python3Packages.fetchPypi {
      pname = "opencloning_linkml";
      version = "1.0.0";
      hash = "sha256-MYwuvLVjyiZiWM1pnY6sSyvWHB2MimRxMbtzUYFahNo=";
    };

    build-system = with python3Packages; [
      poetry-core
      poetry-dynamic-versioning
    ];
    dependencies = [ python3Packages.pydantic ];
    pythonImportsCheck = [ "opencloning_linkml" ];
  };

  sgffp = python3Packages.buildPythonPackage {
    pname = "sgffp";
    version = "0.22.1";
    pyproject = true;

    src = python3Packages.fetchPypi {
      pname = "sgffp";
      version = "0.22.1";
      hash = "sha256-SydGHlxg6aIq2vkJvrYh6McRK10YIhzekbPwWLefExs=";
    };

    build-system = [ python3Packages.hatchling ];
    dependencies = [ python3Packages.xmltodict ];
    pythonImportsCheck = [ "sgffp" ];
  };

  cai2 = python3Packages.buildPythonPackage {
    pname = "cai2";
    version = "1.0.5";
    pyproject = true;

    src = python3Packages.fetchPypi {
      pname = "cai2";
      version = "1.0.5";
      hash = "sha256-RM0j9JOfKbSLcvfJ2ILwxLQfUApSj4KlhcFCUBE5i70=";
    };

    # The PEP 621 author metadata is invalid for current poetry-core, while the
    # included setup.py contains the same release metadata and dependencies.
    postPatch = ''
      rm pyproject.toml
    '';
    build-system = [ python3Packages.setuptools ];
    dependencies = with python3Packages; [
      biopython
      click
      scipy
    ];
    pythonImportsCheck = [ "cai2" ];
  };
in
python3Packages.buildPythonPackage (finalAttrs: {
  pname = "pydna";
  version = "5.5.16";
  pyproject = true;

  src = python3Packages.fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-JEyq9ZhUS8H4r5WkgDeeYAYXskMDZDjAZarBGH3zrUk=";
  };

  build-system = with python3Packages; [
    poetry-core
    poetry-dynamic-versioning
  ];

  dependencies =
    (with python3Packages; [
      appdirs
      biopython
      networkx
      numpy
      opencloning-linkml
      prettytable
      pydivsufsort
      pyfiglet
      regex
      seguid
      sgffp
    ])
    ++ lib.optionals withClipboard [ python3Packages.pyperclip ]
    ++ lib.optionals withDownload (
      with python3Packages;
      [
        pyparsing
        requests
      ]
    )
    ++ lib.optionals withExpress [ cai2 ]
    ++ lib.optionals withGel (
      with python3Packages;
      [
        matplotlib
        pillow
        scipy
      ]
    )
    ++ lib.optionals withPrimerScreen [ python3Packages.pyahocorasick ];

  # Upstream pins pyfiglet 0.8.post1, whose pkg_resources use is incompatible
  # with Python 3.14's setuptools. The current pyfiglet remains API-compatible.
  pythonRelaxDeps = [ "pyfiglet" ];

  # PyPI's source distribution contains the library but not the test suite.
  doCheck = false;
  pythonImportsCheck = [
    "pydna"
    "pydna.assembly"
    "pydna.dseqrecord"
  ]
  ++ lib.optionals withDownload [ "pydna.genbankfixer" ]
  ++ lib.optionals withGel [ "pydna.gel" ]
  ++ lib.optionals withPrimerScreen [ "pydna.primer_screen" ];

  passthru = {
    category = "Library";
    optional-dependencies = {
      clipboard = [ python3Packages.pyperclip ];
      download = with python3Packages; [
        pyparsing
        requests
      ];
      express = [ cai2 ];
      gel = with python3Packages; [
        matplotlib
        pillow
        scipy
      ];
      primer-screen = [ python3Packages.pyahocorasick ];
    };
  };

  meta = {
    description = "Clone with Python! Data structures for double stranded DNA & simulation of homologous recombination, Gibson assembly, cut & paste cloning.";
    homepage = "https://github.com/pydna-group/pydna";
    changelog = "https://github.com/pydna-group/pydna/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
})
