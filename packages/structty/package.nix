{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  zlib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "structty";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "steineggerlab";
    repo = "StrucTTY";
    tag = finalAttrs.version;
    hash = "sha256-b8jNd8uUcZl0+NWrNkD7p2Q+PEupWP8VNzJf14/hhVc=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ zlib ];

  # Upstream does not provide CMake install rules.
  installPhase = ''
    runHook preInstall
    install -Dm755 StrucTTY $out/bin/StrucTTY
    runHook postInstall
  '';

  passthru.category = "Structure";

  meta = {
    description = "Interactive, terminal-native protein structure viewer";
    homepage = "https://github.com/steineggerlab/StrucTTY";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.unix;
    mainProgram = "StrucTTY";
  };
})
