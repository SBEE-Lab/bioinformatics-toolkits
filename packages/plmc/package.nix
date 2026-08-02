{
  lib,
  stdenv,
  fetchFromGitHub,
  llvmPackages,
  # Disable OpenMP when runtime floating-point results must be deterministic.
  openmpSupport ? true,
}:
stdenv.mkDerivation (_finalAttrs: {
  pname = "plmc";
  # No upstream tags/releases; track the master HEAD by commit date.
  version = "0-unstable-2023-01-21";

  src = fetchFromGitHub {
    owner = "debbiemarkslab";
    repo = "plmc";
    rev = "18c9e55e3bd2f14f4968be19a807b401996c929a";
    hash = "sha256-3P69lrNWTlv4fZekHajt7zeqcphXZDc0IyRC264bjaE=";
  };

  # gcc's -fopenmp pulls in its own libgomp; clang needs the standalone libomp.
  buildInputs = lib.optional (openmpSupport && stdenv.cc.isClang) llvmPackages.openmp;

  # Avoid the Makefile's unconditional x86-only code-generation flag.
  buildPhase = ''
    runHook preBuild
    $CC src/lib/twister.c src/lib/lbfgs.c src/plm.c src/inference.c src/weights.c src/main.c \
      -o plmc -std=c99 -O3 ${lib.optionalString stdenv.hostPlatform.isx86_64 "-msse4.2"} \
      ${lib.optionalString openmpSupport "-fopenmp"} -lm
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 plmc $out/bin/plmc
    runHook postInstall
  '';

  # Infer a small model from the bundled DHFR alignment.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/plmc -o test.params -le 16.0 -lh 0.01 -m 2 -g -f DYR_ECOLI example/protein/DHFR.a2m
    test -s test.params || { echo "plmc wrote no parameter file"; exit 1; }
    echo "install check OK: $(stat -c%s test.params) bytes of params"
    runHook postInstallCheck
  '';

  passthru.category = "Evolution & Variation";

  meta = {
    description = "Infer Potts models (couplings) from a multiple sequence alignment by pseudo-likelihood maximization";
    homepage = "https://github.com/debbiemarkslab/plmc";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "plmc";
  };
})
