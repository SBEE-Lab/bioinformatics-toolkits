{
  lib,
  fetchFromGitHub,
  python3Packages,
}:

python3Packages.buildPythonPackage (finalAttrs: {
  pname = "snapgene-reader";
  version = "0.1.23";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Edinburgh-Genome-Foundry";
    repo = "SnapGeneReader";
    tag = "v${finalAttrs.version}";
    hash = "sha256-fuXfkvAoRkv73GjFr2A5UuHXvDJ170iC/oU0xUSHUaA=";
  };

  build-system = [ python3Packages.setuptools ];

  dependencies = with python3Packages; [
    biopython
    html2text
    xmltodict
  ];

  nativeCheckInputs = [ python3Packages.pytestCheckHook ];
  enabledTestPaths = [ "tests" ];
  pythonImportsCheck = [ "snapgene_reader" ];

  passthru.category = "Library";

  meta = {
    description = "Convert SnapGene files to dictionaries and Biopython records";
    homepage = "https://github.com/Edinburgh-Genome-Foundry/SnapGeneReader";
    changelog = "https://github.com/Edinburgh-Genome-Foundry/SnapGeneReader/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
