{
  lib,
  python3Packages,
  fetchFromGitHub,
  rustPlatform,
  cargo,
  rustc,
}:
let
  # Runtime dependency split out of biotite; absent from nixpkgs, so vendor it
  # here. Pure Cython, no Rust.
  biotraj = python3Packages.buildPythonPackage (finalAttrs: {
    pname = "biotraj";
    version = "1.2.2";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "biotite-dev";
      repo = "biotraj";
      tag = "v${finalAttrs.version}";
      hash = "sha256-N2MOgrlebfX+0Men73EsDDjV3MLBqT8CbIZpFsLgw9M=";
    };

    # Version is dynamic via setuptools-scm, which needs a .git that
    # fetchFromGitHub strips; pin it explicitly.
    env.SETUPTOOLS_SCM_PRETEND_VERSION = finalAttrs.version;

    build-system = with python3Packages; [
      setuptools
      setuptools-scm
      cython
      numpy
    ];

    dependencies = with python3Packages; [
      numpy
      scipy
    ];

    # Tests need trajectory data files not shipped in the sdist.
    doCheck = false;
    pythonImportsCheck = [ "biotraj" ];

    meta = {
      description = "Basic trajectory file format functionality for Biotite; forked from MDTraj";
      homepage = "https://github.com/biotite-dev/biotraj";
      license = lib.licenses.lgpl21Plus;
      platforms = lib.platforms.unix;
    };
  });
in
python3Packages.buildPythonPackage (finalAttrs: {
  pname = "biotite";
  version = "1.7.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "biotite-dev";
    repo = "biotite";
    tag = "v${finalAttrs.version}";
    hash = "sha256-gbGrIkty6uF4h398sVY8XPaY26DVFHZwrcuI1rgSqFE=";
  };

  # Upstream omits Cargo.lock for its Rust library, so keep dependency
  # resolution stable in this package.
  cargoDeps = rustPlatform.fetchCargoVendor {
    name = "${finalAttrs.pname}-${finalAttrs.version}-vendor";
    inherit (finalAttrs) src;
    hash = "sha256-gwLDU4P5LguZEkvP0P5cLjeYYWLvBHoAGcoX/erm6EA=";
    postPatch = ''
      cp ${./Cargo.lock} Cargo.lock
    '';
  };

  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock

    # Use the Rust toolchain supplied by Nix.
    substituteInPlace setup.py \
      --replace-fail "from puccinialin import setup_rust" ""
    substituteInPlace pyproject.toml \
      --replace-fail '"puccinialin", ' ""
  '';

  env.SETUPTOOLS_SCM_PRETEND_VERSION = finalAttrs.version;

  build-system = with python3Packages; [
    setuptools
    setuptools-scm
    setuptools-rust
    cython
  ];

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    cargo
    rustc
  ];

  dependencies = [
    biotraj
  ]
  ++ (with python3Packages; [
    numpy
    requests
    msgpack
    networkx
    packaging
  ]);

  # Tests pull large reference datasets at runtime.
  doCheck = false;
  pythonImportsCheck = [
    "biotite"
    "biotite.sequence"
    "biotite.structure"
  ];

  passthru.category = "Library";

  meta = {
    description = "Comprehensive library for computational molecular biology";
    homepage = "https://www.biotite-python.org";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
})
