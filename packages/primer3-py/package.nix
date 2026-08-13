{
  lib,
  python3Packages,
  fetchFromGitHub,
}:
python3Packages.buildPythonPackage (finalAttrs: {
  pname = "primer3-py";
  version = "2.3.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "libnano";
    repo = "primer3-py";
    tag = "v${finalAttrs.version}";
    hash = "sha256-HL/kFpz5xvFDKgef2+AI/qjs2jakl00qfPSABYMGyrI=";
  };

  # Cython 3.2 remains source-compatible; upstream's compatible-release
  # constraint only reflects the version used to generate release artifacts.
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail '"Cython~=3.1.0"' '"Cython"'
  '';

  build-system = with python3Packages; [
    setuptools
    wheel
    cython
    distutils
  ];

  nativeCheckInputs = [ python3Packages.pytestCheckHook ];

  pythonImportsCheck = [
    "primer3"
    "primer3.bindings"
  ];

  # Upstream tests import from the source tree, so build extensions in place.
  preCheck = "python setup.py build_ext --inplace";
  enabledTestPaths = [ "tests" ];

  passthru.category = "Library";

  meta = {
    description = "Python bindings for Primer3 primer design and oligonucleotide analysis";
    homepage = "https://github.com/libnano/primer3-py";
    changelog = "https://github.com/libnano/primer3-py/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.unix;
  };
})
