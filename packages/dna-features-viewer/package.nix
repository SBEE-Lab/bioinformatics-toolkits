{
  lib,
  fetchFromGitHub,
  python3Packages,
}:

let
  bcbio-gff = python3Packages.buildPythonPackage (finalAttrs: {
    pname = "bcbio-gff";
    version = "0.7.1";
    format = "wheel";

    src = python3Packages.fetchPypi {
      pname = "bcbio_gff";
      inherit (finalAttrs) version;
      format = "wheel";
      python = "py3";
      dist = "py3";
      hash = "sha256-mLGMeX+6vSf0fC7cKlxeddN6NTzCKGaExGUHKOZv+P0=";
    };

    dependencies = with python3Packages; [
      biopython
      six
    ];

    doCheck = false;
    pythonImportsCheck = [ "BCBio.GFF" ];
  });
in
python3Packages.buildPythonPackage (finalAttrs: {
  pname = "dna-features-viewer";
  version = "3.1.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Edinburgh-Genome-Foundry";
    repo = "DnaFeaturesViewer";
    tag = "v${finalAttrs.version}";
    hash = "sha256-7MXFgmuwgq3dm3QvHbtG5SGc8qGXrPtGiqh2/xySqOU=";
  };

  build-system = [ python3Packages.setuptools ];

  dependencies = with python3Packages; [
    bcbio-gff
    biopython
    matplotlib
    packaging
  ];

  nativeCheckInputs = with python3Packages; [
    bokeh
    pytestCheckHook
  ];
  enabledTestPaths = [ "tests" ];
  pythonImportsCheck = [ "dna_features_viewer" ];

  passthru.category = "Library";

  meta = {
    description = "Plot features from DNA sequences";
    homepage = "https://github.com/Edinburgh-Genome-Foundry/DnaFeaturesViewer";
    changelog = "https://github.com/Edinburgh-Genome-Foundry/DnaFeaturesViewer/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
